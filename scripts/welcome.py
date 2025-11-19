#!/usr/bin/env python3

import pyfiglet
from colorama import Fore, Style

# Print AXIOM in figlet with color
axiom_text = pyfiglet.figlet_format("AXIOM", font="roman")
print(Fore.CYAN + axiom_text + Style.RESET_ALL)

# Print helpful message
print(Fore.GREEN + "For a quick reference guide, read the welcome file by typing: " +
      Style.RESET_ALL + Fore.MAGENTA + "bat ~/docs/WELCOME.md" +
      Style.RESET_ALL + Fore.GREEN + ", then press enter." +
      Style.RESET_ALL + "\n")
