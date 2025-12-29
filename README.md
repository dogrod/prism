# Prism 📱

A receipt scanning iOS app built with **UIKit (Programmatic UI)** and **MVVM architecture**.

[![Swift](https://img.shields.io/badge/Swift-5.0-orange.svg)](https://swift.org)
[![Platform](https://img.shields.io/badge/Platform-iOS%2015.0+-blue.svg)](https://developer.apple.com/ios/)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

## Features

- 📷 Scan receipts using camera or photo library
- 🔍 OCR text recognition via Apple Vision Framework
- 🤖 AI-powered receipt parsing using OpenAI GPT
- 📊 Automatic classification of items as "Need" or "Want"

## Requirements

| Dependency | Version |
|------------|---------|
| iOS | 15.0+ |
| Xcode | 14.0+ |
| Swift | 5.0+ |

## Quick Start

### 1. Clone & Setup

```bash
git clone https://github.com/yourusername/Prism.git
cd Prism
cp Prism/Config.plist.example Prism/Config.plist
```

### 2. Configure API Key

Edit `Prism/Config.plist` with your OpenAI API key:

```xml
<key>OPENAI_API_KEY</key>
<string>sk-your-actual-api-key</string>
```

> ⚠️ **Security:** `Config.plist` is gitignored. Never commit API keys.

### 3. Build & Run

Open `Prism.xcodeproj` in Xcode, then ⌘R to run.

## Project Structure

```
Prism/
├── App/           # AppDelegate, SceneDelegate
├── Core/          # Constants, Extensions
├── Data/          # Core Data, Repositories
├── Features/      # ViewControllers, ViewModels
│   ├── Capture/   # Receipt scanning (POC)
│   └── Dashboard/ # Transaction overview
└── Services/      # OCR, LLM integrations
```

## Architecture

**MVVM** (Model-View-ViewModel) with dependency injection:

| Layer | Responsibility |
|-------|---------------|
| **View** | UIKit ViewControllers, programmatic Auto Layout |
| **ViewModel** | State management via Combine `@Published` |
| **Model** | Codable structs, Core Data entities |
| **Services** | OCR (Vision), LLM (OpenAI), Database |

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing`)
3. Commit changes (`git commit -m 'Add amazing feature'`)
4. Push to branch (`git push origin feature/amazing`)
5. Open a Pull Request

## License

MIT License – see [LICENSE](LICENSE) for details.
