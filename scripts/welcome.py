#!/usr/bin/env python3

import pyfiglet
from colorama import Fore, Style

START_ITALICS = "\x1B[3m"

# Print AXIOM in figlet with color
axiom_text = pyfiglet.figlet_format("AXIOM", font="roman")
print(Fore.CYAN + axiom_text + Style.RESET_ALL)

# Print helpful message
print(Fore.GREEN + "For a quick reference guide, read the welcome markdown file by typing: " +
      Style.RESET_ALL + Fore.MAGENTA + "bat ~/docs/WELCOME.md" +
      Style.RESET_ALL + Fore.GREEN + ", then press enter." +
      Style.RESET_ALL + "\n")

print(START_ITALICS + "This banner was created by the ~/scripts/welcome.py program. You can run it by typing " + Style.RESET_ALL + Fore.CYAN + "python ~/scripts/welcome.py" + Style.RESET_ALL + ".")
