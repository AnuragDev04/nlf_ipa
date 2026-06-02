# Quick Visual Guide: Role-Based Dashboard Titles

## Before & After

### BEFORE (Hardcoded)
```
┌─────────────────────────────────────────┐
│ Admin Dashboard                   🔔    │
├─────────────────────────────────────────┤
│  (Same for ALL roles)                   │
│  - Admin users see: Admin Dashboard     │
│  - HR users see: Admin Dashboard        │
│  - Sales users see: Admin Dashboard     │
│  - Everyone sees: Admin Dashboard ❌    │
└─────────────────────────────────────────┘
```

### AFTER (Dynamic)
```
┌─────────────────────────────────────────┐
│ Admin Dashboard                   🔔    │
└─────────────────────────────────────────┘
     (Admin login)

┌─────────────────────────────────────────┐
│ Hr Dashboard                      🔔    │
└─────────────────────────────────────────┘
     (HR login)

┌─────────────────────────────────────────┐
│ Sales Dashboard                   🔔    │
└─────────────────────────────────────────┘
     (Sales login)

┌─────────────────────────────────────────┐
│ Hr Manager Dashboard              🔔    │
└─────────────────────────────────────────┘
     (HR Manager login) ✅
```

## Data Flow

```
Login Screen
    ↓
User authenticates with email & password
    ↓
Server returns role: "hr" (or "admin", "sales", etc.)
    ↓
Login saves to SharedPreferences:
    - role = "hr"
    - isLoggedIn = true
    - userData = {...}
    ↓
Navigate to DashboardScreen → HomeScreen
    ↓
HomeScreen initializes:
    - _loadUserRole() reads "role" from SharedPreferences
    - Sets: _userRole = "hr"
    ↓
_getDashboardTitle() formats the role:
    - Takes: "hr"
    - Returns: "Hr Dashboard"
    ↓
Display title in header: "Hr Dashboard" ✅
```

## Code Integration Points

### 1. **Login.dart** (Already Working)
```dart
// Line ~111
await prefs.setString("role", result['roll'] ?? '');
```
✅ Role is already being saved

### 2. **Home Screen** (NEW - Implementation)

**Step 1: Load Role**
```dart
Future<void> _loadUserRole() async {
  final prefs = await SharedPreferences.getInstance();
  final role = prefs.getString('role') ?? '';
  setState(() => _userRole = role);
}
```

**Step 2: Format Title**
```dart
String _getDashboardTitle() {
  if (_userRole.isEmpty) return 'Dashboard';
  final formattedRole = _userRole
      .split('_')
      .map((word) => word[0].toUpperCase() + word.substring(1).toLowerCase())
      .join(' ');
  return '$formattedRole Dashboard';
}
```

**Step 3: Display Title**
```dart
Text(_getDashboardTitle(), ...)  // Instead of Text('Admin Dashboard', ...)
```

## Supported Role Formats

| Input Role | Output Title |
|-----------|--------------|
| admin | Admin Dashboard |
| hr | Hr Dashboard |
| sales | Sales Dashboard |
| lead | Lead Dashboard |
| backoffice | Backoffice Dashboard |
| accounts | Accounts Dashboard |
| material | Material Dashboard |
| dispatch | Dispatch Dashboard |
| site | Site Dashboard |
| hr_manager | Hr Manager Dashboard |
| sales_head | Sales Head Dashboard |
| backoffice_admin | Backoffice Admin Dashboard |

## Testing Checklist

- [ ] Login as Admin user → See "Admin Dashboard"
- [ ] Login as HR user → See "Hr Dashboard"
- [ ] Login as Sales user → See "Sales Dashboard"
- [ ] Logout and login with different role → Title changes correctly
- [ ] Close app and reopen → Role is maintained from SharedPreferences
- [ ] Test with multi-word roles (e.g., "hr_manager") → Displays as "Hr Manager Dashboard"

## Customization

To modify the title format, edit `_getDashboardTitle()`:

**Current format:**
```dart
return '$formattedRole Dashboard';  // "Hr Dashboard"
```

**Alternative formats:**

```dart
// Option 1: Add role icon/emoji
return '👤 $formattedRole Dashboard';

// Option 2: Custom messages per role
if (_userRole == 'admin') return '⚙️ Admin Control Panel';
if (_userRole == 'hr') return '👥 HR Management';
return '$formattedRole Dashboard';

// Option 3: All caps
return '${formattedRole.toUpperCase()} DASHBOARD';
```

## Files Modified

📁 **`lib/pages/home_screen.dart`**
- Added `_userRole` state variable
- Added `_loadUserRole()` method
- Added `_getDashboardTitle()` method
- Updated `initState()` to call `_loadUserRole()`
- Updated header Text widget to use `_getDashboardTitle()`

---

✅ **Implementation Complete!**
The dashboard now dynamically displays the user's role as the title.

