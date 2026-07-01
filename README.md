# Samsung Wallet Fix

> A Magisk / KernelSU / APatch module that enables **Samsung Pay Mini** on rooted Samsung devices using targeted Zygisk property spoofing — without affecting the rest of your system.

---

## How It Works

Standard system-wide prop spoofing (`system.prop`) changes device identity for **every** app on the phone, which can break things. This module takes a smarter approach:

- **Zygisk targeted hook** — spoofing is injected only into the `com.samsung.android.spaymini` process at launch time
- **No global side effects** — all other apps see your real device identity
- **Spoof profile**: Galaxy M32 (`SM-M325F`, India/INS) — a device that officially supports Samsung Pay Mini

---

## Requirements

| Requirement | Details |
|---|---|
| Root Manager | Magisk / KernelSU / APatch |
| Zygisk | Must be **enabled** in your root manager |
| Android | 11+ |
| Device | Any rooted Samsung device |

---

## Installation

1. Download `Samsung.Wallet.Fix.zip` from the [latest release](https://github.com/TheBizarreAbhishek/Samsung-Wallet-Fix/releases/latest)
2. Flash it via your root manager
3. During flashing:
   - If Samsung Pay Mini is **not installed** → press **Volume Up** to download & install, or **Volume Down** to skip *(auto-installs in 10 seconds)*
   - If an **update is available** → same prompt *(auto-updates in 10 seconds)*
   - If already **up to date** → no action needed
4. Reboot your device
5. Open Samsung Wallet

---

## Auto-Update System

This module includes a fully automated update pipeline:

```
Every day at 8:30 AM IST
        ↓
GitHub Actions queries official Samsung Galaxy Store API
        ↓
New version found?
        ↓ YES
Download APK → Delete old release → Create new GitHub release
(APK + flashable module zip bundled together)
        ↓
Root manager shows "Samsung Wallet Fix — Update available"
        ↓
User flashes module update
        ↓
customize.sh detects installed APK version
        ↓
Auto-updates Samsung Pay Mini silently (no prompt on module update)
```

When a new version of Samsung Pay Mini is detected, the **module version is also bumped** so your root manager notifies you directly — no manual checking needed.

---

## Transparency & Security

### Zygisk Binaries
All Zygisk `.so` libraries included in this module are **not compiled from scratch by hand**. They are taken from the open-source [TargetedFix v4](https://github.com/VisionR1/TargetedFix/releases/tag/v4) project and binary-patched to use this module's ID (`samsungspay`). You can verify the patch yourself:

```bash
strings zygisk/arm64-v8a.so | grep samsungspay
```

### Samsung Pay Mini APK
The `com.samsung.android.spaymini` APK bundled in every release is **downloaded directly and exclusively from Samsung's official Galaxy Store servers** using Samsung's own distribution API:

```
https://vas.samsungapps.com/stub/stubDownload.as
  ?appId=com.samsung.android.spaymini
  &deviceId=SM-M325F
  &csc=INS      ← India region
  &mcc=404&mnc=20
```

The APK is **unmodified** — no repackaging, no tampering, no added code. You can verify the APK signature matches an official Samsung build after installation.

The entire download and release pipeline runs inside GitHub Actions and the [workflow source](.github/workflows/check-spay-update.yml) is fully visible in this repository.

---

## Module Structure

```
Samsung-Wallet-Fix/
├── .github/workflows/
│   └── check-spay-update.yml   ← Daily auto-update GitHub Action
├── zygisk/
│   ├── arm64-v8a.so            ← Zygisk hook (TargetedFix v4, patched)
│   ├── armeabi-v7a.so
│   ├── x86.so
│   └── x86_64.so
├── config/
│   ├── target.txt              ← com.samsung.android.spaymini
│   └── fix.prop                ← Galaxy M32 spoof profile
├── scripts/
│   └── fetch_apk.py            ← Samsung API query script (used by CI)
├── classes.dex                 ← Zygisk Java hook (TargetedFix v4)
├── customize.sh                ← Installer with interactive APK management
├── module.prop                 ← Module metadata + update check URL
├── update.json                 ← Root manager update notification data
└── META-INF/                   ← Magisk install entry point
```

---

## FAQ

**Q: Will this break banking apps or other Samsung apps?**
No. The spoof is scoped exclusively to `com.samsung.android.spaymini`. Every other app on your device sees your real hardware identity.

**Q: Do I need to keep the module after setting up Samsung Pay?**
No — once Samsung Pay Mini is set up and working, you *can* disable the module. However, keeping it active ensures the spoof persists across app updates and reboots.

**Q: Where does the APK come from?**
Directly from Samsung's official distribution servers. The exact API call is visible in [`scripts/fetch_apk.py`](scripts/fetch_apk.py) and [`check-spay-update.yml`](.github/workflows/check-spay-update.yml).

**Q: How do I get app updates?**
Your root manager will show "Samsung Wallet Fix — Update available" when a new Samsung Pay Mini version is detected. Just flash the new module zip — it handles the APK update automatically.

---

## Credits

| Component | Source |
|---|---|
| Zygisk hook engine | [VisionR1/TargetedFix](https://github.com/VisionR1/TargetedFix) |
| Module design & automation | [TheBizarreAbhishek](https://github.com/TheBizarreAbhishek) |
| Samsung Pay Mini APK | Official Samsung Galaxy Store |

---

## Contact

Telegram: [@TheGreatBabaAbhishek](https://t.me/TheGreatBabaAbhishek)
