# Loggit Technical Guide

**Architecture, Patterns, and Development Guidelines**

---

## 🏗️ Technical Architecture

### **Project Structure**
```
lib/
├── features/           # Feature-based organization
│   ├── chat/          # Chat interface (main UI)
│   ├── dashboard/     # Main dashboard
│   ├── expenses/      # Expense management
│   ├── tasks/         # Task management (most complete)
│   ├── reminders/     # Reminder management
│   ├── notes/         # Notes management
│   └── gym/           # Gym log management
├── models/            # Data models and interfaces
├── services/          # Business logic (parsing, storage)
├── shared/            # Reusable components
│   ├── design/        # Design system (colors, spacing, widgets)
│   └── utils/         # Utilities
└── main.dart          # App entry point
```

### **Key Design Patterns**
- **Feature-based Architecture** - Each log type has its own feature folder
- **Shared Design System** - Consistent colors, spacing, and components
- **Service Layer** - Business logic separated from UI
- **Model-driven Development** - Strong typing with JSON serialization

### **State Management**
- **Simple setState** - Using Flutter's built-in state management
- **Local Storage** - SharedPreferences for data persistence
- **No external libraries** - Keeping it simple for MVP

### **Dependencies**
```yaml
dependencies:
  flutter: sdk: flutter
  cupertino_icons: ^1.0.8
  shared_preferences: ^2.2.2  # Local storage
```

---

## 💬 Chat-Driven Interface Architecture

### **Core Concept**
The chat interface is the primary way users interact with Loggit. Natural language input gets parsed into structured data.

### **Parsing Flow**
1. **User Input** → Text message in chat
2. **Parser Service** → `log_parser_service.dart` analyzes text
3. **Log Detection** → Determines log type and extracts data
4. **Confirmation** → Shows user what was detected
5. **Save/Cancel** → User confirms or cancels
6. **Storage** → Data saved to appropriate location

### **Parser Examples** (`log_parser_service.dart`)
```dart
// Expenses
"Coffee £3.50" → Expense(category: "Coffee", amount: 3.50)

// Tasks  
"Task: Call client tomorrow at 3pm" → Task(title: "Call client", dueDate: tomorrow, timeOfDay: 15:00)

// Reminders
"Remind me to buy milk" → Reminder(title: "buy milk", reminderTime: calculated)

// Notes
"Note: Client prefers phone calls" → Note(content: "Client prefers phone calls")

// Gym Logs
"Squats 80kg x 5 reps" → GymLog(exercises: [Exercise(name: "Squats", weight: 80, reps: 5)])
```

### **Confirmation Workflow**
```dart
// 1. Parse message
final logEntry = LogParserService.parseMessage(message);

// 2. Show confirmation
final confirmationMessage = _getConfirmationMessage(logEntry);

// 3. Handle response
onConfirmationResponse: (confirmed, [updatedLogEntry]) =>
    _handleLogConfirmation(confirmed, updatedLogEntry)
```

---

## 📊 Data Models Architecture

### **Common Interface**
All models implement `LogEntry` interface:
```dart
abstract class LogEntry {
  String get displayTitle;
  String get logType;
  DateTime get timestamp;
  String? get category;
}
```

### **Model Hierarchy**
```dart
// Base interface
LogEntry

// Implementations
├── Expense (simple)
├── Task (complex)
├── Reminder (simple)
├── Note (simple)
└── GymLog (complex)
```

### **Task Model** - Most Complex
```dart
class Task implements LogEntry {
  final String title;
  final String? description;
  final DateTime? dueDate;
  final TaskPriority priority;      // High/Medium/Low
  final TaskStatus status;          // Not Started/In Progress/Completed
  final ReminderType reminder;      // None/15min/1hr/1day
  final RecurrenceType recurrence;  // None/Daily/Weekly/Monthly
  final TimeOfDay? timeOfDay;
  // ... other fields
}
```

### **Serialization Pattern**
All models support JSON serialization:
```dart
// Save
Map<String, dynamic> toJson()

// Load
factory Model.fromJson(Map<String, dynamic> json)
```

---

## 🔧 Development Guidelines

### **Adding New Features**
1. **Follow Feature Structure** - Add to appropriate feature folder
2. **Update Parser** - Add parsing logic to `log_parser_service.dart`
3. **Create UI** - Follow design system patterns
4. **Add Storage** - Implement save/load functionality
5. **Test Thoroughly** - Manual testing for edge cases

### **Code Style**
- **Feature-based organization** - Keep related code together
- **Strong typing** - Use proper types and enums
- **Consistent naming** - camelCase variables, PascalCase classes
- **Documentation** - Comment complex parsing logic

### **UI/UX Patterns**
- **Confirmation prompts** - Always confirm before saving
- **Progressive disclosure** - Show advanced options when needed
- **Consistent feedback** - Loading states, success messages
- **Accessibility** - Proper contrast, readable text sizes

### **Common Patterns**

#### **Adding a New Log Type**
```dart
// 1. Create model
class NewLog implements LogEntry {
  // ... properties
  @override
  String get logType => 'newlog';
}

// 2. Add to parser
static NewLog? _parseNewLog(String message) {
  // ... parsing logic
}

// 3. Add to confirmation
case 'newlog':
  return "Log new entry: ${newLog.title}?";
```

#### **Creating a Dashboard Screen**
```dart
// Follow the pattern from tasks_screen_new.dart
class NewDashboard extends StatefulWidget {
  final VoidCallback onBack;
  // ... constructor
}

// Include proper theming and responsive design
```

#### **Storage Pattern**
```dart
// Save
final prefs = await SharedPreferences.getInstance();
final jsonList = items.map((item) => json.encode(item.toJson())).toList();
await prefs.setStringList('items', jsonList);

// Load
final jsonList = prefs.getStringList('items') ?? [];
items.clear();
for (final jsonString in jsonList) {
  final jsonMap = json.decode(jsonString);
  items.add(Model.fromJson(jsonMap));
}
```

---

## 🎯 Future Technical Considerations

### **Phase 3: Business Features**
- **Multi-business profiles** - Separate data storage
- **Receipt storage** - File upload and management
- **Export functionality** - CSV/PDF generation
- **Cloud sync** - Supabase integration

### **Phase 4: AI & Smart Features**
- **Smart categorization** - ML-based suggestions
- **Conversational analytics** - Natural language queries
- **Predictive insights** - Trend analysis
- **Voice input** - Speech-to-text integration

### **Phase 5: Advanced Features**
- **Multi-currency** - Currency conversion and display
- **Push notifications** - Local notification system
- **Offline support** - Sync when online
- **Team collaboration** - Shared logs and permissions

---

**Last Updated**: Current session - Task management system nearly complete
```

```markdown:scope/DESIGN_SYSTEM.md
# Loggit Design System

**Colors, Components, and UI/UX Patterns**

---

##  Color Palette

### **Primary Brand Colors**
```dart
// From color_guide.dart
LoggitColors.teal        // Tasks, FAB, primary actions
LoggitColors.tealDark    // Active teal states
LoggitColors.indigo      // Expenses, financial data
LoggitColors.indigoLight // Expense card backgrounds
```

### **Status Colors**
```dart
// Task Status Colors
LoggitColors.pendingTasksBg    // Orange background for pending
LoggitColors.pendingTasksText  // Orange text for pending
LoggitColors.completedTasksBg  // Green background for completed
LoggitColors.completedTasksText // Green text for completed

// Other Status Colors
LoggitColors.expensesBg        // Indigo background for expenses
LoggitColors.expensesText      // Indigo text for expenses
LoggitColors.remindersBg       // Red background for reminders
LoggitColors.remindersText     // Red text for reminders
```

### **Background Colors**
```dart
// Light Mode
LoggitColors.lightGray         // General background
LoggitColors.pureWhite         // Chat/cards background

// Dark Mode (ChatGPT-inspired)
LoggitColors.darkBg            // Main background
LoggitColors.darkCard          // Card/sheet backgrounds
LoggitColors.darkUserBubble    // User chat bubble
```

### **Text Colors**
```dart
// Light Mode
LoggitColors.darkGrayText      // Main text
LoggitColors.lighterGraySubtext // Subtext

// Dark Mode
LoggitColors.darkText          // Primary text
LoggitColors.darkSubtext       // Subtle text
```

### **Utility Colors**
```dart
LoggitColors.divider           // Dividers and borders
LoggitColors.mediumShadow      // Card shadows
LoggitColors.softShadow        // Subtle shadows
```

---

## 🧩 Component Library

### **FeatureCardButton**
**Purpose**: Main navigation buttons for different log types
**Usage**: Dashboard and main navigation
**Styling**: Rounded corners, status-based colors, consistent sizing

### **StatusCard**
**Purpose**: Display status information with color coding
**Usage**: Task status, expense summaries
**Styling**: Background color based on status, rounded corners

### **Header**
**Purpose**: Screen headers with back navigation
**Usage**: All dashboard screens
**Styling**: Consistent typography, back button, title

### **PillButton**
**Purpose**: Small action buttons
**Usage**: Priority selection, quick actions
**Styling**: Pill shape, consistent padding, status colors

### **RoundedTextInput**
**Purpose**: Consistent input styling
**Usage**: Forms and search fields
**Styling**: Rounded corners, subtle background, consistent padding

---

## 📐 Spacing System

### **Spacing Tokens** (`spacing.dart`)
```dart
// Base spacing unit: 8px
Spacing.xs    // 4px
Spacing.sm    // 8px
Spacing.md    // 16px
Spacing.lg    // 24px
Spacing.xl    // 32px
Spacing.xxl   // 48px
```

### **Usage Guidelines**
- **Margins**: Use spacing tokens for consistent margins
- **Padding**: Apply consistent padding to components
- **Gaps**: Use spacing tokens for gaps between elements
- **Grid**: 8px grid system for alignment

---

## 🎭 Design Principles

### **1. ChatGPT-Inspired Dark Mode**
- **Familiar Interface**: Users recognize the dark theme pattern
- **Subtle Contrasts**: Not harsh black/white contrasts
- **Comfortable Reading**: Easy on the eyes for extended use

### **2. Consistent Spacing**
- **8px Grid System**: All spacing based on 8px increments
- **Visual Rhythm**: Consistent spacing creates visual hierarchy
- **Clean Layout**: Proper spacing reduces visual clutter

### **3. Rounded Corners**
- **12px Border Radius**: Modern, friendly appearance
- **Consistent Application**: All cards, buttons, inputs use same radius
- **Soft Edges**: Creates approachable, modern feel

### **4. Subtle Shadows**
- **Light Shadows**: Depth without overwhelming
- **Consistent Elevation**: Cards and elevated elements
- **Material Design**: Follows Material Design principles

### **5. Status-Based Colors**
- **Visual Feedback**: Different colors for different states
- **Intuitive Understanding**: Users quickly understand status
- **Consistent Application**: Same colors across all log types

---

## 🎨 UI/UX Patterns

### **Confirmation Workflow**
```dart
// Pattern: Always confirm before saving
"Log expense: £3.50 for Coffee?"
[Yes] [No]
```

### **Progressive Disclosure**
- **Simple First**: Show basic options initially
- **Advanced Later**: Reveal advanced options when needed
- **Clean Interface**: Don't overwhelm users with all options

### **Status Indicators**
- **Color Coding**: Use consistent colors for status
- **Visual Hierarchy**: Status should be immediately visible
- **Consistent Application**: Same patterns across all log types

### **Form Design**
- **Rounded Inputs**: Consistent with overall design
- **Subtle Backgrounds**: Light backgrounds for input fields
- **Clear Labels**: Descriptive labels for all fields
- **Validation Feedback**: Clear error states

### **Button Design**
- **Consistent Sizing**: Same size for similar actions
- **Status Colors**: Use appropriate colors for actions
- **Clear Hierarchy**: Primary vs secondary actions
- **Touch Targets**: Adequate size for mobile interaction

---

## 🌙 Dark Mode Implementation

### **Theme Configuration**
```dart
// Light Theme
ThemeData(
  brightness: Brightness.light,
  scaffoldBackgroundColor: Colors.transparent,
  // ... other light theme settings
)

// Dark Theme
ThemeData(
  brightness: Brightness.dark,
  scaffoldBackgroundColor: LoggitColors.darkBg,
  // ... other dark theme settings
)
```

### **Color Adaptation**
- **Automatic Switching**: Colors adapt based on theme
- **Consistent Contrast**: Maintain readability in both modes
- **Status Colors**: Adapt appropriately for dark mode

### **Component Adaptation**
- **Cards**: Dark backgrounds in dark mode
- **Text**: Proper contrast in both modes
- **Shadows**: Adjusted for dark mode visibility

---

## 📱 Responsive Design

### **Screen Sizes**
- **Mobile First**: Designed for mobile devices
- **Tablet Support**: Responsive layouts for larger screens
- **Consistent Experience**: Same functionality across devices

### **Touch Targets**
- **Minimum Size**: 44px for touch targets
- **Adequate Spacing**: Prevent accidental taps
- **Clear Feedback**: Visual feedback for interactions

### **Typography**
- **Readable Sizes**: Minimum 14px for body text
- **Hierarchy**: Clear typography hierarchy
- **Consistent Fonts**: Use system fonts for performance

---

**Last Updated**: Current session - Design system established and implemented
```

```markdown:scope/QUICK_REFERENCE.md
# Loggit Quick Reference

**Key Files, Commands, and Immediate Next Steps**

---

## 📁 Key Files

### **Core Application**
- **Main App**: `lib/main.dart` - App configuration, themes, navigation
- **Chat Interface**: `lib/features/chat/chat_screen_new.dart` - Primary UI (1410 lines)
- **Tasks Screen**: `lib/features/tasks/tasks_screen_new.dart` - Most complete feature (2268 lines)
- **Dashboard**: `lib/features/dashboard/dashboard_screen.dart` - Overview screen

### **Design System**
- **Colors**: `lib/shared/design/color_guide.dart` - All color definitions
- **Spacing**: `lib/shared/design/spacing.dart` - Spacing tokens
- **Components**: `lib/shared/design/widgets/` - Reusable UI components

### **Data & Logic**
- **Parser Service**: `lib/services/log_parser_service.dart` - Message parsing logic (343 lines)
- **Task Model**: `lib/features/tasks/task_model.dart` - Most complex data model (169 lines)
- **Other Models**: `lib/features/*/model.dart` - Expense, Reminder, Note, GymLog

### **Configuration**
- **Dependencies**: `pubspec.yaml` - Flutter dependencies
- **Project Scope**: `scope/PROJECT_SCOPE.md` - Long-term planning
- **Current Status**: `scope/CURRENT_STATUS.md` - What's built

---

##  Common Development Tasks

### **Adding a New Log Type**
1. Create model in `lib/features/newtype/newtype_model.dart`
2. Add parsing logic to `lib/services/log_parser_service.dart`
3. Create UI components following design system
4. Add to main navigation in `lib/main.dart`
5. Implement storage logic

### **Creating a New Dashboard Screen**
1. Follow pattern from `tasks_screen_new.dart`
2. Use shared components from `lib/shared/design/widgets/`
3. Implement proper theming and responsive design
4. Add navigation from main app

### **Updating Design System**
1. Modify `lib/shared/design/color_guide.dart` for colors
2. Update `lib/shared/design/spacing.dart` for spacing
3. Create new components in `lib/shared/design/widgets/`
4. Update existing screens to use new components

### **Testing Data Persistence**
1. Check `lib/main.dart` for save/load logic
2. Test with SharedPreferences
3. Verify JSON serialization in models
4. Test edge cases and error handling

---

## 🚨 Known Issues

### **Current Problems**
- **Task completion** - UI exists but logic not implemented
- **Data persistence** - Some new task fields may not save properly
- **Other dashboards** - Reminders, Notes, Gym logs screens not built
- **Import missing** - FeatureCardButton import issue in tasks_screen_new.dart

### **Workarounds**
- **Task completion**: Need to implement toggle logic in tasks screen
- **Data persistence**: Test save/load for all new fields
- **Missing screens**: Build following tasks screen pattern
- **Import issue**: Add import for FeatureCardButton

---

## ⚡ Immediate Next Steps

### **Priority 1: Complete Task Management**
1. **Implement task completion** in `tasks_screen_new.dart`
2. **Add task deletion** functionality
3. **Test data persistence** for all task fields
4. **Fix any UI inconsistencies**

### **Priority 2: Build Other Dashboards**
1. **Create Reminders screen** following tasks pattern
2. **Create Notes screen** with list and editing
3. **Create Gym logs screen** with exercise tracking
4. **Ensure consistent UI** across all screens

### **Priority 3: Polish & Testing**
1. **Test parsing edge cases** in `log_parser_service.dart`
2. **Verify dark/light mode** on all screens
3. **Test data integrity** across app restarts
4. **Fix any remaining bugs**

---

## 🎯 Quick Commands

### **Flutter Commands**
```bash
# Run the app
flutter run

# Get dependencies
flutter pub get

# Clean and rebuild
flutter clean && flutter pub get

# Check for issues
flutter analyze
```

### **Common Code Patterns**

#### **Save Data**
```dart
final prefs = await SharedPreferences.getInstance();
final jsonList = items.map((item) => json.encode(item.toJson())).toList();
await prefs.setStringList('items', jsonList);
```

#### **Load Data**
```dart
final prefs = await SharedPreferences.getInstance();
final jsonList = prefs.getStringList('items') ?? [];
items.clear();
for (final jsonString in jsonList) {
  final jsonMap = json.decode(jsonString);
  items.add(Model.fromJson(jsonMap));
}
```

#### **Add to Parser**
```dart
static NewLog? _parseNewLog(String message) {
  // Add parsing logic here
  return NewLog(...);
}
```

---

## 📊 Current Status Summary

- **Phase 1 (Expenses)**: ✅ Complete
- **Phase 2 (Multi-Log)**: 🔄 70% Complete
  - Foundation: ✅ Complete
  - Tasks: 🔄 95% Complete
  - Other Dashboards: ⏳ Not Started
- **Overall**: ~85% of MVP features complete

---

## 🔗 Related Documentation
- **Current Status**: `scope/CURRENT_STATUS.md` - Detailed implementation status
- **Technical Guide**: `scope/TECHNICAL_GUIDE.md` - Architecture and patterns
- **Design System**: `scope/DESIGN_SYSTEM.md` - UI/UX guidelines
- **Project Scope**: `scope/PROJECT_SCOPE.md` - Long-term planning

---

**Last Updated**: Current session - Task management system nearly complete
```

```markdown:scope/CONCEPT_OVERVIEW.md
# Loggit – Concept & Functional Overview

**The Ultimate Chat-Driven Personal & Business Logging Assistant**

---

## 1. Vision & Goal

Loggit is a mobile app designed to be the ultimate chat-driven personal and business logging assistant. Its core mission is:

**To simplify the way individuals and small businesses record, track, and analyze daily activities and business data, using natural language conversations.**

Instead of dealing with multiple apps for notes, expenses, reminders, or fitness logs, users can simply type a message like chatting to an assistant, and Loggit understands and organizes the information automatically.

---

## 2. Core Concept: Chat-Driven Logging

At the heart of Loggit is a chat UI. Users type natural, conversational messages to log:

- **Expenses**
- **Tasks**
- **Reminders**
- **Notes**
- **Gym logs**
- **Other specialized logs in the future**

### Example Inputs:
```
Coffee £3.50
Meeting with John tomorrow at 2pm
Remind me to renew car insurance next week
Bench press 80kg x 5 reps
```

### How It Works:
1. **User types message** → Natural language input
2. **Loggit parses text** → Detects log type and extracts data
3. **App confirms** → Shows what it detected
4. **User confirms** → "Log expense: £3.50 for Coffee? Yes/No"
5. **Data stored** → Saved in appropriate section

---

## 3. Key Log Types & Features

### A. Expenses
**Purpose**: Track personal or business spending quickly.

**Features**:
- Recognizes currency amounts in text (e.g. £, $, €)
- Suggests categories automatically (e.g. "Coffee" → Dining)
- Confirms logs before saving
- Displays total spend, graphs & trends, recent expenses list

**Future Support**:
- Multi-currency
- Business vs personal mode
- Receipt upload (premium)
- Exports (CSV, PDF)

**Example Input**: `Groceries £42.80`

### B. Tasks
**Purpose**: Manage personal or business to-do lists via chat.

**Features**:
- Understands tasks, due dates, optional reminders
- Allows marking tasks complete, editing tasks
- Dashboard shows upcoming tasks, overdue tasks, completed tasks

**Example Input**: `Finish project report by Friday`

### C. Reminders
**Purpose**: Set quick reminders without needing a separate app.

**Features**:
- Recognizes time, day, or date references
- Sends push notifications
- Allows editing reminder time, marking reminders as done

**Example Input**: `Remind me to call Dad at 6pm`

### D. Notes
**Purpose**: Keep personal or business notes organized.

**Features**:
- Quick note capture via chat
- Categorization (e.g. Work, Ideas, Health)
- Searchable notes dashboard

**Future Features**:
- Tags
- AI summaries

**Example Input**: `Note: Check out new supplier for coffee beans.`

### E. Gym Logs
**Purpose**: Track fitness progress conversationally.

**Features**:
- Understands exercises, weight lifted, sets and reps
- Dashboards show workout history, personal bests, trends over time

**Example Input**: `Deadlift 100kg x 5 reps`

---

## 4. Premium / Business Features

### Core Business Features:
- **Personal vs business mode toggle**
- **Business-specific expense categories**
- **Multi-business profiles**
- **Profit & Loss reports**
- **Receipt photo storage**

### Export Capabilities:
- **CSV exports**
- **PDF reports**
- **ZIP archive** (receipts, data)

### Advanced Features:
- **Predictive analytics** (future phase)
- **Unlimited logs** (free plan limits logs)

---

## 5. AI & Smart Features (Future Phase)

### Smart Categorization:
- "Lunch £15" → Dining

### Conversational Analytics:
- "How much did I spend on dining last month?"

### Intelligent Insights:
- Reminders and task insights
- Suggest prioritizing overdue tasks
- Predictive spending insights
- Forecasting trends

---

## 6. Technical & Platform Details

### Platform:
- **Flutter mobile app**

### Backend:
- **Supabase**
  - Authentication
  - Data sync
  - Storage (receipts, files)

### Security Features:
- **PIN lock**
- **Biometric login**
- **Dark mode support**
- **Push notifications**
- **Multi-currency support**

### Guest Mode:
- **Log without account**
- **Upgrade for premium features**

---

## 7. UI & UX Overview

### Chat UI:
- **Core input screen**
- **Sends and receives chat bubbles**
- **Recognizes typed logs automatically**
- **Shows confirmation prompts**: "Log expense: £3.50 for Coffee?"

### Dashboards:
Each log type has its own dashboard:
- **Expenses**: Totals, charts, recent logs
- **Tasks**: Upcoming, overdue, completed lists
- **Reminders**: Active reminders
- **Notes**: List of notes, search function
- **Gym Logs**: Graphs of workouts, history

### Navigation:
- **Chat tab**
- **Dashboard tab**
- **Settings tab**
- **Premium / business toggle**

---

## 8. Goals & Differentiation

Loggit aims to:

✅ **Be faster than traditional apps** for logging small daily data
✅ **Reduce friction** — no forms or complicated inputs
✅ **Be a single app for multiple log types**
✅ **Cater to individuals and small businesses**
✅ **Use conversational AI** for intelligent suggestions and analysis
✅ **Help users keep their life and business organized** without mental clutter

---

## 9. Sample User Scenarios

### Scenario 1 – Personal User
**Emma types**: "Petrol £45"

→ **Loggit parses it**:
- Category: Petrol
- Amount: £45

→ **Prompts for confirmation**: "Log expense: £45 for Petrol? Yes/No"

→ **Emma taps Yes**. Expense is saved and visible in her expense dashboard.

### Scenario 2 – Small Business User
**Mark types**: "New client meeting on Monday at 11am"

→ **Loggit logs it as**:
- Task: New client meeting
- Date: Monday at 11am

→ **Appears in tasks dashboard** under upcoming tasks.

### Scenario 3 – Gym Tracking
**Ali types**: "Squats 90kg x 5 reps"

→ **Loggit logs**:
- Exercise: Squats
- Weight: 90kg
- Reps: 5

→ **Adds to gym dashboard** and updates personal records.

### Scenario 4 – Reminder
**Nina types**: "Remind me to send invoice next Thursday."

→ **Loggit schedules**:
- Reminder title: Send invoice
- Date: Next Thursday

→ **Push notification sent** at chosen time.

---

## 10. Future Roadmap

### Phase 1: Core Features ✅
- Chat-driven logging for all types
- Basic dashboards
- Local storage

### Phase 2: Enhanced Features 🔄
- Task completion and management
- Advanced filtering and search
- Data persistence improvements

### Phase 3: Business Features 📋
- Business mode toggle
- Multi-business profiles
- Receipt storage
- Export functionality

### Phase 4: AI & Smart Features 🚀
- Voice input for logs
- AI-driven insights and reports
- Smart search across all log types
- Predictive analytics

### Phase 5: Platform Expansion 🌐
- Web and desktop versions
- Social / collaborative logs (e.g. team tasks)
- Custom log types (e.g. moods, medication)

---

## Summary

**Loggit is not just a note-taking app or an expense tracker—it's a unified digital memory for life and business, driven by simple conversational input.**

It aims to save users time, reduce mental load, and deliver powerful insights by transforming chat messages into structured, searchable data. By making logging as simple as having a conversation, Loggit becomes the central hub for all personal and business organization needs.

---

**Last Updated**: Current session - Core concept and vision established
```

```markdown:scope/CURRENT_STATUS.md
# Loggit Current Status

**What's Actually Built vs What's Planned**

---

## ✅ **Phase 1: Expenses MVP** - COMPLETE

### **Core Infrastructure**
- ✅ Flutter project setup with proper folder structure
- ✅ Dark/Light theme switching with ChatGPT-inspired dark mode
- ✅ Local storage using SharedPreferences
- ✅ Responsive design system with custom colors and spacing

### **Chat-Driven Interface**
- ✅ **Chat Screen** (`chat_screen_new.dart`) - Main interface with:
  - Animated typing effect for suggested actions
  - Message parsing for all log types
  - Confirmation prompts with Yes/No buttons
  - Auto-scrolling chat interface
- ✅ **Log Parser Service** (`log_parser_service.dart`) - Handles:
  - Expense parsing: "Coffee £3.50"
  - Task parsing: "Task: Call client tomorrow at 3pm"
  - Reminder parsing: "Remind me to buy milk"
  - Note parsing: "Note: Client prefers calls"
  - Gym log parsing: "Squats 3 sets x 10 reps"

### **Data Models** (All Implemented)
- ✅ **Expense Model** - Amount, category, timestamp
- ✅ **Task Model** - Title, description, due date, priority, status, reminders, recurrence
- ✅ **Reminder Model** - Title, reminder time
- ✅ **Note Model** - Content, timestamp
- ✅ **Gym Log Model** - Exercises with sets, reps, weight

### **UI Components**
- ✅ **Dashboard Screen** - Shows total expenses and recent logs
- ✅ **Tasks Screen** (`tasks_screen_new.dart`) - Full task management with:
  - Task creation/editing modal
  - Priority chips (High/Medium/Low)
  - Status dropdown (Not Started/In Progress/Completed)
  - Category selection
  - Date/time pickers with future-only restrictions
  - Reminder options
  - Search and filtering
  - Sorting by due date, priority, category
- ✅ **Shared Design System**:
  - Color guide (`color_guide.dart`) - Consistent color tokens
  - Spacing system (`spacing.dart`) - Consistent margins/padding
  - Custom widgets: FeatureCardButton, Header, StatusCard, PillButton

### **Storage & State Management**
- ✅ Local storage for all log types
- ✅ Data persistence across app sessions
- ✅ State management using setState (simple but effective)

---

##  **Phase 2: Multi-Log MVP** - IN PROGRESS

### ✅ **Completed**
- ✅ All data models implemented
- ✅ Chat parsing for all log types
- ✅ Confirmation prompts for all log types
- ✅ **Tasks Dashboard** - Fully functional with comprehensive editing

### ⏳ **In Progress / Recently Completed**
- ✅ Task editing modal with comprehensive fields
- ✅ Status-based UI styling (white/orange/teal backgrounds)
- ✅ Button sizing and layout improvements
- ✅ Category dropdown text styling fixes

### 📋 **Not Yet Implemented**
- [ ] **Task completion functionality** - UI exists but logic needs implementation
- [ ] **Task deletion** - Not yet implemented
- [ ] **Other dashboard screens**:
  - [ ] Reminders dashboard
  - [ ] Notes dashboard
  - [ ] Gym logs dashboard
- [ ] **Data persistence testing** - Some new fields may not save properly

---

## 📊 **Implementation Details**

### **Current Data Models**
All models implement `LogEntry` interface:
- **Expense**: Simple amount + category
- **Task**: Complex with priority, status, reminders, recurrence
- **Reminder**: Title + reminder time
- **Note**: Content + timestamp
- **GymLog**: Exercises with sets, reps, weight

### **Current UI State**
- **Chat Interface**: Fully functional with parsing and confirmation
- **Tasks Screen**: Most complete feature with comprehensive editing
- **Dashboard**: Basic overview of all logs
- **Other Screens**: Not yet built

### **Current Storage**
- **Local Storage**: SharedPreferences for all log types
- **Data Persistence**: Saves and loads on app start
- **No Cloud Sync**: Local-only for MVP

---

## 🎯 **Immediate Next Priorities**

### **Priority 1: Complete Task Management**
1. [ ] Implement task completion functionality
2. [ ] Add task deletion capability
3. [ ] Test and fix data persistence for all task fields
4. [ ] Ensure all task features work properly

### **Priority 2: Build Other Dashboards**
1. [ ] Create Reminders dashboard screen
2. [ ] Create Notes dashboard screen
3. [ ] Create Gym logs dashboard screen
4. [ ] Ensure consistent UI/UX across all screens

### **Priority 3: Polish & Testing**
1. [ ] Fix any UI inconsistencies
2. [ ] Test edge cases in parsing
3. [ ] Ensure data integrity across all log types
4. [ ] Test dark/light mode on all screens

---

##  **Progress Summary**

- **Phase 1 (Expenses)**: 100% Complete ✅
- **Phase 2 (Multi-Log)**: ~70% Complete 🔄
  - Foundation: 100% ✅
  - Tasks Dashboard: 95% ✅
  - Other Dashboards: 0% ⏳
  - Polish & Testing: 50% 

**Overall Project**: ~85% of MVP features complete

---

**Last Updated**: Current session - Task management system nearly complete
```
