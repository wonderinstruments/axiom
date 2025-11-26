{
  config,
  lib,
  pkgs,
  ...
}:

let
  # Patch wikiman to use 'find -L' for following symlinks (required for NixOS)
  wikiman-nixos = pkgs.wikiman.overrideAttrs (oldAttrs: {
    postPatch =
      (oldAttrs.postPatch or "")
      + ''
        # Replace 'find' with 'find -L' to follow symlinks in NixOS store
        substituteInPlace wikiman \
          --replace "conf_find='find'" "conf_find='find -L'"
      '';
  });
in
{
  # Install the patched wikiman and optional tldr pages
  home.packages = [
    wikiman-nixos
    pkgs.tldr # tldr-pages for wikiman
  ];

  # Enable man page cache generation for apropos/whatis support
  programs.man.generateCaches = true;

  # Wikiman configuration
  xdg.configFile."wikiman/wikiman.conf".text = ''
    # Sources to search (empty = all available)
    sources = man, tldr

    # Fuzzy finder
    fuzzy_finder = fzf

    # Quick search mode (only by title)
    quick_search = false

    # AND operator mode (must contain all keywords)
    and_operator = false

    # Manpages language(s)
    man_lang = en

    # Wiki language(s)
    wiki_lang = en

    # Show previews in TUI
    tui_preview = true

    # Keep open after viewing a result
    tui_keep_open = false

    # Show source column
    tui_source_column = false

    # Viewer for HTML pages
    tui_html = w3m
  '';
}
