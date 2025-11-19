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
