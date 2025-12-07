# Axiom System Module
#
# Applies global system settings from /etc/axiom/system.conf.
# Settings are read from the generated system-data.nix file.

{ config, lib, pkgs, ... }:

let
  # Import the generated system data
  systemData = import ../config/system/system-data.nix;

in
{
  config = {
    # Hostname
    networking.hostName = systemData.hostname;

    # Timezone
    time.timeZone = systemData.timezone;

    # Locale
    i18n.defaultLocale = systemData.locale;
  };
}
