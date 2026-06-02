import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:fluttertoast/fluttertoast.dart';
import '../utils/colors.dart';
import '../utils/constants.dart';
import 'package:flutter/gestures.dart';
import 'package:nlf/pages/dashboard.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailMobileController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscureText = true;
  bool _keepSignedIn = false;
  bool _isLoading = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final String apiUrl = AppConstants.LOGIN_API;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeOutCubic,
          ),
        );

    _animationController.forward();
    _loadSavedCredentials();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _emailMobileController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _loadSavedCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    final savedEmail = prefs.getString("saved_email");
    final savedPassword = prefs.getString("saved_password");

    if (savedEmail != null) _emailMobileController.text = savedEmail;
    if (savedPassword != null) _passwordController.text = savedPassword;

    if (savedEmail != null && savedPassword != null) {
      setState(() => _keepSignedIn = true);
    }
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final input = _emailMobileController.text.trim();
      final isEmail = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(input);
      final requestBody = <String, dynamic>{
        "password": _passwordController.text.trim(),
      };
      if (isEmail) {
        requestBody["email"] = input;
      } else {
        requestBody["mob"] = input;
      }

      final response = await http
          .post(
        Uri.parse(apiUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(requestBody),
      )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data[AppConstants.SUCCESS] == "1" ||
            data[AppConstants.SUCCESS] == 1) {
          final result = data[AppConstants.DATA] as Map<String, dynamic>?;
          if (result == null) {
            _showError("User data not found");
            return;
          }

          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool("isLoggedIn", true);
          await prefs.setString("userData", json.encode(data));
          await prefs.setString("mobile", result['mobile'] ?? '');
          await prefs.setString("name", result['name'] ?? '');
          await prefs.setString("email", result['email'] ?? '');
          await prefs.setString("id", result['id'] ?? '');
          await prefs.setString(
            "role",
            result['roll'] ?? '',
          );

          if (_keepSignedIn) {
            await prefs.setString("saved_email", _emailMobileController.text.trim());
            await prefs.setString(
              "saved_password",
              _passwordController.text.trim(),
            );
          } else {
            await prefs.remove("saved_email");
            await prefs.remove("saved_password");
          }

          _showSuccess("Welcome back, ${result['name'] ?? 'User'}!");

          if (mounted) {
            Navigator.pushReplacement(
              context,
              PageRouteBuilder(
                pageBuilder: (_, __, ___) => const DashboardScreen(),
                transitionsBuilder: (_, a, __, c) =>
                    FadeTransition(opacity: a, child: c),
                transitionDuration: const Duration(milliseconds: 500),
              ),
            );
          }
        } else {
          _showError(data['message'] ?? "Invalid Credentials");
        }
      } else {
        _showError("Server error: ${response.statusCode}");
      }
    } catch (e) {
      _showError(
        e.toString().contains('timeout')
            ? "Connection timeout. Please check your internet."
            : "Network error: ${e.toString()}",
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String msg) {
    Fluttertoast.showToast(
      msg: msg,
      backgroundColor: Colors.red.shade600,
      textColor: Colors.white,
      gravity: ToastGravity.BOTTOM,
      fontSize: 14,
      toastLength: Toast.LENGTH_LONG,
    );
  }

  void _showSuccess(String msg) {
    Fluttertoast.showToast(
      msg: msg,
      backgroundColor: Colors.green.shade600,
      textColor: Colors.white,
      gravity: ToastGravity.BOTTOM,
      fontSize: 14,
      toastLength: Toast.LENGTH_SHORT,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Decorative background elements
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color:
                AppColors.primaryText?.withOpacity(0.1) ??
                    Colors.blue.withOpacity(0.1),
              ),
            ),
          ),
          Positioned(
            bottom: -50,
            left: -50,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color:
                AppColors.secondaryText?.withOpacity(0.1) ??
                    Colors.purple.withOpacity(0.1),
              ),
            ),
          ),

          // Main content
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const SizedBox(height: 20),

                      // Logo with subtle shadow
                      Hero(
                        tag: 'app_logo',
                        child: Container(
                          width: 180,
                          height: 180,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.08),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(24),
                            child: Image.asset(
                              'assets/images/demologo.png',
                              fit: BoxFit.contain,
                              errorBuilder: (_, __, ___) => Container(
                                color:
                                AppColors.primaryText?.withOpacity(0.1) ??
                                    Colors.blue.shade100,
                                child: const Icon(
                                  Icons.lock_rounded,
                                  size: 60,
                                  color: Colors.grey,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 32),

                      // Welcome text
                      Text(
                        'Welcome Back!',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'serif',
                          color: Colors.black,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Login to continue your journey',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 15,
                          color: AppColors.greyText ?? Colors.grey[600],
                          fontFamily: 'serif',
                          height: 1.4,
                        ),
                      ),

                      const SizedBox(height: 30),

                      // Login Form
                      Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // ✅ Email/Mobile Field
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Email/Mobile',
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    fontFamily: 'serif',
                                  ),
                                ),
                                const SizedBox(height: 8),
                                TextFormField(
                                  controller: _emailMobileController,
                                  keyboardType: TextInputType.emailAddress,
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontFamily: 'serif',
                                  ),
                                  decoration: InputDecoration(
                                    labelText: 'Email/Mobile',
                                    labelStyle: TextStyle(
                                      color: AppColors.greyText,
                                      fontFamily: 'serif',
                                    ),
                                    prefixIcon: Icon(
                                      Icons.email,
                                      color: AppColors.greyText,
                                    ),
                                    hintText: 'Enter email or mobile number',
                                    hintStyle: TextStyle(
                                      color: AppColors.greyText,
                                      fontFamily: 'serif',
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(
                                        color: AppColors.lightGrey,
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(
                                        color: AppColors.secondaryText,
                                      ),
                                    ),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Please enter email or mobile number';
                                    }
                                    final input = value.trim();
                                    final isEmail = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(input);
                                    final isMobile = RegExp(r'^\+?[0-9]{7,15}$').hasMatch(input);
                                    if (!isEmail && !isMobile) {
                                      return 'Please enter a valid email or mobile number';
                                    }
                                    return null;
                                  },
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),

                            // ✅ Password Field - Same style as Email
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Password',
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    fontFamily: 'serif',
                                  ),
                                ),
                                const SizedBox(height: 8),
                                TextFormField(
                                  controller: _passwordController,
                                  obscureText: _obscureText,
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontFamily: 'serif',
                                  ),
                                  decoration: InputDecoration(
                                    labelText: 'Password',
                                    labelStyle: TextStyle(
                                      color: AppColors.greyText,
                                      fontFamily: 'serif',
                                    ),
                                    prefixIcon: Icon(
                                      Icons.lock,
                                      color: AppColors.greyText,
                                    ),
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _obscureText
                                            ? Icons.visibility_off
                                            : Icons.visibility,
                                        color: AppColors.greyText,
                                        size: 20,
                                      ),
                                      onPressed: () => setState(
                                            () => _obscureText = !_obscureText,
                                      ),
                                    ),
                                    hintText: 'Enter password',
                                    hintStyle: TextStyle(
                                      color: AppColors.greyText,
                                      fontFamily: 'serif',
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(
                                        color: AppColors.lightGrey,
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(
                                        color: AppColors.secondaryText,
                                      ),
                                    ),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Please enter password';
                                    }
                                    if (value.length < 6) {
                                      return 'Password must be at least 6 characters';
                                    }
                                    return null;
                                  },
                                ),
                              ],
                            ),

                            const SizedBox(height: 5),

                            // Forgot Password
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: () {
                                  _showError(
                                    "Forgot password feature coming soon!",
                                  );
                                },
                                child: Text(
                                  'Forgot Password?',
                                  style: TextStyle(
                                    color: AppColors.primaryText ?? Colors.blue,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                    fontFamily: 'serif',
                                  ),
                                ),
                              ),
                            ),

                            const SizedBox(height: 5),

                            // Keep me signed in
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                              ),
                              child: Row(
                                children: [
                                  Theme(
                                    data: Theme.of(context).copyWith(
                                      unselectedWidgetColor: Colors.grey[400],
                                    ),
                                    child: Checkbox(
                                      value: _keepSignedIn,
                                      onChanged: (v) async {
                                        final newValue = v ?? false;
                                        setState(
                                              () => _keepSignedIn = newValue,
                                        );

                                        if (!newValue) {
                                          final prefs =
                                          await SharedPreferences.getInstance();
                                          await prefs.remove("saved_email");
                                          await prefs.remove("saved_password");
                                        }
                                      },
                                      activeColor:
                                      AppColors.primaryText ?? Colors.blue,
                                      checkColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    "Keep me signed in",
                                    style: TextStyle(
                                      fontFamily: 'serif',
                                      fontSize: 14,
                                      color:
                                      AppColors.greyText ??
                                          Colors.grey[700],
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 20),

                            // Login Button
                            SizedBox(
                              width: double.infinity,
                              height: 56,
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _login,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                  AppColors.buttonColor ?? Colors.blue,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  elevation: _isLoading ? 0 : 8,
                                  shadowColor:
                                  (AppColors.buttonColor ?? Colors.blue)
                                      .withOpacity(0.4),
                                ),
                                child: _isLoading
                                    ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2.5,
                                  ),
                                )
                                    : const Text(
                                  "Continue",
                                  style: TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w600,
                                    fontFamily: 'serif',
                                    letterSpacing: 0.3,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Loading overlay
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.15),
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 3,
                    ),
                    SizedBox(height: 20),
                    Text(
                      'Signing in...',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        fontFamily: 'serif',
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}