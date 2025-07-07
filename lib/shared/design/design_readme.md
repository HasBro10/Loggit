# Loggit Design System

## Feature Selectors (Tasks, Expenses, etc.)
- Use `FeatureCardButton` (`widgets/feature_card_button.dart`) for feature selectors at the top of screens (see chat screen design).
- These are rectangular cards with rounded corners, soft background tint, large icon in a colored circle, and dark text.
- Example usage:

```dart
FeatureCardButton(
  label: 'Tasks',
  icon: Icons.check_circle,
  iconBgColor: LoggitColors.tealDark,
  iconColor: Colors.white,
  cardColor: Color(0xFFECFDF5),
  selected: true,
  onTap: () {},
)
```

## PillButton
- Use `PillButton` (`widgets/pill_button.dart`) for compact, oval-shaped actions (not for feature selection cards).
- Example: quick filters, small actions, etc.

## Other Design Tokens
- Colors: `color_guide.dart`
- Spacing: `spacing.dart`
- Fonts: `fonts.dart`
- Shadows: `shadows.dart`

## Widgets
- `feature_card_button.dart`: Card-style feature selector (recommended for top-of-screen feature tabs)
- `pill_button.dart`: Compact, oval-shaped button for secondary actions
- `status_card.dart`: For status/summary cards (e.g., task stats)
- `header.dart`: App bar/header
- `rounded_text_input.dart`: Rounded input field

## Usage
- Always use the design system widgets and tokens for consistent UI.
- See chat screen for example of correct feature selector usage.
