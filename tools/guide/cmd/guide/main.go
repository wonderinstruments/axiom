package main

import (
	"context"
	"errors"
	"flag"
	"fmt"
	"io"
	"math/rand"
	"os"
	"os/signal"
	"strings"
	"syscall"
	"time"

	"github.com/charmbracelet/bubbles/spinner"
	"github.com/charmbracelet/bubbletea"
	"github.com/charmbracelet/glamour"
	"github.com/charmbracelet/lipgloss"
	"golang.org/x/sys/unix"
	"wonderinstruments/guide-go/internal/config"
	"wonderinstruments/guide-go/internal/llmclient"
	"wonderinstruments/guide-go/internal/wm"
)


type cliArgs struct {
	fromFish   bool
	nulHistory bool
	userPrompt string
}

func parseArgs() (cliArgs, int) {
	fs := flag.NewFlagSet("guide", flag.ContinueOnError)
	fs.SetOutput(io.Discard) // silence default usage to keep stdout clean
	fromFish := fs.Bool("from-fish", false, "Indicates invocation from fish dispatch function")
	nulHistory := fs.Bool("nul-history", false, "Read null-separated fish history from stdin")

	// Manually split on literal "--" to capture prompt verbatim
	raw := os.Args[1:]
	sep := -1
	for i, a := range raw {
		if a == "--" {
			sep = i
			break
		}
	}
	var flagsPart, promptPart []string
	if sep >= 0 {
		flagsPart = raw[:sep]
		promptPart = raw[sep+1:]
	} else {
		flagsPart = raw
	}
	if err := fs.Parse(flagsPart); err != nil {
		fmt.Fprintln(os.Stderr, "Error:", err)
		return cliArgs{}, 2
	}
	prompt := strings.TrimSpace(strings.Join(promptPart, " "))
	if prompt == "" {
		fmt.Fprintln(os.Stderr, "Error: No prompt provided. Usage: guide --from-fish -- 'your prompt'")
		return cliArgs{}, 2
	}
	return cliArgs{fromFish: *fromFish, nulHistory: *nulHistory, userPrompt: prompt}, 0
}

func readFishHistory(enabled bool) []string {
	if !enabled {
		return nil
	}
	fd := int(os.Stdin.Fd())
	// Set non-blocking; if it fails, just skip reading
	if err := unix.SetNonblock(fd, true); err != nil {
		return nil
	}
	defer func() { _ = unix.SetNonblock(fd, false) }()
	var b []byte
	tmp := make([]byte, 64*1024)
	for {
		n, err := unix.Read(fd, tmp)
		if n > 0 {
			b = append(b, tmp[:n]...)
			continue
		}
		if err == nil {
			// No bytes but no error; wait briefly and retry once
			time.Sleep(1 * time.Millisecond)
			// Try one more read; if still empty, break
			n2, err2 := unix.Read(fd, tmp)
			if n2 > 0 {
				b = append(b, tmp[:n2]...)
			}
			if err2 != nil && err2 != syscall.EAGAIN && err2 != syscall.EWOULDBLOCK && err2 != io.EOF {
				break
			}
			break
		}
		if errors.Is(err, syscall.EAGAIN) || errors.Is(err, syscall.EWOULDBLOCK) {
			break
		}
		if errors.Is(err, io.EOF) {
			break
		}
		// Any other error: stop trying
		break
	}
	if len(b) == 0 {
		return nil
	}
	// Split by NUL, decode UTF-8 (ignore errors by replacing invalid runes)
	s := string(b)
	rawItems := strings.Split(s, "\x00")
	out := make([]string, 0, len(rawItems))
	for _, it := range rawItems {
		it = strings.TrimSpace(it)
		if it != "" {
			out = append(out, it)
		}
	}
	return out
}

func setupSignals() chan os.Signal {
	signal.Ignore(syscall.SIGPIPE)
	ch := make(chan os.Signal, 1)
	signal.Notify(ch, os.Interrupt)
	return ch
}

// generateRandomString creates a random string of letters and numbers
func generateRandomString(length int) string {
	const charset = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
	b := make([]byte, length)
	for i := range b {
		b[i] = charset[rand.Intn(len(charset))]
	}
	return string(b)
}


func buildSystemPrompt() string {
	// Get current working directory
	pwd, err := os.Getwd()
	if err != nil {
		pwd = "(unknown)"
	}

	// Get directory listing
	files, err := os.ReadDir(pwd)
	dirListing := "(unable to read directory)"
	if err == nil {
		var fileNames []string
		for _, file := range files {
			name := file.Name()
			if file.IsDir() {
				name += "/"
			}
			fileNames = append(fileNames, name)
		}
		dirListing = strings.Join(fileNames, "  ")
	}

	// Get information about open windows
	windowInfo := wm.GetWindowInfoSafely()

	prompt := fmt.Sprintf(`You are a helpful AI assistant specialized in helping users navigate the command line and computer systems.

Style Guidelines:
- Be direct, concise, and to the point.
- Do not use the first person perspective (No use of me/I). Instead, produce output that matches the style of documentation. If you must refer to yourself, refer to yourself in the third personas 'the large language model'.
- If you need to describe what you are doing, say things like "the large language model is performing linear algebra", rather than using personifying language like 'thinking'.
- Your role: Help with command line tasks, file operations, system administration, and general computer navigation. If you are asked to stray beyond that role (for example, into emotions, casual conversation, etc), explain that you are only able to produce output related to your role.

Context:
- System: Ubuntu Linux with i3 window manager and fish shell
- Available tools: ranger (file manager), tldr (simplified man pages), fzf (fuzzy finder), fd (modern find), ripgrep/rg (fast grep), eza (modern ls), nvim (neovim), bat (better cat), plus standard tools (grep, find, sed, awk, etc.)
- The user invokes this llm response with the command '? <user_input>'
- To open the app launcher, the user can use the 'Super + Space' shortcut
- Current directory: %s
- Directory contents: %s
- Open windows: %s
`, pwd, dirListing, windowInfo)
	return prompt
}

// Custom message types
type tokenMsg string
type streamDoneMsg struct{}
type streamErrorMsg error
type randomStringMsg string

// Main streaming model for Bubble Tea
type streamModel struct {
	spinner      spinner.Model
	renderer     *glamour.TermRenderer
	content      string
	userPrompt   string
	randomString string
	thinking     bool
	done         bool
	err          error
	quitting     bool
}

func newStreamModel(userPrompt string) streamModel {
	s := spinner.New()
	s.Spinner = spinner.Dot
	s.Style = s.Style.Foreground(lipgloss.Color("2")) // Green color

	// Initialize Glamour renderer
	renderer, err := glamour.NewTermRenderer(
		glamour.WithAutoStyle(),
		glamour.WithWordWrap(80),
	)
	if err != nil {
		renderer = nil // Fallback to plain text
	}

	return streamModel{
		spinner:      s,
		renderer:     renderer,
		userPrompt:   userPrompt,
		randomString: generateRandomString(40),
		thinking:     true,
	}
}

func (m streamModel) Init() tea.Cmd {
	return tea.Batch(
		m.spinner.Tick,
		tea.Tick(time.Second/8, func(time.Time) tea.Msg {
			return randomStringMsg(generateRandomString(40))
		}),
	)
}

func (m streamModel) Update(msg tea.Msg) (tea.Model, tea.Cmd) {
	switch msg := msg.(type) {
	case tea.KeyMsg:
		if msg.Type == tea.KeyCtrlC {
			m.quitting = true
			return m, tea.Quit
		}
		return m, nil

	case tokenMsg:
		// First token stops thinking
		if m.thinking {
			m.thinking = false
		}
		m.content += string(msg)
		return m, nil

	case randomStringMsg:
		// Update random string only when thinking
		if m.thinking {
			m.randomString = string(msg)
			// Schedule next random string update
			return m, tea.Tick(time.Second/8, func(time.Time) tea.Msg {
				return randomStringMsg(generateRandomString(40))
			})
		}
		return m, nil

	case streamDoneMsg:
		m.done = true
		return m, tea.Quit

	case streamErrorMsg:
		m.err = error(msg)
		m.done = true
		return m, tea.Quit

	default:
		var cmd tea.Cmd
		m.spinner, cmd = m.spinner.Update(msg)
		return m, cmd
	}
}

func (m streamModel) View() string {
	// Create a nice display for the user input that stays visible throughout
	userInputDisplay := fmt.Sprintf("\n❯ %s\n\n", m.userPrompt)

	if m.quitting {
		// Return the final content when quitting to preserve output
		if m.content != "" {
			var contentOutput string
			if m.renderer != nil {
				if rendered, err := m.renderer.Render(m.content); err == nil {
					contentOutput = rendered
				} else {
					contentOutput = m.content
				}
			} else {
				contentOutput = m.content
			}
			return userInputDisplay + contentOutput
		}
		return userInputDisplay
	}

	if m.thinking {
		return fmt.Sprintf("%s%s", userInputDisplay, m.randomString)
	}

	// Render the accumulated content
	if m.content == "" {
		return userInputDisplay
	}

	var contentOutput string
	if m.renderer != nil {
		if rendered, err := m.renderer.Render(m.content); err == nil {
			contentOutput = strings.TrimRight(rendered, "\n")
		} else {
			contentOutput = strings.TrimRight(m.content, "\n")
		}
	} else {
		// Fallback to plain text
		contentOutput = strings.TrimRight(m.content, "\n")
	}

	return userInputDisplay + contentOutput
}

func streamChat(ctx context.Context, cfg config.Config, prompt string) error {
	// Create OpenAI-compatible client using configured server URL
	serverURL := config.ServerURL(cfg)
	client := llmclient.NewClient(serverURL)

	// Create the Bubble Tea program without alt screen to preserve output
	model := newStreamModel(prompt)
	p := tea.NewProgram(model)

	// Start the Bubble Tea program in a goroutine
	programDone := make(chan struct{})
	go func() {
		defer close(programDone)
		if _, err := p.Run(); err != nil {
			fmt.Fprintf(os.Stderr, "Error running program: %v\n", err)
		}
	}()

	// Stream function that sends tokens to the Bubble Tea model
	streamFn := func(token string) {
		p.Send(tokenMsg(token))
	}

	// Build dynamic system message with current context
	systemMsg := buildSystemPrompt()
	// prompt += " /no_think"

	// Stream the chat completion
	err := llmclient.StreamChat(ctx, client, systemMsg, prompt, "llama", streamFn)
	if err != nil {
		// Send error message to the model
		p.Send(streamErrorMsg(err))
		// If we got EPIPE, exit successfully
		if errors.Is(err, syscall.EPIPE) {
			return nil
		}
		// Provide helpful error message for connection failures
		if strings.Contains(err.Error(), "connection refused") || strings.Contains(err.Error(), "no such host") {
			return fmt.Errorf("%w\n\nThe llama-server is not running. Please start it with:\n  sudo systemctl start guide-llama-server\n\nOr check its status with:\n  sudo systemctl status guide-llama-server", err)
		}
		return err
	}

	// Wait a moment for the final render
	time.Sleep(100 * time.Millisecond)
	p.Send(streamDoneMsg{})

	// Wait for Bubble Tea to finish and restore the terminal
	<-programDone

	// Print a final newline to preserve the last line and flush output
	fmt.Print("\n")
	os.Stdout.Sync()

	return nil
}

func main() {
	args, code := parseArgs()
	if code != 0 {
		os.Exit(code)
	}

	_ = readFishHistory(args.nulHistory) // Currently unused but reserved for future context

	sigCh := setupSignals()
	ctx, cancel := context.WithCancel(context.Background())
	defer cancel()

	// Load configuration
	cfg, err := config.Load("")
	if err != nil {
		fmt.Fprintf(os.Stderr, "Error loading configuration: %v\n", err)
		os.Exit(1)
	}

	// Handle SIGINT by canceling context
	go func() {
		<-sigCh
		cancel()
	}()

	// Run streamChat synchronously to ensure proper cleanup
	err = streamChat(ctx, cfg, args.userPrompt)

	// Determine exit code after cleanup is complete
	exitCode := 0
	switch {
	case errors.Is(err, syscall.EPIPE):
		// Handle broken pipe quietly
		exitCode = 0
	case err != nil:
		fmt.Fprintln(os.Stderr, "Error: Failed to generate response:", err)
		exitCode = 1
	case ctx.Err() == context.Canceled:
		// Interrupted by SIGINT
		fmt.Fprintln(os.Stderr)
		exitCode = 130
	}
	os.Exit(exitCode)
}
