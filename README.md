# 📚 MoodleTrack

MoodleTrack is a **cross-platform mobile app (Android & iOS)** designed for **Wits University students** to easily keep up with their **Moodle notifications and events**. The app also lets students **add personal events** to their calendar and receive **reminder notifications** before those events.  

Built with **Flutter (Dart)**, using the **Moodle REST API** and **Firebase** for backend services.  

---

## ✨ Features  
- 🔔 **Real-time Moodle Notifications** (synced via Moodle REST API)  
- 📅 **Integrated Calendar** with Moodle events  
- ➕ **Add Custom Events** (e.g., study sessions, meetings)  
- ⏰ **Reminders & Push Notifications** before events  
- 📲 Available on **Android (APK)** and **iOS (IPA)**  

---

## 🛠️ Tech Stack  
- **Frontend:** Flutter (Dart)  
- **Backend:** Firebase  
- **API:** Moodle REST API  

---

## 🚀 Installation  

### 📱 Android (APK)  
1. Download the latest `MoodleTracker.apk` from the [Releases](../../releases).  
2. Transfer it to your Android phone (or download directly on your phone).  
3. Enable **Install from Unknown Sources** (only once).  
4. Tap the APK and install.  

---

### 🍏 iOS (IPA)  

#### Option 1: If you have a Mac (Xcode)  
1. Clone this repo.  
2. Open the project in **Xcode**.  
3. Connect your iPhone.  
4. Build & run on your device.  

#### Option 2: Windows or Mac (Sideloadly)  
1. Download the latest `MoodleTracker.ipa` from the [Releases](../../releases).  
2. Install **[Sideloadly](https://sideloadly.io/)**.  
3. Connect your iPhone via USB.  
4. Open Sideloadly → drag & drop the `.ipa` file.  
5. Sign in with your Apple ID (required by Apple).  
6. The app will install on your iPhone.  

---

## 🔧 Development (for contributors)  
If you want to run the app from source:  

```bash
# Clone the repository
git clone https://github.com/mahlatseclayton/MoodleTrack.git
cd MoodleTracker

# Install dependencies
flutter pub get

# Run on connected device
flutter run
