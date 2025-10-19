{
  lib,
  pkgs,
  config,
  ...
}:
let
  cfg = config.axiom.docs;

  # Documentation files from the ansible templates
  docTemplates = {
    "WELCOME.md" = ''
      # Quick Reference Guide

      Welcome to Axiom 1! Here are some helpful commands and shortcuts:

      ## Command Help
      - To run a command, type it and then press Enter
      - `tldr <command>` - Get practical examples and help for any command
      - `? <question>` - Ask a question and get an AI-powered answer

      ## System Navigation
      - `Super + Space` - Open application launcher
      - `eza` - List the files and directories in the current directory
      - `bat <filename>` - Read a text file. To exit bat, press `q`.
      - `ranger` - Enter file manager

      ---
      *This file is located at `~/WELCOME.md`. You can open it directly with `bat WELCOME.md`*

      More pointers can be found in ~/docs/. You can list the help files with `eza docs`.

      To read one of those files, use their location + filename. For example: `bat docs/TERMINAL.md`.
    '';

    "docs/TERMINAL.md" = ''
      # Terminal Guide for Beginners 🚀

      ## Getting Around

      ### Where Am I?
      ```bash
      pwd    # Shows your current location
      ```

      ### Looking Around
      ```bash
      ls     # Shows files and folders here
      ls -l  # Shows more details about files
      ```

      ### Moving Around
      ```bash
      cd Documents    # Go into the Documents folder
      cd ..           # Go back up one folder
      cd ~            # Go to your home folder
      ```

      ## Working with Files

      ### Making Things
      ```bash
      touch my-file.txt     # Create a new empty file
      mkdir my-folder       # Create a new folder
      ```

      ### Copying and Moving
      ```bash
      cp file.txt copy.txt        # Make a copy of a file
      mv old-name.txt new-name.txt # Rename a file
      ```

      ### Safe File Deletion 🗑️
      **Important**: Never use `rm` - it deletes files forever!
      ```bash
      # Use trash instead - it's much safer!
      trash file.txt         # Moves file to trash (can get it back!)
      trash restore          # Get files back from trash
      trash list             # See what's in the trash
      trash empty file.txt   # Empty file.txt from the trash, deleting it forever
      ```

      ## Reading Files
      ```bash
      bat story.txt    # Show what's inside a file
      ```

      ## Important Key Shortcuts

      ### If Something Goes Wrong
      - **Ctrl+C**: Stop whatever is happening (emergency brake!)
      - **Ctrl+L**: Clear the screen and start fresh

      ### Making Typing Easier
      - **Tab**: Let the computer finish typing for you
      - **Up Arrow**: Bring back the last command you typed
      - **Ctrl+A**: Jump to the beginning of what you're typing
      - **Ctrl+E**: Jump to the end of what you're typing

      ## Finding Things
      ```bash
      find . -name "*.txt"     # Find all text files here
      grep "hello" file.txt    # Look for the word "hello" in a file
      ```

      ## Getting Help
      ```bash
      tldr ls           # Read the manual for any command
      command --help   # Quick help for most commands
      ```

      ## Fun Tips! 🎉

      - **Tab twice**: See all the options available
      - **Type the first few letters** of a file name, then press Tab - the computer will finish it!
      - **Up arrow key**: Brings back commands you used before
      - **Use spaces in folder names?** Put quotes around them: `cd "My Cool Folder"`

      ## Safety First! ⚠️

      1. **Always use `trashy` instead of `rm`** - you can get your files back!
      2. **Ctrl+C is your friend** - use it if something seems stuck
      3. **Ask for help** if you're not sure about a command:
      ```bash
      ? <type your question after the question mark>
      ```
      4. **Start in your home folder** (`cd ~`) when practicing

      ---

      🌟 **Remember**: The terminal is very powerful, so take your time and don't be afraid to ask questions!
    '';

    "docs/TEXT_EDITOR.md" = ''
      # Text Editor Guide (Neovim) ✏️

      ## Getting Started

      ### Opening the Editor
      ```bash
      nvim filename.txt    # Open a specific file
      nvim                 # Open without a file
      ```

      ### Learning the Basics - IMPORTANT! 🎓
      **Before doing anything else, learn with the built-in tutorial:**
      ```
      :Tutor
      ```
      This opens an interactive lesson that teaches you step by step!

      ## Two Important Modes

      Neovim works differently than other editors - it has **modes**:

      ### Normal Mode (for moving around)
      - This is where you start
      - You can't type text, but you can move around and give commands
      - Press **Esc** to get back here from anywhere

      ### Insert Mode (for typing)
      - This is where you actually type text
      - Press **i** to enter Insert mode
      - You'll see `-- INSERT --` at the bottom

      ## Essential Commands

      ### Getting Into Insert Mode
      ```
      i    # Start typing where the cursor is
      a    # Start typing after the cursor
      o    # Create a new line and start typing
      ```

      ### Moving Around (Normal Mode)
      ```
      h    # Move left
      j    # Move down  
      k    # Move up
      l    # Move right

      # Or just use the arrow keys!
      ```

      ### Saving and Quitting
      ```
      :w         # Save the file
      :q         # Quit (if no changes)
      :wq        # Save and quit
      :q!        # Quit without saving (emergency exit!)
      ```

      ## Basic Editing

      ### Deleting Things (Normal Mode)
      ```
      x      # Delete the character under cursor
      dd     # Delete the whole line
      ```

      ### Copying and Pasting
      ```
      yy     # Copy the whole line
      p      # Paste after cursor
      ```

      ### Undo and Redo
      ```
      u          # Undo last change
      Ctrl + r   # Redo (undo the undo)
      ```

      ## Finding Text
      ```
      /hello     # Search for "hello" (press Enter)
      n          # Go to next match
      N          # Go to previous match
      ```

      ## Tips for Beginners 🌟

      1. **Start with :Tutor** - It's the best way to learn!
      2. **Remember the modes** - Normal for moving, Insert for typing
      3. **Esc is your friend** - When confused, press Esc to get back to Normal mode
      4. **Practice small steps** - Don't try to learn everything at once
      5. **Use arrow keys** - You don't have to use hjkl if you're just starting

      ## Common Beginner Mistakes

      ### "I can't type anything!"
      - You're probably in Normal mode
      - Press **i** to start typing

      ### "I typed weird characters instead!"
      - You pressed keys in Normal mode
      - Press **u** to undo, then **i** to enter Insert mode

      ### "I can't save!"
      - Make sure you're in Normal mode (press Esc)
      - Type **:w** and press Enter

      ### "I'm stuck!"
      - Press **Esc** a few times
      - Type **:q!** and press Enter to quit without saving
      - Don't worry, you can try again!

      ## Getting Help
      ```
      :help        # Open the help system
      :help :w     # Get help about a specific command
      ```

      ## Fun Features to Try Later 🎉

      Once you're comfortable with the basics:
      - **Ctrl + o** and **Ctrl + i**: Jump back and forth between locations
      - **gg**: Go to top of file
      - **G**: Go to bottom of file
      - **:set number**: Show line numbers

      ---

      🎯 **Remember**: Neovim is very powerful, but start with **:Tutor** and practice the basics. Don't rush - even experienced programmers had to learn these steps!
    '';

    "docs/WINDOWS.md" = ''
      # Window Management with i3 🪟

      ## The Super Key
      The **Super key** (Windows key) is your main tool for controlling windows!

      ## Opening Programs
      ```
      Super + Enter    # Open a terminal
      Super + Space    # Open program launcher (type to search)
      ```

      ## Moving Around Windows
      ```
      Super + Arrow Keys    # Move between windows
      Super + h/j/k/l      # Move between windows (vim style)
      ```

      ## Managing Windows

      ### Splitting Windows
      ```
      Super + v        # Split vertically (side by side)
      Super + s        # Split horizontally (top and bottom)
      ```

      ### Changing Window Size
      ```
      Super + r        # Enter resize mode, then use arrow keys
                       # Press Enter or Escape when done
      ```

      ### Window Layouts
      ```
      Super + e        # Default layout (side by side)
      Super + w        # Tabbed layout (like browser tabs)
      ```

      ## Workspaces (Like Having Multiple Desks!)

      ### Switching Workspaces
      ```
      Super + 1        # Go to workspace 1
      Super + 2        # Go to workspace 2
      ...and so on up to Super + 0 for workspace 10
      ```

      ### Moving Windows to Different Workspaces
      ```
      Super + Shift + 1    # Move window to workspace 1
      Super + Shift + 2    # Move window to workspace 2
      ...and so on
      ```

      ## Closing Things
      ```
      Super + Shift + q    # Close the current window
      ```

      ## Fullscreen
      ```
      Super + f        # Make window take up whole screen
                       # Press again to make it normal size
      ```

      ## Tips for Beginners 🌟

      1. **Start simple**: Just use Super + Enter to open terminals and practice moving between them
      2. **Use workspaces**: Keep different activities on different workspaces (games on 2, homework on 3)
      3. **Don't panic**: If windows look weird, try Super + e to reset the layout
      4. **Practice the basics**: Opening, closing, and moving between windows

      ## Emergency Help! 🚨
      - **Super + Shift + c**: Reload i3 config (if something breaks)
      - **Super + Shift + r**: Restart i3 (bigger reset)
      - **Ctrl + Alt + T**: Often opens a terminal (backup if Super + Enter doesn't work)

      ---

      🎯 **Pro Tip**: Think of workspaces like having multiple desks - you can organize your work and switch between them instantly!
    '';
  };
in
{
  options.axiom.docs = {
    # Enable documentation deployment
    enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable deployment of documentation files.";
    };

    # Whether to overwrite existing docs
    overwrite = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Whether to overwrite existing documentation files.";
    };

    # Custom documentation files (can override defaults)
    customDocs = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
      default = { };
      description = "Map of relative path -> file content for custom documentation files.";
    };
  };

  config = lib.mkIf cfg.enable {
    # Deploy documentation files using home.file for direct file management
    home.file =
      let
        # Merge default templates with custom docs
        allDocs = docTemplates // cfg.customDocs;

        # Create file entries with force option based on overwrite setting
        createFileEntry =
          name: content:
          lib.nameValuePair name {
            text = content;
            force = cfg.overwrite;
          };
      in
      lib.mapAttrs' createFileEntry allDocs;

    # Ensure the docs directory exists by creating a placeholder file that gets removed
    home.activation.docsDirectory = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      set -eu
      mkdir -p "$HOME/docs"
    '';
  };
}
