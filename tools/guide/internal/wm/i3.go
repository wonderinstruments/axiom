package wm

import (
	"fmt"
	"strings"

	"github.com/mdirkse/i3ipc-go"
)

// WindowInfo represents information about an open window
type WindowInfo struct {
	Class string
	Title string
}

// GetI3WindowInfo connects to i3 and retrieves information about open windows
func GetI3WindowInfo() ([]WindowInfo, error) {
	conn, err := i3ipc.GetIPCSocket()
	if err != nil {
		return nil, fmt.Errorf("failed to connect to i3: %w", err)
	}
	defer conn.Close()

	tree, err := conn.GetTree()
	if err != nil {
		return nil, fmt.Errorf("failed to get window tree: %w", err)
	}

	var windows []WindowInfo
	
	// Recursive function to traverse the window tree
	var walk func(node i3ipc.I3Node)
	walk = func(node i3ipc.I3Node) {
		// Check if this node represents a window with properties
		if node.Window_Properties.Class != "" {
			windows = append(windows, WindowInfo{
				Class: node.Window_Properties.Class,
				Title: node.Name,
			})
		}
		
		// Recursively check child nodes
		for _, n := range node.Nodes {
			walk(n)
		}
		
		// Also check floating nodes
		for _, n := range node.Floating_Nodes {
			walk(n)
		}
	}
	
	walk(tree)
	return windows, nil
}

// FormatWindowInfo formats window information for inclusion in a prompt
func FormatWindowInfo(windows []WindowInfo) string {
	if len(windows) == 0 {
		return "(no windows detected)"
	}
	
	var parts []string
	for _, w := range windows {
		if w.Title != "" && w.Title != w.Class {
			parts = append(parts, fmt.Sprintf("%s (%s)", w.Class, w.Title))
		} else {
			parts = append(parts, w.Class)
		}
	}
	
	return strings.Join(parts, ", ")
}

// GetWindowInfoSafely attempts to get window info but returns a safe fallback on error
func GetWindowInfoSafely() string {
	windows, err := GetI3WindowInfo()
	if err != nil {
		// Return a safe fallback instead of exposing errors in the prompt
		return "(window info unavailable)"
	}
	return FormatWindowInfo(windows)
}
