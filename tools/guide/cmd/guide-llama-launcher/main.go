package main

import (
	"fmt"
	"log"
	"os"
	"strconv"
	"syscall"

	"wonderinstruments/guide-go/internal/config"
)

func main() {
	// Load configuration
	cfg, err := config.Load("")
	if err != nil {
		log.Fatalf("Failed to load configuration: %v", err)
	}

	// Validate required fields
	if cfg.Llama.Binary == "" {
		log.Fatal("Error: llama.binary not configured. Please set it in /etc/guide/config.toml")
	}
	if cfg.Llama.Model == "" {
		log.Fatal("Error: llama.model not configured. Please set it in /etc/guide/config.toml")
	}

	// Check if binary exists
	if _, err := os.Stat(cfg.Llama.Binary); err != nil {
		log.Fatalf("Error: llama-server binary not found at %s: %v", cfg.Llama.Binary, err)
	}

	// Check if model exists
	if _, err := os.Stat(cfg.Llama.Model); err != nil {
		log.Fatalf("Error: model file not found at %s: %v", cfg.Llama.Model, err)
	}

	// Build argument list
	args := []string{
		cfg.Llama.Binary, // argv[0] should be the binary name
		"--host", cfg.Server.Host,
		"--port", strconv.Itoa(cfg.Server.Port),
		"-m", cfg.Llama.Model,
		"--threads", strconv.Itoa(cfg.Llama.Threads),
		"--ctx-size", strconv.Itoa(cfg.Llama.CtxSize),
		"--temp", fmt.Sprintf("%g", cfg.Llama.Temperature),
	}

	// Add optional parameters
	if cfg.Llama.NGpuLayers > 0 {
		args = append(args, "--n-gpu-layers", strconv.Itoa(cfg.Llama.NGpuLayers))
	}

	if cfg.Llama.RopeFreqBase > 0 {
		args = append(args, "--rope-freq-base", fmt.Sprintf("%g", cfg.Llama.RopeFreqBase))
	}

	if cfg.Llama.RopeFreqScale > 0 {
		args = append(args, "--rope-freq-scale", fmt.Sprintf("%g", cfg.Llama.RopeFreqScale))
	}

	if cfg.Llama.Mlock {
		args = append(args, "--mlock")
	}

	if cfg.Llama.Verbose {
		args = append(args, "--verbose")
	}

	// Add any extra arguments
	args = append(args, cfg.Llama.ExtraArgs...)

	// Log the command we're about to execute (helpful for debugging)
	log.Printf("Launching llama-server: %s", cfg.Llama.Binary)
	log.Printf("Model: %s", cfg.Llama.Model)
	log.Printf("Server: %s:%d", cfg.Server.Host, cfg.Server.Port)

	// Replace this process with llama-server so systemd tracks it directly
	env := os.Environ()
	if err := syscall.Exec(cfg.Llama.Binary, args, env); err != nil {
		log.Fatalf("Failed to exec llama-server: %v", err)
	}
}
