use anyhow::{Context, Result, bail};
use clap::Parser;
use colored::Colorize;
use hocon::HoconLoader;
use std::collections::HashMap;
use std::fs;
use std::io::{self, Write};
use std::path::{Path, PathBuf};
use std::process::Command;
use uuid::Uuid;

const REPO_URL: &str = "https://github.com/wonderinstruments/nix-config.git";

/// Axiom configuration manager
/// Converts HOCON configs to Nix and rebuilds the system
#[derive(Parser, Debug)]
#[command(author, version, about)]
struct Args {
    /// Only validate and generate configs, don't rebuild
    #[arg(long)]
    no_rebuild: bool,

    /// Flake directory (default: /etc/nixos)
    #[arg(long, default_value = "/etc/nixos")]
    flake_dir: PathBuf,

    /// User to generate config for (default: current user)
    #[arg(long)]
    user: Option<String>,

    /// Path to user config file (default: ~/config/axiom/config.conf)
    #[arg(long)]
    config: Option<PathBuf>,

    /// Path to admin config file (default: /etc/axiom/<username>.conf)
    #[arg(long)]
    admin_config: Option<PathBuf>,

    /// Initialize config files from templates if they don't exist
    #[arg(long)]
    init: bool,

    /// Reset config files to template defaults
    #[arg(long)]
    reset: bool,

    /// Update to a specific version. Use without value for latest release,
    /// specify a version (e.g. v1.2.3), or 'unstable' for latest commit.
    #[arg(long, value_name = "VERSION")]
    update: Option<Option<String>>,

    /// Skip the update check
    #[arg(long)]
    no_update_check: bool,

    /// Regenerate configs for all users (not just current user)
    #[arg(long)]
    all_users: bool,

    /// Regenerate configs for specific users (comma-separated)
    #[arg(long, value_delimiter = ',')]
    users: Option<Vec<String>>,
}

fn main() -> Result<()> {
    let args = Args::parse();

    // Check if running as root - if not, re-exec with sudo (passwordless via sudoers rule)
    let is_root = unsafe { libc::geteuid() } == 0;
    if !is_root {
        let exe = std::env::current_exe().context("Failed to get current executable")?;
        let status = Command::new("sudo")
            .arg("--non-interactive")
            .arg(&exe)
            .args(std::env::args().skip(1))
            .status()
            .context("Failed to run with sudo. Make sure axiom-rebuild is in sudoers.")?;
        std::process::exit(status.code().unwrap_or(1));
    }

    // Get the real user even when running under sudo
    let current_username = args.user.clone().unwrap_or_else(|| {
        std::env::var("SUDO_USER")
            .or_else(|_| std::env::var("USER"))
            .expect("Could not determine current user")
    });

    // Check if the original user is in the wheel group
    let is_wheel_user = is_user_in_wheel(&current_username);

    // Restrict non-wheel users
    if !is_wheel_user {
        if args.update.is_some() {
            bail!("Only administrators can update the system. Run without --update to rebuild your config.");
        }
        if args.all_users {
            bail!("Only administrators can use --all-users.");
        }
        if args.users.is_some() {
            bail!("Only administrators can use --users.");
        }
        if args.user.is_some() && args.user.as_ref() != Some(&current_username) {
            bail!("Only administrators can generate configs for other users.");
        }
    }

    // Handle --update if specified (wheel users only, checked above)
    if let Some(version_opt) = &args.update {
        return handle_update(version_opt.clone(), &args);
    }

    // Check for updates (unless disabled) - only for wheel users
    if !args.no_update_check && is_wheel_user {
        check_for_updates(&args.flake_dir)?;
    }

    // Get the real user's home directory
    let current_home_dir = if let Ok(sudo_user) = std::env::var("SUDO_USER") {
        format!("/home/{}", sudo_user)
    } else {
        std::env::var("HOME").expect("Could not determine home directory")
    };
    let current_config_dir = PathBuf::from(&current_home_dir).join("config/axiom");

    let current_user_config_path = args.config.clone().unwrap_or_else(|| current_config_dir.join("config.conf"));
    let current_admin_config_path = args.admin_config.clone().unwrap_or_else(|| PathBuf::from("/etc/axiom").join(format!("{}.conf", current_username)));

    let template_dir = args.flake_dir.join("templates");
    let output_dir = args.flake_dir.join("config/users");
    let system_output_dir = args.flake_dir.join("config/system");
    let users_config_path = PathBuf::from("/etc/axiom/users.conf");
    let system_config_path = PathBuf::from("/etc/axiom/system.conf");

    // Handle --init or --reset (for current user only)
    if args.init || args.reset {
        init_configs(&current_config_dir, &current_user_config_path, &current_admin_config_path, &template_dir, args.reset)?;
        if args.init && !args.reset {
            println!("{}", "Config files initialized. Edit them and run axiom-rebuild again.".green());
            return Ok(());
        }
    }

    // Auto-copy users template if it doesn't exist
    if !users_config_path.exists() {
        let users_template = template_dir.join("users.conf");
        if users_template.exists() {
            fs::create_dir_all(users_config_path.parent().unwrap_or(Path::new("/etc/axiom")))?;
            fs::copy(&users_template, &users_config_path)
                .with_context(|| format!("Failed to copy users template to {}", users_config_path.display()))?;
            #[cfg(unix)]
            {
                use std::os::unix::fs::PermissionsExt;
                let perms = std::fs::Permissions::from_mode(0o644);
                fs::set_permissions(&users_config_path, perms)?;
            }
            println!("  {} {}", "Created users config:".green(), users_config_path.display());
        }
    }

    // Auto-copy system template if it doesn't exist
    if !system_config_path.exists() {
        let system_template = template_dir.join("system.conf");
        if system_template.exists() {
            fs::create_dir_all(system_config_path.parent().unwrap_or(Path::new("/etc/axiom")))?;
            fs::copy(&system_template, &system_config_path)
                .with_context(|| format!("Failed to copy system template to {}", system_config_path.display()))?;
            #[cfg(unix)]
            {
                use std::os::unix::fs::PermissionsExt;
                let perms = std::fs::Permissions::from_mode(0o644);
                fs::set_permissions(&system_config_path, perms)?;
            }
            println!("  {} {}", "Created system config:".green(), system_config_path.display());
        }
    }

    // Ensure output directories exist
    fs::create_dir_all(&output_dir)
        .with_context(|| format!("Failed to create output directory: {}", output_dir.display()))?;
    fs::create_dir_all(&system_output_dir)
        .with_context(|| format!("Failed to create system output directory: {}", system_output_dir.display()))?;

    // Parse configs
    println!("{}", "Parsing configuration...".blue());

    // Get list of all users from users.conf (curator is always included)
    let all_usernames = get_all_usernames(&users_config_path)?;

    // Determine which users to regenerate configs for
    let users_to_update: Vec<String> = if args.all_users {
        // --all-users: regenerate for everyone
        all_usernames.clone()
    } else if let Some(ref specified_users) = args.users {
        // --users=alice,bob: regenerate for specific users
        specified_users.clone()
    } else {
        // Default: just the current user
        vec![current_username.clone()]
    };

    // For users NOT in our update list, create their .nix if it doesn't exist
    // (handles new users added to users.conf)
    for user in &all_usernames {
        let user_nix_path = output_dir.join(format!("{}.nix", user));
        if !user_nix_path.exists() && !users_to_update.contains(user) {
            // New user - generate their config with defaults
            println!("  {} new user: {}", "Setting up".blue(), user);
            setup_user_config(user, &template_dir, &output_dir)?;
        }
    }

    // Generate Nix configuration for users we're updating
    println!("{}", "Generating Nix configuration...".blue());
    for user in &users_to_update {
        setup_user_config(user, &template_dir, &output_dir)?;
    }

    // Stage all config/users/*.nix files so flakes can see them
    // (flakes only see files tracked by git)
    let _ = Command::new("git")
        .args(["-C", args.flake_dir.to_str().unwrap_or("/etc/nixos"), "add", "config/users", "config/system"])
        .status();

    // Generate users-data.nix from users.conf
    let users_data_path = system_output_dir.join("users-data.nix");
    let users_data_content = generate_users_data(&users_config_path)?;
    fs::write(&users_data_path, &users_data_content)
        .with_context(|| format!("Failed to write users data: {}", users_data_path.display()))?;
    println!("  {} {}", "Generated:".green(), users_data_path.display());

    // Generate system-data.nix from system.conf
    let system_data_path = system_output_dir.join("system-data.nix");
    let system_data_content = generate_system_data(&system_config_path)?;
    fs::write(&system_data_path, &system_data_content)
        .with_context(|| format!("Failed to write system data: {}", system_data_path.display()))?;
    println!("  {} {}", "Generated:".green(), system_data_path.display());

    // Rebuild if requested
    if !args.no_rebuild {
        println!("{}", "Rebuilding system...".blue());

        // Add flake directory to git safe.directory to avoid ownership errors
        // (we're running as root but /etc/nixos may be owned by root)
        let _ = Command::new("git")
            .args(["config", "--global", "--add", "safe.directory", args.flake_dir.to_str().unwrap_or("/etc/nixos")])
            .status();

        // Already running as root via sudo
        let status = Command::new("nixos-rebuild")
            .args(["switch", "--flake", &format!("{}#axiom", args.flake_dir.display())])
            .status()
            .context("Failed to run nixos-rebuild")?;

        if status.success() {
            println!("{}", "Rebuild complete!".green().bold());
            
            // Commit config changes to git (run as original user to avoid ownership issues)
            commit_config_changes(&current_config_dir, &current_user_config_path, &current_username)?;
        } else {
            bail!("nixos-rebuild failed with exit code: {:?}", status.code());
        }
    } else {
        println!("{}", "Skipping rebuild (--no-rebuild)".yellow());
    }

    Ok(())
}

fn init_configs(
    config_dir: &Path,
    user_config_path: &Path,
    admin_config_path: &Path,
    template_dir: &Path,
    force: bool,
) -> Result<()> {
    // Create user config directory
    fs::create_dir_all(config_dir)
        .with_context(|| format!("Failed to create config directory: {}", config_dir.display()))?;

    // Create admin config directory (/etc/axiom/) - requires sudo
    let admin_config_dir = admin_config_path.parent().unwrap_or(Path::new("/etc/axiom"));
    if !admin_config_dir.exists() {
        fs::create_dir_all(admin_config_dir)
            .with_context(|| format!("Failed to create admin config directory: {} (try running with sudo)", admin_config_dir.display()))?;
    }

    let user_template = template_dir.join("user-config.conf");
    let admin_template = template_dir.join("admin-config.conf");

    if force || !user_config_path.exists() {
        if user_template.exists() {
            fs::copy(&user_template, user_config_path)?;
            println!("  {} {}", "Created:".green(), user_config_path.display());
        } else {
            println!("  {} User template not found: {}", "Warning:".yellow(), user_template.display());
        }
    }

    if force || !admin_config_path.exists() {
        if admin_template.exists() {
            fs::copy(&admin_template, admin_config_path)?;
            // Set admin config to be owned by root and not world-writable
            #[cfg(unix)]
            {
                use std::os::unix::fs::PermissionsExt;
                let perms = std::fs::Permissions::from_mode(0o644);
                fs::set_permissions(admin_config_path, perms)?;
            }
            println!("  {} {} (requires sudo to edit)", "Created:".green(), admin_config_path.display());
        } else {
            println!("  {} Admin template not found: {}", "Warning:".yellow(), admin_template.display());
        }
    }

    Ok(())
}

/// Check if a user is in the wheel group (has admin privileges)
fn is_user_in_wheel(username: &str) -> bool {
    // Use `id` command to get groups for the user
    if let Ok(output) = Command::new("id").args(["-Gn", username]).output() {
        if let Ok(groups) = String::from_utf8(output.stdout) {
            return groups.split_whitespace().any(|g| g == "wheel");
        }
    }
    false
}

/// Get list of all usernames from users.conf (curator is always included)
fn get_all_usernames(users_config_path: &Path) -> Result<Vec<String>> {
    let mut usernames = vec!["curator".to_string()];

    if users_config_path.exists() {
        let users_config = parse_hocon(users_config_path)?;
        if let Some(HoconValue::Object(users_obj)) = users_config.get("users") {
            for (key, value) in users_obj {
                // Each user entry should be an object (not the curator string key)
                if matches!(value, HoconValue::Object(_)) {
                    usernames.push(key.clone());
                }
            }
        }
    }

    Ok(usernames)
}

/// Set up config files and generate nix for a user
fn setup_user_config(username: &str, template_dir: &Path, output_dir: &Path) -> Result<()> {
    let user_home = format!("/home/{}", username);
    let user_config_dir = PathBuf::from(&user_home).join("config/axiom");
    let user_config_file = user_config_dir.join("config.conf");
    let user_admin_config = PathBuf::from("/etc/axiom").join(format!("{}.conf", username));

    // Create user config directory if it doesn't exist
    if !user_config_dir.exists() {
        fs::create_dir_all(&user_config_dir).ok(); // May fail if user home doesn't exist yet
    }

    // Copy user config template if missing
    if !user_config_file.exists() {
        let user_template = template_dir.join("user-config.conf");
        if user_template.exists() && user_config_dir.exists() {
            fs::copy(&user_template, &user_config_file).ok();
            // Set ownership to user (we're running as root)
            #[cfg(unix)]
            {
                if let Ok(output) = Command::new("id").args(["-u", username]).output() {
                    if let Ok(uid_str) = String::from_utf8(output.stdout) {
                        if let Ok(uid) = uid_str.trim().parse::<u32>() {
                            let _ = Command::new("chown")
                                .args(["-R", &format!("{}:{}", uid, uid), user_config_dir.to_str().unwrap_or("")])
                                .status();
                        }
                    }
                }
            }
            println!("  {} {} for {}", "Created user config:".green(), user_config_file.display(), username);
        }
    }

    // Copy admin config template if missing
    if !user_admin_config.exists() {
        let admin_template = template_dir.join("admin-config.conf");
        if admin_template.exists() {
            fs::create_dir_all(user_admin_config.parent().unwrap_or(Path::new("/etc/axiom")))?;
            fs::copy(&admin_template, &user_admin_config)
                .with_context(|| format!("Failed to copy admin template for {}", username))?;
            #[cfg(unix)]
            {
                use std::os::unix::fs::PermissionsExt;
                let perms = std::fs::Permissions::from_mode(0o644);
                fs::set_permissions(&user_admin_config, perms)?;
            }
            println!("  {} {} for {}", "Created admin config:".green(), user_admin_config.display(), username);
        }
    }

    // Parse user's configs and generate nix
    let user_config_data = if user_config_file.exists() {
        parse_hocon(&user_config_file)
            .with_context(|| format!("Failed to parse user config for {}: {}", username, user_config_file.display()))?
    } else {
        HashMap::new() // Empty config if file doesn't exist yet
    };

    let admin_config_data = if user_admin_config.exists() {
        Some(parse_hocon(&user_admin_config)
            .with_context(|| format!("Failed to parse admin config for {}: {}", username, user_admin_config.display()))?)
    } else {
        None
    };

    let nix_content = generate_nix(username, &user_config_data, admin_config_data.as_ref())?;
    let output_path = output_dir.join(format!("{}.nix", username));
    
    fs::write(&output_path, &nix_content)
        .with_context(|| format!("Failed to write Nix config for {}: {}", username, output_path.display()))?;

    println!("  {} {}", "Generated:".green(), output_path.display());
    Ok(())
}

fn parse_hocon(path: &Path) -> Result<HashMap<String, HoconValue>> {
    let content = fs::read_to_string(path)?;
    let hocon = HoconLoader::new()
        .load_str(&content)?
        .hocon()?;

    hocon_to_map(&hocon)
}

#[derive(Debug, Clone)]
enum HoconValue {
    String(String),
    Integer(i64),
    Float(f64),
    Boolean(bool),
    Array(Vec<HoconValue>),
    Object(HashMap<String, HoconValue>),
    Null,
}

fn hocon_to_map(hocon: &hocon::Hocon) -> Result<HashMap<String, HoconValue>> {
    match hocon {
        hocon::Hocon::Hash(map) => {
            let mut result = HashMap::new();
            for (k, v) in map {
                result.insert(k.clone(), hocon_to_value(v)?);
            }
            Ok(result)
        }
        _ => bail!("Expected root to be an object"),
    }
}

fn hocon_to_value(hocon: &hocon::Hocon) -> Result<HoconValue> {
    match hocon {
        hocon::Hocon::String(s) => Ok(HoconValue::String(s.clone())),
        hocon::Hocon::Integer(i) => Ok(HoconValue::Integer(*i)),
        hocon::Hocon::Real(f) => Ok(HoconValue::Float(*f)),
        hocon::Hocon::Boolean(b) => Ok(HoconValue::Boolean(*b)),
        hocon::Hocon::Array(arr) => {
            let values: Result<Vec<_>> = arr.iter().map(hocon_to_value).collect();
            Ok(HoconValue::Array(values?))
        }
        hocon::Hocon::Hash(map) => {
            let mut result = HashMap::new();
            for (k, v) in map {
                result.insert(k.clone(), hocon_to_value(v)?);
            }
            Ok(HoconValue::Object(result))
        }
        hocon::Hocon::Null => Ok(HoconValue::Null),
        hocon::Hocon::BadValue(e) => bail!("Bad value in config: {:?}", e),
    }
}

fn generate_nix(
    username: &str,
    user_config: &HashMap<String, HoconValue>,
    admin_config: Option<&HashMap<String, HoconValue>>,
) -> Result<String> {
    let mut nix = String::new();

    nix.push_str(&format!(
        r#"# Auto-generated by axiom-rebuild for user: {}
# Do not edit this file directly - edit ~/.config/axiom/config.conf instead

{{ ... }}:
{{
"#,
        username
    ));

    // Generate user config options
    generate_nix_attrs(&mut nix, "axiom", user_config, 1)?;

    // Generate admin config options if present
    if let Some(admin) = admin_config {
        nix.push('\n');
        generate_nix_attrs(&mut nix, "axiom.admin", admin, 1)?;
    }

    nix.push_str("}\n");

    Ok(nix)
}

fn generate_nix_attrs(
    output: &mut String,
    prefix: &str,
    config: &HashMap<String, HoconValue>,
    indent: usize,
) -> Result<()> {
    let indent_str = "  ".repeat(indent);

    for (key, value) in config {
        let full_key = if prefix.is_empty() {
            key.clone()
        } else {
            format!("{}.{}", prefix, key)
        };

        match value {
            HoconValue::Object(obj) => {
                // Recurse into nested objects
                generate_nix_attrs(output, &full_key, obj, indent)?;
            }
            _ => {
                // Write leaf value
                let nix_value = hocon_value_to_nix(value)?;
                output.push_str(&format!("{}{} = {};\n", indent_str, full_key, nix_value));
            }
        }
    }

    Ok(())
}

fn hocon_value_to_nix(value: &HoconValue) -> Result<String> {
    match value {
        HoconValue::String(s) => Ok(format!("\"{}\"", escape_nix_string(s))),
        HoconValue::Integer(i) => Ok(i.to_string()),
        HoconValue::Float(f) => Ok(f.to_string()),
        HoconValue::Boolean(b) => Ok(if *b { "true" } else { "false" }.to_string()),
        HoconValue::Array(arr) => {
            let items: Result<Vec<_>> = arr.iter().map(hocon_value_to_nix).collect();
            Ok(format!("[ {} ]", items?.join(" ")))
        }
        HoconValue::Object(obj) => {
            let mut items = Vec::new();
            for (k, v) in obj {
                items.push(format!("{} = {}", k, hocon_value_to_nix(v)?));
            }
            Ok(format!("{{ {} }}", items.join("; ")))
        }
        HoconValue::Null => Ok("null".to_string()),
    }
}

fn escape_nix_string(s: &str) -> String {
    s.replace('\\', "\\\\")
        .replace('"', "\\\"")
        .replace('\n', "\\n")
        .replace('\t', "\\t")
        .replace("${", "\\${")
}

/// Generate users-data.nix from /etc/axiom/users.conf
/// This creates a simple data file that the users.nix module imports
fn generate_users_data(users_config_path: &Path) -> Result<String> {
    let mut nix = String::new();
    nix.push_str("# Auto-generated by axiom-rebuild from /etc/axiom/users.conf\n");
    nix.push_str("# Do not edit this file directly - edit /etc/axiom/users.conf instead\n\n");

    // If users.conf doesn't exist yet, return empty data
    if !users_config_path.exists() {
        nix.push_str("{\n");
        nix.push_str("  usernames = [];\n");
        nix.push_str("  users = {};\n");
        nix.push_str("}\n");
        return Ok(nix);
    }

    let users_config = parse_hocon(users_config_path)
        .with_context(|| format!("Failed to parse users config: {}", users_config_path.display()))?;

    // Extract the "curator" object from the config (optional)
    let curator_obj = match users_config.get("curator") {
        Some(HoconValue::Object(obj)) => Some(obj),
        _ => None,
    };

    // Extract the "users" object from the config (optional)
    let users_obj_opt = match users_config.get("users") {
        Some(HoconValue::Object(obj)) => Some(obj),
        _ => None,
    };

    // Collect curator config
    let mut curator_fields: Vec<String> = Vec::new();
    if let Some(curator) = curator_obj {
        if let Some(HoconValue::String(s)) = curator.get("displayName") {
            curator_fields.push(format!("  displayName = \"{}\";", escape_nix_string(s)));
        }
        match curator.get("hashedPassword") {
            Some(HoconValue::String(s)) => curator_fields.push(format!("  hashedPassword = \"{}\";", escape_nix_string(s))),
            Some(HoconValue::Null) => curator_fields.push("  hashedPassword = \"\";".to_string()),
            _ => (),
        }
    }

    // Collect usernames and user defs
    let mut usernames: Vec<String> = Vec::new();
    let mut user_defs: Vec<String> = Vec::new();

    if let Some(users_obj) = users_obj_opt {
        for (key, value) in users_obj {
            // Each user should be an object
            if let HoconValue::Object(user_data) = value {
                usernames.push(key.clone());

                // Extract user fields
                let display_name = match user_data.get("displayName") {
                    Some(HoconValue::String(s)) => format!("\"{}\"", escape_nix_string(s)),
                    _ => format!("\"{}\"", key),
                };

                let has_root = match user_data.get("hasRootPermissions") {
                    Some(HoconValue::Boolean(b)) => if *b { "true" } else { "false" },
                    _ => "false",
                };

                let hashed_password = match user_data.get("hashedPassword") {
                    Some(HoconValue::String(s)) => format!("\"{}\"", escape_nix_string(s)),
                    Some(HoconValue::Null) => "\"\"".to_string(),  // Empty string = passwordless login
                    _ => "\"\"".to_string(),  // Default to passwordless
                };

                user_defs.push(format!(
                    "    {} = {{\n      displayName = {};\n      hasRootPermissions = {};\n      hashedPassword = {};\n    }};",
                    key, display_name, has_root, hashed_password
                ));
            }
        }
    }

    // Generate the Nix attrset
    nix.push_str("{\n");

    // Curator config
    nix.push_str("  curator = {\n");
    for field in &curator_fields {
        nix.push_str(field);
        nix.push('\n');
    }
    nix.push_str("  };\n\n");
    
    // Usernames list
    let usernames_str: Vec<String> = usernames.iter().map(|u| format!("\"{}\"", u)).collect();
    nix.push_str(&format!("  usernames = [ {} ];\n\n", usernames_str.join(" ")));

    // Users attrset
    nix.push_str("  users = {\n");
    for def in user_defs {
        nix.push_str(&def);
        nix.push('\n');
    }
    nix.push_str("  };\n");
    nix.push_str("}\n");

    Ok(nix)
}

/// Generate system-data.nix from /etc/axiom/system.conf
/// This creates a simple data file that the system.nix module imports
fn generate_system_data(system_config_path: &Path) -> Result<String> {
    let mut nix = String::new();
    nix.push_str("# Auto-generated by axiom-rebuild from /etc/axiom/system.conf\n");
    nix.push_str("# Do not edit this file directly - edit /etc/axiom/system.conf instead\n\n");

    // Default values
    let mut hostname = "axiom".to_string();
    let mut timezone = "America/Los_Angeles".to_string();
    let mut locale = "en_US.UTF-8".to_string();

    // If system.conf exists, parse it
    if system_config_path.exists() {
        let system_config = parse_hocon(system_config_path)
            .with_context(|| format!("Failed to parse system config: {}", system_config_path.display()))?;

        // Extract the "system" object from the config
        if let Some(HoconValue::Object(system_obj)) = system_config.get("system") {
            if let Some(HoconValue::String(s)) = system_obj.get("hostname") {
                hostname = s.clone();
            }
            if let Some(HoconValue::String(s)) = system_obj.get("timezone") {
                timezone = s.clone();
            }
            if let Some(HoconValue::String(s)) = system_obj.get("locale") {
                locale = s.clone();
            }
        }
    }

    // Generate the Nix attrset
    nix.push_str("{\n");
    nix.push_str(&format!("  hostname = \"{}\";\n", escape_nix_string(&hostname)));
    nix.push_str(&format!("  timezone = \"{}\";\n", escape_nix_string(&timezone)));
    nix.push_str(&format!("  locale = \"{}\";\n", escape_nix_string(&locale)));
    nix.push_str("}\n");

    Ok(nix)
}

/// Represents the installed version info
#[derive(Debug)]
struct VersionInfo {
    version: String,
    commit: Option<String>,
    is_release: bool,
}

impl std::fmt::Display for VersionInfo {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        if self.is_release {
            write!(f, "v{}", self.version)
        } else if let Some(commit) = &self.commit {
            write!(f, "unstable ({})", &commit[..7.min(commit.len())])
        } else {
            write!(f, "{}", self.version)
        }
    }
}

/// Read the current installed version from VERSION file
fn read_installed_version(flake_dir: &Path) -> Result<VersionInfo> {
    let version_file = flake_dir.join("VERSION");
    
    if !version_file.exists() {
        return Ok(VersionInfo {
            version: "0.0.0".to_string(),
            commit: None,
            is_release: false,
        });
    }
    
    let content = fs::read_to_string(&version_file)
        .context("Failed to read VERSION file")?;
    let version = content.trim().to_string();
    
    // Check if we're on a release by looking at the git state in /etc/nixos
    // If VERSION matches a tag pattern and there's no COMMIT file, it's a release
    let commit_file = flake_dir.join("COMMIT");
    let commit = if commit_file.exists() {
        Some(fs::read_to_string(&commit_file)
            .unwrap_or_default()
            .trim()
            .to_string())
    } else {
        None
    };
    
    // It's a release if VERSION looks like semver and there's no COMMIT file
    let is_release = commit.is_none() && 
        version.split('.').count() >= 2 &&
        version.chars().next().map(|c| c.is_ascii_digit()).unwrap_or(false);
    
    Ok(VersionInfo {
        version,
        commit,
        is_release,
    })
}

/// Compare semver versions, returns true if remote is newer
fn is_newer_version(local: &str, remote: &str) -> bool {
    let parse_version = |v: &str| -> (u32, u32, u32) {
        let v = v.trim_start_matches('v');
        let parts: Vec<u32> = v.split('.')
            .filter_map(|p| p.parse().ok())
            .collect();
        (
            parts.first().copied().unwrap_or(0),
            parts.get(1).copied().unwrap_or(0),
            parts.get(2).copied().unwrap_or(0),
        )
    };
    
    let local_v = parse_version(local);
    let remote_v = parse_version(remote);
    
    remote_v > local_v
}

/// Check for updates and prompt the user
fn check_for_updates(flake_dir: &Path) -> Result<()> {
    let installed = read_installed_version(flake_dir)?;
    
    // Try to get latest release tag (silently fail if no network)
    let latest_tag = match get_latest_release_tag() {
        Ok(tag) => tag,
        Err(_) => return Ok(()), // Can't check, continue silently
    };
    
    let latest_version = latest_tag.trim_start_matches('v');
    
    // Check if update is available
    let update_available = if installed.is_release {
        is_newer_version(&installed.version, latest_version)
    } else {
        // On unstable - always offer to go to latest release
        true
    };
    
    if !update_available {
        return Ok(());
    }
    
    // Show update prompt
    println!();
    println!("{}", "━".repeat(50).dimmed());
    if installed.is_release {
        println!(
            "{}  {} → {}",
            "Update available:".yellow().bold(),
            format!("v{}", installed.version).dimmed(),
            format!("v{}", latest_version).green().bold()
        );
    } else {
        println!(
            "{}  {} → {}",
            "Release available:".yellow().bold(),
            installed.to_string().dimmed(),
            format!("v{}", latest_version).green().bold()
        );
    }
    println!("{}", "━".repeat(50).dimmed());
    
    print!("Would you like to update now? [y/N] ");
    io::stdout().flush()?;
    
    let mut input = String::new();
    io::stdin().read_line(&mut input)?;
    
    if input.trim().eq_ignore_ascii_case("y") {
        // Re-exec with --update flag
        let exe = std::env::current_exe().context("Failed to get current executable")?;
        let status = Command::new(&exe)
            .arg("--update")
            .status()
            .context("Failed to run update")?;
        
        if status.success() {
            std::process::exit(0);
        } else {
            bail!("Update failed");
        }
    }
    
    println!();
    Ok(())
}

fn commit_config_changes(config_dir: &Path, config_path: &Path, username: &str) -> Result<()> {
    // Helper to run git commands as the original user (not root)
    // This avoids "dubious ownership" errors when the user later runs git
    let git_as_user = |args: &[&str]| -> std::io::Result<std::process::Output> {
        Command::new("sudo")
            .args(["-u", username, "git"])
            .args(args)
            .current_dir(config_dir)
            .output()
    };
    
    let git_as_user_status = |args: &[&str]| -> Result<bool> {
        let status = Command::new("sudo")
            .args(["-u", username, "git"])
            .args(args)
            .current_dir(config_dir)
            .status()
            .context("Failed to run git command")?;
        Ok(status.success())
    };

    // Initialize git repo if it doesn't exist
    let git_dir = config_dir.join(".git");
    if !git_dir.exists() {
        println!("{}", "Initializing git repository for config...".blue());
        if !git_as_user_status(&["init"])? {
            bail!("git init failed");
        }
        
        // Set local git config for this repo
        git_as_user_status(&["config", "user.email", "axiom@localhost"])?;
        git_as_user_status(&["config", "user.name", "axiom-rebuild"])?;
    }

    // Check if there are any changes to commit
    let diff_output = git_as_user(&["diff", "--color=always", "--", config_path.file_name().unwrap_or_default().to_str().unwrap_or("")])
        .context("Failed to run git diff")?;

    let diff_str = String::from_utf8_lossy(&diff_output.stdout);
    
    // Also check for untracked files
    let status_output = git_as_user(&["status", "--porcelain", "--", config_path.file_name().unwrap_or_default().to_str().unwrap_or("")])
        .context("Failed to run git status")?;

    let status_str = String::from_utf8_lossy(&status_output.stdout);
    
    if diff_str.is_empty() && status_str.is_empty() {
        println!("  {}", "(no config changes to commit)".dimmed());
        return Ok(());
    }

    // Print the diff
    if !diff_str.is_empty() {
        println!("\n{}", "Config changes:".blue().bold());
        println!("{}", diff_str);
    } else if !status_str.is_empty() {
        println!("\n{}", "New config file:".blue().bold());
    }

    // Stage the config file
    if !git_as_user_status(&["add", "--", config_path.file_name().unwrap_or_default().to_str().unwrap_or("")])? {
        bail!("git add failed");
    }

    // Commit with a timestamp
    let timestamp = chrono::Local::now().format("%Y-%m-%d %H:%M:%S");
    let commit_msg = format!("axiom-rebuild: {}", timestamp);
    
    if git_as_user_status(&["commit", "-m", &commit_msg])? {
        println!("  {} {}", "Committed:".green(), commit_msg);
    }
    // If commit fails (e.g., nothing to commit), that's okay

    Ok(())
}

/// Handle the --update flag
fn handle_update(version: Option<String>, args: &Args) -> Result<()> {
    let flake_dir = &args.flake_dir;
    let backup_id = Uuid::new_v4();
    let backup_dir = PathBuf::from(format!("/tmp/nixos-backup-{}", backup_id));

    // Determine what version/ref to fetch
    let is_unstable = matches!(&version, Some(v) if v == "unstable");
    let target_ref = match &version {
        None => {
            // No version specified - get latest release tag
            println!("{}", "Fetching latest release...".blue());
            get_latest_release_tag()?
        }
        Some(v) if v == "unstable" => {
            println!("{}", "Fetching latest commit (unstable)...".blue());
            "HEAD".to_string()
        }
        Some(v) => {
            // Specific version requested
            println!("{} {}", "Fetching version:".blue(), v);
            v.clone()
        }
    };

    println!("  {} {}", "Target:".green(), target_ref);

    // Create temporary directory for cloning
    let temp_dir = tempfile::tempdir().context("Failed to create temp directory")?;
    let clone_path = temp_dir.path();

    // Clone the repo
    println!("{}", "Cloning repository...".blue());
    let clone_status = Command::new("git")
        .args(["clone", "--depth", "1", "--branch", &target_ref, REPO_URL])
        .arg(clone_path)
        .status();

    // If --branch fails (e.g., for HEAD), try clone + checkout
    let clone_success = match clone_status {
        Ok(status) if status.success() => true,
        _ => {
            // Fallback: full clone then checkout
            println!("  {} {}", "Retrying with full clone...".yellow(), target_ref);
            let status = Command::new("git")
                .args(["clone", REPO_URL])
                .arg(clone_path)
                .status()
                .context("Failed to clone repository")?;

            if !status.success() {
                bail!("Failed to clone repository");
            }

            // Checkout the specific ref
            if target_ref != "HEAD" {
                let status = Command::new("git")
                    .args(["checkout", &target_ref])
                    .current_dir(clone_path)
                    .status()
                    .context("Failed to checkout ref")?;

                if !status.success() {
                    bail!("Failed to checkout {}", target_ref);
                }
            }
            true
        }
    };

    if !clone_success {
        bail!("Failed to clone repository");
    }

    // Get the commit hash for tracking (especially for unstable)
    let commit_hash = Command::new("git")
        .args(["rev-parse", "HEAD"])
        .current_dir(clone_path)
        .output()
        .ok()
        .and_then(|o| String::from_utf8(o.stdout).ok())
        .map(|s| s.trim().to_string());

    // Create backup of current /etc/nixos
    println!("{}", "Creating backup of current configuration...".blue());
    if flake_dir.exists() {
        let status = Command::new("cp")
            .args(["-a"])
            .arg(flake_dir)
            .arg(&backup_dir)
            .status()
            .context("Failed to create backup")?;

        if !status.success() {
            bail!("Failed to create backup of {}", flake_dir.display());
        }
        println!("  {} {}", "Backup created:".green(), backup_dir.display());
    }

    // Copy new config to /etc/nixos, preserving hardware-configuration.nix
    println!("{}", "Installing new configuration...".blue());

    // Use rsync to copy, excluding hardware-configuration.nix and .git
    let status = Command::new("rsync")
        .args([
            "-av",
            "--delete",
            "--exclude",
            "hardware-configuration.nix",
            "--exclude",
            ".git",
        ])
        .arg(format!("{}/", clone_path.display()))
        .arg(format!("{}/", flake_dir.display()))
        .status()
        .context("Failed to copy new configuration")?;

    if !status.success() {
        // Restore from backup
        println!("{}", "Copy failed, restoring from backup...".red());
        restore_from_backup(&backup_dir, flake_dir)?;
        bail!("Failed to install new configuration");
    }

    // Write COMMIT file for unstable builds, remove it for releases
    let commit_file = flake_dir.join("COMMIT");
    if is_unstable {
        if let Some(hash) = &commit_hash {
            fs::write(&commit_file, hash).ok();
        }
    } else {
        // Remove COMMIT file for release builds
        if commit_file.exists() {
            fs::remove_file(&commit_file).ok();
        }
    }

    // Initialize git in /etc/nixos for flake support
    // Flakes require the directory to be a git repo
    println!("{}", "Initializing git for flake support...".blue());
    if !flake_dir.join(".git").exists() {
        let status = Command::new("git")
            .arg("init")
            .current_dir(flake_dir)
            .status()
            .context("Failed to init git")?;

        if !status.success() {
            println!("{}", "Warning: git init failed, flake may not work correctly".yellow());
        }
    }

    // Stage all files so flake can see them
    let status = Command::new("git")
        .args(["add", "-A"])
        .current_dir(flake_dir)
        .status()
        .context("Failed to stage files")?;

    if !status.success() {
        println!("{}", "Warning: git add failed".yellow());
    }

    // Now proceed with normal rebuild
    println!("{}", "Proceeding with rebuild...".blue());

    // Re-run axiom-rebuild without --update to do the actual rebuild
    let exe = std::env::current_exe().context("Failed to get current executable")?;
    let mut rebuild_args: Vec<String> = vec![];

    if args.no_rebuild {
        rebuild_args.push("--no-rebuild".to_string());
    }
    rebuild_args.push("--flake-dir".to_string());
    rebuild_args.push(flake_dir.to_string_lossy().to_string());

    if let Some(user) = &args.user {
        rebuild_args.push("--user".to_string());
        rebuild_args.push(user.clone());
    }
    if let Some(config) = &args.config {
        rebuild_args.push("--config".to_string());
        rebuild_args.push(config.to_string_lossy().to_string());
    }
    if let Some(admin_config) = &args.admin_config {
        rebuild_args.push("--admin-config".to_string());
        rebuild_args.push(admin_config.to_string_lossy().to_string());
    }
    if args.init {
        rebuild_args.push("--init".to_string());
    }
    if args.reset {
        rebuild_args.push("--reset".to_string());
    }

    let status = Command::new(&exe)
        .args(&rebuild_args)
        .status()
        .context("Failed to run rebuild")?;

    if !status.success() {
        // Rebuild failed - restore from backup
        println!("\n{}", "Rebuild failed! Restoring from backup...".red().bold());
        restore_from_backup(&backup_dir, flake_dir)?;

        // Re-init git after restore
        if !flake_dir.join(".git").exists() {
            let _ = Command::new("git")
                .arg("init")
                .current_dir(flake_dir)
                .status();
        }
        let _ = Command::new("git")
            .args(["add", "-A"])
            .current_dir(flake_dir)
            .status();

        println!("{}", "Previous configuration restored.".green());
        bail!("Rebuild failed, rolled back to previous configuration");
    }

    // Success - clean up backup
    println!("{}", "Cleaning up...".blue());
    if backup_dir.exists() {
        fs::remove_dir_all(&backup_dir).ok();
    }

    println!("\n{} {}", "Successfully updated to:".green().bold(), target_ref);
    Ok(())
}

/// Get the latest release tag from the remote repository
fn get_latest_release_tag() -> Result<String> {
    let output = Command::new("git")
        .args(["ls-remote", "--tags", "--sort=-v:refname", REPO_URL])
        .output()
        .context("Failed to fetch tags from remote")?;

    if !output.status.success() {
        bail!("Failed to fetch tags from remote");
    }

    let stdout = String::from_utf8_lossy(&output.stdout);

    // Parse the output to find the latest semver tag
    // Format: <sha>\trefs/tags/<tag>
    for line in stdout.lines() {
        if let Some(tag_ref) = line.split('\t').nth(1) {
            let tag = tag_ref.trim_start_matches("refs/tags/");
            // Skip tags ending with ^{} (annotated tag derefs)
            if tag.ends_with("^{}") {
                continue;
            }
            // Check if it looks like a semver tag (v1.2.3 or 1.2.3)
            let version_part = tag.trim_start_matches('v');
            if version_part.split('.').count() >= 2
                && version_part.chars().next().map(|c| c.is_ascii_digit()).unwrap_or(false)
            {
                return Ok(tag.to_string());
            }
        }
    }

    bail!("No release tags found. Use --update unstable for latest commit.")
}

/// Restore /etc/nixos from backup
fn restore_from_backup(backup_dir: &Path, flake_dir: &Path) -> Result<()> {
    if !backup_dir.exists() {
        bail!("Backup directory does not exist: {}", backup_dir.display());
    }

    // Remove current flake_dir contents (except hardware-configuration.nix)
    // Then copy from backup
    let status = Command::new("rsync")
        .args([
            "-av",
            "--delete",
            "--exclude",
            "hardware-configuration.nix",
        ])
        .arg(format!("{}/", backup_dir.display()))
        .arg(format!("{}/", flake_dir.display()))
        .status()
        .context("Failed to restore from backup")?;

    if !status.success() {
        bail!("Failed to restore from backup");
    }

    // Clean up backup after successful restore
    fs::remove_dir_all(backup_dir).ok();

    Ok(())
}
