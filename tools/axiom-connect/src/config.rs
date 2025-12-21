use anyhow::{Context, Result};
use serde::{Deserialize, Serialize};
use std::fs;
use std::path::PathBuf;

#[derive(Debug, Serialize, Deserialize)]
pub struct AppConfig {
    pub server_url: String,
    pub device_token: Option<String>,
    /// User session token for authenticated API calls
    pub auth_token: Option<String>,
}

impl Default for AppConfig {
    fn default() -> Self {
        Self {
            server_url: "http://localhost:8080".to_string(),
            device_token: None,
            auth_token: None,
        }
    }
}

impl AppConfig {
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
            // Return defaults, don't create file yet
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
