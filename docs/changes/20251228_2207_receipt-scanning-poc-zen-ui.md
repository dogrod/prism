# Prism iOS POC: Receipt Scanning & Zen UI Foundation

**Date:** 2025-12-28
**Type:** Feature | POC | Infrastructure

---

## 1. Product & UX Context

### What Changed
- Implemented a complete **Receipt Scanning POC** that uses the device camera/photo library to capture receipts, extract text via OCR, and parse structured data using OpenAI's LLM.
- Built a **Scan History** feature allowing users to view their last 20 scans with thumbnail previews, merchant names, dates, and totals.
- Redesigned the UI from a raw prototype to a **"Digital Zen"** aesthetic—a Notion-inspired, Japanese minimalist design with:
  - Off-white paper-like backgrounds
  - Serif typography for titles (New York font)
  - Subtle shadows and crisp borders
  - Light mode enforced globally

### Why
- **POC Validation:** Prove that OCR + LLM can reliably extract merchant, items, totals, tax, tips, and payment info from real receipts.
- **Debugging Support:** Scan History lets developers inspect OCR/LLM results during testing.
- **Premium Feel:** The Zen aesthetic differentiates Prism from utilitarian finance apps.

### Visuals
- Portal-style image viewer with subtle border animations during scanning
- Capsule-shaped model selector in custom navigation bar
- Glassmorphic result cards with monospaced JSON display
- ZenToast notifications for successful transaction saves

---

## 2. Technical Implementation

### Key Changes
- **OCRService:** Vision framework integration (`VNRecognizeTextRequest`) for text recognition
- **LLMService:** OpenAI API integration with dynamic model selection and conditional temperature parameter (GPT-5 series doesn't support temperature)
- **ModelManager:** Singleton with `UserDefaults` persistence for switching between GPT-5 Nano, GPT-5 Mini, and GPT-4o Mini
- **CaptureViewController:** Complete rewrite with programmatic Auto Layout, custom nav bar, and Combine bindings
- **Theme System:** `PrismTheme` enum with centralized colors, fonts, spacing, and reusable components (`CardView`, `PrimaryButton`, `PortalView`)

### Tech Stack
- **UIKit** (Programmatic UI, no Storyboards)
- **Combine** for reactive state management
- **Vision Framework** for OCR
- **URLSession** for OpenAI API calls
- **Core Data** for transaction persistence (scaffolded)

### Refactoring
- Migrated from SwiftUI entry point to UIKit `AppDelegate`/`SceneDelegate`
- Fixed Info.plist "multiple commands produce" build error via `PBXFileSystemSynchronizedBuildFileExceptionSet`
- Forced Light Mode globally via `UIUserInterfaceStyle` in Info.plist and `window.overrideUserInterfaceStyle`

---

## 3. Architecture & Data Models

### Schema Changes
- **ScanHistoryRecord** (in-memory): `id`, `timestamp`, `originalImage`, `receiptData`, `rawJSONString`
- **ReceiptJSON** (Codable): Added `tip` field, `PaymentInfo` nested struct with `type` and `last4`
- **Transaction** (Core Data entity, scaffolded): Referenced in `CaptureViewModel` for persistence

### New Services/Modules
| Module | Purpose |
|--------|---------|
| `VisionOCRService` | Wraps Vision framework for text recognition |
| `OpenAILLMService` | Calls OpenAI chat completions API |
| `ModelManager` | Manages selected AI model with persistence |
| `ScanHistoryManager` | In-memory storage for recent scans |
| `ScanProcessor` | Pipeline for processing receipts and saving transactions |

### App Structure
```
Prism/
├── App/           # AppDelegate, SceneDelegate
├── Core/          # Constants, Theme, ModelManager, Extensions
├── Data/          # Persistence, ScanHistoryManager, Repositories
├── Services/      # OCRService, LLMService, Models/
├── Features/
│   ├── Capture/   # CaptureViewController, CaptureViewModel
│   ├── History/   # HistoryListViewController, RecordDetailViewController
│   ├── Transactions/
│   └── Settings/
```

---

## 4. Pending / Next Steps

### Technical Debt
- [ ] `TransactionRepository` is a placeholder—needs Core Data CRUD implementation
- [ ] Debug logging should be wrapped in a `#if DEBUG` flag for production builds
- [ ] Config.plist API key loading could use Keychain for better security

### Known Issues
- LaunchServices console warnings in Simulator are benign (system noise)
- GPT-5 model names are placeholders—update when official models are released

### Future Features
- [ ] Camera capture mode (vs. photo library only)
- [ ] Receipt image preprocessing (contrast, rotation)
- [ ] Category management UI
- [ ] Export/share transaction history
