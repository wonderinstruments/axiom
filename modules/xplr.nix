{ pkgs, ... }:
{
  programs.xplr = {
    enable = true;
    plugins = {
      nuke = pkgs.fetchFromGitHub {
        owner = "Junker";
        repo = "nuke.xplr";
        rev = "main";
        sha256 = "sha256-k/yre9SYNPYBM2W1DPpL6Ypt3w3EMO9dznHwa+fw/n0=";
      };
    };
    extraConfig = ''
      require("nuke").setup{
        open = {
          run_executables = false,
          custom = {
            {mime_regex = ".*", command = "xdg-open {}"}
          }
        }
      }

      -- Enter key opens files
      local key = xplr.config.modes.builtin.default.key_bindings.on_key
      key["enter"] = xplr.config.modes.custom.nuke.key_bindings.on_key.o
    '';
  };
}
