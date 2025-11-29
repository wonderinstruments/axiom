package main

import (
	"bufio"
	"context"
	"encoding/json"
	"fmt"
	"os"
	"os/exec"
	"strings"

	"github.com/wailsapp/wails/v2/pkg/runtime"
)

// App struct
type App struct {
	ctx           context.Context
	authenticated bool
	sudoPassword  string
}

// NewApp creates a new App application struct
func NewApp() *App {
	return &App{
		authenticated: false,
	}
}

// startup is called when the app starts. The context is saved
// so we can call the runtime methods
func (a *App) startup(ctx context.Context) {
	a.ctx = ctx
}

// AuthenticateSudo validates the sudo password
func (a *App) AuthenticateSudo(password string) error {
	// First, invalidate any cached sudo credentials
	println("[AuthenticateSudo] Invalidating sudo cache...")
	exec.Command("sudo", "-k").Run()

	// Test sudo access with the provided password
	println("[AuthenticateSudo] Testing password...")
	cmd := exec.Command("sudo", "-S", "-k", "true")
	cmd.Stdin = strings.NewReader(password + "\n")
	output, err := cmd.CombinedOutput()
	
	println(fmt.Sprintf("[AuthenticateSudo] Exit code: %v", err))
	println(fmt.Sprintf("[AuthenticateSudo] Output: %s", string(output)))
	
	if err != nil {
		println("[AuthenticateSudo] Failed - incorrect password")
		return fmt.Errorf("authentication failed")
	}
	
	// Check if output contains error messages
	outputStr := string(output)
	if strings.Contains(outputStr, "Sorry") || strings.Contains(outputStr, "incorrect") {
		println("[AuthenticateSudo] Failed - password rejected")
		return fmt.Errorf("authentication failed")
	}
	
	println("[AuthenticateSudo] Success")
	a.authenticated = true
	a.sudoPassword = password
	return nil
}

// IsAuthenticated returns whether sudo access has been granted
func (a *App) IsAuthenticated() bool {
	return a.authenticated
}

// Quit closes the application
func (a *App) Quit() {
	runtime.Quit(a.ctx)
}

// ReadNixConfig reads and parses the admin.nix file
func (a *App) ReadNixConfig() (map[string]interface{}, error) {
	if !a.authenticated {
		return nil, fmt.Errorf("not authenticated")
	}

	nixPath := "/etc/nixos/templates/admin.nix"

	// Read the file
	cmd := exec.Command("sudo", "-S", "cat", nixPath)
	cmd.Stdin = strings.NewReader(a.sudoPassword + "\n")
	output, err := cmd.Output()
	if err != nil {
		return nil, fmt.Errorf("failed to read nix file: %v", err)
	}

	// Remove first line
	lines := strings.Split(string(output), "\n")
	if len(lines) < 2 {
		return nil, fmt.Errorf("file too short")
	}
	modifiedContent := strings.Join(lines[1:], "\n")

	// Write to temporary file
	tmpFile, err := os.CreateTemp("", "admin-*.nix")
	if err != nil {
		return nil, fmt.Errorf("failed to create temp file: %v", err)
	}
	defer os.Remove(tmpFile.Name())
	defer tmpFile.Close()

	if _, err := tmpFile.WriteString(modifiedContent); err != nil {
		return nil, fmt.Errorf("failed to write temp file: %v", err)
	}
	tmpFile.Close()

	// Evaluate with nix
	cmd = exec.Command("nix", "eval", "--json", "--file", tmpFile.Name())
	jsonOutput, err := cmd.Output()
	if err != nil {
		return nil, fmt.Errorf("failed to evaluate nix file: %v", err)
	}

	// Parse JSON
	var result map[string]interface{}
	if err := json.Unmarshal(jsonOutput, &result); err != nil {
		return nil, fmt.Errorf("failed to parse nix output: %v", err)
	}

	return result, nil
}

// SaveNixConfig writes the updated config back to the nix file and rebuilds
func (a *App) SaveNixConfig(config map[string]interface{}) error {
	if !a.authenticated {
		return fmt.Errorf("not authenticated")
	}

	println("[SaveNixConfig] Starting save process...")
	nixPath := "/etc/nixos/templates/admin.nix"

	// Convert config to Nix format
	println("[SaveNixConfig] Converting config to Nix format...")
	nixContent := formatNixConfig(config)
	println("[SaveNixConfig] Generated Nix content:")
	println(nixContent)

	// Add the first line back
	fullContent := "{ ... }:\n" + nixContent

	// Write to temporary file
	println("[SaveNixConfig] Writing to temporary file...")
	tmpFile, err := os.CreateTemp("", "admin-*.nix")
	if err != nil {
		return fmt.Errorf("failed to create temp file: %v", err)
	}
	defer os.Remove(tmpFile.Name())
	println(fmt.Sprintf("[SaveNixConfig] Temp file created: %s", tmpFile.Name()))

	if _, err := tmpFile.WriteString(fullContent); err != nil {
		return fmt.Errorf("failed to write temp file: %v", err)
	}
	tmpFile.Close()

	// Copy temp file to actual location with sudo
	println(fmt.Sprintf("[SaveNixConfig] Copying to %s...", nixPath))
	cmd := exec.Command("sudo", "-S", "cp", tmpFile.Name(), nixPath)
	cmd.Stdin = strings.NewReader(a.sudoPassword + "\n")
	if err := cmd.Run(); err != nil {
		return fmt.Errorf("failed to write nix file: %v", err)
	}
	println("[SaveNixConfig] File copied successfully")

	// Run nixos-rebuild
	println("[SaveNixConfig] Running nixos-rebuild switch (this may take a while)...")
	runtime.EventsEmit(a.ctx, "rebuild-output", "Running nixos-rebuild switch...")

	cmd = exec.Command("sudo", "-S", "nixos-rebuild", "switch")
	cmd.Stdin = strings.NewReader(a.sudoPassword + "\n")

	// Create pipes for stdout and stderr
	stdout, err := cmd.StdoutPipe()
	if err != nil {
		return fmt.Errorf("failed to create stdout pipe: %v", err)
	}
	stderr, err := cmd.StderrPipe()
	if err != nil {
		return fmt.Errorf("failed to create stderr pipe: %v", err)
	}

	if err := cmd.Start(); err != nil {
		return fmt.Errorf("failed to start nixos-rebuild: %v", err)
	}

	// Read stdout in goroutine
	go func() {
		scanner := bufio.NewScanner(stdout)
		for scanner.Scan() {
			line := scanner.Text()
			println(line)
			runtime.EventsEmit(a.ctx, "rebuild-output", line)
		}
	}()

	// Read stderr in goroutine
	go func() {
		scanner := bufio.NewScanner(stderr)
		for scanner.Scan() {
			line := scanner.Text()
			println(line)
			runtime.EventsEmit(a.ctx, "rebuild-output", line)
		}
	}()

	if err := cmd.Wait(); err != nil {
		return fmt.Errorf("nixos-rebuild failed: %v", err)
	}

	runtime.EventsEmit(a.ctx, "rebuild-output", "nixos-rebuild completed successfully")
	println("[SaveNixConfig] nixos-rebuild completed successfully")

	return nil
}

// formatNixConfig converts a JSON config to Nix format
func formatNixConfig(config map[string]interface{}) string {
	var sb strings.Builder
	sb.WriteString("{\n")

	if axiom, ok := config["axiom"].(map[string]interface{}); ok {
		if admin, ok := axiom["admin"].(map[string]interface{}); ok {
			sb.WriteString("  axiom.admin = {\n")
			for key, value := range admin {
				if nested, ok := value.(map[string]interface{}); ok {
					// Check if this is a nested section or a direct enable
					if enable, hasEnable := nested["enable"].(bool); hasEnable {
						// Direct enable property
						sb.WriteString(fmt.Sprintf("    %s.enable = %t;\n", key, enable))
					} else {
						// Nested section
						sb.WriteString(fmt.Sprintf("    %s = {\n", key))
						for itemKey, itemValue := range nested {
							if itemNested, ok := itemValue.(map[string]interface{}); ok {
								if enable, hasEnable := itemNested["enable"].(bool); hasEnable {
									sb.WriteString(fmt.Sprintf("      %s.enable = %t;\n", itemKey, enable))
								}
							}
						}
						sb.WriteString("    };\n")
					}
				}
			}
			sb.WriteString("  };\n")
		}
	}

	sb.WriteString("}\n")
	return sb.String()
}
