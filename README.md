# Mr.V Agent - macOS AI Assistant

Aplicație nativă macOS pentru interacțiunea cu agenți AI prin modele locale (Ollama) și modele comerciale (Claude, ChatGPT, Perplexity).

## Features

- 🔐 Autentificare securizată cu password
- 💬 Chat interface cu streaming responses
- 🤖 Support pentru multiple AI providers:
  - Claude (Anthropic)
  - ChatGPT (OpenAI)
  - Perplexity
  - Ollama (Local)
- ⚙️ Settings pentru configurare API keys
- 🔒 Stocare securizată în macOS Keychain
- 🎨 SwiftUI modern interface

## Requirements

- macOS 13.0 (Ventura) sau mai nou
- Xcode 15.0+
- Swift 5.9+

## Setup

### Opțiunea 1: Xcode Project (Recomandat)

1. Deschide Xcode
2. File → New → Project
3. Selectează "macOS" → "App"
4. Product Name: "MrVAgent"
5. Interface: SwiftUI
6. Bundle Identifier: `com.vict0r.MrVAgent`
7. Copiază toate fișierele din folderul `MrVAgent/` în proiectul Xcode
8. Adaugă Keychain Sharing capability în Signing & Capabilities

### Opțiunea 2: Swift Package Manager

```bash
cd MrVAgent
swift build
swift run MrVAgent
```

## Configuration

### API Keys

După autentificare, accesează Settings pentru a configura API keys:

1. **Claude (Anthropic)**: https://console.anthropic.com/
2. **OpenAI (ChatGPT)**: https://platform.openai.com/api-keys
3. **Perplexity**: https://www.perplexity.ai/settings/api
4. **Ollama**: Instalează local de la https://ollama.ai/

### First Run

- Username: `Vict0r`
- La prima rulare vei fi întrebat să setezi un password
- Password-ul este stocat securizat în macOS Keychain

## Architecture

```
MrVAgent/
├── Models/              # Data models
├── Services/            # Business logic și API integrations
├── ViewModels/          # MVVM ViewModels
└── Views/              # SwiftUI Views
```

## Development

Proiectul folosește arhitectura MVVM (Model-View-ViewModel) cu:
- SwiftUI pentru UI
- async/await pentru operații asynchrone
- Keychain pentru stocare securizată
- Protocol-based AI service abstraction

## License

Private project - All rights reserved
