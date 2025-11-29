package main

import (
	"bufio"
	"context"
	"fmt"
	"os"
	"os/exec"
	"os/user"
	"sort"
	"strings"

	"github.com/gurkankaymak/hocon"
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

// getAdminConfigPath returns the path to the admin config file for the current user
func getAdminConfigPath() (string, error) {
	currentUser, err := user.Current()
	if err != nil {
		return "", fmt.Errorf("failed to get current user: %v", err)
	}
	return fmt.Sprintf("/etc/axiom/%s.conf", currentUser.Username), nil
}

// ReadNixConfig reads and parses the admin HOCON config file
func (a *App) ReadNixConfig() (map[string]interface{}, error) {
	if !a.authenticated {
		return nil, fmt.Errorf("not authenticated")
	}

	configPath, err := getAdminConfigPath()
	if err != nil {
		return nil, err
	}

	// Read the file with sudo
	cmd := exec.Command("sudo", "-S", "cat", configPath)
	cmd.Stdin = strings.NewReader(a.sudoPassword + "\n")
	output, err := cmd.Output()
	if err != nil {
		return nil, fmt.Errorf("failed to read config file: %v", err)
	}

	// Parse HOCON
	conf, err := hocon.ParseString(string(output))
	if err != nil {
		return nil, fmt.Errorf("failed to parse HOCON config: %v", err)
	}

	// Convert to the expected format for the frontend
	// The frontend expects: { axiom: { admin: { section: { item: { enable: bool } } } } }
	result := make(map[string]interface{})
	admin := make(map[string]interface{})

	// Get all top-level keys from the config
	root := conf.GetRoot()
	if rootObj, ok := root.(hocon.Object); ok {
		for sectionName := range rootObj {
			sectionObj := conf.GetObject(sectionName)
			if sectionObj != nil {
				sectionMap := make(map[string]interface{})
				for itemKey := range sectionObj {
					// Check if this is a nested object with .enable
					itemObj := conf.GetObject(sectionName + "." + itemKey)
					if itemObj != nil {
						// It's a nested object, check for enable
						enablePath := sectionName + "." + itemKey + ".enable"
						enableVal := conf.GetBoolean(enablePath)
						sectionMap[itemKey] = map[string]interface{}{
							"enable": enableVal,
						}
					} else {
						// Check if it's a direct .enable property (like "firefox.enable = true")
						if strings.HasSuffix(itemKey, ".enable") {
							// This is handled by the object case above
							continue
						}
					}
				}
				admin[sectionName] = sectionMap
			}
		}
	}

	result["axiom"] = map[string]interface{}{
		"admin": admin,
	}

	return result, nil
}

// SaveNixConfig writes the updated config back to the HOCON file and rebuilds
func (a *App) SaveNixConfig(config map[string]interface{}) error {
	if !a.authenticated {
		return fmt.Errorf("not authenticated")
	}

	println("[SaveNixConfig] Starting save process...")
	configPath, err := getAdminConfigPath()
	if err != nil {
		return err
	}

	// Convert config to HOCON format
	println("[SaveNixConfig] Converting config to HOCON format...")
	hoconContent := formatHoconConfig(config)
	println("[SaveNixConfig] Generated HOCON content:")
	println(hoconContent)

	// Write to temporary file
	println("[SaveNixConfig] Writing to temporary file...")
	tmpFile, err := os.CreateTemp("", "admin-*.conf")
	if err != nil {
		return fmt.Errorf("failed to create temp file: %v", err)
	}
	defer os.Remove(tmpFile.Name())
	println(fmt.Sprintf("[SaveNixConfig] Temp file created: %s", tmpFile.Name()))

	if _, err := tmpFile.WriteString(hoconContent); err != nil {
		return fmt.Errorf("failed to write temp file: %v", err)
	}
	tmpFile.Close()

	// Copy temp file to actual location with sudo
	println(fmt.Sprintf("[SaveNixConfig] Copying to %s...", configPath))
	cmd := exec.Command("sudo", "-S", "cp", tmpFile.Name(), configPath)
	cmd.Stdin = strings.NewReader(a.sudoPassword + "\n")
	if err := cmd.Run(); err != nil {
		return fmt.Errorf("failed to write config file: %v", err)
	}
	println("[SaveNixConfig] File copied successfully")

	// Run axiom-rebuild (converts HOCON to Nix and rebuilds)
	println("[SaveNixConfig] Running axiom-rebuild (this may take a while)...")
	runtime.EventsEmit(a.ctx, "rebuild-output", "Running axiom-rebuild...")

	cmd = exec.Command("sudo", "-S", "axiom-rebuild", "--no-update-check")
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
		return fmt.Errorf("failed to start axiom-rebuild: %v", err)
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
		return fmt.Errorf("axiom-rebuild failed: %v", err)
	}

	runtime.EventsEmit(a.ctx, "rebuild-output", "axiom-rebuild completed successfully")
	println("[SaveNixConfig] axiom-rebuild completed successfully")

	return nil
}

// formatHoconConfig converts a JSON config to HOCON format
func formatHoconConfig(config map[string]interface{}) string {
	var sb strings.Builder

	sb.WriteString("# Axiom Admin Configuration\n")
	sb.WriteString("# This file controls administrator-level settings.\n")
	sb.WriteString("# Edit this file and run `axiom-rebuild` to apply changes.\n\n")

	if axiom, ok := config["axiom"].(map[string]interface{}); ok {
		if admin, ok := axiom["admin"].(map[string]interface{}); ok {
			// Sort section keys for consistent output
			sectionKeys := make([]string, 0, len(admin))
			for key := range admin {
				sectionKeys = append(sectionKeys, key)
			}
			sort.Strings(sectionKeys)

			for _, sectionKey := range sectionKeys {
				value := admin[sectionKey]
				if nested, ok := value.(map[string]interface{}); ok {
					sb.WriteString(fmt.Sprintf("%s {\n", sectionKey))

					// Sort item keys for consistent output
					itemKeys := make([]string, 0, len(nested))
					for itemKey := range nested {
						itemKeys = append(itemKeys, itemKey)
					}
					sort.Strings(itemKeys)

					for _, itemKey := range itemKeys {
						itemValue := nested[itemKey]
						if itemNested, ok := itemValue.(map[string]interface{}); ok {
							if enable, hasEnable := itemNested["enable"].(bool); hasEnable {
								sb.WriteString(fmt.Sprintf("  %s.enable = %t\n", itemKey, enable))
							}
						}
					}
					sb.WriteString("}\n\n")
				}
			}
		}
	}

	return sb.String()
}
