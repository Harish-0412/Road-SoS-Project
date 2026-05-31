import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../services/user_profile_service.dart';
import 'home_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  
  // Profile Form Controllers
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _vehicleController = TextEditingController();

  late final List<OnboardingData> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      OnboardingData(
        title: "Save Lives in the Golden Hour",
        description: "Quickly report accidents and get AI-powered first-aid instructions even without internet.",
        icon: Icons.speed,
      ),
      OnboardingData(
        title: "Your Profile",
        description: "We need your details to provide faster assistance during emergencies.",
        icon: Icons.person_add,
        isProfilePage: true,
      ),
      OnboardingData(
        title: "Preferred Theme",
        description: "Choose a visual mode that fits your tactical preference.",
        icon: Icons.palette,
        isThemePage: true,
      ),
      OnboardingData(
        title: "Location Assistance",
        description: "We need location access to find the nearest hospitals, police stations, and mechanics for you.",
        icon: Icons.location_on,
        permission: kIsWeb ? null : Permission.location,
      ),
      OnboardingData(
        title: "Emergency SMS",
        description: "In critical situations, we send your location and details to emergency contacts via SMS automatically.",
        icon: Icons.sms,
        permission: kIsWeb ? null : Permission.sms,
      ),
    ];
  }

  Future<void> _requestPermission(Permission permission) async {
    if (kIsWeb) return;
    await permission.request();
  }

  Future<void> _completeOnboarding() async {
    // Save profile (all fields are validated before this step)
    await UserProfileService.saveProfile(
      name: _nameController.text.trim(),
      phone: _phoneController.text.trim(),
      vehicle: _vehicleController.text.trim(),
    );

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_complete', true);
    
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => const HomeScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 600),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(), // Enforce button-based step progression
                onPageChanged: (index) => setState(() => _currentPage = index),
                itemCount: _pages.length,
                itemBuilder: (context, index) {
                  return _buildPage(_pages[index]);
                },
              ),
            ),
            _buildBottomControls(),
          ],
        ),
      ),
    );
  }

  Widget _buildPage(OnboardingData data) {
    final theme = Theme.of(context);
    final onSurfaceColor = theme.colorScheme.brightness == Brightness.dark ? Colors.white : Colors.black87;
    final bodyColor = theme.colorScheme.brightness == Brightness.dark ? Colors.grey[400]! : Colors.black54;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 40.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 20),
          Icon(data.icon, size: 80, color: AppTheme.tacticalRed),
          const SizedBox(height: 30),
          Text(
            data.title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: onSurfaceColor,
              fontSize: 26,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 20),
          if (data.isProfilePage) ...[
            _buildProfileForm(),
          ] else if (data.isThemePage) ...[
            _buildThemeSelection(),
          ] else ...[
            Text(
              data.description,
              textAlign: TextAlign.center,
              style: TextStyle(color: bodyColor, fontSize: 16, height: 1.5),
            ),
          ],
          if (data.permission != null) ...[
            const SizedBox(height: 40),
            ElevatedButton.icon(
              onPressed: () => _requestPermission(data.permission!),
              icon: const Icon(Icons.security, size: 20),
              label: Text(
                "Grant ${data.permission.toString().split('.').last.toUpperCase()} Access",
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.tacticalRed,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildProfileForm() {
    return Column(
      children: [
        const SizedBox(height: 10),
        _buildTextField(_nameController, "Full Name", Icons.person),
        const SizedBox(height: 15),
        _buildTextField(_phoneController, "Phone / Contact Number", Icons.phone, keyboardType: TextInputType.phone),
        const SizedBox(height: 15),
        _buildTextField(_vehicleController, "Vehicle Number (e.g. TN-07-CS-1234)", Icons.directions_car),
      ],
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint, IconData icon, {TextInputType? keyboardType}) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: TextStyle(color: isDark ? Colors.white : Colors.black87),
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: AppTheme.tacticalRed),
        hintText: hint,
        hintStyle: TextStyle(color: isDark ? Colors.grey[500] : Colors.grey[600]),
        filled: true,
        fillColor: isDark ? Colors.grey[900] : Colors.grey[200],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.tacticalRed, width: 1.5),
        ),
      ),
    );
  }

  Widget _buildThemeSelection() {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20.0),
      child: Column(
        children: [
          Row(
            children: [
              // Light Theme Card
              Expanded(
                child: GestureDetector(
                  onTap: () => themeProvider.toggleTheme(false),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: !isDark ? AppTheme.tacticalRed : Colors.grey[300]!,
                        width: !isDark ? 3.0 : 1.0,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: !isDark ? AppTheme.tacticalRed.withOpacity(0.3) : Colors.black12,
                          blurRadius: !isDark ? 12 : 6,
                          spreadRadius: !isDark ? 2 : 0,
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Icon(Icons.wb_sunny, size: 40, color: !isDark ? AppTheme.tacticalRed : Colors.grey),
                        const SizedBox(height: 12),
                        const Text(
                          "Stark Light",
                          style: TextStyle(
                            color: Colors.black87,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          "Clean & High Contrast",
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.black54, fontSize: 11),
                        ),
                        const SizedBox(height: 12),
                        if (!isDark)
                          const Icon(Icons.check_circle, color: AppTheme.tacticalRed, size: 24)
                        else
                          const Icon(Icons.radio_button_off, color: Colors.grey, size: 24),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 20),
              // Dark Theme Card
              Expanded(
                child: GestureDetector(
                  onTap: () => themeProvider.toggleTheme(true),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1E1E),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark ? AppTheme.tacticalRed : Colors.grey[800]!,
                        width: isDark ? 3.0 : 1.0,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: isDark ? AppTheme.tacticalRed.withOpacity(0.5) : Colors.black54,
                          blurRadius: isDark ? 12 : 6,
                          spreadRadius: isDark ? 2 : 0,
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Icon(Icons.nightlight_round, size: 40, color: isDark ? AppTheme.tacticalRed : Colors.grey),
                        const SizedBox(height: 12),
                        const Text(
                          "Charcoal Night",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          "Tactical & Easy on Eyes",
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white60, fontSize: 11),
                        ),
                        const SizedBox(height: 12),
                        if (isDark)
                          const Icon(Icons.check_circle, color: AppTheme.tacticalRed, size: 24)
                        else
                          const Icon(Icons.radio_button_off, color: Colors.grey, size: 24),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBottomControls() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF161616) : Colors.white,
        border: Border(
          top: BorderSide(
            color: isDark ? Colors.white10 : Colors.black.withOpacity(0.05),
            width: 1,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: List.generate(
              _pages.length,
              (index) => Container(
                margin: const EdgeInsets.only(right: 8),
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _currentPage == index ? AppTheme.tacticalRed : (isDark ? Colors.grey[700] : Colors.grey[300]),
                ),
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              if (_currentPage == 1) {
                // Profile fields validation
                if (_nameController.text.trim().isEmpty) {
                  _showError("Please enter your Full Name");
                  return;
                }
                if (_phoneController.text.trim().isEmpty || _phoneController.text.trim().length < 10) {
                  _showError("Please enter a valid 10-digit Phone Number");
                  return;
                }
                if (_vehicleController.text.trim().isEmpty) {
                  _showError("Please enter your Vehicle Number");
                  return;
                }
              }

              if (_currentPage == _pages.length - 1) {
                _completeOnboarding();
              } else {
                _pageController.nextPage(
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.easeInOut,
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.tacticalRed,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              elevation: 4,
            ),
            child: Text(
              _currentPage == _pages.length - 1 ? "GET STARTED" : "NEXT",
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, letterSpacing: 1),
            ),
          ),
        ],
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message, style: const TextStyle(fontWeight: FontWeight.bold))),
          ],
        ),
        backgroundColor: AppTheme.tacticalRed,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }
}

class OnboardingData {
  final String title;
  final String description;
  final IconData icon;
  final Permission? permission;
  final bool isProfilePage;
  final bool isThemePage;

  OnboardingData({
    required this.title,
    required this.description,
    required this.icon,
    this.permission,
    this.isProfilePage = false,
    this.isThemePage = false,
  });
}
