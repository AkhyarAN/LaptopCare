# LaptopCare - Style Guide

## **Design System Overview**

LaptopCare menggunakan Material Design 3 dengan konsistensi visual yang berfokus pada kemudahan penggunaan dan profesionalitas.

## **1. Color Palette**

### Primary Colors
```dart
Primary Color    : #2196F3 (Blue 500)
Secondary Color  : #03A9F4 (Light Blue 500)  
Accent Color     : #00BCD4 (Cyan 500)
```

### Status Colors
```dart
Success Color    : #43A047 (Green 600)
Warning Color    : #FFA000 (Amber 600)
Error Color      : #E53935 (Red 600)
```

### Neutral Colors
```dart
Background Light : #FFFFFF
Background Dark  : #121212
Surface Light    : #F5F5F5
Surface Dark     : #1E1E1E
Text Primary     : #212121 (Light) / #FFFFFF (Dark)
Text Secondary   : #757575 (Light) / #AAAAAA (Dark)
```

## **2. Typography**

### Font Family
- **Primary**: Roboto (Material Design default)
- **Fallback**: SF Pro Display (iOS), Segoe UI (Windows)

### Text Styles
```dart
// Headlines
Headline Large   : 32sp, Bold
Headline Medium  : 28sp, Bold  
Headline Small   : 24sp, SemiBold

// Titles
Title Large      : 22sp, Medium
Title Medium     : 16sp, Medium
Title Small      : 14sp, Medium

// Body Text
Body Large       : 16sp, Regular
Body Medium      : 14sp, Regular
Body Small       : 12sp, Regular

// Labels
Label Large      : 14sp, Medium
Label Medium     : 12sp, Medium
Label Small      : 11sp, Medium
```

## **3. Spacing System**

### Standard Spacing Scale
```dart
xs  : 4px
sm  : 8px
md  : 16px
lg  : 24px
xl  : 32px
xxl : 48px
```

### Component Spacing
- **Card padding**: 16px
- **Screen padding**: 16px
- **Button height**: 50px
- **Input field height**: 56px
- **Icon size**: 24px (standard), 20px (small), 32px (large)

## **4. Component Library**

### Buttons

#### Primary Button
```dart
ElevatedButton(
  style: ElevatedButton.styleFrom(
    backgroundColor: AppTheme.primaryColor,
    foregroundColor: Colors.white,
    minimumSize: Size(double.infinity, 50),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8),
    ),
  ),
  child: Text('Primary Action'),
)
```

#### Secondary Button
```dart
OutlinedButton(
  style: OutlinedButton.styleFrom(
    foregroundColor: AppTheme.primaryColor,
    side: BorderSide(color: AppTheme.primaryColor),
    minimumSize: Size(double.infinity, 50),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8),
    ),
  ),
  child: Text('Secondary Action'),
)
```

### Cards

#### Standard Card
```dart
Card(
  elevation: 2,
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(12),
  ),
  child: Padding(
    padding: EdgeInsets.all(16),
    child: // Card content
  ),
)
```

#### Laptop Profile Card
- Rounded corners: 12px
- Elevation: 2
- Image container: 60x60px with 8px border radius
- Selected state: Primary color border (2px)

### Input Fields

#### Standard Text Field
```dart
TextFormField(
  decoration: InputDecoration(
    labelText: 'Field Label',
    hintText: 'Enter value',
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
    ),
    contentPadding: EdgeInsets.symmetric(
      horizontal: 16, 
      vertical: 16
    ),
  ),
)
```

## **5. Navigation**

### Bottom Navigation
- 4 tabs: Laptops, Tasks, Reminders, Profile
- Selected indicator: Primary color
- Icon size: 24px
- Label: 12sp Medium

### App Bar
- Background: Primary color (Light) / Grey 900 (Dark)
- Foreground: White
- Elevation: 0
- Center title: true
- Action icons: 24px

## **6. Image Guidelines**

### Laptop Images
- **Aspect ratio**: 1:1 (square)
- **Recommended size**: 1024x1024px
- **Compression**: 80% quality
- **Format**: JPEG/PNG
- **Placeholder**: Laptop icon (grey)

### Profile Images  
- **Aspect ratio**: 1:1 (square)
- **Size**: 128x128px
- **Border radius**: 50% (circular)

## **7. Loading States**

### Progress Indicators
```dart
// Primary loading
CircularProgressIndicator(
  color: AppTheme.primaryColor,
)

// Button loading (white on primary)
CircularProgressIndicator(
  color: Colors.white,
  strokeWidth: 2,
)
```

### Skeleton Loading
- Background: Grey 300 (Light) / Grey 700 (Dark)
- Animation: Shimmer effect
- Border radius: Match component

## **8. Error Handling**

### Error Messages
```dart
SnackBar(
  content: Text('Error message'),
  backgroundColor: AppTheme.errorColor,
  behavior: SnackBarBehavior.floating,
)
```

### Success Messages
```dart
SnackBar(
  content: Text('Success message'),
  backgroundColor: AppTheme.successColor,
  behavior: SnackBarBehavior.floating,
)
```

## **9. Accessibility**

### Color Contrast
- **Minimum contrast ratio**: 4.5:1
- **Large text**: 3:1
- **Interactive elements**: Clear focus indicators

### Touch Targets
- **Minimum size**: 44x44px
- **Recommended**: 48x48px
- **Spacing**: 8px between targets

### Text Scaling
- **Support**: Dynamic type scaling
- **Maximum**: 200% scaling
- **Minimum**: 85% scaling

## **10. Animation Guidelines**

### Duration
```dart
Fast    : 150ms (micro-interactions)
Normal  : 300ms (page transitions)
Slow    : 500ms (complex animations)
```

### Easing
```dart
Standard    : Curves.easeInOut
Entering    : Curves.easeOut  
Exiting     : Curves.easeIn
```

### Common Animations
- **Page transitions**: Slide and fade
- **Button press**: Scale down to 95%
- **Loading**: Rotation and fade
- **List items**: Slide up with stagger

## **11. Layout Patterns**

### Screen Layout
```dart
Scaffold(
  appBar: AppBar(...),
  body: Padding(
    padding: EdgeInsets.all(16),
    child: Column(...),
  ),
  floatingActionButton: ...,
)
```

### Form Layout
- **Field spacing**: 16px vertical
- **Section spacing**: 24px vertical
- **Button spacing**: 32px from last field

### List Layout
- **Item spacing**: 16px vertical
- **Horizontal padding**: 16px
- **Card margin**: 8px bottom

## **12. Implementation Notes**

### Theme Usage
```dart
// Access theme colors
Theme.of(context).colorScheme.primary
Theme.of(context).colorScheme.onSurface

// Access custom colors
AppTheme.primaryColor
AppTheme.successColor
```

### Responsive Design
```dart
// Screen breakpoints
Mobile   : < 600px
Tablet   : 600px - 1024px  
Desktop  : > 1024px

// Layout adjustments
if (MediaQuery.of(context).size.width > 600) {
  // Tablet/Desktop layout
} else {
  // Mobile layout
}
```

---

**Version**: 1.0  
**Last Updated**: 22 Juni 2025  
**Maintainer**: Akhyar Nurullah 