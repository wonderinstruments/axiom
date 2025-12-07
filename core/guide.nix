# Guide LLM Service
# Local LLM assistant service running as the curator user

{ pkgs, ... }:
{
  services.guide = {
    enable = true;
    user = "curator";
    group = "users";
    package = pkgs.guide;
    launcherPackage = pkgs.guide-llama-launcher;
  };
}
