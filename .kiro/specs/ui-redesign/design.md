# Design Document

## Overview

This design document outlines the rapid 1-hour implementation of GigWork App's visual-only redesign following Rework.md v5.0 specifications. The design focuses on three critical components: global theme system, JobCard refactoring, and analytics screen simplification. MCP servers will be leveraged throughout for faster, error-free development with real-time validation and documentation lookup.

## Architecture

### Rapid Implementation Strategy

The design follows a streamlined 3-phase approach optimized for speed:

1. **Foundation Phase (15 minutes)**: Replace color palette, add dependencies, update global theme
2. **Component Phase (35 minutes)**: Refactor JobCard, BottomNavigationBar, and analytics screen
3. **Validation Phase (10 minutes)**: Test functionality and visual consistency using MCP diagnostic tools

### MCP Server Integration Points

- **Documentation Lookup**: Use MCP servers for Flutter/Dart API references
- **Code Validation**: Real-time syntax and best practice checking
- **Theme Consistency**: Automated verification of design system adherence
- **Error Prevention**: Proactive issue detection during implementation

## Components and Interfaces

### Exact Color Palette Implementation

**Complete replacement for lib/utils/app_colors.dart:**

```dart
import 'package:flutter/material.dart';

class AppColors {
  static const Color background = Color(0xFF000404);
  static const Color surface = Color(0xFF1A1A1A);
  static const Color primaryAccent = Color(0xFFFF2E00);
  static const Color textPrimary = Color(0xFFC4C4C4);
  static const Color textSecondary = Color(0xFF8A8A8A);
  static const Color textOnAccent = Color(0xFFFFFFFF);
  static const Color icon = Color(0xFFC4C4C4);
  static const Color iconActive = Color(0xFFFF2E00);
  static const Color border = Color(0xFF2C2C2C);
}
```

### Global Theme Configuration

**Exact ThemeData for lib/main.dart:**

```dart
theme: ThemeData(
  brightness: Brightness.dark,
  scaffoldBackgroundColor: AppColors.background,
  primaryColor: AppColors.primaryAccent,
  fontFamily: GoogleFonts.poppins().fontFamily,
  textTheme: const TextTheme(
    headline1: TextStyle(fontSize: 28.0, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
    headline2: TextStyle(fontSize: 22.0, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
    subtitle1: TextStyle(fontSize: 16.0, color: AppColors.textSecondary),
    bodyText1: TextStyle(fontSize: 14.0, color: AppColors.textPrimary),
    button: TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold, color: AppColors.textOnAccent),
    caption: TextStyle(fontSize: 12.0, color: AppColors.textSecondary),
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: AppColors.background,
    elevation: 0,
    iconTheme: IconThemeData(color: AppColors.icon),
  ),
  bottomNavigationBarTheme: const BottomNavigationBarThemeData(
    backgroundColor: AppColors.surface,
    selectedItemColor: AppColors.iconActive,
    unselectedItemColor: AppColors.icon,
    showUnselectedLabels: false,
    type: BottomNavigationBarType.fixed,
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: AppColors.primaryAccent,
      foregroundColor: AppColors.textOnAccent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30.0)),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
    ),
  ),
  inputDecorationTheme: InputDecorationTheme(
    hintStyle: const TextStyle(color: AppColors.textSecondary),
    filled: true,
    fillColor: AppColors.surface,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0), borderSide: const BorderSide(color: AppColors.border)),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0), borderSide: const BorderSide(color: AppColors.border)),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0), borderSide: const BorderSide(color: AppColors.primaryAccent)),
  ),
  cardTheme: CardTheme(
    color: AppColors.surface,
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16.0),
      side: const BorderSide(color: AppColors.border, width: 1.0),
    ),
  ),
);
```

### Critical Component Blueprints

#### 1. JobCard Component (Priority 1)

**Location**: All job lists (user_home_screen.dart, etc.)

**Implementation Pattern**:
```dart
Card(
  child: Padding(
    padding: const EdgeInsets.all(16.0),
    child: Row(
      children: [
        // Job Details Column
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Job Title", style: Theme.of(context).textTheme.headline2),
              const SizedBox(height: 4),
              Text("Company Name • Location", style: Theme.of(context).textTheme.caption),
            ],
          ),
        ),
        // Salary Column
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text("₹ 500/hr", style: Theme.of(context).textTheme.headline2?.copyWith(color: AppColors.primaryAccent)),
            const SizedBox(height: 4),
            Text("Full-time", style: Theme.of(context).textTheme.caption),
          ],
        ),
      ],
    ),
  ),
)
```

#### 2. Floating BottomNavigationBar (Priority 2)

**Location**: user_home_screen.dart, employee_home_screen.dart

**Implementation Pattern**:
```dart
ClipRRect(
  borderRadius: BorderRadius.circular(30.0),
  child: Padding(
    padding: const EdgeInsets.all(12.0),
    child: BottomNavigationBar(
      // Existing BottomNavigationBar properties
      // Will automatically adopt bottomNavigationBarTheme
    ),
  ),
)
```

#### 3. Analytics Screen Simplification (Priority 3)

**Location**: lib/screens/main/employye/emp_analytics.dart

**Critical Actions**:
1. **Remove all fl_chart imports and widgets**
2. **Replace with Card-based statistics**

**Implementation Pattern**:
```dart
// Replace charts with cards
Column(
  children: [
    Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text("Active Jobs", style: Theme.of(context).textTheme.subtitle1),
            const SizedBox(height: 8),
            Text("24", style: Theme.of(context).textTheme.headline1),
          ],
        ),
      ),
    ),
    Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text("Applicants", style: Theme.of(context).textTheme.subtitle1),
            const SizedBox(height: 8),
            Text("156", style: Theme.of(context).textTheme.headline1),
          ],
        ),
      ),
    ),
  ],
)
```

## Data Models

### Dependencies Required

**Add to pubspec.yaml**:
```yaml
dependencies:
  google_fonts: ^6.1.0
  eva_icons_flutter: ^3.1.0
```

### Icon Migration Pattern

**Replace throughout codebase**:
```dart
// Before
Icons.home → EvaIcons.home
Icons.search → EvaIcons.search
Icons.person → EvaIcons.person
Icons.work → EvaIcons.briefcase
Icons.chat → EvaIcons.messageCircle
```

## Error Handling

### MCP-Assisted Validation

1. **Syntax Validation**: Use MCP servers to check Dart syntax before implementation
2. **Theme Consistency**: Automated verification that all components use global theme
3. **Import Validation**: Ensure all required packages are properly imported
4. **Runtime Testing**: Quick validation of core user flows

### Fallback Strategies

```dart
// Safe theme access
TextStyle? getTextStyle(BuildContext context, String styleName) {
  switch (styleName) {
    case 'headline1': return Theme.of(context).textTheme.headline1;
    case 'headline2': return Theme.of(context).textTheme.headline2;
    default: return Theme.of(context).textTheme.bodyText1;
  }
}
```

## Testing Strategy

### Rapid Validation Checklist

1. **Visual Verification** (2 minutes):
   - Dark theme applied globally
   - JobCards display correctly
   - Navigation bar is floating and rounded

2. **Functional Testing** (3 minutes):
   - All navigation works
   - Job listings load
   - Analytics screen shows cards (no charts)

3. **MCP Diagnostic Check** (5 minutes):
   - No compilation errors
   - All imports resolved
   - Theme consistency verified

## Implementation Phases

### Phase 1: Foundation Setup (15 minutes)

1. **Replace Color Palette** (3 minutes):
   - Completely overwrite lib/utils/app_colors.dart
   - Use MCP server to validate color hex codes

2. **Add Dependencies** (5 minutes):
   - Add google_fonts and eva_icons_flutter to pubspec.yaml
   - Run flutter pub get
   - Use MCP server to verify package compatibility

3. **Update Global Theme** (7 minutes):
   - Replace ThemeData in lib/main.dart with exact specification
   - Use MCP server to validate theme structure

### Phase 2: Component Refactoring (35 minutes)

1. **JobCard Implementation** (15 minutes):
   - Locate all job list widgets
   - Replace with Card-based layout
   - Apply typography hierarchy
   - Use MCP server for code validation

2. **Navigation Bar Styling** (10 minutes):
   - Wrap BottomNavigationBar in ClipRRect and Padding
   - Test floating effect
   - Verify theme adoption

3. **Analytics Screen Simplification** (10 minutes):
   - **CRITICAL**: Remove all fl_chart widgets
   - Replace with Card-based statistics
   - Use existing data, display in cards
   - Test functionality preservation

### Phase 3: Validation & Testing (10 minutes)

1. **MCP Diagnostic Run** (5 minutes):
   - Check for compilation errors
   - Validate theme consistency
   - Verify icon replacements

2. **Functional Testing** (5 minutes):
   - Test core user flows
   - Verify visual consistency
   - Confirm no functionality broken

## Critical Success Factors

### Speed Optimizations

1. **Focus on High-Impact Changes**: JobCard, navigation, analytics screen
2. **Use Global Theming**: Let Flutter's theme system handle most styling automatically
3. **MCP Server Assistance**: Real-time validation prevents time-consuming debugging
4. **Minimal Icon Replacement**: Focus on most visible icons first

### Error Prevention

1. **Exact Code Copying**: Use provided code snippets exactly as specified
2. **MCP Validation**: Check each change before proceeding
3. **Incremental Testing**: Test after each major component change
4. **Preserve Existing Logic**: Only modify visual elements

This design ensures rapid, error-free implementation of the visual redesign within the 1-hour constraint while leveraging MCP servers for maximum efficiency and quality assurance.