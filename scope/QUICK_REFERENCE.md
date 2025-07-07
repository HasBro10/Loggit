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

## �� Common Development Tasks

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