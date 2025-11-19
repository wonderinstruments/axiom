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
