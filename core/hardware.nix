# Core hardware and platform configuration
# Audio, networking, clipboard, virtualization

{ pkgs, ... }:
{
  # Networking
  networking.networkmanager.enable = true;

  # Audio (PipeWire)
  services.pipewire = {
    enable = true;
    pulse.enable = true;
  };

  # Clipboard support
  environment.systemPackages = with pkgs; [
    xclip
  ];

  # Docker
  virtualisation.docker.enable = true;
}
