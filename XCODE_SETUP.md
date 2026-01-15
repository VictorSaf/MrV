# Xcode Setup Instructions

Aplicația Mr.V Agent a fost complet implementată. Urmează acești pași pentru a o rula în Xcode.

## Pasul 1: Creează Proiectul Xcode

1. Deschide **Xcode**
2. Selectează **File** → **New** → **Project**
3. Alege **macOS** tab → **App** template
4. Configurează proiectul:
   - **Product Name**: `MrVAgent`
   - **Team**: Selectează team-ul tău
   - **Organization Identifier**: `com.vict0r` (sau propriul tău)
   - **Bundle Identifier**: `com.vict0r.MrVAgent`
   - **Interface**: **SwiftUI**
   - **Language**: **Swift**
   - **Storage**: None
   - **Include Tests**: Opțional
5. Salvează proiectul în `MrVAgent/` folder (deasupra folderului existent MrVAgent/)

## Pasul 2: Șterge Fișierele Default

După ce Xcode creează proiectul:
1. În Project Navigator, șterge fișierele default:
   - `ContentView.swift` (dacă există)
   - `MrVAgentApp.swift` (dacă există - vom folosi cel implementat)
   - `Assets.xcassets` (șterge doar acest folder)

## Pasul 3: Adaugă Fișierele Implementate

1. În Finder, deschide folderul `MrVAgent/MrVAgent/` care conține toate fișierele implementate
2. În Xcode Project Navigator, selectează grupul principal `MrVAgent`
3. Drag & drop toate fișierele și folderele din `MrVAgent/MrVAgent/` în Xcode:
   - `MrVAgentApp.swift`
   - Folderul `Models/` (cu toate fișierele)
   - Folderul `Services/` (cu toate fișierele)
   - Folderul `ViewModels/` (cu toate fișierele)
   - Folderul `Views/` (cu toate fișierele)
   - Folderul `Assets.xcassets/`

4. În dialog, asigură-te că:
   - ✅ **Copy items if needed** este bifat
   - ✅ **Create groups** este selectat
   - ✅ **Add to targets: MrVAgent** este bifat

## Pasul 4: Configurare Project Settings

1. Selectează **proiectul MrVAgent** în Project Navigator
2. Selectează **target-ul MrVAgent**
3. Tab **Signing & Capabilities**:
   - Configurează **Team**-ul tău
   - Verifică că **Bundle Identifier** este corect
   - Click pe **+ Capability** și adaugă **Keychain Sharing**
4. Tab **General**:
   - **Deployment Target**: **macOS 13.0** sau mai nou
   - **Category**: Productivity (opțional)

## Pasul 5: Verificare și Build

1. Selectează schema **MrVAgent** și un Mac device
2. Product → Build (Cmd+B)
3. Verifică că nu sunt erori de compilare
4. Dacă sunt warning-uri despre preview macros, ignore-le (sunt normale fără plugin-uri suplimentare)

## Pasul 6: Run Application

1. Product → Run (Cmd+R)
2. Aplicația ar trebui să pornească și să afișeze ecranul de autentificare
3. La prima rulare:
   - Setează un password (va fi stocat în Keychain)
   - Username-ul este hardcodat: **Vict0r**

## Pasul 7: Configurare API Keys

După autentificare:
1. Click pe butonul **Settings** (gear icon) din toolbar
2. Pentru fiecare provider AI dorit:
   - Introdu API key-ul
   - Click **Save**
   - Verifică că apare checkmark-ul verde
3. API keys-urile vor fi stocate securizat în macOS Keychain

### Obținere API Keys

- **Claude**: https://console.anthropic.com/
- **ChatGPT**: https://platform.openai.com/api-keys
- **Perplexity**: https://www.perplexity.ai/settings/api
- **Ollama**: Instalează local: `brew install ollama` apoi `ollama serve`

## Pasul 8: Testare

1. În sidebar, selectează un AI provider (asigură-te că este configurat - checkmark verde)
2. Scrie un mesaj în input field
3. Verifică că primești streaming response de la Mr.V
4. Testează cu diferiți provideri
5. Verifică că mesajele apar corect cu bubble design

## Troubleshooting

### Eroare: "Cannot find KeychainService in scope"
- Verifică că toate fișierele din `Services/` sunt adăugate la target
- Clean Build Folder (Shift+Cmd+K) apoi rebuild

### Ollama Connection Error
- Asigură-te că Ollama rulează: `ollama serve`
- Download un model: `ollama pull llama2`
- Verifică că rulează pe `http://localhost:11434`

### API Key Invalid
- Verifică formatul key-ului
- Claude keys: încep cu `sk-ant-`
- OpenAI keys: încep cu `sk-`
- Perplexity keys: încep cu `pplx-`

### Build Errors
- Verifică că **Deployment Target** este macOS 13.0+
- Verifică că toate fișierele sunt adăugate la target-ul corect
- Clean Build Folder și rebuild

## Structura Finală în Xcode

```
MrVAgent/
├── MrVAgent (folder albastru - target)
│   ├── MrVAgentApp.swift
│   ├── Models/
│   │   ├── Message.swift
│   │   ├── AIProvider.swift
│   │   └── APIConfiguration.swift
│   ├── Services/
│   │   ├── KeychainService.swift
│   │   ├── AuthenticationService.swift
│   │   ├── AIService.swift
│   │   ├── ClaudeService.swift
│   │   ├── OpenAIService.swift
│   │   ├── PerplexityService.swift
│   │   └── OllamaService.swift
│   ├── ViewModels/
│   │   ├── AuthViewModel.swift
│   │   ├── ChatViewModel.swift
│   │   └── SettingsViewModel.swift
│   ├── Views/
│   │   ├── AuthenticationView.swift
│   │   ├── MainView.swift
│   │   ├── ChatView.swift
│   │   ├── MessageRowView.swift
│   │   ├── SettingsView.swift
│   │   └── ModelSelectorView.swift
│   └── Assets.xcassets/
│       └── AppIcon.appiconset/
└── MrVAgent.xcodeproj
```

## Features Implementate

✅ Autentificare cu password (stocat în Keychain)
✅ Chat interface cu Mr.V
✅ Support pentru 4 AI providers (Claude, GPT, Perplexity, Ollama)
✅ Selector model în sidebar
✅ Settings pentru API keys management
✅ Streaming responses (token-by-token)
✅ Stocare securizată în macOS Keychain
✅ Error handling comprehensive
✅ UI modern cu SwiftUI
✅ Dark mode support (automat)
✅ Conversation history management

## Next Steps (Faze Viitoare)

Pentru Faza 2 și următoarele, vezi documentul `README.md` pentru roadmap-ul complet:
- Multi-agent conversations
- Tool use / function calling
- File attachments și vision
- Context management
- Long-term memory
- Custom agent creation
- Plugin system

---

**Succes cu Mr.V Agent!** 🚀🤖
