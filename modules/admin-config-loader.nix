# Admin Configuration Loader (NixOS module)
#
# This module initializes the admin config file at /etc/axiom/admin.toml.
# The actual option settings are handled by admin-config-loader-hm.nix
# (a home-manager module) since axiom.admin.* are home-manager options.
#
# This file can only be modified by root, providing a security boundary
# for options like which applications/games are available.

{ lib, config, pkgs, ... }:

let
  # Path to the template (in the nix-config repo)
  templatePath = ../templates/admin-config.toml;

in
{
  config = {
    # =========================================================================
    # Install the admin config template to /etc/axiom/ if it doesn't exist
    # We use system.activationScripts to only copy if missing
    # =========================================================================
    system.activationScripts.initAxiomAdminConfig = lib.stringAfter [ "etc" ] ''
      if [ ! -f /etc/axiom/admin.toml ]; then
        mkdir -p /etc/axiom
        cp ${templatePath} /etc/axiom/admin.toml
        chmod 644 /etc/axiom/admin.toml
        echo "Initialized Axiom admin config at /etc/axiom/admin.toml"
      fi
    '';
  };
}
