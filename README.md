# Oi QR Scanner 🟢

[![Premium](https://img.shields.io/badge/Experience-Premium-green.svg)]()
[![Ads](https://img.shields.io/badge/Ads-None-red.svg)]()
[![Privacy](https://img.shields.io/badge/Privacy-On--Device-blue.svg)]()

**Oi QR Scanner** is a world-class, high-contrast, and ultra-fast utility suite designed for users who demand both aesthetic excellence and uncompromising privacy. Built with Flutter and Google ML Kit, it delivers a high-performance scanning experience with a professional-grade design system.

---

## ✨ Key Features

### 🛡️ Safety Shield
Scan with confidence. Our real-time URL verification system analyzes links for potential risks, masked URLs (shorteners), and insecure protocols (HTTP) before you tap.

### 🍱 Bento Design System
A cutting-edge visual experience. Your scan history is organized in a beautiful, staggered Bento Grid with Glassmorphic cards that react dynamically to your interactions.

### ⚡ Blazing Speed
Detection in as little as **0.04 seconds**. Optimized for efficiency, the scanner ROI is decoupled for rapid and precise results even in low-light conditions.

### 🎨 High-Contrast Neon UI
Designed for maximum legibility and style. A deep slate and neon green palette combined with smooth shared-axis transitions provides a premium dark-mode feeling.

### 🤫 100% Ad-Free
No banners, no interstitials, no tracking. Just pure utility, maximizing screen real-estate and user focus.

### 🔊 Tactile & Auditory Feedback
- **Double-Tap Haptics**: Custom tactile feedback for successful scans.
- **Cyber-Chime**: Futuristic audio confirmation for a truly tech-forward experience.

---

## 🛠️ Technical Specs

- **Core Framework**: [Flutter](https://flutter.dev)
- **Engine**: [Google ML Kit](https://developers.google.com/ml-kit) (On-Device Text & Barcode)
- **Scanning Engine**: Optimized Mobile Scanner (DetectionSpeed.unrestricted)
- **Security**: Local Biometric Authentication (Face/Fingerprint)
- **Persistence**: SQLite (Local Database)
- **Export**: Professional PDF & CSV reporting.

---

## 🚦 Getting Started

### Prerequisites
- Flutter SDK (^3.11.1)
- Android API 21+ / iOS 12.0+

### Installation
1. Clone the repository:
   ```bash
   git clone https://github.com/oiapplications/oiqrscanner.git
   ```
2. Install dependencies:
   ```bash
   flutter pub get
   ```
3. Run the application:
   ```bash
   flutter run --release
   ```

---

## 🔒 Privacy & Security

We believe your data is yours. 
- **100% On-Device**: Scanned images and text never leave the device.
- **No Cloud Required**: All ML processing is performed locally.
- **Encryption**: Exported reports are saved locally to protected app directories.

See [SECURITY.md](SECURITY.md) for more details.

---

## 📜 License
This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

© 2026 Oi Applications. Made with ❤️ in Bangladesh.
