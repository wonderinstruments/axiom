# Guide - Local LLM CLI Tool

A command-line interface for interacting with a local LLM (Qwen3-4B-Instruct) from the fish shell.

## Features

- **Streaming output**: Real-time streaming responses from the local LLM
- **Fish shell integration**: Designed to work with fish shell's `dispatch-or-execute` function
- **History awareness**: Can ingest fish shell history (currently stored but not yet used for context)
- **Non-blocking I/O**: Handles stdin gracefully when no input is available
- **Clean stdout**: LLM responses on stdout, diagnostics on stderr

## Prerequisites

- **Environment**: Requires Nix shell environment (run `nix-shell` first)
- **Model**: Qwen3-4B-Instruct-2507-Q8_0.gguf model in `./models/` directory
- **Dependencies**: llama-cpp-python (available in the Nix environment)

## Installation

### Quick Install (Recommended)

Use the automated installation script:

```bash
# Clone and install from source
git clone <repository-url>
cd guide
./install.sh
```

Or build with Make:

```bash
# One-command setup and install
make setup && make install
```

### Manual Installation

1. **Install dependencies**:
   - Go 1.21+
   - cmake, make, gcc
   - git

2. **Build the project**:
   ```bash
   make setup    # Initialize submodules and build llama.cpp
   make build    # Build the binary
   make install  # Install to ~/.local/bin
   ```

3. **Set up your shell** (optional but recommended):
   ```bash
   source ~/.config/guide/setup.sh
   ```

## Usage

### Basic Usage

```bash
guide --from-fish -- "What is Python?"
```

### With Fish History (as intended from fish shell)

```bash
history --null --max=200 | guide --from-fish --nul-history -- "Explain this command"
```

### With Custom Model Path

```bash
# Set custom model location
export GUIDE_MODEL_PATH="/path/to/your/model.gguf"
guide --from-fish -- "Your question"
```

### Fish Shell Integration

The tool is designed to be called from fish shell via the `dispatch-or-execute` function. In fish, type:

```fish
?What is Python?
```

This will automatically call:
```bash
history --null | guide --from-fish --nul-history -- "What is Python?"
```

## Command Line Options

- `--from-fish`: Indicates invocation from fish dispatch function
- `--nul-history`: Read null-separated fish history from stdin
- `-- "prompt"`: Your question or prompt (everything after `--`)

## Technical Details

### Environment Requirements

- Must run in `nix-shell` environment
- Uses the exact same LLM configuration as the original `main.py`:
  - Model: `./models/Qwen3-4B-Instruct-2507-Q8_0.gguf`
  - Context length: 4096 tokens
  - Temperature: 0.7
  - CPU-based inference with optimizations

### Output Format

- **stdout**: LLM response only (clean for piping)
- **stderr**: Model loading logs, diagnostics, error messages

### Exit Codes

- `0`: Success
- `1`: Runtime/LLM initialization error
- `2`: Argument error (e.g., missing prompt)

### History Handling

Fish history is currently ingested and stored but not yet used for context. This is a placeholder for future enhancement where command history could provide context to the LLM.

## Examples

### Simple Question
```bash
nix-shell --run "./guide --from-fish -- 'Hello, how are you?'"
```

### With Fake History
```bash
echo -en "ls -la\\0cd /home\\0" | nix-shell --run "./guide --from-fish --nul-history -- 'What do these commands do?'"
```

### Piping Output
```bash
nix-shell --run "./guide --from-fish -- 'List 3 colors'" | head -1
```

## Development

### File Structure

- `main.py`: Source code (also serves as backup)
- `guide`: Executable script (copy of main.py)
- `models/`: Directory containing the GGUF model file
- `shell_config/fish/functions/dispatch-or-execute.fish`: Fish integration

### Modular Functions

The code is organized into modular functions:
- `init_llm()`: Initialize the Llama model
- `build_messages()`: Construct message format for the LLM
- `stream_chat()`: Handle streaming output
- `read_fish_history()`: Parse fish history from stdin
- `parse_args()`: Command line argument parsing

## Model Configuration

### Automatic Model Discovery

Guide automatically searches for GGUF model files in these locations (in order):

1. **Environment variable**: `$GUIDE_MODEL_PATH`
2. **Current directory**: `./models/Qwen3-4B-Instruct-2507-Q8_0.gguf`
3. **Current directory**: `./Qwen3-4B-Instruct-2507-Q8_0.gguf`
4. **Parent directory**: `../models/Qwen3-4B-Instruct-2507-Q8_0.gguf`
5. **User data directory**: `~/.local/share/guide/models/Qwen3-4B-Instruct-2507-Q8_0.gguf`
6. **User config directory**: `~/.config/guide/models/Qwen3-4B-Instruct-2507-Q8_0.gguf`
7. **Any .gguf file** in the above directories

### Setting Custom Model Path

```bash
# Temporary (for current session)
export GUIDE_MODEL_PATH="/path/to/your/model.gguf"

# Permanent (add to ~/.bashrc or ~/.zshrc)
echo 'export GUIDE_MODEL_PATH="/path/to/your/model.gguf"' >> ~/.bashrc

# Or use the config file created by install script
source ~/.config/guide/config.env
```

### Debug Model Path

To see which paths Guide is checking:

```bash
make debug-paths
```

## Troubleshooting

### Common Issues

#### "Model file not found"

**Solution**: Download a GGUF model and place it in one of the search locations, or set `GUIDE_MODEL_PATH`.

```bash
# Check what paths are being searched
make debug-paths

# Set custom path
export GUIDE_MODEL_PATH="/path/to/your/model.gguf"

# Or copy model to standard location
mkdir -p ~/.local/share/guide/models
cp your-model.gguf ~/.local/share/guide/models/
```

#### "llama-server binary not found"

**Solution**: Build the llama.cpp server:

```bash
make llama-server
```

Or ensure `llama-server` is in your PATH.

#### "Binary won't run" / Permission denied

**Solution**: Make the binary executable:

```bash
chmod +x ~/.local/bin/guide
# or
make install  # Reinstall with correct permissions
```

#### "Go version too old"

**Solution**: Update Go to version 1.21 or later:

```bash
# On Ubuntu/Debian
sudo snap install go --classic

# On macOS
brew install go

# Or download from https://golang.org/dl/
```

### Getting Help

```bash
# Show help
guide --help

# Show available make targets
make help

# Debug model path search
make debug-paths

# Test installation
make dev
```

### Performance Tips

- **Model size**: Smaller models (4B parameters) load faster than larger ones (8B+)
- **Model format**: Q8_0 quantization provides good quality/speed balance
- **First run**: Model loading takes longer on first run (model is cached afterwards)
- **CPU optimization**: llama.cpp automatically detects and uses CPU optimizations

## Notes

- The tool preserves the exact same LLM behavior as the original `main.py`
- Fish history is read but not currently used in prompts (reserved for future use)
- Model loading can take a few seconds on first run
- All stdout is the LLM response - perfect for shell scripting and piping
- Cross-platform: Works on Linux, macOS, and Windows
