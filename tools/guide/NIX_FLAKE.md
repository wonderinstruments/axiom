# Guide Nix Flake

This flake provides a complete Nix/NixOS setup for the Guide LLM application.

## Features

- ✅ Builds the `guide` client binary
- ✅ Builds the `guide-llama-launcher` systemd service binary
- ✅ Provides a NixOS module for declarative configuration
- ✅ Automatic systemd service setup
- ✅ Optional automatic model download
- ✅ Development shell with all dependencies

## Quick Start

### Building the Binaries

```bash
# Build the guide client
nix build .#guide

# Build the launcher
nix build .#guide-llama-launcher

# Build both
nix build

# Run directly without installing
nix run . -- --from-fish -- "Hello, world!"
```

### Development

```bash
# Enter development shell
nix develop

# Now you can use go commands directly
go build ./cmd/guide
go build ./cmd/guide-llama-launcher
```

### First-Time Setup

The first time you build, you'll need to update the `vendorHash`:

1. Try to build: `nix build`
2. The build will fail and show you the expected hash
3. Copy the hash shown in the error message
4. Update line 28 in `flake.nix` with the correct hash
5. Build again: `nix build`

## NixOS Module Usage

### 1. Add to Your Flake

In your NixOS configuration's `flake.nix`:

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    guide.url = "github:wonderinstruments/guide";  # or path:/path/to/guide
  };

  outputs = { self, nixpkgs, guide, ... }: {
    nixosConfigurations.yourhostname = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        guide.nixosModules.default
        ./configuration.nix
      ];
    };
  };
}
```

### 2. Configure in configuration.nix

#### Basic Configuration

```nix
{ config, pkgs, ... }:

{
  services.guide = {
    enable = true;
    
    llama = {
      # Specify where the model should be stored
      modelPath = "/var/lib/guide/models/model.gguf";
      
      # Optional: Provide a URL to automatically download the model
      modelUrl = "https://example.com/path/to/your-model.gguf";
    };
  };
}
```

#### Advanced Configuration

```nix
{ config, pkgs, ... }:

{
  services.guide = {
    enable = true;
    
    # Custom user/group (optional)
    user = "guide";
    group = "guide";
    
    # Server settings
    server = {
      host = "127.0.0.1";
      port = 8234;
    };
    
    # LLM configuration
    llama = {
      # Use a custom llama-cpp package
      package = pkgs.llama-cpp;
      
      modelPath = "/var/lib/guide/models/model.gguf";
      modelUrl = "https://huggingface.co/...";  # Your model URL
      
      # Performance tuning
      threads = 0;        # 0 = auto-detect CPU threads
      ctxSize = 4096;     # Context window size
      temperature = 0.7;  # Sampling temperature
      batchSize = 512;    # Batch size for processing
      
      # GPU acceleration (requires CUDA-enabled llama-cpp)
      gpuLayers = 0;      # 0 = CPU only, increase to offload to GPU
      
      # Memory management
      mlock = false;      # Lock model in RAM (prevents swapping)
      
      # Debugging
      verbose = false;
      
      # Additional llama-server arguments
      extraArgs = [];
    };
    
    # OpenMP threads for CPU inference
    ompNumThreads = 8;
  };
}
```

#### GPU Acceleration Example

```nix
{ config, pkgs, ... }:

{
  services.guide = {
    enable = true;
    
    llama = {
      # Use CUDA-enabled llama-cpp
      package = pkgs.llama-cpp.override { 
        cudaSupport = true; 
      };
      
      modelPath = "/var/lib/guide/models/model.gguf";
      
      # Offload layers to GPU
      gpuLayers = 35;  # Adjust based on your GPU memory
    };
  };
}
```

### 3. Deploy

```bash
# Rebuild your NixOS configuration
sudo nixos-rebuild switch

# Check service status
systemctl status guide-llama-server

# View logs
journalctl -u guide-llama-server -f

# Use the client
guide --from-fish -- "Hello!"
```

## Configuration Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `enable` | bool | `false` | Enable the guide service |
| `package` | package | `self.packages.guide` | The guide client package |
| `launcherPackage` | package | `self.packages.guide-llama-launcher` | The launcher package |
| `user` | string | `"guide"` | User to run the service as |
| `group` | string | `"guide"` | Group to run the service as |
| `server.host` | string | `"127.0.0.1"` | Server bind address |
| `server.port` | int | `8234` | Server port |
| `llama.package` | package | `pkgs.llama-cpp` | llama-cpp package to use |
| `llama.modelPath` | string | - | **Required**: Path to GGUF model file |
| `llama.modelUrl` | string? | `null` | URL to download model from (if not exists) |
| `llama.threads` | int | `0` | CPU threads (0 = auto) |
| `llama.ctxSize` | int | `4096` | Context size in tokens |
| `llama.temperature` | float | `0.7` | Sampling temperature |
| `llama.gpuLayers` | int | `0` | GPU layers to offload |
| `llama.batchSize` | int | `512` | Batch size |
| `llama.ropeFreqBase` | float | `0.0` | RoPE frequency base |
| `llama.ropeFreqScale` | float | `0.0` | RoPE frequency scale |
| `llama.mlock` | bool | `false` | Lock model in RAM |
| `llama.verbose` | bool | `false` | Enable verbose logging |
| `llama.extraArgs` | list | `[]` | Additional CLI arguments |
| `ompNumThreads` | int? | `8` | OMP_NUM_THREADS env var |

## Model Download

When you specify `llama.modelUrl`, the flake will:

1. Create a systemd service (`guide-model-download.service`) that runs before the main service
2. Download the model to `llama.modelPath` if it doesn't exist
3. Only download once (checks if file exists before downloading)

Example:

```nix
services.guide = {
  enable = true;
  llama = {
    modelPath = "/var/lib/guide/models/Qwen3-Coder-30B-A3B-Instruct-Q8_0.gguf";
    modelUrl = "https://huggingface.co/unsloth/Qwen3-Coder-30B-A3B-Instruct-GGUF/resolve/main/Qwen3-Coder-30B-A3B-Instruct-Q8_0.gguf";
  };
};
```

The model will be downloaded automatically on first boot or service start.

## Directory Structure

The flake creates the following:

- `/etc/guide/config.toml` - Generated configuration file
- User-specified model path (e.g., `/var/lib/guide/models/`)
- Systemd services:
  - `guide-llama-server.service` - Main service
  - `guide-model-download.service` - Optional model downloader

## Troubleshooting

### Service Won't Start

```bash
# Check status
systemctl status guide-llama-server

# View detailed logs
journalctl -u guide-llama-server -n 100

# Check configuration
cat /etc/guide/config.toml

# Verify model exists
ls -lh /var/lib/guide/models/
```

### Update vendorHash

If you modify Go dependencies:

```bash
# Clear the old build
nix flake update

# Try building - it will show the new hash
nix build

# Update flake.nix with the new hash
```

### Rebuild After Changes

After modifying the flake:

```bash
# Test the build
nix build

# Apply to NixOS
sudo nixos-rebuild switch
```

### Model Not Downloading

```bash
# Check model download service
systemctl status guide-model-download
journalctl -u guide-model-download

# Manually trigger download
sudo systemctl restart guide-model-download
```

## Non-NixOS Usage

You can use this flake on non-NixOS systems too:

```bash
# Install the binaries
nix profile install .#guide
nix profile install .#guide-llama-launcher

# Or run directly
nix run . -- --from-fish -- "Your question"

# Use with home-manager for user-level services
```

## Development Workflow

```bash
# Enter dev shell
nix develop

# Make changes to Go code
vim cmd/guide/main.go

# Build and test
go build ./cmd/guide
./guide --help

# Format Nix code
nix fmt

# Check flake
nix flake check

# Update dependencies
go mod tidy
nix build  # Will show new vendorHash if needed
```

## Integration with Fish Shell

The NixOS module installs the `guide` binary system-wide, so you can use it from fish:

```fish
# Direct usage
guide --from-fish -- "What is Nix?"

# With history
history --null | guide --from-fish --nul-history -- "Explain this command"

# Integration in fish config
function dispatch-or-execute
    # ... your fish function that calls guide
end
```

## Examples

See `nixos-example.nix` for complete configuration examples.

## See Also

- Main README: `README.md`
- Systemd documentation: `systemd/README.md`
- Installation script: `install` (for non-Nix installations)
