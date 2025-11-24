treefmt
sudo cp /etc/nixos/hardware-configuration.nix .
sudo cp -r . /etc/nixos
sudo nixos-rebuild switch --flake /etc/nixos#axiom
