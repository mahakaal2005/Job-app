# LookGig - Job Search & Recruitment Platform

A modern Flutter-based mobile application connecting job seekers with employers. Built with Firebase backend for real-time data synchronization and secure authentication.

## 🚀 Features

### For Job Seekers (Users)
- 📱 Browse and search job listings
- 🔖 Bookmark favorite jobs
- 📝 Apply to jobs with resume upload
- 💬 Chat with employers
- 👤 Complete profile with skills, education, and experience
- 📊 Track application status

### For Employers
- 📋 Post and manage job openings
- 👥 View and manage applicants
- 💬 Chat with candidates
- 📈 Analytics dashboard
- 🏢 Company profile management

## 🛠️ Tech Stack

- **Framework**: Flutter 3.x
- **Language**: Dart
- **Backend**: Firebase (Authentication, Firestore, Storage)
- **State Management**: Provider
- **Image Upload**: Cloudinary
- **Authentication**: Firebase Auth (Email/Password, Google Sign-In)

## 📋 Prerequisites

Before you begin, ensure you have the following installed:
- Flutter SDK (3.0.0 or higher)
- Dart SDK (3.0.0 or higher)
- Android Studio / Xcode (for mobile development)
- Firebase CLI (optional, for deployment)
- Git

## 🔧 Setup Instructions

### 1. Clone the Repository

```bash
git clone https://github.com/YOUR_USERNAME/look-gig.git
cd look-gig
```

### 2. Install Dependencies

```bash
flutter pub get
```

### 3. Firebase Configuration

#### Create a Firebase Project
1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Create a new project
3. Enable the following services:
   - Authentication (Email/Password, Google)
   - Cloud Firestore
   - Cloud Storage

#### Add Firebase to Your App

**For Android:**
1. Download `google-services.json` from Firebase Console
2. Place it in `android/app/`

**For iOS:**
1. Download `GoogleService-Info.plist` from Firebase Console
2. Place it in `ios/Runner/`

#### Generate Firebase Options
```bash
flutterfire configure
```

### 4. Environment Variables

Create a `.env` file in the root directory:

```bash
cp .env.example .env
```

Edit `.env` and add your credentials:

```env
APP_NAME=LookGig
APP_VERSION=1.0.0

# Cloudinary Configuration
CLOUDINARY_CLOUD_NAME=your_cloud_name
CLOUDINARY_API_KEY=your_api_key
CLOUDINARY_API_SECRET=your_api_secret
CLOUDINARY_UPLOAD_PRESET=your_upload_preset

# API Configuration
API_BASE_URL=https://your-api-url.com
```

### 5. Firestore Security Rules

Deploy the Firestore security rules:

```bash
firebase deploy --only firestore:rules
```

### 6. Run the App

```bash
# For Android
flutter run

# For iOS
flutter run -d ios

# For Web
flutter run -d chrome
```

## 📁 Project Structure

```
lib/
├── main.dart                 # App entry point
├── routes/                   # Navigation routes
├── screens/                  # UI screens
│   ├── initial/             # Splash, onboarding
│   ├── login_signup/        # Authentication screens
│   └── main/                # Main app screens
│       ├── user/            # Job seeker screens
│       └── employye/        # Employer screens
├── services/                # Business logic & API calls
├── provider/                # State management
├── utils/                   # Utilities & helpers
└── widgets/                 # Reusable widgets
```

## 🔐 Security

- **Never commit** `.env` file
- **Never commit** Firebase configuration files
- **Never commit** API keys or secrets
- All sensitive data is in `.gitignore`

## 🧪 Testing

```bash
# Run unit tests
flutter test

# Run integration tests
flutter test integration_test/
```

## 📦 Building for Production

### Android
```bash
flutter build apk --release
# or
flutter build appbundle --release
```

### iOS
```bash
flutter build ios --release
```

## 🤝 Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📝 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 👥 Authors

- Your Name - Initial work

## 🙏 Acknowledgments

- Flutter team for the amazing framework
- Firebase for backend services
- All contributors who helped with the project

## 📞 Support

For support, email support@lookgig.com or open an issue in the repository.

## 🔄 Changelog

See [CHANGELOG.md](CHANGELOG.md) for a list of changes.

---

Made with ❤️ using Flutter
