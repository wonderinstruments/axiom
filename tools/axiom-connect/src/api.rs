use anyhow::{Context, Result, bail};
use serde::{Deserialize, Serialize};
use serde_json::Value as JsonValue;

#[derive(Debug, Clone, Serialize, Deserialize, PartialEq, Eq)]
#[serde(rename_all = "snake_case")]
pub enum ConfigType {
    UserConfig,
    AdminConfig,
    System,
    Users,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct ConfigEntry {
    pub config_type: ConfigType,
    pub username: Option<String>,
    pub config: JsonValue,
    pub updated_at: String,
}

#[derive(Debug, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct DeviceConfigBundle {
    #[allow(dead_code)]
    pub device_token: String,
    pub configs: Vec<ConfigEntry>,
    #[allow(dead_code)]
    pub updated_at: String,
}

#[derive(Debug, Serialize)]
#[serde(rename_all = "camelCase")]
pub struct ConfigBundleUpdateRequest {
    pub configs: Vec<ConfigEntryUpdate>,
}

#[derive(Debug, Serialize)]
#[serde(rename_all = "camelCase")]
pub struct ConfigEntryUpdate {
    pub config_type: ConfigType,
    pub username: Option<String>,
    pub config: JsonValue,
}

#[derive(Debug, Serialize)]
#[serde(rename_all = "camelCase")]
pub struct SingleConfigUpdateRequest {
    pub config: JsonValue,
}

#[derive(Debug, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct ConfigCheckResponse {
    pub has_updates: bool,
    #[allow(dead_code)]
    pub server_timestamp: String,
    pub config_timestamps: Vec<ConfigTimestamp>,
}

#[derive(Debug, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct ConfigTimestamp {
    pub config_type: ConfigType,
    pub username: Option<String>,
    pub updated_at: String,
}

#[derive(Debug, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct DeviceSummary {
    pub device_token: String,
    #[allow(dead_code)]
    pub created_at: String,
    pub last_seen_at: Option<String>,
    pub config_count: i32,
}

#[derive(Debug, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct DeviceListResponse {
    pub devices: Vec<DeviceSummary>,
}

#[derive(Debug, Serialize)]
#[serde(rename_all = "camelCase")]
pub struct DeviceRegistrationRequest {
    pub device_token: String,
    pub secret: String,
}

#[derive(Debug, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct DeviceRegistrationResponse {
    pub device_token: String,
    pub created_at: String,
}

#[derive(Debug, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct ErrorResponse {
    pub error: String,
    pub message: String,
}

// Auth types
#[derive(Debug, Serialize)]
#[serde(rename_all = "camelCase")]
pub struct LoginRequest {
    pub email: String,
    pub password: String,
}

#[derive(Debug, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct AuthResponse {
    pub token: String,
    pub user: UserInfo,
}

#[derive(Debug, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct UserInfo {
    #[allow(dead_code)]
    pub id: String,
    pub email: String,
}

pub struct ApiClient {
    base_url: String,
    client: reqwest::blocking::Client,
    auth_token: Option<String>,
}

impl ApiClient {
    pub fn new(base_url: &str, auth_token: Option<&str>) -> Self {
        Self {
            base_url: base_url.trim_end_matches('/').to_string(),
            client: reqwest::blocking::Client::new(),
            auth_token: auth_token.map(String::from),
        }
    }

    fn add_auth(&self, request: reqwest::blocking::RequestBuilder) -> reqwest::blocking::RequestBuilder {
        match &self.auth_token {
            Some(token) => request.header("Authorization", format!("Bearer {}", token)),
            None => request,
        }
    }

    fn url(&self, path: &str) -> String {
        format!("{}/api/v1{}", self.base_url, path)
    }

    pub fn register_device(&self, device_token: &str, secret: &str) -> Result<DeviceRegistrationResponse> {
        let request = DeviceRegistrationRequest {
            device_token: device_token.to_string(),
            secret: secret.to_string(),
        };

        let response = self.add_auth(
            self.client
                .post(self.url("/devices"))
                .json(&request)
        )
            .send()
            .context("Failed to connect to server")?;

        if response.status().is_success() {
            response.json().context("Failed to parse response")
        } else {
            let error: ErrorResponse = response.json()
                .unwrap_or(ErrorResponse { 
                    error: "unknown".to_string(), 
                    message: "Unknown error".to_string() 
                });
            bail!("{}: {}", error.error, error.message)
        }
    }

    pub fn list_devices(&self) -> Result<DeviceListResponse> {
        let response = self.add_auth(
            self.client
                .get(self.url("/devices"))
        )
            .send()
            .context("Failed to connect to server")?;

        if response.status().is_success() {
            response.json().context("Failed to parse response")
        } else {
            bail!("Failed to list devices: {}", response.status())
        }
    }

    pub fn get_configs(&self, device_token: &str) -> Result<DeviceConfigBundle> {
        let response = self.add_auth(
            self.client
                .get(self.url(&format!("/devices/{}/configs", device_token)))
        )
            .send()
            .context("Failed to connect to server")?;

        if response.status().is_success() {
            response.json().context("Failed to parse response")
        } else {
            bail!("Failed to get configs: {}", response.status())
        }
    }

    pub fn check_configs(&self, device_token: &str, since: Option<&str>) -> Result<ConfigCheckResponse> {
        let mut url = self.url(&format!("/devices/{}/configs/check", device_token));
        if let Some(since) = since {
            url = format!("{}?since={}", url, urlencoding::encode(since));
        }

        let response = self.add_auth(
            self.client
                .get(&url)
        )
            .send()
            .context("Failed to connect to server")?;

        if response.status().is_success() {
            response.json().context("Failed to parse response")
        } else {
            bail!("Failed to check configs: {}", response.status())
        }
    }

    pub fn update_config(&self, device_token: &str, config: &ConfigEntry) -> Result<()> {
        let config_type = match config.config_type {
            ConfigType::UserConfig => "user_config",
            ConfigType::AdminConfig => "admin_config",
            ConfigType::System => "system",
            ConfigType::Users => "users",
        };

        let mut url = self.url(&format!("/devices/{}/configs/{}", device_token, config_type));
        if let Some(ref username) = config.username {
            url = format!("{}?username={}", url, urlencoding::encode(username));
        }

        let request = SingleConfigUpdateRequest {
            config: config.config.clone(),
        };

        let response = self.add_auth(
            self.client
                .put(&url)
                .json(&request)
        )
            .send()
            .context("Failed to connect to server")?;

        if response.status().is_success() {
            Ok(())
        } else {
            bail!("Failed to update config: {}", response.status())
        }
    }

    pub fn update_all_configs(&self, device_token: &str, configs: &[ConfigEntry]) -> Result<()> {
        let request = ConfigBundleUpdateRequest {
            configs: configs.iter().map(|c| ConfigEntryUpdate {
                config_type: c.config_type.clone(),
                username: c.username.clone(),
                config: c.config.clone(),
            }).collect(),
        };

        let response = self.add_auth(
            self.client
                .put(self.url(&format!("/devices/{}/configs", device_token)))
                .json(&request)
        )
            .send()
            .context("Failed to connect to server")?;

        if response.status().is_success() {
            Ok(())
        } else {
            bail!("Failed to update configs: {}", response.status())
        }
    }

    // Auth methods

    pub fn login(&self, email: &str, password: &str) -> Result<AuthResponse> {
        let request = LoginRequest {
            email: email.to_string(),
            password: password.to_string(),
        };

        let response = self.client
            .post(self.url("/auth/login"))
            .json(&request)
            .send()
            .context("Failed to connect to server")?;

        if response.status().is_success() {
            response.json().context("Failed to parse response")
        } else {
            let error: ErrorResponse = response.json()
                .unwrap_or(ErrorResponse {
                    error: "unknown".to_string(),
                    message: "Unknown error".to_string(),
                });
            bail!("{}: {}", error.error, error.message)
        }
    }

    pub fn logout(&self, token: &str) -> Result<()> {
        let response = self.client
            .post(self.url("/auth/logout"))
            .header("Authorization", format!("Bearer {}", token))
            .send()
            .context("Failed to connect to server")?;

        if response.status().is_success() {
            Ok(())
        } else {
            bail!("Failed to logout: {}", response.status())
        }
    }

    pub fn get_current_user(&self, token: &str) -> Result<UserInfo> {
        let response = self.client
            .get(self.url("/auth/me"))
            .header("Authorization", format!("Bearer {}", token))
            .send()
            .context("Failed to connect to server")?;

        if response.status().is_success() {
            response.json().context("Failed to parse response")
        } else if response.status() == reqwest::StatusCode::UNAUTHORIZED {
            bail!("Session expired or invalid")
        } else {
            bail!("Failed to get user info: {}", response.status())
        }
    }
}
