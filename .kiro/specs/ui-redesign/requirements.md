# Requirements Document

## Introduction

The GigWork App requires a complete visual-only redesign following Rework.md v5.0 specifications. This is a rapid 1-hour implementation focused on aesthetic transfer with no functional changes. The redesign transforms the app to a professional dark "stock market app" aesthetic with data-forward display, high contrast clarity, and strategic accent usage. MCP servers will be leveraged for faster, error-free development.

## Requirements

### Requirement 1

**User Story:** As a user, I want a professional dark theme interface, so that I can have a modern "stock market app" aesthetic experience.

#### Acceptance Criteria

1. WHEN the app launches THEN the system SHALL display Color(0xFF000404) as the primary background
2. WHEN surface elements are rendered THEN the system SHALL use Color(0xFF1A1A1A) for cards and elevated components
3. WHEN the interface is displayed THEN the system SHALL use Color(0xFFC4C4C4) for primary text and Color(0xFF8A8A8A) for secondary text
4. WHEN borders are needed THEN the system SHALL use Color(0xFF2C2C2C) for all border elements
5. WHEN the color palette is implemented THEN the system SHALL completely replace lib/utils/app_colors.dart with the exact 9-color palette from Rework.md v5.0

### Requirement 2

**User Story:** As a user, I want clear visual hierarchy with Poppins typography, so that I can easily scan and prioritize information.

#### Acceptance Criteria

1. WHEN the app initializes THEN the system SHALL implement Poppins font family via google_fonts package
2. WHEN displaying main titles THEN the system SHALL use 28px bold text for headline1 style
3. WHEN showing section headers THEN the system SHALL use 22px bold text for headline2 style
4. WHEN presenting subtitles THEN the system SHALL use 16px normal text for subtitle1 style
5. WHEN displaying body content THEN the system SHALL use 14px normal text for bodyText1 style
6. WHEN showing button text THEN the system SHALL use 16px bold text for button style
7. WHEN displaying metadata THEN the system SHALL use 12px normal text for caption style

### Requirement 3

**User Story:** As a user, I want consistent iconography, so that I can quickly recognize interface elements.

#### Acceptance Criteria

1. WHEN icons are displayed THEN the system SHALL use eva_icons_flutter package instead of Material Icons
2. WHEN icons are inactive THEN the system SHALL display them in Color(0xFFC4C4C4)
3. WHEN icons are active THEN the system SHALL display them in Color(0xFFFF2E00)
4. WHEN replacing icons THEN the system SHALL replace ALL instances of Icons.* with EvaIcons.* equivalents

### Requirement 4

**User Story:** As a user, I want clear primary actions, so that I can easily identify and interact with CTAs.

#### Acceptance Criteria

1. WHEN primary buttons are displayed THEN the system SHALL use Color(0xFFFF2E00) as background exclusively for CTAs
2. WHEN button text is rendered THEN the system SHALL use Color(0xFFFFFFFF) on accent-colored buttons
3. WHEN buttons are styled THEN the system SHALL use 30px border radius for primary buttons
4. WHEN accent color is used THEN the system SHALL reserve Color(0xFFFF2E00) exclusively for primary actions and critical highlights

### Requirement 5

**User Story:** As a user, I want the JobCard component to follow the new aesthetic, so that job listings have a professional appearance.

#### Acceptance Criteria

1. WHEN job lists are displayed THEN the system SHALL use Card widgets with the global cardTheme
2. WHEN JobCard content is laid out THEN the system SHALL use Row with Expanded for job details and Column for salary
3. WHEN job titles are shown THEN the system SHALL use Theme.of(context).textTheme.headline2 style
4. WHEN company info is displayed THEN the system SHALL use Theme.of(context).textTheme.caption style
5. WHEN salary is shown THEN the system SHALL use headline2 style with AppColors.primaryAccent color
6. WHEN JobCard padding is applied THEN the system SHALL use EdgeInsets.all(16.0) inside the Card

### Requirement 6

**User Story:** As a user, I want a floating rounded navigation bar, so that the interface has a modern aesthetic.

#### Acceptance Criteria

1. WHEN BottomNavigationBar is displayed THEN the system SHALL wrap it in Padding with EdgeInsets.all(12.0)
2. WHEN the navigation is styled THEN the system SHALL wrap the Padding in ClipRRect with BorderRadius.circular(30.0)
3. WHEN navigation items are shown THEN the system SHALL use AppColors.iconActive for selected items
4. WHEN navigation is rendered THEN the system SHALL use AppColors.icon for unselected items
5. WHEN navigation type is set THEN the system SHALL use BottomNavigationBarType.fixed with showUnselectedLabels: false

### Requirement 7

**User Story:** As a user, I want the analytics screen to display stats in cards without charts, so that I can view key metrics clearly.

#### Acceptance Criteria

1. WHEN analytics screen loads THEN the system SHALL remove all fl_chart widgets completely
2. WHEN statistics are displayed THEN the system SHALL show metrics like "Active Jobs" and "Applicants" in separate Card widgets
3. WHEN metric names are shown THEN the system SHALL use Theme.of(context).textTheme.subtitle1 style
4. WHEN metric numbers are displayed THEN the system SHALL use Theme.of(context).textTheme.headline1 style
5. WHEN cards are arranged THEN the system SHALL use Column or GridView layout for clean presentation

### Requirement 8

**User Story:** As a developer, I want rapid implementation with MCP server assistance, so that the 1-hour deadline can be met with error-free code.

#### Acceptance Criteria

1. WHEN implementing changes THEN the system SHALL use MCP servers for Flutter documentation lookup and code validation
2. WHEN writing code THEN the system SHALL leverage MCP tools for syntax checking and best practices
3. WHEN applying themes THEN the system SHALL use MCP servers to verify theme consistency across components
4. WHEN testing changes THEN the system SHALL use MCP diagnostic tools to catch errors early
5. WHEN implementing typography THEN the system SHALL use MCP servers to validate Google Fonts integration

### Requirement 9

**User Story:** As a stakeholder, I want all existing functionality preserved, so that no business logic is disrupted.

#### Acceptance Criteria

1. WHEN implementing redesign THEN the system SHALL NOT modify any files in lib/provider/ directory
2. WHEN applying changes THEN the system SHALL NOT alter any files in lib/models/ directory
3. WHEN updating UI THEN the system SHALL NOT change any files in lib/services/ directory
4. WHEN redesigning screens THEN the system SHALL NOT modify any files in lib/routes/ directory
5. WHEN the redesign is complete THEN the system SHALL preserve all Firebase integrations and API functionality

### Requirement 10

**User Story:** As a user, I want consistent global theming, so that all components follow the new design system.

#### Acceptance Criteria

1. WHEN global theme is applied THEN the system SHALL update ThemeData in lib/main.dart with exact specifications from Rework.md v5.0
2. WHEN theme properties are set THEN the system SHALL configure brightness: Brightness.dark
3. WHEN component themes are defined THEN the system SHALL set appBarTheme, bottomNavigationBarTheme, elevatedButtonTheme, inputDecorationTheme, and cardTheme
4. WHEN text theme is configured THEN the system SHALL define headline1, headline2, subtitle1, bodyText1, button, and caption styles
5. WHEN the theme is complete THEN the system SHALL ensure all components automatically adopt the global styling