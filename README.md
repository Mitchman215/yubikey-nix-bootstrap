# yubikey-bootstrap

Bootstrap GPG + SSH with a YubiKey on a new machine. One command to go from a fresh install to `git clone` over SSH.

## Usage

```bash
nix run --extra-experimental-features "nix-command flakes" github:Mitchman215/yubikey-nix-bootstrap
```

This will:
1. Configure the GPG agent with pinentry and SSH support
2. Import and trust your public key from GitHub
3. Tether your YubiKey and register its auth key for SSH
4. Verify GPG signing and SSH access to GitHub

After the script completes, you can clone private repos and set up home-manager, which takes over GPG/SSH configuration going forward.

## Requirements

- [Nix](https://nixos.org/download)
- A provisioned YubiKey (see the main dotfiles repo for provisioning docs)
