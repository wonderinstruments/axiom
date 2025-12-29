use anyhow::{Context, Result, bail};
use colored::Colorize;
use futures_util::{SinkExt, StreamExt};
use notify::{RecommendedWatcher, RecursiveMode, Watcher, Event};
use serde::{Deserialize, Serialize};
use std::process::Command;
use std::sync::mpsc;
use std::time::Duration;
use tokio::time::{interval, timeout};
use tokio_tungstenite::{
    connect_async, tungstenite::protocol::Message,
};
use tracing::{error, info, warn};

use crate::config::{AppConfig, SystemConfig};
use crate::api::ApiClient;

/// Messages sent from agent to server
#[derive(Debug, Clone, Serialize)]
#[serde(tag = "type", rename_all = "snake_case")]
pub enum AgentMessage {
    Connect { device_token: String, secret: String },
    Heartbeat { device_token: String },
    CommandResult {
        command_id: String,
        success: bool,
        #[serde(skip_serializing_if = "Option::is_none")]
        error: Option<String>,
        #[serde(skip_serializing_if = "Option::is_none")]
        output: Option<String>,
    },
}

/// Commands received from server
#[derive(Debug, Clone, Deserialize)]
#[serde(tag = "type", rename_all = "snake_case")]
pub enum ServerCommand {
    PullConfig {
        command_id: String,
        #[serde(default)]
        users: Option<Vec<String>>,
    },
    Rebuild {
        command_id: String,
        #[serde(default)]
        users: Option<Vec<String>>,
    },
    Ping {
        #[serde(default = "default_ping_id")]
        command_id: String,
    },
}

fn default_ping_id() -> String {
    "ping".to_string()
}

/// Run the agent daemon using system-wide configuration
/// This is meant to be run as a system service, not per-user
pub async fn run_agent(_config: &AppConfig) -> Result<()> {
    // Load system config (ignore user config for system-wide agent)
    let config = AppConfig::load_for_agent()?;

    let device_token = config.device_token.as_ref()
        .context("No device token configured. Run 'axiom-connect device register' first.")?;

    let device_secret = config.device_secret.as_ref()
        .context("No device secret configured. Run 'axiom-connect device register' first.")?;

    info!("Starting axiom-connect agent for device: {}", device_token);
    println!("{} {}", "Starting agent for device:".green(), device_token);
    println!("  Using system config: {}", SystemConfig::system_config_path().display());

    // Set up global ctrl+c handler
    let shutdown = std::sync::Arc::new(std::sync::atomic::AtomicBool::new(false));
    let shutdown_clone = shutdown.clone();

    ctrlc::set_handler(move || {
        println!("\n{}", "Shutting down...".yellow());
        shutdown_clone.store(true, std::sync::atomic::Ordering::SeqCst);
    }).context("Failed to set ctrl+c handler")?;

    // Set up config file watcher
    let config_reload = std::sync::Arc::new(std::sync::atomic::AtomicBool::new(false));
    let config_reload_clone = config_reload.clone();

    let (tx, rx) = mpsc::channel();
    let mut watcher: RecommendedWatcher = Watcher::new(
        move |res: Result<Event, notify::Error>| {
            if let Ok(event) = res {
                if event.kind.is_modify() || event.kind.is_create() {
                    let _ = tx.send(());
                }
            }
        },
        notify::Config::default().with_poll_interval(Duration::from_secs(2)),
    )?;

    // Watch the system config directory
    let config_path = SystemConfig::system_config_path();
    if let Some(parent) = config_path.parent() {
        if parent.exists() {
            watcher.watch(parent, RecursiveMode::NonRecursive)?;
            info!("Watching config directory: {}", parent.display());
        }
    }

    // Spawn a task to handle config reload signals
    let config_reload_for_task = config_reload.clone();
    std::thread::spawn(move || {
        while rx.recv().is_ok() {
            info!("Config file changed, will reload on next reconnect");
            config_reload_for_task.store(true, std::sync::atomic::Ordering::SeqCst);
        }
    });

    // Connect with automatic reconnection
    let mut current_config = config;
    loop {
        if shutdown.load(std::sync::atomic::Ordering::SeqCst) {
            info!("Shutdown requested");
            return Ok(());
        }

        // Check if we need to reload config
        if config_reload_clone.load(std::sync::atomic::Ordering::SeqCst) {
            config_reload_clone.store(false, std::sync::atomic::Ordering::SeqCst);
            println!("{}", "Config changed, reloading...".cyan());

            match AppConfig::load_for_agent() {
                Ok(new_config) => {
                    if new_config.device_token != current_config.device_token ||
                       new_config.server_url != current_config.server_url {
                        println!("  {} Device token or server URL changed", "!".yellow());
                        current_config = new_config;
                    }
                }
                Err(e) => {
                    warn!("Failed to reload config: {}", e);
                }
            }
        }

        let device_token = match current_config.device_token.as_ref() {
            Some(t) => t,
            None => {
                println!("{}", "No device token configured, waiting...".yellow());
                tokio::time::sleep(Duration::from_secs(10)).await;
                continue;
            }
        };

        let device_secret = match current_config.device_secret.as_ref() {
            Some(s) => s,
            None => {
                println!("{}", "No device secret configured, waiting...".yellow());
                tokio::time::sleep(Duration::from_secs(10)).await;
                continue;
            }
        };

        match connect_and_run(&current_config, device_token, device_secret, shutdown.clone()).await {
            Ok(_) => {
                if shutdown.load(std::sync::atomic::Ordering::SeqCst) {
                    return Ok(());
                }
                info!("WebSocket connection closed normally");
                println!("{}", "Connection closed. Reconnecting...".yellow());
            }
            Err(e) => {
                error!("WebSocket error: {}", e);
                println!("{} {}", "Connection error:".red(), e);
            }
        }

        // Exponential backoff starting at 1 second, max 60 seconds
        static mut BACKOFF: u64 = 1;
        let delay = unsafe {
            let d = BACKOFF;
            BACKOFF = std::cmp::min(BACKOFF * 2, 60);
            d
        };

        println!("{} {} seconds...", "Reconnecting in".yellow(), delay);
        tokio::time::sleep(Duration::from_secs(delay)).await;
    }
}

async fn connect_and_run(
    config: &AppConfig,
    device_token: &str,
    device_secret: &str,
    shutdown: std::sync::Arc<std::sync::atomic::AtomicBool>,
) -> Result<()> {
    // Build WebSocket URL
    let ws_url = build_ws_url(&config.server_url)?;
    info!("Connecting to {}", ws_url);
    println!("{} {}", "Connecting to:".blue(), ws_url);
    
    // Connect with timeout
    let (ws_stream, _response) = timeout(
        Duration::from_secs(30),
        connect_async(&ws_url)
    )
    .await
    .context("Connection timeout")?
    .context("Failed to connect to WebSocket")?;
    
    // Reset backoff on successful connection
    unsafe { crate::agent::BACKOFF = 1; }
    
    println!("{}", "Connected!".green().bold());
    info!("WebSocket connected");
    
    let (mut write, mut read) = ws_stream.split();
    
    // Send connect message with device secret for authentication
    let connect_msg = AgentMessage::Connect {
        device_token: device_token.to_string(),
        secret: device_secret.to_string(),
    };
    let msg_text = serde_json::to_string(&connect_msg)?;
    write.send(Message::Text(msg_text.into())).await?;
    info!("Sent connect message");
    
    // Set up heartbeat interval (every 30 seconds)
    let mut heartbeat_interval = interval(Duration::from_secs(30));
    
    // Clone values for async move
    let device_token_owned = device_token.to_string();
    let device_secret_owned = device_secret.to_string();
    let server_url = config.server_url.clone();

    loop {
        tokio::select! {
            // Handle incoming messages
            msg = read.next() => {
                match msg {
                    Some(Ok(Message::Text(text))) => {
                        match serde_json::from_str::<ServerCommand>(&text) {
                            Ok(cmd) => {
                                info!("Received command: {:?}", cmd);
                                let result = handle_command(&cmd, &server_url, &device_token_owned, &device_secret_owned).await;
                                
                                // Send result back
                                let result_msg = match result {
                                    Ok(output) => AgentMessage::CommandResult {
                                        command_id: get_command_id(&cmd),
                                        success: true,
                                        error: None,
                                        output: Some(output),
                                    },
                                    Err(e) => AgentMessage::CommandResult {
                                        command_id: get_command_id(&cmd),
                                        success: false,
                                        error: Some(e.to_string()),
                                        output: None,
                                    },
                                };
                                
                                let msg_text = serde_json::to_string(&result_msg)?;
                                write.send(Message::Text(msg_text.into())).await?;
                            }
                            Err(e) => {
                                warn!("Failed to parse command: {} - {}", text, e);
                            }
                        }
                    }
                    Some(Ok(Message::Ping(data))) => {
                        write.send(Message::Pong(data)).await?;
                    }
                    Some(Ok(Message::Close(_))) => {
                        info!("Server closed connection");
                        break;
                    }
                    Some(Err(e)) => {
                        error!("WebSocket error: {}", e);
                        break;
                    }
                    None => {
                        info!("WebSocket stream ended");
                        break;
                    }
                    _ => {}
                }
            }
            
            // Send heartbeat
            _ = heartbeat_interval.tick() => {
                let heartbeat = AgentMessage::Heartbeat {
                    device_token: device_token_owned.clone(),
                };
                let msg_text = serde_json::to_string(&heartbeat)?;
                if let Err(e) = write.send(Message::Text(msg_text.into())).await {
                    error!("Failed to send heartbeat: {}", e);
                    break;
                }
                info!("Sent heartbeat");
            }
            
            // Check for shutdown
            _ = tokio::time::sleep(Duration::from_millis(100)) => {
                if shutdown.load(std::sync::atomic::Ordering::SeqCst) {
                    info!("Received shutdown signal");
                    write.send(Message::Close(None)).await.ok();
                    return Ok(());
                }
            }
        }
    }
    
    Ok(())
}

fn build_ws_url(server_url: &str) -> Result<String> {
    let base = server_url.trim_end_matches('/');
    
    // Convert http:// to ws:// and https:// to wss://
    let ws_base = if base.starts_with("https://") {
        base.replace("https://", "wss://")
    } else if base.starts_with("http://") {
        base.replace("http://", "ws://")
    } else {
        format!("ws://{}", base)
    };
    
    Ok(format!("{}/api/v1/ws/agent", ws_base))
}

fn get_command_id(cmd: &ServerCommand) -> String {
    match cmd {
        ServerCommand::PullConfig { command_id, .. } => command_id.clone(),
        ServerCommand::Rebuild { command_id, .. } => command_id.clone(),
        ServerCommand::Ping { command_id } => command_id.clone(),
    }
}

async fn handle_command(cmd: &ServerCommand, server_url: &str, device_token: &str, device_secret: &str) -> Result<String> {
    match cmd {
        ServerCommand::PullConfig { users, .. } => {
            println!("{}", "Received pull_config command".cyan());
            handle_pull_config(server_url, device_token, users.as_deref(), device_secret).await
        }
        ServerCommand::Rebuild { users, .. } => {
            println!("{}", "Received rebuild command".cyan());
            handle_rebuild(users.as_deref()).await
        }
        ServerCommand::Ping { .. } => {
            Ok("pong".to_string())
        }
    }
}

async fn handle_pull_config(
    server_url: &str,
    device_token: &str,
    users: Option<&[String]>,
    device_secret: &str,
) -> Result<String> {
    println!("  {} configs from server...", "Pulling".blue());

    // Clone values for the blocking task
    let server_url = server_url.to_string();
    let device_token = device_token.to_string();
    let users = users.map(|u| u.to_vec());
    let device_secret = device_secret.to_string();

    // Run blocking API call in a separate thread
    let result = tokio::task::spawn_blocking(move || {
        // Use device secret for authentication (not user auth token)
        let client = ApiClient::new(&server_url, Some(&device_secret));
        
        // Use the existing pull logic
        let user_filter = users.as_ref().and_then(|u| u.first().map(|s| s.as_str()));
        
        // Pull configs from server
        let server_bundle = client.get_configs(&device_token)
            .context("Failed to get configs from server")?;
        
        // Filter by user if specified
        let configs: Vec<_> = server_bundle.configs.iter()
            .filter(|c| {
                match user_filter {
                    Some(u) => c.username.as_deref() == Some(u),
                    None => true,
                }
            })
            .cloned()
            .collect();
        
        // Write configs locally
        for config in &configs {
            crate::local::write_local_config(config)
                .with_context(|| format!("Failed to write {:?} config", config.config_type))?;
        }
        
        Ok::<_, anyhow::Error>(configs.len())
    })
    .await
    .context("Blocking task panicked")??;
    
    let msg = format!("Pulled {} configs", result);
    println!("  {} {}", "✓".green(), msg);
    Ok(msg)
}

async fn handle_rebuild(users: Option<&[String]>) -> Result<String> {
    println!("  {} system...", "Rebuilding".blue());
    
    // Build axiom-rebuild command
    let mut cmd = Command::new("axiom-rebuild");
    
    // Add user flags if specified
    if let Some(users) = users {
        if users.len() == 1 {
            cmd.arg("--user").arg(&users[0]);
        } else if !users.is_empty() {
            cmd.arg("--users").arg(users.join(","));
        }
    }
    
    // Run the command
    let output = cmd
        .output()
        .context("Failed to execute axiom-rebuild. Is it installed?")?;
    
    let stdout = String::from_utf8_lossy(&output.stdout);
    let stderr = String::from_utf8_lossy(&output.stderr);
    
    if output.status.success() {
        let msg = format!("Rebuild completed successfully");
        println!("  {} {}", "✓".green(), msg);
        Ok(format!("{}\n{}", msg, stdout))
    } else {
        let msg = format!("Rebuild failed: {}", stderr);
        println!("  {} {}", "✗".red(), msg);
        bail!("{}\nstdout: {}\nstderr: {}", msg, stdout, stderr)
    }
}

// Mutable static for backoff (safe because we only access it from single-threaded context)
static mut BACKOFF: u64 = 1;
