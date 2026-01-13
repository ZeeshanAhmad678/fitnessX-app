# 🏃‍♂️ FitnessX - Activity & Hydration Tracker

**FitnessX** is a modern mobile health application built with **Flutter**. It is designed to help users maintain an active lifestyle by tracking daily steps in real-time using device sensors and monitoring hydration levels with smart logging features. All user data is securely synced to the cloud via Firebase.

## ✨ Features

### 👣 Live Step Counter (Pedometer)
* **Real-Time Tracking:** Uses the device's hardware sensor (`ActivityRecognition`) to count steps accurately while walking.
* **Smart Session Logic:** Automatically calculates steps for the current day/session, resetting the view to 0 when the app starts.
* **Goal Alerts:** Displays a congratulatory popup immediately when the daily step target (e.g., 2,400 steps) is achieved.

### 💧 Hydration Tracker
* **Smart Logging:** "Quick Add" buttons (100ml, 200ml, 500ml) for effortless logging.
* **Dynamic Goals:** Visualizes remaining water intake to reach daily targets (e.g., 8L).
* **Custom Targets:** Users can edit their daily water and step goals via the dashboard.

### ☁️ Cloud Sync & Auth
* **Secure Login:** Powered by **Firebase Authentication** (Email/Password).
* **Data Persistence:** User profile (Age, Weight, Height), step goals, and hydration logs are saved to **Cloud Firestore**, ensuring data is never lost.

---

## 🛠️ Tech Stack

* **Framework:** Flutter (Dart)
* **Backend:** Firebase (Auth, Firestore)
* **Sensors:** `pedometer` (Android Activity Recognition)
* **State Management:** `setState` & `Streams`
* **Routing:** `go_router`

---

## 📸 Screenshots

| Home Screen | Activity Tracker | Onboarding |
|:---:|:---:|:---:|
| <img src="assets/screenshots/home.png" width="200" /> | <img src="assets/screenshots/activity.png" width="200" /> | <img src="assets/screenshots/login.png" width="200" /> | <img src="assets/screenshots/profile.png" width="200" />

*(Note: Add your actual screenshots to an `assets/screenshots` folder in your repo to make them visible here)*

---

## 🚀 Getting Started

Follow these steps to run the project locally.

### Prerequisites
* Flutter SDK installed
* Java/JDK installed (for Android build)
* An Android device or Emulator

### Installation

1.  **Clone the repository**
    ```bash
    git clone https://github.com/ZeeshanAhmad678/fitnessX-app.git
    cd fitness-x
    ```

2.  **Install Dependencies**
    ```bash
    flutter pub get
    ```

3.  **Firebase Setup**
    * This project uses Firebase. You must add your own `google-services.json` file.
    * Go to [Firebase Console](https://console.firebase.google.com/).
    * Create a project and add an Android app with package name: `com.example.fitness_app` (or your specific ID).
    * Download `google-services.json` and place it in `android/app/`.

4.  **Run the App**
    ```bash
    flutter run
    ```

---

## 📱 Permissions

To ensure the step counter works, this app requires the following permissions (already configured in `AndroidManifest.xml`):

* `ACTIVITY_RECOGNITION` (For counting steps)
* `INTERNET` (For Firebase Sync)

---

## 📦 Release Build

To generate a signed APK for Android devices:

1.  Create a `key.properties` file in the `android/` folder with your keystore details.
2.  Run the build command:
    ```bash
    flutter build apk --release
    ```
3.  The APK will be generated at `build/app/outputs/flutter-apk/app-release.apk`.

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

**Developed by:** Zeeshan Ahmad and Saqib Shahab

