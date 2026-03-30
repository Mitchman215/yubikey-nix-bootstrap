# yubikey-bootstrap

Bootstrap GPG + SSH with a YubiKey on a new machine. One command to go from a fresh install to `git clone` over SSH.

## Usage

```bash
nix develop --extra-experimental-features "nix-command flakes" github:Mitchman215/yubikey-bootstrap
```

This drops you into a shell with `gpg`, `git`, `ssh`, and `curl` available, then automatically:
1. Configures the GPG agent with pinentry and SSH support
2. Imports and trusts your public key from GitHub
3. Tethers your YubiKey and registers its auth key for SSH
4. Verifies SSH access to GitHub

After bootstrap completes, you're in an interactive shell with everything configured. Clone your private repos and set up home-manager, which takes over GPG/SSH configuration going forward.

## Requirements

- [Nix](https://nixos.org/download)
- A provisioned YubiKey (see the main dotfiles repo for provisioning docs)
- On NixOS, `services.pcscd.enable = true;` must be set in your configuration (run `sudo nixos-rebuild switch` after adding it)
