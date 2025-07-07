# NOTE FOR AI AND COLLABORATORS

AI: Always follow these rules for file and folder organization. When starting a new chat or session, refer to this file to remember the progress and status of the loggit project.

**IMPORTANT:** Always check off completed features in `scope/PROJECT_SCOPE.md` as we build them. This keeps track of project progress and status.

# Documentation Update Rules

## Automatic Documentation Updates

**CRITICAL:** As we develop Loggit, you MUST automatically update the scope documentation files when:

### ✅ **What to Update Automatically**
- **New features implemented** → Update `scope/CURRENT_STATUS.md`
- **Technical decisions changed** → Update `scope/TECHNICAL_GUIDE.md`
- **Design patterns added** → Update `scope/DESIGN_SYSTEM.md`
- **Priorities shifted** → Update `scope/QUICK_REFERENCE.md`
- **Progress made** → Update completion percentages and checkboxes
- **Issues resolved** → Remove from known issues list
- **New issues found** → Add to known issues list

### 📝 **Update Process**
1. **Recognize changes** during development
2. **Update relevant scope files** immediately
3. **Keep documentation current** with actual implementation
4. **Ask for confirmation** only for major vision/concept changes

### 🎯 **Scope Files to Maintain**

# Folder Structure Rules

## HTML Files

- All `.html` files should go into the `/html` folder.
- If you have multiple themes or styles, create subfolders like `/html/themes` or `/html/templates`.

## CSS Files

- Place all `.css` files into a `/css` folder.
- If you have different themes, use subfolders like `/css/themes`.

## JavaScript Files

- Store all `.js` files in a `/js` folder.
- Organize scripts by functionality if needed (e.g., `/js/utils`, `/js/components`).

## Dart Files

- Keep all Dart files in the `/lib` folder for Flutter projects.
- Use subfolders for features, models, services, etc.

## Assets

- Place images, fonts, and other assets in the `/assets` folder.
- Use subfolders like `/assets/images`, `/assets/fonts`.

## Dart Feature-based Structure (Recommended)

- Organize Dart code by feature for scalability and clarity:

```
lib/
  features/
    chat/
      chat_screen.dart
      chat_message.dart
      chat_controller.dart
    dashboard/
      dashboard_screen.dart
      summary_card.dart
    expenses/
      expense_model.dart
      expense_service.dart
  models/
  services/
  shared/
    widgets/
    utils/
    themes/
  main.dart
```

- Place all code related to a feature (screens, widgets, logic) in its own folder under `features/`.
- Use `shared/` for reusable widgets, utilities, and themes.
- Use `models/` for data models and `services/` for business logic or storage.

---

This way, Cursor will know exactly where to place each type of file, keeping your project neat and easy to navigate.

# Page Isolation Rule

- Each page must have its own widget and its own functions.
- Any logic, state, or function that is only used by a page should be defined within that page’s file or subfolder.
- Changes to one page’s code should not affect other pages unless explicitly intended (e.g., via shared widgets or services).
- Shared code should be placed in `shared/` or a dedicated shared location, and only imported where needed.
- This ensures that working on one page will not break or change the behavior of other pages.

# Page File Creation and Category Organization Rule

- Whenever a new page is created under any feature/category (e.g., chat, tasks, reminders, etc.), a new Dart file must be created for that page inside the appropriate feature/category folder.
- If a feature/category (like reminders) has multiple pages, each page must have its own file within that category's folder.
- Before creating a new file for a page, the AI will suggest a file name and ask the user to confirm or approve the name. The file will only be created after user approval.
- This ensures all pages are well organized by category, and the user has control over file naming.

# Import Organization Rule

- **Group imports** in this order: Flutter/Dart core → Third-party packages → Local imports
- **Use relative imports** for files within the same feature folder
- **Use absolute imports** for shared components and services
- **Limit import lines** - if a file has more than 10 imports, consider splitting it
- **Remove unused imports** immediately to keep code clean

# Widget Structure Rule

- **Keep widgets under 200 lines** - split large widgets into smaller components
- **Extract reusable widgets** to `shared/widgets/` when used in multiple places
- **Use const constructors** for widgets that don't change
- **Separate UI logic** from business logic - keep widgets focused on presentation
- **Name widgets descriptively** - avoid generic names like "Widget1" or "MyWidget"

# State Management Rule

- **Use StatefulWidget** only when local state is needed
- **Keep state as local as possible** - don't lift state unnecessarily
- **Use providers/services** for shared state across multiple pages
- **Dispose resources properly** - cancel timers, controllers, and streams
- **Avoid global variables** - use proper state management instead

# File Naming Convention Rule

- **Use snake_case** for all Dart files (e.g., `chat_screen.dart`, `expense_model.dart`)
- **Use descriptive names** that indicate the file's purpose
- **Add suffixes** for clarity: `_screen.dart`, `_widget.dart`, `_model.dart`, `_service.dart`
- **Group related files** with similar prefixes in the same folder
- **Avoid abbreviations** unless they're universally understood

# Error Handling Rule

- **Always handle potential errors** in async operations
- **Provide user-friendly error messages** instead of technical exceptions
- **Use try-catch blocks** for operations that might fail
- **Log errors appropriately** for debugging without exposing sensitive data
- **Graceful degradation** - app should continue working even if some features fail

# Code Comment Rule

- **Comment complex business logic** - explain the "why" not the "what"
- **Document public APIs** with clear descriptions
- **Use TODO comments** for future improvements with clear context
- **Remove outdated comments** when code changes
- **Keep comments concise** and up-to-date with the code

# Performance Rule

- **Use const constructors** wherever possible
- **Implement proper list views** with `ListView.builder` for large lists
- **Optimize image loading** with proper sizing and caching
- **Minimize widget rebuilds** by using appropriate state management
- **Profile regularly** to identify performance bottlenecks

# Development Rules

## Dependency Management

**CRITICAL:** Before implementing any new feature, you MUST:
1. **Check dependencies** - Identify what other features/components are needed
2. **Suggest implementation order** - Recommend the sequence for building features
3. **Warn about missing dependencies** - Alert if prerequisites aren't met
4. **Consider integration points** - Think about how features connect

## Code Quality Standards

- **Follow Flutter best practices** for widget structure and state management
- **Use meaningful variable and function names** that clearly describe their purpose
- **Add comments** for complex logic or business rules
- **Keep functions focused** - single responsibility principle
- **Handle errors gracefully** with proper error boundaries and user feedback

## UI/UX Consistency

- **Follow the established design system** in `scope/DESIGN_SYSTEM.md`
- **Use consistent spacing, colors, and typography** from the design guide
- **Maintain responsive design** for different screen sizes
- **Ensure accessibility** with proper contrast ratios and screen reader support
- **Test user flows** to ensure intuitive navigation

## Testing Requirements

- **Write unit tests** for business logic and services
- **Add widget tests** for UI components
- **Test edge cases** and error scenarios
- **Verify integration** between features
- **Update tests** when features change

## Performance Considerations

- **Optimize widget rebuilds** with proper state management
- **Use efficient data structures** for large datasets
- **Implement lazy loading** for lists and grids

# Documentation and Troubleshooting Rule

## Notes Folder Documentation

**CRITICAL:** When encountering and solving difficult technical issues, you MUST:

### ✅ **What to Document**
- **Complex UI problems** (shadows, animations, layout issues)
- **Performance bottlenecks** and their solutions
- **Integration challenges** between features
- **Platform-specific issues** (iOS/Android/Web differences)
- **Third-party library conflicts** and resolutions
- **State management problems** and fixes
- **Design system inconsistencies** and solutions

### 📝 **Documentation Process**
1. **Identify the problem** - describe what wasn't working
2. **Explain the solution** - detail how it was fixed
3. **Provide code examples** - show the working implementation
4. **List key points** - important details to remember
5. **Note when to use** - scenarios where this fix applies
6. **Reference affected files** - which files were changed

### 🎯 **File Organization**
- **Create notes in `/notes/` folder**
- **Use descriptive filenames** (e.g., `SHADOW_FIXES.md`, `ANIMATION_ISSUES.md`)
- **Group related fixes** in the same file
- **Update existing notes** when solutions improve

### 🔄 **Maintenance**
- **Reference notes first** when similar issues arise
- **Update notes** when better solutions are found
- **Remove outdated solutions** to avoid confusion
- **Cross-reference** between related notes

**Example:** Shadow clipping issues → Document in `/notes/SHADOW_FIXES.md` with exact solution pattern
- **Minimize memory usage** with proper disposal of resources
- **Profile performance** on target devices

## Git Workflow

- **Create feature branches** for new development
- **Write descriptive commit messages** that explain the change
- **Test thoroughly** before merging to main
- **Update documentation** with code changes
- **Review dependencies** before pushing changes

---

These rules ensure consistent, maintainable, and high-quality code development for the Loggit project. 