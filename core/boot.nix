# Boot configuration

{ ... }:
{
  # Use the systemd-boot EFI boot loader
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Disable power management (for always-on systems)
  powerManagement.enable = false;
}
