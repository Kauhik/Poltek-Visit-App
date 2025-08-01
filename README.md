# Poltek Visit App

An interactive iOS application that showcases cutting‑edge Apple platform technologies (SwiftUI, Vision, CoreML, ARKit, CoreNFC) while guiding visiting student teams through a cross‑cultural scavenger hunt. Originally built for a joint Singapore Polytechnic & Indonesian learner workshop, this app mixes real‑time sensor demos with culturally themed puzzles.

---

## Why This App Exists

1. **Hands‑on Tech Showcase**  
   Demonstrate real‑world usage of Vision (pose detection), CoreML (action & image classification), SoundAnalysis (audio recognition), ARKit (motion classification), and CoreNFC (tag reading) within a single SwiftUI experience, and to promote cross cultrue relations

2. **Cross‑Cultural Engagement**  
   Bring together 150 students (70 Singaporean, 80 Indonesian) through collaborative, location‑based puzzles that reveal heritage and cultural facts as teams unlock each clue.

3. **Scalable Self‑Guided Experience**  
   Support large groups on their own devices without constant instructor oversight, using persistent state and clear feedback to keep everyone on track.

---

## Getting Started

1. **Clone the repository**
   ```bash
   git clone https://github.com/Kauhik/Poltek-Visit-App
   cd PoltekVisitApp


## Getting Started

2. **Add Real‑World Assets**  
   Copy the entire `PoltekAssets/` folder from the Xcode project’s asset group and place it physically throughout the Campus/Academy

3. **Open in Xcode**  
   Double‑click `PoltekVisitApp.xcodeproj` and select your target device or simulator.

4. **Configure Permissions**  
   Add the following keys to your `Info.plist`:
   - `NSCameraUsageDescription`
   - `NSMicrophoneUsageDescription`
   - `NFCReaderUsageDescription`

5. **Build & Run**  
   Press Run in Xcode. On first launch, grant requested permissions, then enter your team number to begin.

---

## How to Use

### Team Entry

- Enter a two‑digit group number (1–55).
- Tap **Play** to navigate to the **Clue Grid**.

### Clue Grid

- View your locker number and locked puzzle tiles.
- Tap **Scan Clue** to launch the multi‑modal scanner.

### Scanner Tabs

- **QR**: Scan five predefined QR codes.
- **Camera**: Perform live action poses (SG & ID) to unlock two clues.
- **Listen**: Recognize four audio snippets with SoundAnalysis.
- **Move**: Replicate ARKit motion sequences.
- **NFC**: Tap four NFC tags to collect the final clues.

### Puzzle Reveal

- After each scan type completes, solve the corresponding cultural puzzle.
- Collect letters A–D to reveal your team’s final code.
- Enter the code on the **Code Reveal** screen and celebrate your success! 🎉

---

## Deployment Context

- **Ideal Setting**: Educational workshops, hackathons, campus tours  
- **Target Users**: Student teams, workshop attendees, tech demonstrators  
- **Hardware**: iPhone with camera, mic, and NFC support

---

## Contributing

1. Fork the repo and create a feature branch:
   ```bash
   git checkout -b feature/YourFeature
2. Implement your changes with clear, production‑quality code.
3. Add or update tests under Tests/.
4. Submit a Pull Request with a descriptive title and summary of changes.
---
Made by Kaushik Manian in Year Long Internship @ Apple Developer Academy ILB
