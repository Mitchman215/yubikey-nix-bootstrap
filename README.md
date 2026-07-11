# yubikey-nix-bootstrap

Bootstrap GPG + SSH with a YubiKey on a new machine. One command to go from a fresh install to `git clone` over SSH.

## Usage

```bash
nix develop --extra-experimental-features "nix-command flakes" github:Mitchman215/yubikey-nix-bootstrap
```

Use `nix develop`, not `nix run` — this flake only exposes a dev shell, and the bootstrap leaves you in an interactive shell to clone repos.

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

## Platform notes

### Linux

scdaemon uses nixpkgs' internal CCID driver by default, which conflicts with `pcscd`. The bootstrap writes `disable-ccid` to `scdaemon.conf` to force the PC/SC path, so `pcscd` must be running (hence the NixOS requirement above, and `pcsclite`/`ccid` in the dev shell).

On Debian/Ubuntu-based distros, install and enable `pcscd` before running the bootstrap:

```bash
sudo apt install scdaemon pcscd pcsc-tools
sudo systemctl enable --now pcscd
```

Verify the reader and card are visible:

```bash
systemctl status pcscd
pcsc_scan -n                       # list readers and exit
gpg-connect-agent "scd --version" /bye
gpg --card-status
```

### macOS

Works out of the box; no `pcscd` to manage. nixpkgs builds gnupg with `--disable-ccid-driver`, so scdaemon always uses PC/SC via the system framework (`/System/Library/Frameworks/PCSC.framework/PCSC`), backed by macOS SmartCardServices, which launchd starts on demand. This is the same PC/SC path Yubico recommends for [resolving GPG CCID conflicts](https://support.yubico.com/hc/en-us/articles/4819584884124) on macOS — nixpkgs just does it at build time. The `disable-ccid` line and the `pcsclite`/`ccid` dev-shell packages are inert on macOS but harmless.

If `gpg --card-status` reports "card not present" or "Operation not supported by device", macOS's CryptoTokenKit PIV token is likely holding the card. Disable it and replug:

```bash
sudo defaults write /Library/Preferences/com.apple.security.smartcard DisabledTokens -array com.apple.CryptoTokenKit.pivtoken
```
