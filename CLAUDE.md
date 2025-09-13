# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Plan·Do is a Korean productivity app built with Flutter that implements a PDS (Plan-Do-See) methodology. The app integrates with Notion API and Google Calendar for external task synchronization and focuses on time-based task management with clarification, planning, review, and archival workflows.

## Development Commands

### Setup and Dependencies
```bash
flutter pub get                    # Install dependencies
flutter pub upgrade                # Upgrade dependencies
```

### Building and Running
```bash
flutter run                       # Run in debug mode
flutter run --release             # Run in release mode
flutter build apk                 # Build Android APK
flutter build ios                 # Build iOS app
```

### Testing and Analysis
```bash
flutter test                      # Run unit tests
flutter analyze                   # Static code analysis
flutter doctor                    # Check Flutter installation
```

### Platform-specific Development
```bash
flutter run -d chrome             # Run on web
flutter run -d windows            # Run on Windows
flutter run -d android            # Run on Android device/emulator
flutter run -d ios                # Run on iOS device/simulator
```

## Architecture Overview

### State Management
- **Provider Pattern**: Uses `provider` package for state management
- **Key Providers**:
  - `ItemProvider`: Manages inbox items and tasks
  - `DailyPlanProvider`: Handles daily planning and scheduling
  - `ReviewProvider`: Manages review and reflection data
  - `PDSDiaryProvider`: Handles PDS diary entries
  - `TaskProvider`: Core task management
  - `ThemeProvider`: UI theme management

### Navigation Structure
The app uses a 5-tab bottom navigation:
1. **Notion** (`InboxScreen`): Import and manage tasks from Notion
2. **명료화** (`ClarificationScreen`): Task clarification and processing
3. **계획** (`PlanScreen`): Daily planning and scheduling
4. **점검** (`ReviewScreen`): Review and reflection
5. **아카이브** (`ArchiveScreen`): Completed tasks and history

### Data Models
- **Task**: Core task entity with time tracking, categories, and external integration
- **Item**: Inbox items for processing
- **DailyPlan**: Daily planning structure
- **Review**: Review and reflection data
- **NotionTask**: Notion-specific task representation
- **PDSPlan**: Plan-Do-See planning structure

### External Integrations
- **Notion API**: Full CRUD operations with multiple databases (TODO, MEMO, PROJECT, GOAL, AREA_RESOURCE)
- **Google Calendar**: Calendar synchronization service
- **Firebase**: Authentication and cloud storage (configured but usage varies)
- **OAuth2**: Authentication for external services

### Database and Storage
- **SQLite** (`sqflite`): Local database for offline functionality
- **SharedPreferences**: Local settings and simple data storage
- **DatabaseService**: Centralized database operations

### Key Services
- `NotionApiService`: Notion integration with API key management
- `GoogleCalendarService`: Google Calendar synchronization
- `DatabaseService`: Local SQLite operations
- `CalendarSyncService`: Cross-platform calendar sync
- `WidgetService`: Home widget integration

## Project Structure

```
lib/
├── main.dart                 # App entry point with Provider setup
├── models/                   # Data models and entities
├── providers/               # State management providers
├── screens/                 # UI screens for each navigation tab
├── services/               # External integrations and data services
├── utils/                  # Utility functions and helpers
└── widgets/               # Reusable UI components
```

## Development Notes

### Localization
- Primary locale: Korean (`ko_KR`)
- Fallback: English (`en_US`)
- Uses `flutter_localizations` with `intl` package

### Theme and UI
- Material Design with custom color scheme
- Primary color: `#2563EB` (blue)
- Background: `#F8FAFC` (light gray)
- Custom card styling with subtle borders

### API Keys and Configuration
- Notion API keys stored in SharedPreferences
- Database IDs are hardcoded in `NotionApiService`
- No external configuration files for sensitive data

### Platform Support
Configured for all Flutter platforms:
- Android, iOS, Web, Windows, macOS, Linux

### Testing
- Basic widget tests in `test/widget_test.dart`
- Run tests with `flutter test`