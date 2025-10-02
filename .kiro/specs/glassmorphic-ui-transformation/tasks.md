# Implementation Plan

## Foundation Setup (15 minutes)

- [ ] 1. Create 3D design token system
  - Create lib/utils/three_d_design_tokens.dart with exact shadow, glass, and animation values from GREEN analysis
  - Define const List<BoxShadow> for cardShadow, headerShadow, and pressedShadow
  - Define const Color values for glassCard, glassHeader, and glassBorder
  - Define const ImageFilter values for cardBlur and headerBlur
  - _Requirements: 8.1, 8.2, 8.3, 8.4, 8.5_

- [ ] 1.1 Enhance main screen backgrounds with 3D depth
  - Update lib/screens/main/user/user_home_screen.dart Scaffold body with Container + RadialGradient
  - Use Color.lerp(AppColors.background, Colors.black, 0.2) and 0.4 for gradient depth
  - Set extendBody: true on Scaffold for proper layering
  - Test gradient rendering and performance on device
  - _Requirements: 1.1, 1.2, 1.3, 1.4, 1.5_

- [ ] 1.2 Implement Stack architecture for proper layering
  - Replace existing Column/PageView structure with Stack in user_home_screen.dart
  - Position existing content with Positioned.fill(top: 100) for Layer 1
  - Prepare positioned areas for floating header (Layer 2) and bottom nav (Layer 3)
  - Ensure existing PageView controller and navigation functionality preserved
  - _Requirements: 4.1, 4.2, 4.3, 4.4, 4.5_

## Core Widget Enhancement (35 minutes)

- [ ] 2. Transform job cards with 3D floating effects
  - Locate existing ListView.builder itemBuilder in user_home_screen.dart
  - Wrap existing job card content with ClipRRect + BackdropFilter + AnimatedContainer
  - Apply ThreeDDesignTokens.cardShadow, glassCard color, and cardBlur filter
  - Add GestureDetector with onTapDown/onTapUp for press animation effects
  - Preserve all existing job model properties, onTap functionality, and navigation
  - Test press animations and ensure smooth performance during scrolling
  - _Requirements: 3.1, 3.2, 3.3, 3.4, 3.5_

- [ ] 2.1 Create floating 3D header element
  - Replace existing AppBar with transparent AppBar (backgroundColor: Colors.transparent, elevation: 0)
  - Create _buildFloatingHeader() method with ClipRRect + BackdropFilter + Container
  - Position header with Positioned(top: MediaQuery.of(context).padding.top + 8)
  - Apply ThreeDDesignTokens.headerShadow and glassHeader styling
  - Integrate existing welcome text, profile avatar, and notification icon
  - Ensure header content remains functional and accessible
  - _Requirements: 2.1, 2.2, 2.3, 2.4, 2.5_

- [ ] 2.2 Enhance existing CircleAvatar widgets with 3D depth
  - Locate existing CircleAvatar widgets for profile and company logos
  - Wrap each CircleAvatar with Container having BoxShadow for 3D depth effect
  - Apply subtle shadow with Colors.black.withOpacity(0.1), offset: Offset(0, 2), blurRadius: 4
  - Maintain existing avatar functionality, image loading, and tap interactions
  - Test avatar rendering and ensure no performance impact
  - _Requirements: 6.1, 6.2, 6.3, 6.4, 6.5_

- [ ] 2.3 Apply same enhancements to employee home screen
  - Update lib/screens/main/employee/employee_home_screen.dart with identical Stack + gradient pattern
  - Apply same 3D job card enhancements to employee job listings
  - Ensure floating header works with employee-specific content and navigation
  - Maintain all existing employee functionality and business logic
  - Test consistency between user and employee screen 3D effects
  - _Requirements: 4.1, 4.2, 4.3, 4.4, 4.5_

## Interactive Polish and Integration (10 minutes)

- [ ] 3. Implement 3D interactive feedback system
  - Add _pressedIndex state variable to track which job card is being pressed
  - Implement AnimatedContainer duration with ThreeDDesignTokens.pressAnimation (150ms)
  - Switch between cardShadow and pressedShadow based on press state
  - Test tap responsiveness and ensure animations feel natural and smooth
  - Verify all existing onTap navigation and functionality preserved
  - _Requirements: 5.1, 5.2, 5.3, 5.4, 5.5_

- [ ] 3.1 Enhance existing buttons and badges with 3D effects
  - Locate existing ElevatedButton widgets and salary badges
  - Add BoxShadow enhancement to existing button styling
  - Apply 3D shadow effects to salary badges and filter chips
  - Use AppColors.primaryAccent.withOpacity(0.3) for accent-colored shadows
  - Ensure button functionality and existing styling preserved
  - _Requirements: 7.1, 7.2, 7.3, 7.4, 7.5_

- [ ] 3.2 Optional: Enhance existing IOSFloatingBottomNav with subtle 3D effects
  - Add subtle BoxShadow to existing IOSFloatingBottomNav if needed
  - Apply BackdropFilter enhancement if not already present
  - Ensure navigation functionality completely preserved
  - Test integration with new 3D design language
  - Maintain existing floating appearance and brand styling
  - _Requirements: 9.1, 9.2, 9.3, 9.4, 9.5_

## Testing and Validation (10 minutes)

- [ ] 4. Comprehensive 3D visual and functional testing
  - Test app startup and verify gradient backgrounds render correctly
  - Verify all job cards have proper 3D floating appearance with shadows
  - Test press animations on job cards for smooth feedback
  - Confirm floating header appears above content with proper glass effect
  - Validate all existing navigation, onTap, and business logic preserved
  - _Requirements: 10.1, 10.2, 10.3, 10.4, 10.5_

- [ ] 4.1 Performance and consistency validation
  - Test scrolling performance with multiple 3D job cards
  - Verify BackdropFilter count stays under 12 widgets simultaneously
  - Check memory usage and ensure no performance degradation
  - Test on different screen sizes and device orientations
  - Validate 3D effects are consistent across user and employee screens
  - Confirm all existing functionality works exactly as before
  - _Requirements: 8.1, 8.2, 8.3, 8.4, 8.5_

- [ ] 4.2 Visual quality assurance and brand consistency
  - Verify proper 3D depth hierarchy: header > cards > background
  - Confirm shadow directions are consistent (top-left light source)
  - Validate glass effects are subtle and enhance rather than distract
  - Check that existing AppColors and brand styling preserved
  - Ensure typography and spacing remain consistent with current app
  - Test that 3D effects complement existing design rather than replace it
  - _Requirements: 1.1, 1.2, 1.3, 1.4, 1.5_

## Implementation Notes

**Critical Success Criteria:**
- Zero breaking changes to existing functionality
- All onTap, navigation, and business logic preserved
- Performance remains smooth during scrolling and interactions
- 3D effects enhance existing design without overwhelming content
- Brand colors and design system maintained throughout

**Performance Targets:**
- Maximum 12 BackdropFilter widgets on screen simultaneously
- Animation response time under 150ms
- No frame drops during ListView scrolling
- Memory usage increase under 10MB

**Fallback Strategy:**
- If BackdropFilter causes performance issues, fall back to solid AppColors.surface
- If animations are choppy, reduce animation duration or disable on lower-end devices
- All 3D enhancements are additive - can be removed without breaking functionality