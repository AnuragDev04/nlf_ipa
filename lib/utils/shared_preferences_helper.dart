import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'constants.dart'; // Make sure this path is correct

class SharedPreferencesHelper {
  static Future<void> saveLoginData(String mobile, Map<String, dynamic> userData) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.PREF_MOBILE_NUMBER, mobile);
    await prefs.setBool(AppConstants.PREF_IS_LOGGED_IN, true);
    await prefs.setString(AppConstants.PREF_USER_DATA, json.encode(userData));
  }

  static Future<String?> getMobileNumber() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString(AppConstants.PREF_MOBILE_NUMBER);
  }

  static Future<bool> isLoggedIn() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool(AppConstants.PREF_IS_LOGGED_IN) ?? false;
  }

  static Future<Map<String, dynamic>?> getUserData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? userDataString = prefs.getString(AppConstants.PREF_USER_DATA);
    if (userDataString != null) {
      return json.decode(userDataString);
    }
    return null;
  }

  static Future<void> clearLoginData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.PREF_MOBILE_NUMBER);
    await prefs.remove(AppConstants.PREF_IS_LOGGED_IN);
    await prefs.remove(AppConstants.PREF_USER_DATA);
  }

  // Additional helper methods
  static Future<void> setKeepSignedIn(bool value) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.PREF_KEEP_SIGNED_IN, value);
  }

  static Future<bool> getKeepSignedIn() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool(AppConstants.PREF_KEEP_SIGNED_IN) ?? false;
  }
}
