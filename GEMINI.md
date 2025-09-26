# Gemini Project Context: vibe_todo_app

## Project Overview

This is a Flutter-based personal productivity application named "second_brain". The app is designed to help users manage their tasks, goals, and knowledge in a structured way, following the "second brain" methodology. It integrates with various external services like Notion and Google Calendar to provide a comprehensive productivity hub.

### Key Technologies:

*   **Framework:** Flutter
*   **State Management:** `provider`
*   **Local Storage:** `sqflite` (SQLite)
*   **Backend/Services:**
    *   Firebase (Authentication, Firestore, Cloud Messaging)
    *   Notion API
    *   Google Calendar API
*   **UI:** Material Design

### Core Features:

*   **Task and Project Management:** Create, organize, and track tasks and projects.
*   **Second Brain:** A system for knowledge management, likely inspired by Tiago Forte's methodology, with "Areas" and "Resources".
*   **PDS Diary:** A Plan-Do-See diary for daily reflection and planning.
*   **Inbox:** A place to capture thoughts and ideas quickly.
*   **Lock Screen Integration:** A feature that appears to work with the device's lock screen.
*   **Notifications:** Time and location-based reminders.

## Building and Running

To build and run this project, you will need to have the Flutter SDK installed.

### Setup:

1.  **Install Dependencies:**
    ```bash
    flutter pub get
    ```

### Running the App:

1.  **Run on a connected device or emulator:**
    ```bash
    flutter run
    ```

### Testing:

*   To run the widget tests:
    ```bash
    flutter test
    ```

## Development Conventions

*   **State Management:** The project uses the `provider` package for state management. State is managed through various `ChangeNotifierProvider`s, such as `ItemProvider`, `DailyPlanProvider`, and `ReviewProvider`.
*   **Database:** A local SQLite database is managed by the `DatabaseService` class. The database schema includes tables for `items`, `hierarchy`, `daily_plans`, `reviews`, `settings`, and `pds_plans`.
*   **Services:** The app is structured with a `services` directory that contains the logic for interacting with external APIs and the local database.
*   **Models:** Data structures are defined in the `models` directory.
*   **UI:** The UI is organized into `screens` and `widgets`. The app uses a custom theme defined in `lib/main.dart`.
*   **Localization:** The app is set up for localization, with support for Korean and English.
