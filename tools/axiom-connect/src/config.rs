use anyhow::{Context, Result};
use serde::{Deserialize, Serialize};
use std::fs;
use std::path::PathBuf;

const DEFAULT_SERVER_URL: &str = "https://curator.wonderinstruments.com";

/// System-wide configuration stored in /etc/axiom-connect/
/// All configuration is stored at system level - this is a device-level tool
#[derive(Debug, Clone, Serialize, Deserialize, Default)]
pub struct SystemConfig {
    pub server_url: Option<String>,
    pub device_token: Option<String>,
    /// Device secret for authenticating with the server (minimum 32 chars)
    pub device_secret: Option<String>,
    /// Auth token for API calls (stored at system level)
    pub auth_token: Option<String>,
}

impl SystemConfig {
    pub fn system_config_path() -> PathBuf {
        PathBuf::from("/etc/axiom-connect/config.toml")
    }

    pub fn load() -> Result<Self> {
        let path = Self::system_config_path();

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
        let path = Self::system_config_path();

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

/// Application configuration - wrapper around SystemConfig for convenience
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct AppConfig {
    pub server_url: String,
    pub device_token: Option<String>,
    /// Device secret for agent authentication (used for WebSocket and REST API)
    pub device_secret: Option<String>,
    /// Auth token for authenticated API calls
    pub auth_token: Option<String>,
}

impl Default for AppConfig {
    fn default() -> Self {
        Self {
            server_url: DEFAULT_SERVER_URL.to_string(),
            device_token: None,
            device_secret: None,
            auth_token: None,
        }
    }
}

impl AppConfig {
    pub fn config_path() -> PathBuf {
        SystemConfig::system_config_path()
    }

    /// Load configuration from system config
    pub fn load() -> Result<Self> {
        let system_config = SystemConfig::load().unwrap_or_default();

        let server_url = system_config.server_url
            .unwrap_or_else(|| DEFAULT_SERVER_URL.to_string());

        Ok(Self {
            server_url,
            device_token: system_config.device_token,
            device_secret: system_config.device_secret,
            auth_token: system_config.auth_token,
        })
    }

    /// Load configuration specifically for the system-wide agent
    /// Same as load() but explicitly documents the intent
    pub fn load_for_agent() -> Result<Self> {
        Self::load()
    }

    /// Save configuration to system config (requires root)
    pub fn save(&self) -> Result<()> {
        let system_config = SystemConfig {
            server_url: Some(self.server_url.clone()),
            device_token: self.device_token.clone(),
            device_secret: self.device_secret.clone(),
            auth_token: self.auth_token.clone(),
        };
        system_config.save()
    }
}
