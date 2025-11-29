use anyhow::{Context, Result, bail};
use clap::Parser;
use colored::Colorize;
use hocon::HoconLoader;
use std::collections::HashMap;
use std::fs;
use std::path::{Path, PathBuf};
use std::process::Command;

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

    /// Path to user config file (default: ~/.config/axiom/config.conf)
    #[arg(long)]
    config: Option<PathBuf>,

    /// Path to admin config file (default: ~/.config/axiom/admin.conf)
    #[arg(long)]
    admin_config: Option<PathBuf>,

    /// Initialize config files from templates if they don't exist
    #[arg(long)]
    init: bool,

    /// Reset config files to template defaults
    #[arg(long)]
    reset: bool,
}

fn main() -> Result<()> {
    let args = Args::parse();

    let username = args.user.unwrap_or_else(|| {
        std::env::var("USER").expect("Could not determine current user")
    });

    let home_dir = std::env::var("HOME").expect("Could not determine home directory");
    let config_dir = PathBuf::from(&home_dir).join(".config/axiom");

    let user_config_path = args.config.unwrap_or_else(|| config_dir.join("config.conf"));
    let admin_config_path = args.admin_config.unwrap_or_else(|| config_dir.join("admin.conf"));

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

        let status = Command::new("sudo")
            .args(["nixos-rebuild", "switch", "--flake", &format!("{}#axiom", args.flake_dir.display())])
            .status()
            .context("Failed to run nixos-rebuild")?;

        if status.success() {
            println!("{}", "Rebuild complete!".green().bold());
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
    fs::create_dir_all(config_dir)
        .with_context(|| format!("Failed to create config directory: {}", config_dir.display()))?;

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
            println!("  {} {}", "Created:".green(), admin_config_path.display());
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
