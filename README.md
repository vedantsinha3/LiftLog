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

| Home | Active Workout | Templates |
|:---:|:---:|:---:|
| Dashboard with stats | Track sets in real-time | Quick start routines |

| History | Exercises | Exercise Detail |
|:---:|:---:|:---:|
| Browse past workouts | Filter & search | Exercise info |


## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- SF Symbols for the beautiful icons
- Apple for SwiftUI and SwiftData

---

**Built with ❤️ using SwiftUI**
