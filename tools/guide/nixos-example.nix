# Example NixOS configuration for the Guide LLM service
# 
# Usage:
# 1. Add this flake to your flake.nix inputs:
#    inputs.guide.url = "path:/path/to/guide";  # or github:wonderinstruments/guide
#
# 2. Import the module in your configuration.nix:
#    imports = [ inputs.guide.nixosModules.default ];
#
# 3. Configure the service (see examples below)

{ config, pkgs, ... }:

{
  # Import the guide module (already done if you imported it in flake.nix)
  # imports = [ inputs.guide.nixosModules.default ];
  
  # Example 1: Basic configuration with automatic model download
  services.guide = {
    enable = true;
    
    llama = {
      modelPath = "/var/lib/guide/models/Qwen3-Coder-30B-A3B-Instruct-Q8_0.gguf";
      modelUrl = "https://huggingface.co/unsloth/Qwen3-Coder-30B-A3B-Instruct-GGUF/resolve/main/Qwen3-Coder-30B-A3B-Instruct-Q8_0.gguf";
    };
  };
  
  # Example 2: Configuration with manual model (no auto-download)
  # services.guide = {
  #   enable = true;
  #   
  #   llama = {
  #     modelPath = "/var/lib/guide/models/model.gguf";
  #     # modelUrl not specified - you must manually place the model file
  #   };
  # };
  
  # Example 3: Advanced configuration
  # services.guide = {
  #   enable = true;
  #   
  #   # Use a custom user instead of the default "guide" user
  #   user = "myuser";
  #   group = "mygroup";
  #   
  #   # Server configuration
  #   server = {
  #     host = "127.0.0.1";
  #     port = 8234;
  #   };
  #   
  #   # LLM configuration
  #   llama = {
  #     modelPath = "/var/lib/guide/models/model.gguf";
  #     modelUrl = "https://example.com/path/to/model.gguf";
  #     
  #     # Performance tuning
  #     threads = 0;  # 0 = auto-detect
  #     ctxSize = 4096;
  #     temperature = 0.7;
  #     batchSize = 512;
  #     
  #     # GPU support (if available)
  #     gpuLayers = 0;  # 0 = CPU only, increase for GPU acceleration
  #     
  #     # Memory optimization
  #     mlock = false;  # Set to true to lock model in RAM
  #     
  #     # Debugging
  #     verbose = false;
  #     
  #     # Additional arguments
  #     extraArgs = [];
  #   };
  #   
  #   # OpenMP threads
  #   ompNumThreads = 8;
  # };
  
  # Example 4: Using GPU acceleration with CUDA
  # services.guide = {
  #   enable = true;
  #   
  #   # Use CUDA-enabled llama-cpp
  #   llama = {
  #     package = pkgs.llama-cpp.override { cudaSupport = true; };
  #     modelPath = "/var/lib/guide/models/model.gguf";
  #     gpuLayers = 35;  # Offload layers to GPU
  #   };
  # };
  
  # After enabling the service, you can:
  # - Check status: systemctl status guide-llama-server
  # - View logs: journalctl -u guide-llama-server -f
  # - Use the client: guide --from-fish -- "Your question"
}
