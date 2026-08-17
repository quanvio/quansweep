<p align="center">
  <img src="logo/quansweep.png" width="128" height="128" alt="QuanSweep icon">
</p>

<h1 align="center">QuanSweep</h1>

<p align="center">
  A lightweight, open-source Mac cleaner that never deletes anything permanently.
</p>

<p align="center">
  <a href="https://github.com/quanvio/quansweep/releases/latest">
    <img src="https://img.shields.io/github/v/release/quanvio/quansweep?label=Download%20for%20macOS&logo=apple&color=2ea043" alt="Download latest release">
  </a>
  <img src="https://img.shields.io/badge/macOS-14%2B-000000?logo=apple" alt="macOS 14+">
  <img src="https://img.shields.io/badge/Swift-5.9-F05138?logo=swift&logoColor=white" alt="Swift 5.9+">
  <img src="https://img.shields.io/github/license/quanvio/quansweep" alt="License">
</p>

---

**QuanSweep** scans your Mac for leftover files, caches, logs, and temporary data. Everything it removes is moved to a **quarantine folder** first, so you can restore it later. Nothing is deleted permanently unless you empty the quarantine yourself.

Built with native Swift + SwiftUI. No Electron, no background daemon, no network calls.

## Highlights

- **Glassmorphism Dashboard** — live system overview with animated gauges, real-time rings for CPU, memory, storage, temperature, fan, and network.
- **Live System Monitor** — native Mach-based CPU and memory readings, plus real CPU temperature via SMC/HID thermal sensors.
- **Orbital Scan Animation** — visual feedback while scanning with category progress arcs.
- **App Residue Scanner** — find leftover files from apps you already uninstalled.
- **Cache Analyzer** — classify caches by owner and skip running apps.
- **Temporary Files** — clean abandoned files in `/tmp` and your user temp folder.
- **User Logs, Trash, Xcode Build Data** — safe, regeneratable cleanup.
- **App Uninstaller** — remove an app from `/Applications` and its related `~/Library` files in one reversible action.
- **Developer Caches** — clean regeneratable Go, Node, Python, Rust, Swift, Homebrew, and Playwright caches.
- **Downloads & Installers** — find old DMGs, PKGs, ZIPs, and archives in `~/Downloads`, and flag installers whose app is already installed.
- **Large Files** — find the biggest files in Downloads, Documents, Desktop, and media folders.
- **AI Models** — detect Hugging Face, Ollama, LM Studio, llama.cpp, and local GGUF/Safetensors/MLX model files.
- **Confidence Engine** — every item gets a 0–100% safety score. Only high-confidence items are selected by default.
- **Quarantine + Undo** — cleaned items are moved, not deleted. Restore them anytime within 30 days.
- **Search & Sort** — filter by name or path and sort scan/quarantine results by size, name, date, or confidence.
- **Protection List** — system folders, documents, photos, mail, keychains, and browser profiles are never touched.
- **Audit Log** — every action is recorded.

## Requirements

- macOS 14.0 (Sonoma) or later
- Apple Silicon or Intel Mac
- **Full Disk Access** is needed for QuanSweep to scan caches and residues.

## Install

### Direct download

[![Download latest release](https://img.shields.io/github/v/release/quanvio/quansweep?label=Download%20QuanSweep.zip&logo=apple&color=2ea043)](https://github.com/quanvio/quansweep/releases/latest)

1. Download `QuanSweep-x.x.x.zip` from the latest release.
2. Double-click to unzip, then drag `QuanSweep.app` to `/Applications`.
3. Launch it and grant **Full Disk Access** when prompted.

### One-line installer

```bash
curl -fsSL https://raw.githubusercontent.com/quanvio/quansweep/main/scripts/install.sh | bash
```

### First launch

QuanSweep is distributed directly so you get the latest version immediately. On the first launch, macOS may show a security gate because the app is not yet codesigned with an Apple Developer ID.

**First launch:** right-click `QuanSweep.app` → **Open**, or approve it in **System Settings → Privacy & Security → Open Anyway**.

**Recommended:** install with the one-line installer above. It removes the quarantine flag automatically so the first launch is seamless.

**If you downloaded the zip manually and see “QuanSweep is damaged and can’t be opened”:**

1. Move `QuanSweep.app` into `/Applications`.
2. Open Terminal and run:

```bash
xattr -cr /Applications/QuanSweep.app
```

3. Right-click `QuanSweep.app` → **Open**, or go to **System Settings → Privacy & Security → Open Anyway**.

> For a fully seamless install, you can later codesign and notarize QuanSweep with an Apple Developer ID.

**Grant Full Disk Access:**

QuanSweep needs permission to read system and user cache folders:

```bash
open "x-apple.systempreferences:com.apple.preference.security?Privacy_AllFiles"
```

Then add **QuanSweep** to the list.

## How to use

1. Open QuanSweep.
2. Click **Start Scan**.
3. Review the results. Safe items are already selected.
4. Click **Move to Quarantine**.
5. If something breaks, go to the **Quarantine** tab and click **Restore**.

## Safety model

| Score | Meaning |
|---|---|
| 99% | Already in Trash or clearly abandoned |
| 90–95% | Regeneratable cache or build data |
| 70–89% | Likely safe, but review first |
| 40–69% | Possible user data or app still installed |
| 0% | Protected by QuanSweep |

Only items with 90%+ confidence are selected automatically.

## Build from source

```bash
git clone https://github.com/quanvio/quansweep.git
cd quansweep
make run            # run directly
make app            # build QuanSweep.app
make zip            # build QuanSweep-x.x.x.zip
```

You need Swift 5.9+ (included with Xcode 15+).

## Project layout

```
QuanSweep/
├── Package.swift
├── Makefile
├── LICENSE
├── README.md
├── CONTRIBUTING.md
├── scripts/
│   ├── build-app.sh
│   ├── package-zip.sh
│   ├── install.sh
│   └── Info.plist
├── Sources/QuanSweep/
│   ├── Core/            # ConfidenceEngine, QuarantineManager, AuditLogger, ProtectionList
│   ├── Scanners/        # AppResidueScanner, CacheScanner, TempScanner, etc.
│   ├── Views/           # SwiftUI interface
│   └── ViewModels/
└── logo/
    └── quansweep.png
```

## Roadmap

- [x] V0.1 — App residues, caches, temp files, logs, trash, Xcode data
- [x] V0.2 — Confidence scoring, orphan detection, search/sort, category drill-down
- [x] V0.3 — App Uninstaller
- [x] V0.4 — Developer cleanup (Go, Node, Python, Rust, Xcode, Homebrew)
- [x] V0.5 — Downloads + installer analyzer
- [x] V0.6 — Large files + duplicate finder
- [x] V0.7 — AI model analyzer (GGUF, MLX, HuggingFace, Ollama)
- [x] V1.2.0 — Dark neon dashboard redesign, live system monitoring, real thermal readings, animated scanning overlay
- [x] V1.2.1 — Glassmorphism UI overhaul, responsive layout fixes, aligned tables and action buttons
- [x] V1.2.2 — Uninstaller responsive redesign, no-wrap action buttons, proportional table columns
- [x] V1.2.3 — Uninstaller sorting, permanent-delete option in app details
- [ ] V1.3.0 — Signed and notarized release builds

## Contributing

Feedback, bug reports, and pull requests are welcome. See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

## License

MIT — see [LICENSE](LICENSE).

---

<p align="center">
  Developed by <a href="https://github.com/quanvio">Quanvio Lab</a>
</p>
