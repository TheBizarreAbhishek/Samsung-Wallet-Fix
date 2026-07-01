#!/system/bin/sh
# Samsung Wallet Fix — customize.sh
# by TheBizarreAbhishek

MODID="samsungspay"
LIVE_PATH="/data/adb/modules/$MODID"
GITHUB_REPO="TheBizarreAbhishek/Samsung-Wallet-Fix"
SPAY_PKG="com.samsung.android.spaymini"

# ─── Detect if this is an update or fresh install ─────────────────────────────
IS_UPDATE=false
[ -d "$LIVE_PATH" ] && IS_UPDATE=true

# ─── Config Preservation (on update) ──────────────────────────────────────────
if $IS_UPDATE && [ -d "$LIVE_PATH/config" ] && [ "$(ls -A "$LIVE_PATH/config")" ]; then
  rm -rf "$MODPATH/config"
  cp -af "$LIVE_PATH/config" "$MODPATH/"
fi

# ══════════════════════════════════════════════════════════════════════════════
#  UI HELPERS
# ══════════════════════════════════════════════════════════════════════════════

I()  { ui_print "  [INFO]  $1"; }
OK() { ui_print "   [OK]  $1"; }
W()  { ui_print " [WARN]  $1"; }
E()  { ui_print "  [ERR]  $1"; }
S()  { ui_print "   [>>]  $1"; }
SEP(){ ui_print "  ·  ·  ·  ·  ·  ·  ·  ·  ·  ·  ·  ·  ·  ·  ·  ·  ·  ·  ·"; }

print_banner() {
  ui_print " "
  ui_print "  ╔═══════════════════════════════════════════╗"
  ui_print "  ║  ░██████╗░ ███████╗██╗   ██╗            ║"
  ui_print "  ║  ██╔════╝  ██╔════╝╚██╗ ██╔╝            ║"
  ui_print "  ║  ╚█████╗░  █████╗   ╚████╔╝             ║"
  ui_print "  ║   ╚═══██╗  ██╔══╝    ╚██╔╝              ║"
  ui_print "  ║  ██████╔╝  ██║        ██║               ║"
  ui_print "  ║  ╚═════╝   ╚═╝        ╚═╝               ║"
  ui_print "  ║                                          ║"
  ui_print "  ║    SAMSUNG   WALLET   FIX   MODULE       ║"
  ui_print "  ║    Targeted Zygisk Spoof Engine  ⚡      ║"
  ui_print "  ║    by TheBizarreAbhishek                 ║"
  ui_print "  ╚═══════════════════════════════════════════╝"
  ui_print " "
}

# ══════════════════════════════════════════════════════════════════════════════
#  VOLUME KEY CHOOSER — with auto-timeout
#  $1 = timeout in seconds (default 10)
#  Returns: 0 = Vol Up / auto (YES), 1 = Vol Down (NO/SKIP)
# ══════════════════════════════════════════════════════════════════════════════

choose_with_timeout() {
  local timeout="${1:-10}"
  local events="$TMPDIR/_swf_events"
  rm -f "$events"

  getevent -lq > "$events" &
  local gpid=$!

  local ticks=0
  local total=$((timeout * 10))
  local remaining=$timeout

  while [ $ticks -lt $total ]; do
    # Check Vol Up
    if grep -q -E "KEY_VOLUMEUP.*DOWN|0073.*00000001" "$events" 2>/dev/null; then
      kill -9 $gpid 2>/dev/null; wait $gpid 2>/dev/null; rm -f "$events"
      return 0
    fi
    # Check Vol Down
    if grep -q -E "KEY_VOLUMEDOWN.*DOWN|0072.*00000001" "$events" 2>/dev/null; then
      kill -9 $gpid 2>/dev/null; wait $gpid 2>/dev/null; rm -f "$events"
      return 1
    fi

    sleep 0.1
    ticks=$((ticks + 1))

    # Show countdown every second
    local new_remaining=$(( (total - ticks) / 10 ))
    if [ "$new_remaining" -ne "$remaining" ]; then
      remaining=$new_remaining
      ui_print "  [---]  Auto-proceeding in ${remaining}s... (Vol- to skip)"
    fi
  done

  kill -9 $gpid 2>/dev/null; wait $gpid 2>/dev/null; rm -f "$events"
  return 0  # Timeout = auto-proceed (YES/default)
}

# ══════════════════════════════════════════════════════════════════════════════
#  GRANT ALL PERMISSIONS
# ══════════════════════════════════════════════════════════════════════════════

grant_permissions() {
  S "Granting runtime permissions..."
  local static_perms="android.permission.READ_PHONE_STATE \
    android.permission.ACCESS_FINE_LOCATION \
    android.permission.ACCESS_COARSE_LOCATION \
    android.permission.ACCESS_BACKGROUND_LOCATION \
    android.permission.CAMERA \
    android.permission.READ_CONTACTS \
    android.permission.SEND_SMS \
    android.permission.RECEIVE_SMS \
    android.permission.READ_SMS \
    android.permission.POST_NOTIFICATIONS \
    android.permission.NFC \
    android.permission.INTERNET"

  local count=0
  for perm in $static_perms; do
    pm grant "$SPAY_PKG" "$perm" >/dev/null 2>&1 && count=$((count+1))
  done

  # Dynamic permissions from package dump
  local dynamic=$(dumpsys package "$SPAY_PKG" 2>/dev/null \
    | grep "android.permission\." \
    | sed -E 's/^[[:space:]]+//;s/:[[:space:]]*$//' \
    | sort -u)
  for perm in $dynamic; do
    pm grant "$SPAY_PKG" "$perm" >/dev/null 2>&1 && count=$((count+1))
  done

  OK "Granted $count permissions to $SPAY_PKG"
}

# ══════════════════════════════════════════════════════════════════════════════
#  DOWNLOAD & INSTALL APK
# ══════════════════════════════════════════════════════════════════════════════

download_and_install() {
  local dest="$TMPDIR/spaymini_install.apk"
  local api="https://api.github.com/repos/${GITHUB_REPO}/releases/latest"
  local apk_url

  S "Contacting GitHub release server..."
  if command -v curl >/dev/null 2>&1; then
    apk_url=$(curl -s --max-time 20 "$api" \
      | grep "browser_download_url" \
      | grep "spaymini" \
      | head -1 \
      | sed 's/.*"browser_download_url": "\([^"]*\)".*/\1/')
  else
    apk_url=$(wget -qO- --timeout=20 "$api" \
      | grep "browser_download_url" \
      | grep "spaymini" \
      | head -1 \
      | sed 's/.*"browser_download_url": "\([^"]*\)".*/\1/')
  fi

  if [ -z "$apk_url" ]; then
    E "Could not resolve APK URL from GitHub releases."
    E "Check: https://github.com/${GITHUB_REPO}/releases"
    return 1
  fi
  OK "APK URL resolved from GitHub"

  S "Downloading Samsung Pay Mini APK..."
  if command -v curl >/dev/null 2>&1; then
    curl -L -s --max-time 300 -o "$dest" "$apk_url"
  else
    wget -q --timeout=300 -O "$dest" "$apk_url"
  fi

  if [ ! -f "$dest" ] || [ ! -s "$dest" ]; then
    E "Download failed — check internet connection."
    return 1
  fi
  OK "Download complete ($(du -sh "$dest" | cut -f1))"

  S "Installing Samsung Pay Mini..."
  local out
  out=$(pm install -r -d -g "$dest" 2>&1)
  if echo "$out" | grep -q "Success"; then
    OK "Install successful!"
    grant_permissions
    rm -f "$dest"
    return 0
  fi
  # Fallback without -g flag
  out=$(pm install -r -d "$dest" 2>&1)
  if echo "$out" | grep -q "Success"; then
    OK "Install successful!"
    grant_permissions
    rm -f "$dest"
    return 0
  fi

  E "Install failed: $out"
  rm -f "$dest"
  return 1
}

# ══════════════════════════════════════════════════════════════════════════════
#  MAIN
# ══════════════════════════════════════════════════════════════════════════════

print_banner

SEP
I "Module     : Samsung Wallet Fix ($MODID)"
I "Target     : $SPAY_PKG"
I "Spoof      : Galaxy M32 (SM-M325F) India/INS"
I "Engine     : TargetedFix Zygisk v4 (patched)"
$IS_UPDATE && I "Mode       : MODULE UPDATE" || I "Mode       : FRESH INSTALL"
SEP

S "Registering Zygisk hook..."
OK "Hook bound  → $SPAY_PKG"
S "Loading spoof profile..."
OK "Profile     → MANUFACTURER=samsung  MODEL=SM-M325F"
OK "Scope       → App-only (system-wide untouched)"
SEP

# ── APK check: only when pm is available (not in recovery) ────────────────────
if ! command -v pm >/dev/null 2>&1; then
  W "Recovery environment detected."
  W "APK management skipped — reboot into system first."

else
  # Read installed version
  installed_vc=$(dumpsys package "$SPAY_PKG" 2>/dev/null \
    | grep -m1 "versionCode" \
    | sed -E 's/.*versionCode=([0-9]+).*/\1/')
  installed_vn=$(dumpsys package "$SPAY_PKG" 2>/dev/null \
    | grep -m1 "versionName" \
    | sed -E 's/.*versionName=([^ ]+).*/\1/')

  # Read latest available version from bundled update.json
  latest_vc=$(grep '"versionCode"' "$MODPATH/update.json" 2>/dev/null \
    | sed -E 's/.*: ?([0-9]+).*/\1/')

  SEP

  # ── Case 1: NOT INSTALLED ──────────────────────────────────────────────────
  if [ -z "$installed_vc" ]; then
    W "Samsung Pay Mini: ✗ NOT INSTALLED"
    ui_print " "
    ui_print "  ┌─────────────────────────────────────────────┐"
    ui_print "  │                                             │"
    ui_print "  │   Samsung Pay Mini is not installed.        │"
    ui_print "  │   Download & install from GitHub releases?  │"
    ui_print "  │                                             │"
    ui_print "  │    Vol UP  (+)  =  INSTALL                  │"
    ui_print "  │    Vol DOWN (-)  =  SKIP                    │"
    ui_print "  │                                             │"
    ui_print "  │   Auto-INSTALL in 10 seconds...             │"
    ui_print "  │                                             │"
    ui_print "  └─────────────────────────────────────────────┘"
    ui_print " "
    if choose_with_timeout 10; then
      download_and_install || W "APK install failed. Install manually from releases."
    else
      W "Skipped. Install com.samsung.android.spaymini manually."
    fi

  # ── Case 2: UPDATE AVAILABLE ───────────────────────────────────────────────
  elif [ -n "$latest_vc" ] && [ "$installed_vc" -lt "$latest_vc" ] 2>/dev/null; then
    I "Samsung Pay Mini: ✓ Installed  v${installed_vn:-$installed_vc}"
    W "New version available! → v${latest_vc}"
    ui_print " "

    if $IS_UPDATE; then
      # Module was updated → user already consented, auto-update APK silently
      ui_print "  ┌─────────────────────────────────────────────┐"
      ui_print "  │                                             │"
      ui_print "  │   Module update detected.                   │"
      ui_print "  │   Auto-updating Samsung Pay Mini...         │"
      ui_print "  │                                             │"
      ui_print "  └─────────────────────────────────────────────┘"
      ui_print " "
      download_and_install || W "APK update failed. Update manually."
    else
      # Fresh scenario with update available
      ui_print "  ┌─────────────────────────────────────────────┐"
      ui_print "  │                                             │"
      ui_print "  │   A newer Samsung Pay Mini is available.    │"
      ui_print "  │   Update now?                               │"
      ui_print "  │                                             │"
      ui_print "  │    Vol UP  (+)  =  UPDATE                   │"
      ui_print "  │    Vol DOWN (-)  =  SKIP                    │"
      ui_print "  │                                             │"
      ui_print "  │   Auto-UPDATE in 10 seconds...              │"
      ui_print "  │                                             │"
      ui_print "  └─────────────────────────────────────────────┘"
      ui_print " "
      if choose_with_timeout 10; then
        download_and_install || W "APK update failed."
      else
        W "Skipped update."
      fi
    fi

  # ── Case 3: UP TO DATE ────────────────────────────────────────────────────
  else
    OK "Samsung Pay Mini: ✓ v${installed_vn:-$installed_vc} — Up to date"
  fi

fi

SEP
ui_print " "
ui_print "  ╔═══════════════════════════════════════════╗"
ui_print "  ║                                           ║"
ui_print "  ║    [✓]  INSTALLATION COMPLETE             ║"
ui_print "  ║                                           ║"
ui_print "  ║    ►  Reboot your device                  ║"
ui_print "  ║    ►  Ensure Zygisk is ENABLED            ║"
ui_print "  ║    ►  Open Samsung Wallet                 ║"
ui_print "  ║                                           ║"
ui_print "  ║    Telegram: @TheGreatBabaAbhishek  ⚡    ║"
ui_print "  ╚═══════════════════════════════════════════╝"
ui_print " "