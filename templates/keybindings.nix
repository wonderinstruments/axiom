{ ... }:
let
  mod = "Mod4"; # Super/Windows key
in
{
  axiom.keybindings = {
    # Application shortcuts
    newTerminal = "${mod}+Return";
    tuiLauncher = "${mod}+Shift+Return";
    applicationLauncher = "${mod}+space";

    # Window management (vim-inspired)
    focusLeft = "${mod}+h";
    focusDown = "${mod}+j";
    focusUp = "${mod}+k";
    focusRight = "${mod}+l";

    # Move windows (vim + shift)
    moveLeft = "${mod}+Shift+h";
    moveDown = "${mod}+Shift+j";
    moveUp = "${mod}+Shift+k";
    moveRight = "${mod}+Shift+l";

    # Splitting (vim-inspired)
    splitHorizontal = "${mod}+s"; # split below (like :sp in vim)
    splitVertical = "${mod}+v"; # split right (like :vsp in vim)

    # Window actions
    closeWindow = "${mod}+q";
    toggleFullscreen = "${mod}+f";

    # Workspace navigation
    workspace1 = "${mod}+1";
    workspace2 = "${mod}+2";
    workspace3 = "${mod}+3";
    workspace4 = "${mod}+4";
    workspace5 = "${mod}+5";
    workspace6 = "${mod}+6";
    workspace7 = "${mod}+7";
    workspace8 = "${mod}+8";
    workspace9 = "${mod}+9";
    workspace10 = "${mod}+0";

    # Move to workspace
    moveToWorkspace1 = "${mod}+Shift+1";
    moveToWorkspace2 = "${mod}+Shift+2";
    moveToWorkspace3 = "${mod}+Shift+3";
    moveToWorkspace4 = "${mod}+Shift+4";
    moveToWorkspace5 = "${mod}+Shift+5";
    moveToWorkspace6 = "${mod}+Shift+6";
    moveToWorkspace7 = "${mod}+Shift+7";
    moveToWorkspace8 = "${mod}+Shift+8";
    moveToWorkspace9 = "${mod}+Shift+9";
    moveToWorkspace10 = "${mod}+Shift+0";
  };
}
