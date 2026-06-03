# DESIGN.md — AI Music Studio UI Only

## 1. Project Goal

Build a **UI-only prototype** for an iOS app called:

**AI Music Studio — Liquid Glass Red/White Edition**

The app is a music AI studio for:
- stem separation
- audio import
- project library
- processing status
- result preview
- studio mixer
- chord analyzer
- beat analyzer
- lyrics viewer
- recording screen

This phase is **UI only**.

Do **not** implement real logic, backend, CoreML, audio processing, file import, recording, export, database, authentication, or cloud sync.

---

## 2. Main Design Direction

Create a native iOS interface inspired by:

- Apple Music
- iOS Liquid Glass
- dark studio interface
- red/white accent edition
- minimal music production app
- clean mobile dashboard

The UI should look premium, simple, and native to iPhone.

The reference style is:

**Dark navy/black background + red glass accent + white cards + soft translucent panels.**

---

## 3. Technical Scope

### Use

- SwiftUI-first UI
- iOS 18.0+
- Xcode 16.4 compatible
- SF Symbols
- Static local mock data only
- Reusable design system
- Responsive iPhone layout

### Do Not Use

- Real audio processing
- CoreML inference
- AVAudioEngine logic
- File picker logic
- Real recording
- Microphone permission
- Backend/API
- Database
- Login/authentication
- Cloud storage
- Export logic
- Real stem playback

All buttons may be clickable visually, but actions should only navigate to UI screens or do nothing.

---

## 4. Important Rule

This is **UI approval phase only**.

The goal is to make all screens visually finished first.  
Business logic will be integrated in the next phase.

Do not connect the UI to real services yet.

---

## 5. App Name

Use this app title in the UI:

```text
AI Music Studio
```

Optional subtitle:

```text
Stem Separation Studio
```

---

## 6. Visual Theme

### Theme Name

```text
Liquid Glass Red/White Edition
```

### Visual Keywords

* dark glass
* red accent
* white translucent card
* soft blur
* rounded corners
* music waveform
* minimal icons
* iPhone native layout
* studio dashboard
* premium but not too crowded

---

## 7. Color Palette

Create centralized colors in `DesignSystem.swift`.

```swift
BackgroundDark      = #101926
BackgroundDeep      = #08111D
SurfaceGlass        = rgba(255,255,255,0.08)
SurfaceLightGlass   = rgba(255,255,255,0.18)
SurfaceCard         = #DDE4EA
PrimaryRed          = #B00020
AccentRed           = #D71920
SoftRed             = #EF4444
TextPrimaryDark     = #FFFFFF
TextPrimaryLight    = #111827
TextSecondary       = #94A3B8
TextMuted           = #64748B
BorderGlass         = rgba(255,255,255,0.18)
SuccessGreen        = #22C55E
WarningYellow       = #F59E0B
RecordRed           = #EF233C
```

---

## 8. Typography

Use native iOS system font.

### Title

* Large title
* Bold
* 28–34 pt

### Screen Header

* Semibold
* 20–24 pt

### Card Title

* Semibold
* 15–17 pt

### Body

* Regular
* 13–15 pt

### Caption

* Regular
* 11–12 pt

Use clean hierarchy. Avoid too much text.

---

## 9. Shape System

Use consistent rounded corners.

```text
Small radius: 10
Medium radius: 16
Large radius: 22
Extra large radius: 28
```

Glass cards should use:

* soft background blur
* translucent overlay
* thin border
* subtle shadow
* rounded corners

---

## 10. Reusable UI Components

Create reusable components before building screens.

### Required Components

```text
GlassCard
GlassButton
GlassIconButton
GlassTabBar
GlassSegmentedControl
GlassListRow
GlassSearchBar
GlassProgressRing
GlassWaveform
StemRow
MixerFader
AudioLevelMeter
MiniPlayerCard
BottomActionBar
```

---

## 11. Navigation Structure

Use bottom navigation with 4 main tabs:

```text
Home
Projects
Tools
Profile
```

### Home Tab

Shows dashboard.

### Projects Tab

Shows project library.

### Tools Tab

Shows shortcuts to:

* Import
* Mixer
* AI Analyzer
* Recording

### Profile Tab

Simple placeholder settings/profile UI.

---

## 12. Screen List

Build these UI screens:

```text
1. Home Page
2. Projects Library
3. Import Sources
4. Processing Status
5. Results
6. Studio Mixer
7. Chord Analyzer
8. Beat Analyzer
9. Lyrics Viewer
10. Recording
11. Tools Hub
12. Profile / Settings Placeholder
```

---

# 13. Screen Specification

---

## 13.1 Home Page

### Purpose

Main dashboard for the AI music studio.

### Header

Show:

```text
Studio
AI Music Studio
```

Top bar should include:

* back/menu placeholder icon
* small red music icon or profile icon
* iPhone status bar style

### Main Hero Card

Use a large glass card with red/blue waveform background.

Text:

```text
Create.
Enhance.
Release.
```

### Quick Actions

Show 4 main action buttons:

```text
New Project
Import Audio
AI Analyzer
Studio Mixer
Record
```

Use red accent icons.

### Recent Projects

Show recent project list with:

* thumbnail
* project name
* stem count
* duration
* date
* more button

Example:

```text
Ocean Waves
6 Stems · 03:24 · Today
```

### Bottom Navigation

Floating glass tab bar:

```text
Home | Projects | Tools | Profile
```

---

## 13.2 Projects Library

### Purpose

Library of all music projects.

### Header

```text
Projects
```

Top right:

* plus button

### Search

Add search bar:

```text
Search
```

### Filter Chips

```text
All
Songs
Sessions
Imported
```

### Project Rows

Each row includes:

* artwork thumbnail
* project name
* duration
* stem count
* date
* more menu

Example project names:

```text
Ocean Wave
Project Nam
Bass 1 Name
Guitar Synth
Other
```

No real project storage.

---

## 13.3 Import Sources

### Purpose

Choose input source before processing.

### Header

```text
Import Source
```

### Source Buttons

Create large glass list rows:

```text
Import Audio
Import Video
Browse Files
From iCloud Drive
```

### Captions

```text
Import Audio — WAV, MP3, M4A
Import Video — Extract audio from video
Browse Files — Choose from local files
From iCloud Drive — Import from iCloud
```

### Footer

Show supported format text:

```text
Supported Formats
WAV, MP3, M4A, AIFF, CAF, MOV, MP4
```

No real file picker yet.

---

## 13.4 Processing Status

### Purpose

Display visual progress while separation is running.

### Header

```text
Processing
```

### Main Progress

Center circular progress ring.

Example:

```text
64%
Separating Stems
```

### Time Info

```text
Elapsed 01:22
ETA 02:38
```

### Pipeline Steps

Show status card:

```text
Decode Audio
STFT Transform
AI Inference
Reconstruction
Export Stems
```

Each step should have:

* icon
* label
* status

Example statuses:

```text
Completed
In Progress
Pending
```

### Engine Card

```text
Engine
Neural Engine

Mode
High Quality
```

### Bottom Button

```text
Cancel
```

No real progress logic. Static UI is acceptable.

---

## 13.5 Results Screen

### Purpose

Show generated stem results.

### Header

```text
Results
```

### Success Card

```text
6 Stems Generated
Separation complete
```

### Stem List

Show these rows:

```text
Vocals
Drums
Bass
Guitar
Keys / Synth
Others
```

Each stem row includes:

* icon
* stem name
* duration
* play button
* more button

### Buttons

```text
Open Mixer
AI Analyzer
Export Stems
Save Project
```

No real playback/export.

---

## 13.6 Studio Mixer

### Purpose

Visual audio mixer for stems.

### Header

```text
Studio Mixer
```

### Mini Player

Show:

* artwork thumbnail
* project name
* duration
* previous button
* play button
* next button
* timeline

### Mixer Channels

Create vertical mixer faders.

Channels:

```text
Vocals
Drums
Bass
Guitar
Keys
Others
Master
```

Each channel includes:

* label
* fader
* M button
* S button
* volume value

### Bottom Controls

```text
Export Mix
Settings
```

No real audio binding.

---

## 13.7 Chord Analyzer

### Purpose

Show chord detection UI.

### Header

```text
AI Analyzer - Chords
```

### Main Info

```text
Key: G Major
Scale: Ionian
Confidence: 98%
```

### Chord Cards

Show large chord boxes:

```text
G
D/F#
Em
C
```

### Detail Stats

```text
Total Chords: 42
Unique Chords: 12
Detected Key: G Major
```

No real chord detection.

---

## 13.8 Beat Analyzer

### Purpose

Show BPM and beat grid UI.

### Header

```text
AI Analyzer - Beat
```

### Main Card

```text
130 BPM
Confidence 96%
```

### Beat Visual

Show red waveform/beat grid cards.

### Controls

```text
Tap Tempo
Metronome
```

### Detail

```text
Time Signature: 4/4
Subdivision: 1/16
```

No real beat detection.

---

## 13.9 Lyrics Viewer

### Purpose

Show timed lyrics UI.

### Header

```text
AI Analyzer - Lyrics
```

### Lyrics List

Show timestamped lyrics.

Example:

```text
01:21 This is somebody that I used to know
01:34 The somebody that I used to know
```

Highlight current lyric line using red glass background.

### Bottom Player

```text
Previous
Play
Next
```

No real lyrics sync.

---

## 13.10 Recording Screen

### Purpose

Visual recorder screen.

### Header

```text
Recording
```

### Waveform Area

Show simple waveform at the top.

### Record Button

Large red glowing circular button in the center.

### Timer

```text
00:03:10
```

### Controls

```text
Metronome
Settings
Input
```

No real recording or microphone permission.

---

## 13.11 Tools Hub

### Purpose

Shortcut screen for all tools.

### Tool Cards

```text
Import Audio
Stem Separation
Studio Mixer
AI Analyzer
Lyrics Viewer
Recording
Export
Settings
```

Each tool card should have:

* icon
* title
* short caption

---

## 13.12 Profile / Settings Placeholder

### Purpose

Simple settings screen for UI phase.

### Items

```text
Profile
Audio Quality
Theme
Storage
About App
Help
```

No account backend.

---

# 14. Mock Data

Create static mock data in one file only:

```text
PreviewData.swift
```

Mock data includes:

```text
Projects
Stems
Lyrics
Chords
Analyzer values
Mixer channels
```

Do not scatter fake data across all views.

---

# 15. UI State Only

Allowed UI states:

```text
selectedTab
selectedAnalyzerTab
selectedProject
selectedStem
isRecordingVisual
progressValue
```

These states are only for visual interaction.

---

# 16. Prohibited Implementation

Do not implement:

```text
Real audio import
Real file picker
Real video extraction
Real stem separation
Real CoreML
Real AVAudioEngine
Real AVAudioRecorder
Real playback engine
Real export
Real save project
Real database
Real API
Real backend
Real login
Real cloud sync
Real payment
```

---

# 17. File Structure

Create or update these files:

```text
DesignSystem.swift
GlassComponents.swift
AppRootView.swift
HomeView.swift
ProjectsView.swift
ToolsHubView.swift
ImportSourceView.swift
ProcessingView.swift
ResultsView.swift
StudioMixerView.swift
AIAnalyzerView.swift
LyricsViewerView.swift
RecordingView.swift
ProfileView.swift
PreviewData.swift
```

Optional component files:

```text
GlassTabBar.swift
GlassProgressRing.swift
GlassWaveform.swift
MixerFader.swift
StemRow.swift
ProjectRow.swift
AudioLevelMeter.swift
MiniPlayerCard.swift
```

---

# 18. UIKit / SwiftUI Rule

If the project uses UIKit lifecycle:

Keep:

```text
SceneDelegate.swift
AppDelegate.swift
```

Set root view to:

```swift
UIHostingController(rootView: AppRootView())
```

Do not create duplicate root controllers.

If the project already uses SwiftUI lifecycle, set:

```swift
AppRootView()
```

as the main view.

---

# 19. Build Rule

Every new Swift file must be added to the Xcode target.

If the project uses a generator script for `.xcodeproj`, update the generator too.

The build must not fail because of:

```text
Cannot find type in scope
File not added to target
Duplicate struct
Duplicate class
Missing import SwiftUI
```

---

# 20. Acceptance Criteria

The UI phase is complete when:

```text
1. App builds successfully on Xcode 16.4.
2. App launches into the new UI.
3. All screens are reachable.
4. Design matches Liquid Glass Red/White Edition.
5. No backend is added.
6. No real audio logic is added.
7. No CoreML logic is added.
8. No file picker logic is added.
9. No recording logic is added.
10. UI uses static mock data only.
11. All colors are centralized.
12. All reusable glass components are centralized.
13. Layout works on iPhone 13 mini to iPhone 16 Pro Max.
14. Existing logic files are not deleted.
```

---

## 21. Final Output Required From Agent

After finishing, provide:

```text
1. List of created files
2. List of modified files
3. Navigation flow summary
4. Confirmation that this is UI-only
5. Confirmation that no backend/logic was added
6. Confirmation that build passed
7. Notes about any files added to Xcode target
```

---

## 22. Final Instruction

Focus only on visual implementation.

Make the app look like a finished premium iOS music studio, but keep every feature as static UI placeholder for now.

Logic, backend, CoreML, import, recording, playback, and export will be added in the next phase.
