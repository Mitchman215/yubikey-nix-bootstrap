GITHUB_USERNAME="Mitchman215"
GNUPG_DIR="$HOME/.gnupg"

echo "=== YubiKey GPG + SSH Bootstrap ==="
echo "This will configure GPG and SSH to work with your YubiKey."
echo ""

# --- Phase 1: Configure GPG Agent ---
echo "--- Phase 1: Configuring GPG agent ---"

mkdir -p "$GNUPG_DIR"
chmod 700 "$GNUPG_DIR"

append_if_missing() {
  local file="$1"
  local line="$2"
  if ! grep -qxF "$line" "$file" 2>/dev/null; then
    echo "$line" >> "$file"
    echo "  Added '$line' to $file"
  else
    echo "  Already set: '$line' in $file"
  fi
}

PINENTRY_PATH=$(which pinentry-curses 2>/dev/null || which pinentry 2>/dev/null || true)
if [ -z "$PINENTRY_PATH" ]; then
  echo "Error: No pinentry program found. Install gnupg first."
  return 1
fi

append_if_missing "$GNUPG_DIR/gpg-agent.conf" "pinentry-program $PINENTRY_PATH"
append_if_missing "$GNUPG_DIR/gpg-agent.conf" "enable-ssh-support"
append_if_missing "$GNUPG_DIR/scdaemon.conf" "disable-ccid"

echo ""

# --- Phase 2: Restart agent and configure environment ---
echo "--- Phase 2: Restarting GPG agent ---"

GPG_TTY=$(tty)
export GPG_TTY
gpgconf --kill gpg-agent
gpg-connect-agent /bye > /dev/null 2>&1
gpg-connect-agent updatestartuptty /bye > /dev/null 2>&1
SSH_AUTH_SOCK=$(gpgconf --list-dirs agent-ssh-socket)
export SSH_AUTH_SOCK

echo "  GPG agent restarted"
echo "  SSH_AUTH_SOCK=$SSH_AUTH_SOCK"
echo ""

# --- Phase 3: Import and trust public key ---
echo "--- Phase 3: Importing public key from GitHub ---"

curl -sf "https://github.com/$GITHUB_USERNAME.gpg" | gpg --import 2>&1
echo ""

KEYID=$(gpg -k --with-colons | awk -F: '/^pub:/ { print $5; exit }')
if [ -z "$KEYID" ]; then
  echo "Error: Could not detect key ID after import."
  return 1
fi
echo "  Key ID: $KEYID"

# Check if already trusted at ultimate level
TRUST_LEVEL=$(gpg -k --with-colons "$KEYID" | awk -F: '/^pub:/ { print $2; exit }')
if [ "$TRUST_LEVEL" = "u" ]; then
  echo "  Key already trusted at ultimate level"
else
  echo "  Setting ultimate trust on key..."
  echo -e "5\ny\n" | gpg --command-fd 0 --edit-key "$KEYID" trust 2>&1
fi
echo ""

# --- Phase 4: Tether YubiKey ---
echo "--- Phase 4: Tethering YubiKey ---"
read -rp "Plug in your YubiKey and press Enter..."

# Ensure pcscd is running (required for scdaemon with disable-ccid)
if ! systemctl is-active --quiet pcscd 2>/dev/null; then
  echo "  pcscd is not running. Attempting to start it..."
  if ! sudo systemctl start pcscd 2>/dev/null; then
    echo "Error: pcscd service is not available."
    echo "On NixOS, add 'services.pcscd.enable = true;' to your configuration and run 'sudo nixos-rebuild switch'."
    return 1
  fi
fi
gpgconf --kill scdaemon
if ! gpg --card-status; then
  echo "Error: Could not detect YubiKey. Make sure it's plugged in."
  return 1
fi
echo "  YubiKey detected"

AUTH_KEYGRIP=$(gpg -K --with-keygrip --with-colons | awk -F: '/^ssb.*:a:/{getline; getline; print $10}')
if [ -z "$AUTH_KEYGRIP" ]; then
  echo "Error: Could not find authentication subkey keygrip."
  return 1
fi

if grep -qxF "$AUTH_KEYGRIP" "$GNUPG_DIR/sshcontrol" 2>/dev/null; then
  echo "  Auth keygrip already in sshcontrol"
else
  echo "$AUTH_KEYGRIP" >> "$GNUPG_DIR/sshcontrol"
  echo "  Added auth keygrip to sshcontrol: $AUTH_KEYGRIP"
fi
echo ""

# --- Phase 5: Verification ---
echo "--- Phase 5: Verification ---"

echo "  Checking ssh-add -l..."
ssh-add -l 2>&1 | head -3
echo ""

echo "  Testing SSH to GitHub (touch YubiKey when it blinks)..."
ssh -T git@github.com 2>&1 || true
echo ""

echo "=== Bootstrap complete. You can now clone repos in this shell. ==="
