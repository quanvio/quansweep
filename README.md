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

- **App Residue Scanner** — find leftover files from apps you already uninstalled.
- **Cache Analyzer** — classify caches by owner and skip running apps.
- **Temporary Files** — clean abandoned files in `/tmp` and your user temp folder.
- **User Logs, Trash, Xcode Build Data** — safe, regeneratable cleanup.
- **Confidence Engine** — every item gets a 0–100% safety score. Only high-confidence items are selected by default.
- **Quarantine + Undo** — cleaned items are moved, not deleted. Restore them anytime within 30 days.
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

Because QuanSweep is distributed directly rather than through the Mac App Store, macOS may ask you to approve the first launch. Right-click `QuanSweep.app` → **Open**, or approve it in **System Settings → Privacy & Security**.

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
- [ ] V0.2 — Confidence scoring improvements and orphan detection
- [ ] V0.3 — Developer cleanup (Go, Node, Python, Rust, Xcode)
- [ ] V0.4 — Downloads + installer analyzer
- [ ] V0.5 — Large files + duplicate finder
- [ ] V0.6 — AI model analyzer (GGUF, MLX, HuggingFace, Ollama)
- [ ] V1.0 — Polished native SwiftUI GUI and signed release builds

## Contributing

Feedback, bug reports, and pull requests are welcome. See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

## License

MIT — see [LICENSE](LICENSE).

---

<p align="center">
  Developed by <a href="https://github.com/quanvio">Quanvio Lab</a>
</p>
