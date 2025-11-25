{ pkgs, ... }:
let
  nukePlugin = pkgs.fetchFromGitHub {
    owner = "Junker";
    repo = "nuke.xplr";
    rev = "main";
    sha256 = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA="; # Update this after first build
  };
in
{
  # Link nuke plugin
  xdg.configFile."xplr/plugins/nuke".source = nukePlugin;

  # Generate init.lua with configuration
  xdg.configFile."xplr/init.lua".text = ''
    -- Add plugin path
    local home = os.getenv("HOME")
    package.path = home
      .. "/.config/xplr/plugins/?/src/init.lua;"
      .. home
      .. "/.config/xplr/plugins/?.lua;"
      .. package.path

    -- Setup nuke plugin with open behavior only
    require("nuke").setup{
      open = {
        run_executables = false,
        custom = {
          {mime_regex = ".*", command = "xdg-open {}"}
        }
      }
    }

    -- Key bindings
    local key = xplr.config.modes.builtin.default.key_bindings.on_key

    -- Enter key opens files
    key["enter"] = xplr.config.modes.custom.nuke.key_bindings.on_key.o
  '';
}
