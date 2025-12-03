package config

import (
	"fmt"
	"log"
	"os"
	"runtime"

	"github.com/BurntSushi/toml"
)

// Server holds server connection configuration
type Server struct {
	Host string `toml:"host"`
	Port int    `toml:"port"`
}

// Llama holds llama-server configuration
type Llama struct {
	Binary        string   `toml:"binary"`
	Model         string   `toml:"model"`
	Threads       int      `toml:"threads"`
	CtxSize       int      `toml:"ctx_size"`
	Temperature   float64  `toml:"temperature"`
	NGpuLayers    int      `toml:"n_gpu_layers"`
	Batch         int      `toml:"batch"`
	RopeFreqBase  float64  `toml:"rope_freq_base"`
	RopeFreqScale float64  `toml:"rope_freq_scale"`
	Mlock         bool     `toml:"mlock"`
	Verbose       bool     `toml:"verbose"`
	ExtraArgs     []string `toml:"extra_args"`
}

// Config holds the complete configuration
type Config struct {
	Server Server `toml:"server"`
	Llama  Llama  `toml:"llama"`
}

// defaults returns a Config with sensible default values
func defaults() Config {
	return Config{
		Server: Server{
			Host: "127.0.0.1",
			Port: 8234,
		},
		Llama: Llama{
			Threads:     0, // 0 means auto-detect
			CtxSize:     4096,
			Temperature: 0.7,
			Batch:       512,
		},
	}
}

// Load reads configuration from a file and returns a Config.
// If path is empty, it will use the GUIDE_CONFIG environment variable,
// or default to /etc/guide/config.toml.
// Missing or partial config files will use default values.
func Load(path string) (Config, error) {
	cfg := defaults()

	// Determine config file path
	configPath := path
	if configPath == "" {
		if envPath := os.Getenv("GUIDE_CONFIG"); envPath != "" {
			configPath = envPath
		} else {
			configPath = "/etc/guide/config.toml"
		}
	}

	// Try to read the config file
	if _, err := os.Stat(configPath); err == nil {
		if _, err := toml.DecodeFile(configPath, &cfg); err != nil {
			return cfg, fmt.Errorf("failed to parse config file %s: %w", configPath, err)
		}
	} else if !os.IsNotExist(err) {
		return cfg, fmt.Errorf("failed to access config file %s: %w", configPath, err)
	}
	// If file doesn't exist, just use defaults (not an error)

	// Apply auto-detection for threads if set to 0
	if cfg.Llama.Threads == 0 {
		cfg.Llama.Threads = runtime.NumCPU()
	}

	// Validate configuration
	validate(cfg)

	return cfg, nil
}

// validate checks configuration and logs warnings for common issues
func validate(cfg Config) {
	if cfg.Server.Host == "" {
		log.Println("Warning: server.host is empty, using default 127.0.0.1")
	}
	if cfg.Server.Port == 0 {
		log.Println("Warning: server.port is 0, using default 8234")
	}
	
	// Validation warnings for llama-server launcher only (not critical for client)
	if cfg.Llama.Binary == "" {
		log.Println("Warning: llama.binary is empty - this is required for the launcher")
	}
	if cfg.Llama.Model == "" {
		log.Println("Warning: llama.model is empty - this is required for the launcher")
	}
}

// ServerURL returns the complete server URL for HTTP clients
func ServerURL(cfg Config) string {
	return fmt.Sprintf("http://%s:%d", cfg.Server.Host, cfg.Server.Port)
}
