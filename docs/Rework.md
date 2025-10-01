# **GigWork App: UI Redesign Specification v5.0**

Project: GigWork App  
Task: Complete UI/UX Visual Redesign  
Author: BMad \- Senior UX Architect Persona  
Date: 2025-09-30  
Version: 5.0 (Definitive Architectural Blueprint)

## **1\. Core Mandate & Guiding Principles**

### **1.1. The Goal: Aesthetic Transfer, Not Functional Change**

The single objective is a **visual-only redesign**. We are applying the *aesthetic* (layout, spacing, typography, colors) of the reference images to the existing GigWork app.

### **1.2. Guiding Design Principles**

The AI agent must adhere to these principles:

* **Data-Forward Display:** Prioritize clear, glanceable data. Use visual hierarchy to draw attention to key numbers (salary, distance).  
* **High Contrast & Clarity:** Use the defined color palette for a sharp, legible interface.  
* **Action-Oriented Accents:** Use the vibrant orange (primaryAccent) **exclusively** for primary calls-to-action (CTAs).  
* **Consistent Spacing & Rounding:** Employ a strict 8px-based spacing system and consistent corner radii.

### **1.3. Strict Boundaries (Out of Scope)**

The AI agent **MUST NOT**:

* Modify files in lib/provider/, lib/models/, lib/services/, or lib/routes/.  
* Alter any backend logic (Firebase calls, API services).  
* **CRITICAL:** Implement any new features, especially financial graphs, charts, or "Buy/Sell" buttons. All data displayed must come from existing app logic.

## **2\. Design System & Global Theme**

### **2.1. Color Palette (lib/utils/app\_colors.dart)**

This file must be **completely replaced** with:

import 'package:flutter/material.dart';

class AppColors {  
  static const Color background \= Color(0xFF000404);  
  static const Color surface \= Color(0xFF1A1A1A);  
  static const Color primaryAccent \= Color(0xFFFF2E00);  
  static const Color textPrimary \= Color(0xFFC4C4C4);  
  static const Color textSecondary \= Color(0xFF8A8A8A);  
  static const Color textOnAccent \= Color(0xFFFFFFFF);  
  static const Color icon \= Color(0xFFC4C4C4);  
  static const Color iconActive \= Color(0xFFFF2E00);  
  static const Color border \= Color(0xFF2C2C2C);  
}

### **2.2. Typography & Icons**

* **Font:** Add google\_fonts to pubspec.yaml and use **Poppins**.  
* **Icons:** Add eva\_icons\_flutter to pubspec.yaml and replace all Icons.\* with EvaIcons.\*.

### **2.3. Theme Architecture (main.dart)**

The MaterialApp theme must be updated to establish the global styles for the entire application. This is a critical step for consistency.

// In lib/main.dart, update ThemeData  
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

## **3\. Component Blueprints & Refactoring Guide**

This section provides explicit instructions for refactoring key UI components to match the reference aesthetic.

### **3.1. Blueprint: The JobCard**

The JobCard is the most important component. It must be refactored to match the layout and hierarchy of the reference "asset" cards.

Location: All job lists, like in user\_home\_screen.dart.  
Action: Replace the existing job list item widget with a Card that contains the following structure:  
// This is a conceptual blueprint, not a runnable widget.  
// The AI agent must adapt this to the existing job model.  
Card(  
  child: Padding(  
    padding: const EdgeInsets.all(16.0),  
    child: Row(  
      children: \[  
        // Column for Job Details  
        Expanded(  
          child: Column(  
            crossAxisAlignment: CrossAxisAlignment.start,  
            children: \[  
              Text("Job Title", style: Theme.of(context).textTheme.headline2),  
              const SizedBox(height: 4),  
              Text("Company Name • Location", style: Theme.of(context).textTheme.caption),  
            \],  
          ),  
        ),  
        // Column for Pay/Salary  
        Column(  
          crossAxisAlignment: CrossAxisAlignment.end,  
          children: \[  
            Text("₹ 500/hr", style: Theme.of(context).textTheme.headline2?.copyWith(color: AppColors.primaryAccent)),  
            const SizedBox(height: 4),  
            Text("Full-time", style: Theme.of(context).textTheme.caption),  
          \],  
        ),  
      \],  
    ),  
  ),  
)

### **3.2. Refactoring: The BottomNavigationBar**

The navigation bar in the reference images is a key part of the aesthetic.

Location: user\_home\_screen.dart and employee\_home\_screen.dart.  
Action:

1. Wrap the existing BottomNavigationBar in a Padding widget: padding: const EdgeInsets.all(12.0).  
2. Wrap that Padding in a ClipRRect widget with borderRadius: BorderRadius.circular(30.0). This will create the rounded, "floating" effect.

### **3.3. Refactoring: The emp\_analytics.dart Screen**

**Action:**

1. **Remove fl\_chart:** Delete any existing chart widgets from this screen.  
2. **Display Stats in Cards:** The screen should display key statistics like "Active Jobs" and "Applicants" in separate Card widgets.  
3. **Apply Hierarchy:** Inside each card, display the metric's name (e.g., "Active Jobs") using Theme.of(context).textTheme.subtitle1 and the corresponding number using Theme.of(context).textTheme.headline1.  
4. Arrange these cards in a clean Column or GridView.

## **4\. Final Verification Checklist**

* \[ \] **Theme & Dependencies:** All Phase 1 and 2 steps are complete.  
* \[ \] **Component Blueprints:** The JobCard and other lists now follow the new layout structure.  
* \[ \] **Navigation Bar:** The bottom navigation bar is styled to be rounded and floating.  
* \[ \] **Analytics Screen:** The analytics screen uses styled cards for stats and contains **no graphs**.  
* \[ \] **Flow Integrity:** The app has been run, and all core user flows remain functional and unchanged.  
* \[ \] **Visual Consistency:** A manual review confirms the new dark theme is applied everywhere.  
  * 