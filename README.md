# 🐦 BirdDex — AI Bird Identification App

**Snap a photo of a bird, and get an instant species ID, rich field-guide details, and its real call — then collect it in your own personal BirdDex.**

BirdDex is a cross-platform Flutter app that combines a **vision-capable LLM (OpenAI GPT-4o mini)** with public biodiversity data sources (**Wikipedia** and **Xeno-canto**) and **local on-device storage (Hive)** to turn bird-watching into a Pokédex-style collection game.

![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-3.9-0175C2?logo=dart&logoColor=white)
![OpenAI](https://img.shields.io/badge/OpenAI-GPT--4o%20mini-412991?logo=openai&logoColor=white)
![Hive](https://img.shields.io/badge/Storage-Hive-FFC107)
![Platforms](https://img.shields.io/badge/Platforms-Android%20%7C%20iOS-3DDC84)

<!-- Add screenshots here, e.g.:
<p align="center">
  <img src="docs/home.png" width="220" />
  <img src="docs/result.png" width="220" />
  <img src="docs/birddex.png" width="220" />
</p>
-->

---

## ✨ Features

### 🔍 AI identification
- Take a photo with the **camera** or pick one from the **gallery**.
- The image is sent to a **multimodal LLM** (GPT-4o mini) with a system prompt that forces a **strict JSON response**, so the output can be parsed reliably instead of scraped from free text.
- Returns common name, scientific name, **confidence score**, description, habitat, diet, IUCN conservation status, size class and weight range.

### 📖 BirdDex collection
- Every identified bird is saved locally and added to a **collection grid** with a progress bar (`N / total collected`).
- Ships with a seed catalogue of species (`assets/data/birds.json`, including Portuguese names). Species you haven't found yet appear **greyed-out as “???”** until you identify them.
- **Search** by common or scientific name.
- **Filter** by Collected / Uncollected / Favorites and by size (Small / Medium / Large).
- **Sort** by A–Z, date collected, or weight (parses `g` and `kg` ranges to a normalised value).

### 🧾 Species detail screen
- Hero image with an **animated, colour-coded confidence bar** (green / orange / red).
- Overview and Details tabs with size, weight, habitat, diet, and a **conservation-status badge** colour-mapped from the IUCN category.
- 🎵 **Bird call player** — streams a real recording from Xeno-canto with play/pause and a seekable progress slider.
- ❤️ **Favorites** and 📝 **personal notes** per species, persisted offline.
- Quick links to the species' Wikipedia page and a share/copy action.

---

## 🧱 Architecture

The app is organised in a simple layered structure — UI screens, service classes that own every network call, and a persistence layer — so each concern can be changed or tested in isolation.

```
lib/
├── main.dart                     # App bootstrap: .env, Hive boxes, first-launch handling
├── screens/
│   ├── home_screen.dart          # Camera / gallery entry point, orchestrates identification
│   ├── result_screen.dart        # Species detail, audio player, favorites, notes
│   └── birddex_screen.dart       # Collection grid with search, filter and sort
├── services/
│   ├── api_service.dart          # OpenAI vision request + JSON parsing + Wikipedia image lookup
│   ├── bird_audio_service.dart   # Xeno-canto v3 API client (species → genus fallback)
│   ├── wikipedia_service.dart    # Wikipedia REST summary/thumbnail helper
│   └── bird_loader.dart          # Seeds the local DB from the bundled JSON
├── models/
│   └── bird.dart                 # Bird model with fromJson / toJson
├── utils/
│   └── weight_parser.dart        # Parses "3-6.7 kg" / "70-100 g" into kg for sorting
└── widgets/
assets/data/birds.json            # Seed catalogue of species
test/                             # Unit tests (model, weight parser) + home-screen widget test
```

### How an identification flows through the app

```
 Camera / Gallery
        │  image_picker (JPEG, quality 85)
        ▼
  HomeScreen ──► ApiService.identifyBird()
                    │  1. base64-encode image
                    │  2. POST → OpenAI Chat Completions (vision, JSON-only prompt)
                    │  3. Parse + validate JSON, apply safe defaults for missing fields
                    │  4. Look up a reference photo via the Wikipedia API
                    ▼
        Save to Hive ('birddex' box, keyed by common name)
                    ▼
  ResultScreen ──► BirdAudioService.fetchBirdCall()  →  Xeno-canto  →  just_audio playback
```

### Design decisions worth calling out
- **Structured LLM output.** The prompt pins the model to a fixed JSON schema and the client defends against malformed or partial responses (`Invalid JSON`, empty content, missing keys → typed errors and default values), so a bad model reply never crashes the UI.
- **Graceful degradation.** Wikipedia image and Xeno-canto audio are best-effort enrichments: failures return `null` and the UI falls back to a placeholder or a “no bird call available” state rather than blocking the identification.
- **Smart audio fallback.** If Xeno-canto has no recording for the exact species, the service retries by **genus** before giving up.
- **Image source priority.** The detail screen picks the best available image: user's own photo → reference image URL → captured file → placeholder.
- **Offline-first personal data.** Collection, favorites and notes live in three separate Hive boxes (`birddex`, `favorites`, `notes`) keyed by species, so they work without a connection and stay independent of one another.
- **Merged data view.** The BirdDex grid merges the bundled catalogue with the user's saved sightings, and also includes birds the AI identified that aren't in the seed list.
- **Secrets out of source control.** API keys are read from a git-ignored `.env` file via `flutter_dotenv`.

---

## 🛠️ Tech stack

| Area | Technology |
|---|---|
| Framework | Flutter (Dart SDK ^3.9.2), Material UI |
| AI / Vision | OpenAI Chat Completions API — `gpt-4o-mini` (multimodal) |
| External data | Wikipedia API (images, links), Xeno-canto API v3 (bird calls) |
| Local storage | `hive` / `hive_flutter` (collection, favorites, notes), `shared_preferences` |
| Media | `image_picker`, `camera`, `just_audio` |
| Networking / config | `http`, `flutter_dotenv` |
| Misc | `url_launcher`, `path_provider` |

---

## 🚀 Getting started

### Prerequisites
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (Dart ^3.9.2)
- An **OpenAI API key** — <https://platform.openai.com/api-keys>
- A free **Xeno-canto API key** (for bird calls) — <https://xeno-canto.org/account>

### Setup

```bash
# 1. Clone
git clone <your-repo-url>
cd flutter_ai_vision

# 2. Install dependencies
flutter pub get

# 3. Create a .env file in the project root (it is git-ignored)
```

```env
OPENAI_API_KEY=your_openai_key_here
XENOCANTO_API_KEY=your_xeno_canto_key_here
```

```bash
# 4. Run on a connected device or emulator
flutter run

# Run the tests
flutter test
```

> **Note:** `.env` is declared as a Flutter asset in `pubspec.yaml`, so the file must exist before building. The bird-call feature is optional — without a Xeno-canto key the rest of the app works and the audio card simply shows “No bird call available”.

---

## 🧭 Roadmap & known limitations

This project is a working prototype, and these are the next steps I'd take to harden it:

- **Move the OpenAI call behind a small backend/proxy.** Today the key is bundled with the app through `.env`, which is fine for local development but should never ship in a production build.
- **On-device inference.** Scaffolding for a TensorFlow Lite classifier (`tflite_service.dart`, `assets/tflite_models/`) exists to enable offline identification and reduce API cost.
- **State management & wider test coverage.** Introduce Provider/Riverpod (or Bloc) and extend the existing tests (model, weight parsing, home-screen widget test) to the API response parsing and the BirdDex merge/filter logic.
- **Location tagging.** Record where each bird was spotted (latitude/longitude fields are already in the storage schema) and show a sightings map.
- **Localisation.** The catalogue already carries Portuguese names; surface them with in-app language switching.
- **Polish.** Replace `print` logging with a proper logger, add rate-limit/retry handling for the AI request, and use `share_plus` for native sharing.

---

## 👤 Author

**Daniel Paulino** — Flutter developer
📧 dnpaulino95@gmail.com

---

*Bird photos are sourced from Wikimedia Commons; bird recordings are provided by contributors to [Xeno-canto](https://xeno-canto.org).*
