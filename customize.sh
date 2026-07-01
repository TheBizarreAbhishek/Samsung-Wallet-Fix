#!/system/bin/sh

MODID=samsungspay
LIVE_PATH="/data/adb/modules/$MODID"

# 1. Config Preservation
if [ -d "$LIVE_PATH/config" ] && [ "$(ls -A "$LIVE_PATH/config")" ]; then
    ui_print "- Preserving existing configuration..."
    rm -rf "$MODPATH/config"
    cp -af "$LIVE_PATH/config" "$MODPATH/"
fi

# Print beautiful header
ui_print "*****************************************"
ui_print "          Samsung Wallet Fix             "
ui_print "*****************************************"
ui_print "- Target: Samsung Pay Mini (com.samsung.android.spaymini)"
ui_print "- Spoofing Profile: Galaxy M32 (SM-M325F)"
ui_print "- Status: Configuring Zygisk targeted spoof..."

# Function to detect volume key press using getevent
choose_option() {
  local events_file="$TMPDIR/events"
  rm -f "$events_file"
  
  # Start getevent in background
  getevent -lq > "$events_file" &
  local pid=$!
  
  local result=1 # Default: Vol Down / Skip
  local count=0
  
  # 30 seconds timeout
  while [ $count -lt 300 ]; do
    if [ -f "$events_file" ]; then
      if grep -q -E "KEY_VOLUMEUP.*DOWN|0073.*DOWN" "$events_file"; then
        result=0 # Vol Up (Install/Update)
        break
      elif grep -q -E "KEY_VOLUMEDOWN.*DOWN|0072.*DOWN" "$events_file"; then
        result=1 # Vol Down (Skip)
        break
      fi
    fi
    count=$((count + 1))
    sleep 0.1
  done
  
  kill -9 $pid 2>/dev/null
  wait $pid 2>/dev/null
  rm -f "$events_file"
  
  return $result
}

# Function to grant all permissions to Samsung Pay Mini
grant_permissions() {
  ui_print "- Granting all permissions for Samsung Pay Mini..."
  
  # Common permissions list
  local permissions="
    android.permission.READ_PHONE_STATE
    android.permission.ACCESS_FINE_LOCATION
    android.permission.ACCESS_COARSE_LOCATION
    android.permission.CAMERA
    android.permission.READ_CONTACTS
    android.permission.SEND_SMS
    android.permission.RECEIVE_SMS
    android.permission.READ_SMS
    android.permission.POST_NOTIFICATIONS
  "
  for perm in $permissions; do
    pm grant com.samsung.android.spaymini "$perm" >/dev/null 2>&1
  done
  
  # Dynamic query of requested permissions
  local all_perms=$(dumpsys package com.samsung.android.spaymini 2>/dev/null | grep "android.permission." | sed -E 's/^[[:space:]]+//;s/:[[:space:]]*$//' | sort -u)
  for perm in $all_perms; do
    pm grant com.samsung.android.spaymini "$perm" >/dev/null 2>&1
  done
  ui_print " - Permissions granted successfully."
}

# Function to download, install, and configure the APK
download_and_install() {
  local github_api="https://api.github.com/repos/TheBizarreAbhishek/Samsung-Wallet-Fix/releases/latest"
  local dest="$TMPDIR/spaymini.apk"

  ui_print "- Fetching latest Samsung Pay Mini from GitHub..."

  # Get the APK download URL from the latest GitHub release
  local apk_url
  if command -v curl >/dev/null 2>&1; then
    apk_url=$(curl -s "$github_api" | grep "browser_download_url" | grep "spaymini" | head -1 | sed 's/.*"browser_download_url": "\([^"]*\)".*/\1/')
  elif command -v wget >/dev/null 2>&1; then
    apk_url=$(wget -qO- "$github_api" | grep "browser_download_url" | grep "spaymini" | head -1 | sed 's/.*"browser_download_url": "\([^"]*\)".*/\1/')
  else
    ui_print " ! Error: Neither curl nor wget is available."
    return 1
  fi

  if [ -z "$apk_url" ]; then
    ui_print " ! Could not find APK in latest GitHub release."
    ui_print " ! Check: https://github.com/TheBizarreAbhishek/Samsung-Wallet-Fix/releases"
    return 1
  fi

  ui_print "- Downloading Samsung Pay Mini APK..."
  if command -v curl >/dev/null 2>&1; then
    curl -L -s -o "$dest" "$apk_url"
  else
    wget -q -O "$dest" "$apk_url"
  fi
  
  if [ ! -f "$dest" ] || [ ! -s "$dest" ]; then
    ui_print " ! Error: Failed to download Samsung Pay Mini APK."
    return 1
  fi
  
  ui_print "- Installing Samsung Pay Mini..."
  # -r: replace, -d: allow downgrade, -g: grant all runtime permissions
  local install_output=$(pm install -r -d -g "$dest" 2>&1)
  if echo "$install_output" | grep -q "Success"; then
    ui_print " - App installed successfully!"
    grant_permissions
  else
    # Fallback to standard pm install if -g fails
    local install_output2=$(pm install -r -d "$dest" 2>&1)
    if echo "$install_output2" | grep -q "Success"; then
      ui_print " - App installed successfully!"
      grant_permissions
    else
      ui_print " ! Installation failed: $install_output2"
      return 1
    fi
  fi
  return 0
}

# App presence and version check
if command -v pm >/dev/null 2>&1; then
  # Fetch currently installed package version code
  local installed_vc=$(dumpsys package com.samsung.android.spaymini 2>/dev/null | grep -m1 versionCode | sed -E 's/.*versionCode=([0-9]+).*/\1/')
  
  if [ -z "$installed_vc" ]; then
    ui_print "- Samsung Pay Mini is NOT installed on your device."
    ui_print " "
    ui_print "   [?] Do you want to download and install Samsung Pay Mini?"
    ui_print "       Press Volume Up (+) to INSTALL"
    ui_print "       Press Volume Down (-) to SKIP"
    ui_print " "
    if choose_option; then
      download_and_install
    else
      ui_print "- Skipping app installation."
    fi
  elif [ "$installed_vc" -lt 554300232 ]; then
    ui_print "- An update is available for Samsung Pay Mini!"
    ui_print "  Installed version: $installed_vc"
    ui_print "  Newest version: 554300232"
    ui_print " "
    ui_print "   [?] Do you want to update Samsung Pay Mini?"
    ui_print "       Press Volume Up (+) to UPDATE"
    ui_print "       Press Volume Down (-) to SKIP"
    ui_print " "
    if choose_option; then
      download_and_install
    else
      ui_print "- Skipping app update."
    fi
  else
    ui_print "- Samsung Pay Mini is already installed and up to date."
  fi
else
  ui_print "- Recovery environment detected: skipping interactive app check."
fi

ui_print "*****************************************"
ui_print "          Installation Complete!         "
ui_print "*****************************************"
ui_print "  Note: Make sure Zygisk is enabled in   "
ui_print "  your Root Manager settings and reboot. "
ui_print "*****************************************"