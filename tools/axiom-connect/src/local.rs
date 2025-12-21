use anyhow::{Context, Result};
use std::fs;
use std::path::PathBuf;
use chrono::{DateTime, Utc};

use crate::api::{ConfigEntry, ConfigType};
use crate::hocon_convert::{hocon_to_json, json_to_hocon};

/// Standard paths for Axiom config files
pub struct ConfigPaths {
    /// User config: ~/config/axiom/config.conf
    pub user_config_dir: PathBuf,
    /// Admin/system configs: /etc/axiom/
    pub etc_axiom: PathBuf,
}

impl ConfigPaths {
    pub fn new() -> Result<Self> {
        let home = dirs::home_dir()
            .context("Could not determine home directory")?;
        
        Ok(Self {
            user_config_dir: home.join("config/axiom"),
            etc_axiom: PathBuf::from("/etc/axiom"),
        })
    }

    /// Get path for user config file
    pub fn user_config(&self, username: &str) -> PathBuf {
        // For current user, use ~/config/axiom/config.conf
        // For other users, use /home/<user>/config/axiom/config.conf
        let current_user = std::env::var("USER").unwrap_or_default();
        if username == current_user {
            self.user_config_dir.join("config.conf")
        } else {
            PathBuf::from(format!("/home/{}/config/axiom/config.conf", username))
        }
    }

    /// Get path for admin config file
    pub fn admin_config(&self, username: &str) -> PathBuf {
        self.etc_axiom.join(format!("{}.conf", username))
    }

    /// Get path for system config
    pub fn system_config(&self) -> PathBuf {
        self.etc_axiom.join("system.conf")
    }

    /// Get path for users config
    pub fn users_config(&self) -> PathBuf {
        self.etc_axiom.join("users.conf")
    }
}

/// Read all local configs, optionally filtered by user
pub fn read_local_configs(user_filter: Option<&str>) -> Result<Vec<ConfigEntry>> {
    let paths = ConfigPaths::new()?;
    let mut configs = Vec::new();

    // Get current user
    let current_user = std::env::var("USER")
        .context("Could not determine current user")?;

    // Determine which users to read configs for
    let users = if let Some(user) = user_filter {
        vec![user.to_string()]
    } else {
        // Read current user + any users from /etc/axiom/*.conf
        let mut users = vec![current_user.clone()];
        if let Ok(entries) = fs::read_dir(&paths.etc_axiom) {
            for entry in entries.flatten() {
                let name = entry.file_name().to_string_lossy().to_string();
                if name.ends_with(".conf") 
                    && name != "system.conf" 
                    && name != "users.conf"
                    && name != "device.conf"
                {
                    let username = name.trim_end_matches(".conf").to_string();
                    if !users.contains(&username) {
                        users.push(username);
                    }
                }
            }
        }
        users
    };

    // Read user configs
    for username in &users {
        let path = paths.user_config(username);
        if let Some(config) = read_config_file(&path, ConfigType::UserConfig, Some(username))? {
            configs.push(config);
        }

        // Read admin config
        let path = paths.admin_config(username);
        if let Some(config) = read_config_file(&path, ConfigType::AdminConfig, Some(username))? {
            configs.push(config);
        }
    }

    // Read system configs (only if no user filter)
    if user_filter.is_none() {
        if let Some(config) = read_config_file(&paths.system_config(), ConfigType::System, None)? {
            configs.push(config);
        }

        if let Some(config) = read_config_file(&paths.users_config(), ConfigType::Users, None)? {
            configs.push(config);
        }
    }

    Ok(configs)
}

fn read_config_file(path: &PathBuf, config_type: ConfigType, username: Option<&str>) -> Result<Option<ConfigEntry>> {
    if !path.exists() {
        return Ok(None);
    }

    let content = fs::read_to_string(path)
        .with_context(|| format!("Failed to read {}", path.display()))?;

    let json = hocon_to_json(&content)
        .with_context(|| format!("Failed to parse HOCON from {}", path.display()))?;

    // Get file modification time as updated_at
    let metadata = fs::metadata(path)?;
    let modified = metadata.modified()
        .map(|t| DateTime::<Utc>::from(t).to_rfc3339())
        .unwrap_or_else(|_| Utc::now().to_rfc3339());

    Ok(Some(ConfigEntry {
        config_type,
        username: username.map(String::from),
        config: json,
        updated_at: modified,
    }))
}

/// Write a config to local file
pub fn write_local_config(config: &ConfigEntry) -> Result<()> {
    let paths = ConfigPaths::new()?;

    let path = match (&config.config_type, &config.username) {
        (ConfigType::UserConfig, Some(user)) => paths.user_config(user),
        (ConfigType::AdminConfig, Some(user)) => paths.admin_config(user),
        (ConfigType::System, _) => paths.system_config(),
        (ConfigType::Users, _) => paths.users_config(),
        _ => anyhow::bail!("Invalid config: {:?} requires username", config.config_type),
    };

    // Create parent directory if needed
    if let Some(parent) = path.parent() {
        fs::create_dir_all(parent)
            .with_context(|| format!("Failed to create directory {}", parent.display()))?;
    }

    // Convert JSON to HOCON
    let hocon_content = json_to_hocon(&config.config, 0);

    // Add header comment
    let header = match config.config_type {
        ConfigType::UserConfig => "# Axiom User Configuration\n# Edit this file and run `axiom-rebuild` to apply changes.\n\n",
        ConfigType::AdminConfig => "# Axiom Admin Configuration\n# Controls app permissions for this user.\n\n",
        ConfigType::System => "# Axiom System Configuration\n# Controls system-wide settings.\n\n",
        ConfigType::Users => "# Axiom User Management\n# Controls system users.\n\n",
    };

    let content = format!("{}{}", header, hocon_content);

    fs::write(&path, content)
        .with_context(|| format!("Failed to write {}", path.display()))?;

    Ok(())
}
