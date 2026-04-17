# Security Policy 🛡️

At **Oi Applications**, the security and privacy of our users' data are our highest priorities. **Oi QR Scanner** is designed to be a "Privacy-First" application, meaning that your data remains on your device at all times.

## 🛡️ Safety Shield™ Philosophy
The **Oi Safety Shield** is a proactive security layer built into the scanner. It automatically analyzes every scanned URL for:
- **Masked Destinations**: Detecting shortened URLs (e.g., bit.ly) to prevent phishing.
- **Insecure Protocols**: Flagging unencrypted HTTP connections.
- **Malformed Data**: Identifying non-standard QR structures.

## 🔒 Data Protection
- **On-Device Intelligence**: All machine learning operations (Barcode scanning, Text recognition, and Translation) are performed strictly on-device using Google ML Kit. No images or text are transmitted to external servers.
- **Local Persistence**: Scan history is stored in a private SQLite database accessible only by the application.
- **Biometric Security**: Users can toggle Biometric Lock (Face/Fingerprint) within the settings to secure access to their scan history.

## 🟢 Supported Versions
Security updates are provided for the latest stable releases of the application.

| Version | Status |
| ------- | ------ |
| 1.0.x   | ✅ Supported (Current) |
| < 1.0   | ❌ End of Life |

## 🚨 Reporting a Vulnerability
We welcome reports from security researchers and users. If you believe you have found a security vulnerability in Oi QR Scanner, please follow these steps:

1. **Email us**: Send a report to **security@oiapplications.com**.
2. **Details**: Provide a detailed description of the vulnerability and steps to reproduce (or a proof-of-concept).
3. **Disclosure**: We request that you do not disclose the vulnerability publicly until we have had a reasonable amount of time to address it.

### Our Commitment
- We will acknowledge receipt of your report within **48 hours**.
- We will provide a estimated timeline for a fix within **7 days**.
- Researchers who provide valid vulnerability reports will be credited in our release notes (if desired).

---

© 2026 Oi Applications. Total Privacy, Total Transparency.
