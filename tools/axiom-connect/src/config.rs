use anyhow::{Context, Result};
use serde::{Deserialize, Serialize};
use std::fs;
use std::path::PathBuf;

/// System-wide configuration stored in /etc/axiom-connect/
/// Contains device_token and server_url for the system-wide agent
#[derive(Debug, Clone, Serialize, Deserialize, Default)]
pub struct SystemConfig {
    pub server_url: Option<String>,
    pub device_token: Option<String>,
}

impl SystemConfig {
    pub fn system_config_path() -> PathBuf {
        PathBuf::from("/etc/axiom-connect/config.toml")
    }

    pub fn load() -> Result<Self> {
        let path = Self::system_config_path();

        if path.exists() {
            let content = fs::read_to_string(&path)
                .with_context(|| format!("Failed to read system config from {}", path.display()))?;
            toml::from_str(&content)
                .with_context(|| format!("Failed to parse system config from {}", path.display()))
        } else {
            Ok(Self::default())
        }
    }

    pub fn save(&self) -> Result<()> {
        let path = Self::system_config_path();

        // Create parent directory if needed
        if let Some(parent) = path.parent() {
            fs::create_dir_all(parent)
                .with_context(|| format!("Failed to create config directory {}", parent.display()))?;
        }

        let content = toml::to_string_pretty(self)
            .context("Failed to serialize system config")?;

        fs::write(&path, content)
            .with_context(|| format!("Failed to write system config to {}", path.display()))?;

        Ok(())
    }
}

/// User-specific configuration stored in ~/.config/axiom-connect/
/// Contains auth_token for the user's session
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct UserConfig {
    /// Server URL override (user can override the system default)
    pub server_url: Option<String>,
    /// Device token override (typically not set, uses system config)
    pub device_token: Option<String>,
    /// User session token for authenticated API calls
    pub auth_token: Option<String>,
}

impl Default for UserConfig {
    fn default() -> Self {
        Self {
            server_url: None,
            device_token: None,
            auth_token: None,
        }
    }
}

impl UserConfig {
    pub fn config_path() -> Result<PathBuf> {
        // Try ~/.config/axiom-connect/config.toml first
        if let Some(config_dir) = dirs::config_dir() {
            return Ok(config_dir.join("axiom-connect").join("config.toml"));
        }

        // Fallback to home directory
        let home = dirs::home_dir()
            .context("Could not determine home directory")?;
        Ok(home.join(".axiom-connect.toml"))
    }

    pub fn load() -> Result<Self> {
        let path = Self::config_path()?;

        if path.exists() {
            let content = fs::read_to_string(&path)
                .with_context(|| format!("Failed to read config from {}", path.display()))?;
            toml::from_str(&content)
                .with_context(|| format!("Failed to parse config from {}", path.display()))
        } else {
            Ok(Self::default())
        }
    }

    pub fn save(&self) -> Result<()> {
        let path = Self::config_path()?;

        // Create parent directory if needed
        if let Some(parent) = path.parent() {
            fs::create_dir_all(parent)
                .with_context(|| format!("Failed to create config directory {}", parent.display()))?;
        }

        let content = toml::to_string_pretty(self)
            .context("Failed to serialize config")?;

        fs::write(&path, content)
            .with_context(|| format!("Failed to write config to {}", path.display()))?;

        Ok(())
    }
}

/// Combined application configuration
/// Merges system config and user config with appropriate precedence
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct AppConfig {
    pub server_url: String,
    pub device_token: Option<String>,
    /// User session token for authenticated API calls
    pub auth_token: Option<String>,
}

const DEFAULT_SERVER_URL: &str = "https://curator.wonderinstruments.com";

impl Default for AppConfig {
    fn default() -> Self {
        Self {
            server_url: DEFAULT_SERVER_URL.to_string(),
            device_token: None,
            auth_token: None,
        }
    }
}

impl AppConfig {
    /// For backwards compatibility - returns user config path
    pub fn config_path() -> Result<PathBuf> {
        UserConfig::config_path()
    }

    /// Load configuration by merging system and user configs
    /// Priority: CLI args > user config > system config > defaults
    pub fn load() -> Result<Self> {
        let system_config = SystemConfig::load().unwrap_or_default();
        let user_config = UserConfig::load().unwrap_or_default();

        // Merge configs: user overrides system, system overrides defaults
        let server_url = user_config.server_url
            .or(system_config.server_url)
            .unwrap_or_else(|| DEFAULT_SERVER_URL.to_string());

        let device_token = user_config.device_token
            .or(system_config.device_token);

        let auth_token = user_config.auth_token;

        Ok(Self {
            server_url,
            device_token,
            auth_token,
        })
    }

    /// Load configuration specifically for the system-wide agent
    /// Only uses system config (ignores user config)
    pub fn load_for_agent() -> Result<Self> {
        let system_config = SystemConfig::load().unwrap_or_default();

        let server_url = system_config.server_url
            .unwrap_or_else(|| DEFAULT_SERVER_URL.to_string());

        Ok(Self {
            server_url,
            device_token: system_config.device_token,
            auth_token: None, // Agent doesn't use user auth tokens
        })
    }

    /// Save to user config (for backwards compatibility with auth commands)
    pub fn save(&self) -> Result<()> {
        let user_config = UserConfig {
            server_url: Some(self.server_url.clone()),
            device_token: self.device_token.clone(),
            auth_token: self.auth_token.clone(),
        };
        user_config.save()
    }

    /// Save device token to system config (requires root)
    pub fn save_device_to_system(&self) -> Result<()> {
        let mut system_config = SystemConfig::load().unwrap_or_default();
        system_config.device_token = self.device_token.clone();
        if system_config.server_url.is_none() {
            system_config.server_url = Some(self.server_url.clone());
        }
        system_config.save()
    }
}
