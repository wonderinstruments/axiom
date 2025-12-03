# Guide systemd Service Installation

This directory contains the systemd service configuration for running the Guide llama-server as a system service.

## Architecture

The Guide application now uses a client-server architecture:
- **guide-llama-server** (systemd service): Long-running llama-server process
- **guide** (client): Connects to the running server for inference requests

This design allows:
- Multiple guide client invocations to share a single loaded model
- Faster response times (no model loading on each request)
- Better resource management
- Simplified deployment via systemd

## Files

- `guide-llama-server.service` - systemd unit file
- `config.toml` - Example configuration file
- `README.md` - This file

## Installation Steps

### 1. Build the Binaries

From the project root:

```bash
# Use the unified install script
./install --build-only

# Or manually with Go:
nix-shell  # if using Nix
go build -o build/guide ./cmd/guide
go build -o build/guide-llama-launcher ./cmd/guide-llama-launcher
```

### 2. Install Binaries

```bash
sudo install -m 755 build/guide /usr/local/bin/
sudo install -m 755 build/guide-llama-launcher /usr/local/bin/
```

### 3. Configure the Service

Copy and edit the configuration file:

```bash
sudo mkdir -p /etc/guide
sudo cp systemd/config.toml /etc/guide/config.toml
sudo vi /etc/guide/config.toml
```

**Important:** Edit the configuration to set:
- `llama.binary` - Absolute path to your llama-server binary
- `llama.model` - Absolute path to your GGUF model file
- `llama.threads` - Number of CPU threads (0 = auto-detect)
- Other parameters as needed

Example:
```toml
[server]
host = "127.0.0.1"
port = 8234

[llama]
binary = "/home/edmundm/wonderinstruments/guide/third_party/go-llama.cpp/llama.cpp/build/bin/llama-server"
model = "/home/edmundm/wonderinstruments/guide/models/granite-4.0-h-tiny-Q6_K.gguf"
threads = 0  # auto-detect
ctx_size = 4096
temperature = 0.7
```

### 4. Install the Service

```bash
sudo cp systemd/guide-llama-server.service /etc/systemd/system/
sudo systemctl daemon-reload
```

### 5. Start and Enable the Service

```bash
# Start the service
sudo systemctl start guide-llama-server

# Enable it to start on boot
sudo systemctl enable guide-llama-server

# Or do both at once:
sudo systemctl enable --now guide-llama-server
```

### 6. Verify Installation

Check service status:
```bash
sudo systemctl status guide-llama-server
```

View logs:
```bash
# Recent logs
sudo journalctl -u guide-llama-server -n 50

# Follow logs in real-time
sudo journalctl -u guide-llama-server -f
```

Verify the server is listening:
```bash
ss -ltn 'sport = :8234'
# or
curl http://127.0.0.1:8234/v1/models
```

Test with the guide client:
```bash
guide --from-fish -- "Hello, are you working?"
```

## Service Management

### Start/Stop/Restart

```bash
# Start
sudo systemctl start guide-llama-server

# Stop
sudo systemctl stop guide-llama-server

# Restart
sudo systemctl restart guide-llama-server

# Reload configuration (stop + start)
sudo systemctl restart guide-llama-server
```

### Check Status

```bash
# Brief status
sudo systemctl status guide-llama-server

# Detailed status
sudo systemctl status guide-llama-server --no-pager -l

# Is it running?
sudo systemctl is-active guide-llama-server

# Is it enabled?
sudo systemctl is-enabled guide-llama-server
```

### View Logs

```bash
# All logs
sudo journalctl -u guide-llama-server

# Last 100 lines
sudo journalctl -u guide-llama-server -n 100

# Follow (tail -f style)
sudo journalctl -u guide-llama-server -f

# Since specific time
sudo journalctl -u guide-llama-server --since "10 minutes ago"

# Only errors
sudo journalctl -u guide-llama-server -p err
```

## Configuration Changes

After modifying `/etc/guide/config.toml`:

```bash
sudo systemctl restart guide-llama-server
```

The launcher will automatically read the new configuration and restart llama-server with updated parameters.

## Troubleshooting

### Service Won't Start

1. **Check the logs:**
   ```bash
   sudo journalctl -u guide-llama-server -n 100
   ```

2. **Common issues:**
   - Binary not found: Verify `llama.binary` path in config
   - Model not found: Verify `llama.model` path in config
   - Permission denied: Ensure user `edmundm` can read the model and execute the binary
   - Port already in use: Change `server.port` in config

3. **Test the launcher manually:**
   ```bash
   sudo -u edmundm /usr/local/bin/guide-llama-launcher
   ```

### Permission Issues

If you see permission denied errors:

```bash
# Check model file permissions
ls -la /path/to/model.gguf

# Ensure edmundm can read it
sudo chmod 644 /path/to/model.gguf
sudo chown edmundm:edmundm /path/to/model.gguf  # if needed

# Check binary permissions
ls -la /path/to/llama-server
```

### Port Conflicts

If port 8234 is already in use:

1. Find what's using it:
   ```bash
   sudo ss -tlnp 'sport = :8234'
   ```

2. Change the port in `/etc/guide/config.toml`:
   ```toml
   [server]
   port = 8235  # or another unused port
   ```

3. Restart the service

### Model Loading Slowly

For large models, loading can take 30-60 seconds. Check:

```bash
# Follow startup logs
sudo journalctl -u guide-llama-server -f
```

Look for "model loaded" or similar messages.

### Client Can't Connect

1. **Verify server is running:**
   ```bash
   sudo systemctl status guide-llama-server
   curl http://127.0.0.1:8234/v1/models
   ```

2. **Check client configuration:**
   The guide client also reads `/etc/guide/config.toml`. Ensure server host/port match.

3. **Test direct connection:**
   ```bash
   curl http://127.0.0.1:8234/v1/chat/completions \
     -H "Content-Type: application/json" \
     -d '{"model":"llama","messages":[{"role":"user","content":"hi"}],"max_tokens":10}'
   ```

### Increase Logging Verbosity

Edit `/etc/guide/config.toml`:

```toml
[llama]
verbose = true
```

Then restart:
```bash
sudo systemctl restart guide-llama-server
```

### Memory Issues

If the model is too large:

1. Use a smaller quantization (Q4_K_M instead of Q8_0)
2. Reduce context size in config:
   ```toml
   [llama]
   ctx_size = 2048  # smaller than 4096
   ```
3. Check system memory:
   ```bash
   free -h
   ```

## Uninstalling

```bash
# Stop and disable service
sudo systemctl stop guide-llama-server
sudo systemctl disable guide-llama-server

# Remove files
sudo rm /etc/systemd/system/guide-llama-server.service
sudo rm -rf /etc/guide
sudo rm /usr/local/bin/guide
sudo rm /usr/local/bin/guide-llama-launcher

# Reload systemd
sudo systemctl daemon-reload
```

## Environment Variables

The service supports these environment variables (edit the service file):

```ini
[Service]
Environment="OMP_NUM_THREADS=8"           # OpenMP threads
Environment="CUDA_VISIBLE_DEVICES=0"      # GPU selection (if using CUDA)
Environment="GUIDE_CONFIG=/custom/path"   # Override config file location
```

After editing the service file:
```bash
sudo systemctl daemon-reload
sudo systemctl restart guide-llama-server
```

## Security Considerations

The service runs as user `edmundm` with these security features:
- `NoNewPrivileges=true` - Prevents privilege escalation
- `ProtectSystem=full` - Read-only access to /usr, /boot, /efi
- `ProtectHome=read-only` - Read-only access to /home
- `PrivateTmp=true` - Private /tmp directory

To relax security (e.g., if you need write access):

Edit `/etc/systemd/system/guide-llama-server.service` and adjust the hardening directives.

## Advanced: Custom User

To run as a different user:

1. Edit `/etc/systemd/system/guide-llama-server.service`:
   ```ini
   [Service]
   User=myuser
   Group=mygroup
   ```

2. Ensure the user can access the model and binary:
   ```bash
   sudo chown myuser:mygroup /path/to/model.gguf
   sudo chmod 644 /path/to/model.gguf
   ```

3. Reload and restart:
   ```bash
   sudo systemctl daemon-reload
   sudo systemctl restart guide-llama-server
   ```

## Support

For issues or questions:
- Check logs: `sudo journalctl -u guide-llama-server`
- Review configuration: `cat /etc/guide/config.toml`
- Test launcher: `sudo -u edmundm /usr/local/bin/guide-llama-launcher`
- See main project README for general guidance
