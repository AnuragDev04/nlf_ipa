# Role-Based Dashboard Title Implementation

## Overview
Implemented a feature to dynamically display the dashboard title based on the user's role. When a user logs in, their dashboard title will now show their role instead of just "Admin Dashboard".

## Changes Made

### File: `lib/pages/home_screen.dart`

#### 1. **Added Role State Variable** (Line 39)
```dart
String _userRole = '';
```
This stores the user's role retrieved from SharedPreferences.

#### 2. **Added `_loadUserRole()` Method** (Lines 48-56)
```dart
Future<void> _loadUserRole() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final role = prefs.getString('role') ?? '';
    setState(() {
      _userRole = role;
    });
  } catch (e) {
    debugPrint("Error loading user role: $e");
  }
}
```
This method loads the user's role from SharedPreferences when the screen initializes.

#### 3. **Called `_loadUserRole()` in `initState()`** (Line 45)
```dart
void initState() {
  super.initState();
  _loadUserRole();  // <-- Added this line
  _loadCachedPermissions();
  _fetchAndCachePermissions();
}
```

#### 4. **Added `_getDashboardTitle()` Helper Method** (Lines 187-197)
```dart
String _getDashboardTitle() {
  if (_userRole.isEmpty) return 'Dashboard';
  
  // Format role name: "admin" -> "Admin", "hr_manager" -> "HR Manager", etc.
  final formattedRole = _userRole
      .split('_')
      .map((word) => word[0].toUpperCase() + word.substring(1).toLowerCase())
      .join(' ');
  
  return '$formattedRole Dashboard';
}
```

**How it works:**
- If no role is set, it defaults to "Dashboard"
- Splits role by underscore and capitalizes each word
- Examples:
  - `admin` → `Admin Dashboard`
  - `hr_manager` → `Hr Manager Dashboard`
  - `lead_sales` → `Lead Sales Dashboard`
  - `backoffice_admin` → `Backoffice Admin Dashboard`

#### 5. **Updated Dashboard Title Display** (Line 238)
Changed from hardcoded text:
```dart
// Before
Text('Admin Dashboard', ...)

// After
Text(_getDashboardTitle(), ...)
```

## How It Works

1. **Login Process**: When a user logs in, their role is saved to SharedPreferences as `'role'` (this is already done in `login.dart`)

2. **Dashboard Initialization**: When the HomeScreen loads:
   - `_loadUserRole()` retrieves the role from SharedPreferences
   - `_getDashboardTitle()` formats the role name to create the dashboard title
   - The title is displayed in the elegant header

3. **Dynamic Display**: The dashboard title automatically adapts based on the user's role

## Example Outputs

| Role | Dashboard Title |
|------|-----------------|
| admin | Admin Dashboard |
| hr | Hr Dashboard |
| hr_manager | Hr Manager Dashboard |
| sales | Sales Dashboard |
| lead | Lead Dashboard |
| backoffice | Backoffice Dashboard |
| accounts | Accounts Dashboard |

## Testing

To test the feature:

1. Log in with different user roles
2. Check the top of the HomeScreen - the title should display the appropriate role

The role name is stored in SharedPreferences during login (in `login.dart`):
```dart
await prefs.setString("role", result['roll'] ?? '');
```

## No Breaking Changes

- All existing functionality remains unchanged
- The feature gracefully handles missing role data (defaults to "Dashboard")
- Error handling is included for SharedPreferences access issues

