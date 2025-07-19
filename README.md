# Loggit

A personal productivity app built with Flutter for logging expenses, tasks, reminders, notes, and gym workouts through natural language chat.

**Timeline Test**: This line was added to test VS Code's timeline feature.

## Features

- **Chat Interface**: Log entries using natural language
- **Expense Tracking**: Log expenses with categories and amounts
- **Task Management**: Create and manage tasks
- **Reminders**: Set time-based reminders
- **Notes**: Save quick notes and thoughts
- **Gym Logging**: Track workouts and exercises
- **Dark Mode**: Toggle between light and dark themes

## Setup

### API Key Configuration

This app uses the Groq API for natural language processing. You need to set up your API key:

1. **Get a Groq API key** from [https://console.groq.com/](https://console.groq.com/)
2. **Set the API key** using one of these methods:

   **Method 1: Command line**
   ```bash
   flutter run --dart-define=GROQ_API_KEY=your_actual_key_here
   ```

   **Method 2: VS Code launch configuration**
   - Open `.vscode/launch.json` (create if it doesn't exist)
   - Add the API key to the args:
   ```json
   {
     "name": "Flutter",
     "request": "launch",
     "type": "dart",
     "args": ["--dart-define=GROQ_API_KEY=your_actual_key_here"]
   }
   ```

   **Method 3: Environment variable**
   ```bash
   export GROQ_API_KEY=your_actual_key_here
   flutter run
   ```

⚠️ **Security**: Never commit your API key to version control. The key is excluded from git via `.gitignore`.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
