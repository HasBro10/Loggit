# Loggit Design System

**Colors, Components, and UI/UX Patterns**

---

## �� Color Palette

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