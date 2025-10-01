# Color Migration Mapping

## Old Color → New Color Mapping

### Primary Colors
- `AppColors.primaryBlue` → `AppColors.primaryAccent`
- `AppColors.neonBlue` → `AppColors.primaryAccent`
- `AppColors.royalBlue` → `AppColors.primaryAccent`
- `AppColors.elegantBlue` → `AppColors.primaryAccent`
- `AppColors.lightBlue` → `AppColors.surface`
- `AppColors.blueShadow` → `AppColors.primaryAccent.withOpacity(0.3)`

### Text Colors
- `AppColors.black` → `AppColors.textPrimary`
- `AppColors.white` → `AppColors.textOnAccent`
- `AppColors.whiteText` → `AppColors.textOnAccent`
- `AppColors.primaryText` → `AppColors.textPrimary`
- `AppColors.secondaryText` → `AppColors.textSecondary`
- `AppColors.mutedText` → `AppColors.textSecondary`
- `AppColors.hintText` → `AppColors.textSecondary`

### Background Colors
- `AppColors.backgroundColor` → `AppColors.background`
- `AppColors.cardBackground` → `AppColors.surface`
- `AppColors.surfaceColor` → `AppColors.surface`
- `AppColors.glassWhite` → `AppColors.surface`

### Status Colors
- `AppColors.success` → `AppColors.primaryAccent`
- `AppColors.error` → `AppColors.primaryAccent`
- `AppColors.warning` → `AppColors.primaryAccent`

### Utility Colors
- `AppColors.grey` → `AppColors.textSecondary`
- `AppColors.lightGrey` → `AppColors.border`
- `AppColors.softGrey` → `AppColors.surface`
- `AppColors.dividerColor` → `AppColors.border`
- `AppColors.shadowLight` → `AppColors.border`
- `AppColors.shadowMedium` → `AppColors.border`

### Gradients (Remove - Use Solid Colors)
- `AppColors.primaryGradient` → `AppColors.primaryAccent`
- `AppColors.blackGradient` → `AppColors.background`

### Icon Colors
- All icon colors → `AppColors.icon` (default) or `AppColors.iconActive` (active state)