# LiftLog 🏋️

A sleek, modern iOS workout tracking app built with SwiftUI and SwiftData.

![iOS 17+](https://img.shields.io/badge/iOS-17%2B-black)
![SwiftUI](https://img.shields.io/badge/SwiftUI-5.0-black)
![SwiftData](https://img.shields.io/badge/SwiftData-1.0-black)
![License](https://img.shields.io/badge/License-MIT-black)

## ✨ Features

### 🏠 Home Dashboard
- Dynamic greeting based on time of day
- Quick workout stats (workouts this week, volume, streak)
- Quick start templates for instant workout access
- Recent workout history at a glance

### 📋 Workout Templates
- Create reusable workout templates
- Customize exercises and default set counts
- Start workouts from templates with pre-configured exercises
- Track last used date for easy access to favorites

### 💪 Active Workout Tracking
- Real-time workout timer
- Live volume calculation
- Set completion tracking with visual feedback
- Completed sets are grayed out and locked
- Progress bar for each exercise
- Easy set/exercise management

### 📊 Workout History
- Browse past workouts organized by month
- Detailed workout summaries with duration, volume, sets
- Expandable exercise cards with set-by-set breakdown
- Delete workouts you no longer need

### 🏃 Exercise Library
- 50+ pre-loaded exercises across all muscle groups
- Filter by muscle group or equipment
- Search functionality
- Create custom exercises
- Detailed exercise info with instructions

## 🎨 Design

LiftLog features a clean, minimal design with:
- **Black & White color palette** for a sleek, modern look
- **Material backgrounds** with frosted glass effects
- **Smooth animations** throughout the app
- **Custom tab bar** with animated selection indicator
- **Consistent typography** using SF Pro with rounded numbers

## 🛠 Tech Stack

- **SwiftUI** - Declarative UI framework
- **SwiftData** - Modern persistence framework
- **Swift 5.9** - Latest Swift features
- **iOS 17+** - Minimum deployment target

## 📁 Project Structure

```
LiftLog/
├── App/
│   ├── LiftLogApp.swift          # App entry point
│   └── ContentView.swift         # Main view with custom tab bar
├── Core/
│   └── ExerciseDataLoader.swift  # Pre-loads exercise library
├── Features/
│   ├── Home/
│   │   └── HomeView.swift        # Dashboard & quick start
│   ├── Templates/
│   │   ├── TemplatesListView.swift
│   │   └── CreateTemplateView.swift
│   ├── Workout/
│   │   ├── ActiveWorkoutView.swift
│   │   └── ExercisePickerView.swift
│   ├── History/
│   │   ├── HistoryListView.swift
│   │   └── WorkoutDetailView.swift
│   └── Exercises/
│       ├── ExerciseListView.swift
│       ├── ExerciseDetailView.swift
│       └── AddExerciseView.swift
├── Models/
│   ├── Exercise.swift            # Exercise model + enums
│   ├── Workout.swift             # Workout & WorkoutExercise models
│   ├── WorkoutSet.swift          # Set model with RPE, set types
│   └── WorkoutTemplate.swift     # Template models
└── Resources/
    └── ExerciseData.json         # Pre-loaded exercises
```

## 🚀 Getting Started

### Requirements
- Xcode 15.0+
- iOS 17.0+
- Swift 5.9+

### Installation

1. Clone the repository
```bash
git clone https://github.com/yourusername/LiftLog.git
```

2. Open the project in Xcode
```bash
cd LiftLog
open LiftLog.xcodeproj
```

3. Build and run on your device or simulator

## 📱 Screenshots

<img width="1206" height="2622" alt="simulator_screenshot_9E0DB4EC-D7EA-4476-A94D-A7F7E1C113D4" src="https://github.com/user-attachments/assets/01e038b2-7e0e-494c-8718-cfa270fd8bf1" />
<img width="1206" height="2622" alt="simulator_screenshot_C7E3007D-C91E-4964-96B6-3A5AF2832260" src="https://github.com/user-attachments/assets/304a9451-3e8e-4f37-ab0f-a94aae6cd359" />
<img width="1206" height="2622" alt="simulator_screenshot_DFDF105C-E843-49FA-9382-B29C44E2D7D9" src="https://github.com/user-attachments/assets/1fc78a7d-6ce8-42dd-a211-4abcf092101f" />
<img width="1206" height="2622" alt="simulator_screenshot_41F59F4B-5D87-48DB-AC35-4357F323F364" src="https://github.com/user-attachments/assets/6709d6bd-9cbd-49c4-8fbc-ee58cb5e6777" />
<img width="1206" height="2622" alt="simulator_screenshot_EB42CDCB-5467-49EE-8678-C072088DD6DD" src="https://github.com/user-attachments/assets/19a8a200-b1ba-492f-8d4f-1b1985fafcef" />
<img width="1206" height="2622" alt="simulator_screenshot_4CFCE15A-CE8B-4BD4-ABA6-FC8CD3430F9C" src="https://github.com/user-attachments/assets/7fb0c47d-9afc-4f91-87e5-7212ef4e787f" />
<img width="1206" height="2622" alt="simulator_screenshot_45EA1FA7-E8AC-4564-96C2-168C15DFD91D" src="https://github.com/user-attachments/assets/a201720b-9723-4bb6-8819-73c484d642da" />







## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- SF Symbols for the beautiful icons
- Apple for SwiftUI and SwiftData

---

**Built with ❤️ using SwiftUI**
