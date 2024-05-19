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

    Create a .env file in the root directory with the following content:

    ```sh
    KEY_STORAGE_KEY=encryption_key
    IV_STORAGE_KEY=encryption_iv
