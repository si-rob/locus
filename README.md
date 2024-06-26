# Locus

## Your Day Decoded

Locus is a Flutter application for Android and iOS designed to log activities every 30 minutes, including details of interactions, actions, and categories. The goal is to help users measure how they spend their time and align their activities with personal goals. Data is stored securely in Google Firebase, with encryption for sensitive information.

## Features

- **Activity Logging**: Log interactions, actions, and categories every 30 minutes.
- **Daily Reports**: View daily summaries of logged activities.
- **Profile Management**: Set and track personal goals.
- **Secure Data Storage**: Store data in Firebase with encryption for sensitive information.
- **Google Sign-In**: Authenticate users with Google Sign-In.

## Getting Started

### Prerequisites

- Flutter SDK
- Firebase account
- Google Cloud project

### Installation

1. **Clone the repository**:

   ```sh
   git clone https://github.com/your-repository/locus.git
   cd locus

2. **Install dependencies**:

    ```sh
    flutter pub get

3. **Set up Firebase**:

    - Create a Firebase project in the Firebase Console.
    - Add Android and iOS apps to your Firebase project.
    - Download the google-services.json (for Android) and GoogleService-Info.plist (for iOS) and place them in the respective directories:
      - android/app
      - ios/Runner

4. **Configure environment variables**:

    Copy env.example to .env file in the root directory and fill in the values for each key:

    ```sh
    ANDROID_API_KEY=android_api_key
   ANDROID_APP_ID=android_app_id
   MESSAGING_SENDER_ID=messaging_sender_id
   PROJECT_ID=project_id
   STORAGE_BUCKET=storage_bucket
   IOS_BUNDLE_ID=ios_bundle_id
   IOS_API_KEY=ios_api_key
   IOS_APP_ID=ios_app_id
   KEY_STORAGE_KEY=key_storage_key
   IV_STORAGE_KEY=iv_storage_key

5. **Run the app**:

    ```sh
    flutter run

### Project Structure

```sh
lib/
├── encryption_service.dart   # Handles encryption and decryption
├── log_entry_screen.dart     # Screen for logging activities
├── main.dart                 # Entry point of the application
├── profile_screen.dart       # Screen for managing user profile and goals
├── reporting_screen.dart     # Screen for viewing daily reports
└── firebase_options.dart     # Firebase configuration
```

### Usage

1. Log Entries: Use the log entry screen to log interactions, actions, and categories every 30 minutes.
2. View Reports: View daily reports of your logged activities.
3. Manage Profile: Set and track your personal goals on the profile screen.

### Security

- Encryption: All sensitive data is encrypted before being stored in Firebase.
- Environment Variables: Environment variables are used to manage encryption keys securely.

### Contributing

If you would like to contribute to this project, please fork the repository and submit a pull request.

### License

This project is licensed under the MIT License.
