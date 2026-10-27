# Custom Widgets Documentation

## CustomAppBar

**File:** `lib/core/widgets/custom_app_bar.dart`

### Description

A reusable AppBar widget used across application screens. It supports a title, optional subtitle, and two optional icons with independent callbacks.

### Properties

| Property | Type | Required | Description |
|---|---|---|---|
| `title` | `String` | Yes | Main AppBar title |
| `subtitle` | `String?` | No | Text displayed below the title |
| `leading` | `IconData?` | No | Right icon in RTL layout |
| `action` | `IconData?` | No | Left icon in RTL layout |
| `onLeadingPressed` | `VoidCallback?` | No | Leading icon click callback |
| `onActionPressed` | `VoidCallback?` | No | Action icon click callback |

### Usage

Import the widget:

```dart
import 'package:sijil/core/widgets/custom_app_bar.dart';
```

Use it inside a Scaffold:

```dart
Scaffold(
  appBar: CustomAppBar(
    title: 'الأسر',
    subtitle: 'حي النور · نطاقك المكلف به',
    leading: Icons.tune,
    action: Icons.notifications_outlined,
    onLeadingPressed: () {
      // Open filters
    },
    onActionPressed: () {
      // Open notifications
    },
  ),
  body: const SizedBox(),
)
```

### Notes

- The title is required; all other properties are optional.
- In RTL mode, `leading` appears on the right and `action` on the left.
- Icons remain visible even when no callback is provided.
- Icons without callbacks are not interactive.
- Colors are defined centrally in `AppColors`.
- The preferred AppBar height is 80 logical pixels.