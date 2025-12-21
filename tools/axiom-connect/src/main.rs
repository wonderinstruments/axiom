use anyhow::{Context, Result};
use clap::{Parser, Subcommand};

mod agent;
mod api;
mod config;
mod hocon_convert;
mod local;

use api::ApiClient;
use config::AppConfig;

/// Axiom Connect - Sync configs with a central server
#[derive(Parser)]
#[command(name = "Axiom Connect", author, version, about)]
struct Cli {
    /// Server URL override
    #[arg(long, global = true)]
    server: Option<String>,

    /// Device token override
    #[arg(long, global = true)]
    token: Option<String>,

    #[command(subcommand)]
    command: Commands,
}

#[derive(Subcommand)]
enum Commands {
    /// Authentication commands
    Auth {
        #[command(subcommand)]
        command: AuthCommands,
    },
    /// Device management commands
    Device {
        #[command(subcommand)]
        command: DeviceCommands,
    },
    /// Config sync commands
    Config {
        #[command(subcommand)]
        command: ConfigCommands,
    },
    /// Agent daemon commands
    Agent {
        #[command(subcommand)]
        command: AgentCommands,
    },
    /// Settings management
    Settings {
        #[command(subcommand)]
        command: SettingsCommands,
    },
}

#[derive(Subcommand)]
enum SettingsCommands {
    /// Set the server URL
    SetServer {
        /// Server URL (e.g., https://curator.example.com)
        url: String,
    },
    /// Show current settings
    Show,
}

#[derive(Subcommand)]
enum AuthCommands {
    /// Login with email and password
    Login {
        /// Email address
        #[arg(long)]
        email: Option<String>,
        /// Password (will prompt if not provided)
        #[arg(long)]
        password: Option<String>,
    },
    /// Logout and clear saved session
    Logout,
    /// Show current authentication status
    Status,
}

#[derive(Subcommand)]
enum AgentCommands {
    /// Start the agent daemon (connects to server via WebSocket)
    Start,
}

#[derive(Subcommand)]
enum DeviceCommands {
    /// Register this device with the server
    Register {
        /// Device token (generated if not provided)
        #[arg(long)]
        token: Option<String>,
    },
    /// List all registered devices
    List,
}

#[derive(Subcommand)]
enum ConfigCommands {
    /// Sync configs with server (last-write-wins)
    Sync {
        /// Only sync configs for a specific user
        #[arg(long)]
        user: Option<String>,
    },
    /// Push local configs to server
    Push {
        /// Force push, overwriting server configs
        #[arg(long)]
        force: bool,
        /// Only push configs for a specific user
        #[arg(long)]
        user: Option<String>,
    },
    /// Pull configs from server to local
    Pull {
        /// Force pull, overwriting local configs
        #[arg(long)]
        force: bool,
        /// Only pull configs for a specific user
        #[arg(long)]
        user: Option<String>,
    },
    /// Check if server has updated configs
    Check,
    /// Download all configs to a directory
    Download {
        /// Directory to download configs to
        dir: String,
    },
    /// Upload configs from a directory
    Upload {
        /// Directory to upload configs from
        dir: String,
    },
}

fn main() -> Result<()> {
    let cli = Cli::parse();

    // Load app config
    let mut app_config = AppConfig::load()?;

    // Apply CLI overrides
    if let Some(server) = cli.server {
        app_config.server_url = server;
    }
    if let Some(token) = cli.token {
        app_config.device_token = Some(token);
    }

    match cli.command {
        Commands::Auth { command } => handle_auth_command(command, &mut app_config),
        Commands::Device { command } => handle_device_command(command, &mut app_config),
        Commands::Config { command } => handle_config_command(command, &app_config),
        Commands::Agent { command } => handle_agent_command(command, &app_config),
        Commands::Settings { command } => handle_settings_command(command, &mut app_config),
    }
}

fn handle_auth_command(command: AuthCommands, config: &mut AppConfig) -> Result<()> {
    use colored::Colorize;
    use std::io::{self, Write};

    let client = ApiClient::new(&config.server_url, config.auth_token.as_deref());

    match command {
        AuthCommands::Login { email, password } => {
            // Get email if not provided
            let email = match email {
                Some(e) => e,
                None => {
                    print!("Email: ");
                    io::stdout().flush()?;
                    let mut input = String::new();
                    io::stdin().read_line(&mut input)?;
                    input.trim().to_string()
                }
            };

            // Get password if not provided
            let password = match password {
                Some(p) => p,
                None => {
                    // Try to read password without echo
                    rpassword::prompt_password("Password: ")
                        .context("Failed to read password")?
                }
            };

            println!("Logging in as {}...", email.cyan());

            match client.login(&email, &password) {
                Ok(response) => {
                    println!("{}", "✓ Login successful".green());
                    println!("  User: {}", response.user.email);

                    // Save token to config
                    config.auth_token = Some(response.token);
                    config.save()?;
                    println!("  Session saved to: {}", AppConfig::config_path()?.display());
                }
                Err(e) => {
                    println!("{} {}", "✗".red(), e);
                    std::process::exit(1);
                }
            }
        }
        AuthCommands::Logout => {
            match &config.auth_token {
                Some(token) => {
                    // Try to logout on server (ignore errors - we'll clear local token anyway)
                    let _ = client.logout(token);

                    config.auth_token = None;
                    config.save()?;
                    println!("{}", "✓ Logged out successfully".green());
                }
                None => {
                    println!("{}", "Not currently logged in".yellow());
                }
            }
        }
        AuthCommands::Status => {
            match &config.auth_token {
                Some(token) => {
                    print!("Checking session... ");
                    io::stdout().flush()?;

                    match client.get_current_user(token) {
                        Ok(user) => {
                            println!("{}", "valid".green());
                            println!("  Logged in as: {}", user.email.cyan());
                            println!("  Server: {}", config.server_url);
                        }
                        Err(_) => {
                            println!("{}", "expired".red());
                            println!("  Run 'axiom-connect auth login' to authenticate");
                        }
                    }
                }
                None => {
                    println!("{}", "Not logged in".yellow());
                    println!("  Run 'axiom-connect auth login' to authenticate");
                }
            }

            // Also show device token status
            if let Some(ref device_token) = config.device_token {
                println!("  Device token: {}", device_token.cyan());
            }
        }
    }

    Ok(())
}

fn handle_settings_command(command: SettingsCommands, config: &mut AppConfig) -> Result<()> {
    use colored::Colorize;

    match command {
        SettingsCommands::SetServer { url } => {
            println!("Setting server URL to: {}", url.cyan());
            config.server_url = url;
            config.save()?;
            println!("{}", "Server URL saved".green());
            println!("  Config file: {}", AppConfig::config_path()?.display());
        }
        SettingsCommands::Show => {
            println!("Current settings:");
            println!("  Server URL: {}", config.server_url.cyan());
            println!("  Device token: {}",
                config.device_token.as_deref().unwrap_or("(not set)"));
            println!("  Auth token: {}",
                if config.auth_token.is_some() { "set".green().to_string() } else { "(not set)".to_string() });
            println!();
            println!("  Config file: {}", AppConfig::config_path()?.display());
        }
    }

    Ok(())
}

fn handle_agent_command(command: AgentCommands, config: &AppConfig) -> Result<()> {
    // Initialize logging for agent mode
    tracing_subscriber::fmt()
        .with_env_filter(
            tracing_subscriber::EnvFilter::from_default_env()
                .add_directive("axiom_connect=info".parse().unwrap())
        )
        .init();

    match command {
        AgentCommands::Start => {
            // Run the async agent
            let rt = tokio::runtime::Runtime::new()?;
            rt.block_on(agent::run_agent(config))
        }
    }
}

fn handle_device_command(command: DeviceCommands, config: &mut AppConfig) -> Result<()> {
    let client = ApiClient::new(&config.server_url, config.auth_token.as_deref());

    match command {
        DeviceCommands::Register { token } => {
            let device_token = token.unwrap_or_else(|| {
                // Generate a token from hostname
                hostname::get()
                    .map(|h| h.to_string_lossy().to_string())
                    .unwrap_or_else(|_| format!("device-{}", uuid::Uuid::new_v4()))
            });

            println!("Registering device with token: {}", device_token);

            // For now, use a placeholder secret since auth is disabled
            let secret = "placeholder-secret-for-development-only";
            
            match client.register_device(&device_token, secret) {
                Ok(response) => {
                    println!("✓ Device registered successfully");
                    println!("  Token: {}", response.device_token);
                    println!("  Created: {}", response.created_at);

                    // Save token to config
                    config.device_token = Some(device_token);
                    config.save()?;
                    println!("  Config saved to: {}", AppConfig::config_path()?.display());
                }
                Err(e) => {
                    if e.to_string().contains("already_exists") {
                        println!("Device already registered. Saving token to config...");
                        config.device_token = Some(device_token);
                        config.save()?;
                    } else {
                        return Err(e);
                    }
                }
            }
        }
        DeviceCommands::List => {
            let response = client.list_devices()?;
            if response.devices.is_empty() {
                println!("No devices registered");
            } else {
                println!("Registered devices:");
                for device in response.devices {
                    println!("  {} (configs: {}, last seen: {})",
                        device.device_token,
                        device.config_count,
                        device.last_seen_at.as_deref().unwrap_or("never")
                    );
                }
            }
        }
    }

    Ok(())
}

fn handle_config_command(command: ConfigCommands, config: &AppConfig) -> Result<()> {
    let device_token = config.device_token.as_ref()
        .context("No device token configured. Run 'axiom-connect device register' first.")?;

    let client = ApiClient::new(&config.server_url, config.auth_token.as_deref());

    match command {
        ConfigCommands::Sync { user } => {
            println!("Syncing configs (last-write-wins)...");
            sync_configs(&client, device_token, user.as_deref())?;
        }
        ConfigCommands::Push { force, user } => {
            println!("Pushing local configs to server{}...", 
                if force { " (force)" } else { "" });
            push_configs(&client, device_token, force, user.as_deref())?;
        }
        ConfigCommands::Pull { force, user } => {
            println!("Pulling configs from server{}...", 
                if force { " (force)" } else { "" });
            pull_configs(&client, device_token, force, user.as_deref())?;
        }
        ConfigCommands::Check => {
            check_for_updates(&client, device_token)?;
        }
        ConfigCommands::Download { dir } => {
            println!("Downloading all configs to {}...", dir);
            download_configs(&client, device_token, &dir)?;
        }
        ConfigCommands::Upload { dir } => {
            println!("Uploading configs from {}...", dir);
            upload_configs(&client, device_token, &dir)?;
        }
    }

    Ok(())
}

fn sync_configs(client: &ApiClient, device_token: &str, user: Option<&str>) -> Result<()> {
    use colored::Colorize;
    
    // Get server configs
    let server_bundle = client.get_configs(device_token)?;
    
    // Get local configs
    let local_configs = local::read_local_configs(user)?;
    
    // Compare timestamps and sync (last-write-wins)
    let mut to_push = Vec::new();
    let mut to_pull = Vec::new();
    
    for local in &local_configs {
        let server_config = server_bundle.configs.iter()
            .find(|s| s.config_type == local.config_type && s.username == local.username);
        
        match server_config {
            Some(server) => {
                let local_time = chrono::DateTime::parse_from_rfc3339(&local.updated_at)?;
                let server_time = chrono::DateTime::parse_from_rfc3339(&server.updated_at)?;
                
                if local_time > server_time {
                    to_push.push(local.clone());
                } else if server_time > local_time {
                    to_pull.push(server.clone());
                }
            }
            None => {
                // Local only - push to server
                to_push.push(local.clone());
            }
        }
    }
    
    // Check for server-only configs
    for server in &server_bundle.configs {
        let has_local = local_configs.iter()
            .any(|l| l.config_type == server.config_type && l.username == server.username);
        if !has_local {
            to_pull.push(server.clone());
        }
    }
    
    // Apply changes
    if to_push.is_empty() && to_pull.is_empty() {
        println!("{}", "Already in sync".green());
        return Ok(());
    }
    
    for config in &to_push {
        println!("  {} {} {}",
            "↑".blue(),
            format!("{:?}", config.config_type).cyan(),
            config.username.as_deref().unwrap_or("(system)"));
        client.update_config(device_token, config)?;
    }
    
    for config in &to_pull {
        println!("  {} {} {}",
            "↓".green(),
            format!("{:?}", config.config_type).cyan(),
            config.username.as_deref().unwrap_or("(system)"));
        local::write_local_config(config)?;
    }
    
    println!("{}", format!("Synced: {} pushed, {} pulled", to_push.len(), to_pull.len()).green());
    Ok(())
}

fn push_configs(client: &ApiClient, device_token: &str, force: bool, user: Option<&str>) -> Result<()> {
    use colored::Colorize;
    
    let local_configs = local::read_local_configs(user)?;
    
    if !force {
        // Check server timestamps first
        let server_bundle = client.get_configs(device_token)?;
        for local in &local_configs {
            if let Some(server) = server_bundle.configs.iter()
                .find(|s| s.config_type == local.config_type && s.username == local.username) 
            {
                let local_time = chrono::DateTime::parse_from_rfc3339(&local.updated_at)?;
                let server_time = chrono::DateTime::parse_from_rfc3339(&server.updated_at)?;
                if server_time > local_time {
                    println!("{}", format!(
                        "Warning: Server has newer {:?} config. Use --force to overwrite.",
                        local.config_type
                    ).yellow());
                }
            }
        }
    }
    
    for config in &local_configs {
        println!("  {} {} {}",
            "↑".blue(),
            format!("{:?}", config.config_type).cyan(),
            config.username.as_deref().unwrap_or("(system)"));
        client.update_config(device_token, config)?;
    }
    
    println!("{}", format!("Pushed {} configs", local_configs.len()).green());
    Ok(())
}

fn pull_configs(client: &ApiClient, device_token: &str, force: bool, user: Option<&str>) -> Result<()> {
    use colored::Colorize;
    
    let server_bundle = client.get_configs(device_token)?;
    
    // Filter by user if specified
    let configs: Vec<_> = server_bundle.configs.iter()
        .filter(|c| {
            match user {
                Some(u) => c.username.as_deref() == Some(u),
                None => true,
            }
        })
        .collect();
    
    if !force {
        let local_configs = local::read_local_configs(user)?;
        for server in &configs {
            if let Some(local) = local_configs.iter()
                .find(|l| l.config_type == server.config_type && l.username == server.username)
            {
                let local_time = chrono::DateTime::parse_from_rfc3339(&local.updated_at)?;
                let server_time = chrono::DateTime::parse_from_rfc3339(&server.updated_at)?;
                if local_time > server_time {
                    println!("{}", format!(
                        "Warning: Local has newer {:?} config. Use --force to overwrite.",
                        server.config_type
                    ).yellow());
                }
            }
        }
    }
    
    for config in &configs {
        println!("  {} {} {}",
            "↓".green(),
            format!("{:?}", config.config_type).cyan(),
            config.username.as_deref().unwrap_or("(system)"));
        local::write_local_config(config)?;
    }
    
    println!("{}", format!("Pulled {} configs", configs.len()).green());
    Ok(())
}

fn check_for_updates(client: &ApiClient, device_token: &str) -> Result<()> {
    use colored::Colorize;
    
    let local_configs = local::read_local_configs(None)?;
    let latest_local = local_configs.iter()
        .map(|c| &c.updated_at)
        .max()
        .cloned();
    
    let response = client.check_configs(device_token, latest_local.as_deref())?;
    
    if response.has_updates {
        println!("{}", "Updates available on server:".yellow());
        for ts in &response.config_timestamps {
            println!("  {} {} ({})",
                format!("{:?}", ts.config_type).cyan(),
                ts.username.as_deref().unwrap_or("(system)"),
                ts.updated_at);
        }
        std::process::exit(1);
    } else {
        println!("{}", "No updates available".green());
        std::process::exit(0);
    }
}

fn download_configs(client: &ApiClient, device_token: &str, dir: &str) -> Result<()> {
    use colored::Colorize;
    use std::fs;
    use std::path::Path;
    
    let bundle = client.get_configs(device_token)?;
    
    // Create device-specific directory
    let device_dir = Path::new(dir).join(device_token);
    fs::create_dir_all(&device_dir)?;
    
    for config in &bundle.configs {
        let (filename, header) = match (&config.config_type, &config.username) {
            (api::ConfigType::UserConfig, Some(user)) => (
                format!("user-config.{}.conf", user),
                "# Axiom User Configuration\n# Edit this file and run `axiom-rebuild` to apply changes.\n\n"
            ),
            (api::ConfigType::AdminConfig, Some(user)) => (
                format!("{}.conf", user),
                "# Axiom Admin Configuration\n# Controls app permissions for this user.\n\n"
            ),
            (api::ConfigType::System, _) => (
                "system.conf".to_string(),
                "# Axiom System Configuration\n# Controls system-wide settings.\n\n"
            ),
            (api::ConfigType::Users, _) => (
                "users.conf".to_string(),
                "# Axiom User Management\n# Controls system users.\n\n"
            ),
            _ => continue,
        };
        
        let filepath = device_dir.join(&filename);
        let hocon_content = hocon_convert::json_to_hocon(&config.config, 0);
        let content = format!("{}{}", header, hocon_content);
        
        fs::write(&filepath, content)?;
        println!("  {} {}", "↓".green(), filepath.display());
    }
    
    println!("{}", format!("Downloaded {} configs to {}/{}", bundle.configs.len(), dir, device_token).green());
    Ok(())
}

fn upload_configs(client: &ApiClient, device_token: &str, dir: &str) -> Result<()> {
    use colored::Colorize;
    use std::fs;
    use std::path::Path;
    
    // Look for device-specific directory
    let device_dir = Path::new(dir).join(device_token);
    let scan_dir = if device_dir.exists() {
        device_dir.as_path()
    } else {
        Path::new(dir)
    };
    
    let mut configs = Vec::new();
    
    for entry in fs::read_dir(scan_dir)? {
        let entry = entry?;
        let path = entry.path();
        
        if !path.is_file() {
            continue;
        }
        
        let filename = path.file_name()
            .and_then(|n| n.to_str())
            .unwrap_or("");
        
        // Skip non-conf files
        if !filename.ends_with(".conf") {
            continue;
        }
        
        // Determine config type and username from filename
        let (config_type, username) = if filename == "system.conf" {
            (api::ConfigType::System, None)
        } else if filename == "users.conf" {
            (api::ConfigType::Users, None)
        } else if filename.starts_with("user-config.") {
            let user = filename
                .strip_prefix("user-config.")
                .and_then(|s| s.strip_suffix(".conf"))
                .map(String::from);
            (api::ConfigType::UserConfig, user)
        } else {
            // Assume it's an admin config (e.g., edmund.conf)
            let user = filename.strip_suffix(".conf").map(String::from);
            (api::ConfigType::AdminConfig, user)
        };
        
        let content = fs::read_to_string(&path)?;
        let json = hocon_convert::hocon_to_json(&content)
            .with_context(|| format!("Failed to parse HOCON from {}", path.display()))?;
        
        let config = api::ConfigEntry {
            config_type,
            username,
            config: json,
            updated_at: chrono::Utc::now().to_rfc3339(),
        };
        
        configs.push(config);
        println!("  {} {}", "↑".blue(), path.display());
    }
    
    if configs.is_empty() {
        anyhow::bail!("No config files found in {}", scan_dir.display());
    }
    
    client.update_all_configs(device_token, &configs)?;
    
    println!("{}", format!("Uploaded {} configs", configs.len()).green());
    Ok(())
}
