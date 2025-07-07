# Shadow Fixes Documentation

## Task Cards Shadow Issue

### Problem
- Task cards had shadows that only appeared when swiping left
- Shadows were being clipped by wrapper containers (AnimatedContainer, Stack, etc.)
- Multiple nested containers were interfering with shadow rendering

### Solution
**Move shadow to the outermost wrapper container:**

```dart
// ✅ CORRECT - Shadow on outer container
GestureDetector(
  child: Container(
    margin: const EdgeInsets.only(bottom: 16),
    padding: const EdgeInsets.all(8), // Space for shadow
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.12),
          blurRadius: 12,
          offset: Offset(0, 4),
          spreadRadius: 0,
        ),
      ],
    ),
    child: Stack(
      children: [
        AnimatedContainer(
          // No shadow here - just animation
          child: buildTaskCard(...),
        ),
      ],
    ),
  ),
)
```

### Key Points
1. **Shadow on outermost container** - not on inner AnimatedContainer
2. **Adequate padding** - 8px minimum for shadow space
3. **No competing shadows** - remove shadows from inner containers
4. **Proper opacity** - 0.12 for visibility without being too strong

### When to Use
- Any card with swipe animations
- Cards wrapped in Stack/AnimatedContainer
- When shadows appear only during interactions

### Files Affected
- `lib/features/tasks/tasks_screen_new.dart` 