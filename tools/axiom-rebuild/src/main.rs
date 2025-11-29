use anyhow::{Context, Result, bail};
use clap::Parser;
use colored::Colorize;
use hocon::HoconLoader;
use std::collections::HashMap;
use std::fs;
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

    // Handle --update if specified
    if let Some(version_opt) = &args.update {
        return handle_update(version_opt.clone(), &args);
    }

    // Get the real user even when running under sudo
    let username = args.user.clone().unwrap_or_else(|| {
        std::env::var("SUDO_USER")
            .or_else(|_| std::env::var("USER"))
            .expect("Could not determine current user")
    });

    // Get the real user's home directory, not root's when using sudo
    let home_dir = if let Ok(sudo_user) = std::env::var("SUDO_USER") {
        // Running under sudo - get the original user's home
        format!("/home/{}", sudo_user)
    } else {
        std::env::var("HOME").expect("Could not determine home directory")
    };
    let config_dir = PathBuf::from(&home_dir).join("config/axiom");

    let user_config_path = args.config.unwrap_or_else(|| config_dir.join("config.conf"));
    // Admin config lives in /etc/axiom/ and requires sudo to edit
    let admin_config_path = args.admin_config.unwrap_or_else(|| PathBuf::from("/etc/axiom").join(format!("{}.conf", username)));

    let template_dir = args.flake_dir.join("templates");
    let output_dir = args.flake_dir.join("config/users");

    // Handle --init or --reset
    if args.init || args.reset {
        init_configs(&config_dir, &user_config_path, &admin_config_path, &template_dir, args.reset)?;
        if args.init && !args.reset {
            println!("{}", "Config files initialized. Edit them and run axiom-rebuild again.".green());
            return Ok(());
        }
    }

    // Check if config files exist
    if !user_config_path.exists() {
        println!("{}", "User config not found. Run with --init to create from template.".yellow());
        println!("  Expected: {}", user_config_path.display());
        bail!("Config file not found");
    }

    // Auto-copy admin template if it doesn't exist
    if !admin_config_path.exists() {
        let admin_template = template_dir.join("admin-config.conf");
        if admin_template.exists() {
            fs::create_dir_all(admin_config_path.parent().unwrap_or(Path::new("/etc/axiom")))?;
            fs::copy(&admin_template, &admin_config_path)
                .with_context(|| format!("Failed to copy admin template to {}", admin_config_path.display()))?;
            println!("  {} {}", "Created admin config:".green(), admin_config_path.display());
        }
    }

    // Parse configs
    println!("{}", "Parsing configuration...".blue());

    let user_config = parse_hocon(&user_config_path)
        .with_context(|| format!("Failed to parse user config: {}", user_config_path.display()))?;

    let admin_config = if admin_config_path.exists() {
        Some(parse_hocon(&admin_config_path)
            .with_context(|| format!("Failed to parse admin config: {}", admin_config_path.display()))?)
    } else {
        println!("{}", "No admin config found, using defaults.".yellow());
        None
    };

    // Generate Nix file
    println!("{}", "Generating Nix configuration...".blue());

    let nix_content = generate_nix(&username, &user_config, admin_config.as_ref())?;

    // Ensure output directory exists
    fs::create_dir_all(&output_dir)
        .with_context(|| format!("Failed to create output directory: {}", output_dir.display()))?;

    let output_path = output_dir.join(format!("{}.nix", username));
    
    fs::write(&output_path, &nix_content)
        .with_context(|| format!("Failed to write Nix config: {}", output_path.display()))?;

    println!("  {} {}", "Generated:".green(), output_path.display());

    // Rebuild if requested
    if !args.no_rebuild {
        println!("{}", "Rebuilding system...".blue());

        // Already running as root via sudo
        let status = Command::new("nixos-rebuild")
            .args(["switch", "--flake", &format!("{}#axiom", args.flake_dir.display())])
            .status()
            .context("Failed to run nixos-rebuild")?;

        if status.success() {
            println!("{}", "Rebuild complete!".green().bold());
            
            // Commit config changes to git (run as original user to avoid ownership issues)
            commit_config_changes(&config_dir, &user_config_path, &username)?;
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
