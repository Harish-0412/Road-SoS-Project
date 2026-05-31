import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
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
    // Save profile if filled
    if (_nameController.text.isNotEmpty) {
      await UserProfileService.saveProfile(
        name: _nameController.text,
        phone: _phoneController.text,
        vehicle: _vehicleController.text,
      );
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_complete', true);
    
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const HomeScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.charcoalNight,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _pageController,
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
    return SingleChildScrollView(
      padding: const EdgeInsets.all(40.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(data.icon, size: 80, color: AppTheme.tacticalRed),
          const SizedBox(height: 30),
          Text(
            data.title,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          if (data.isProfilePage) ...[
            _buildProfileForm(),
          ] else ...[
            Text(
              data.description,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey, fontSize: 16),
            ),
          ],
          if (data.permission != null) ...[
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: () => _requestPermission(data.permission!),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.tacticalRed,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              ),
              child: Text("Grant ${data.permission.toString().split('.').last.toUpperCase()} Access"),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildProfileForm() {
    return Column(
      children: [
        _buildTextField(_nameController, "Full Name", Icons.person),
        const SizedBox(height: 15),
        _buildTextField(_phoneController, "Phone Number", Icons.phone, keyboardType: TextInputType.phone),
        const SizedBox(height: 15),
        _buildTextField(_vehicleController, "Vehicle Number (Optional)", Icons.directions_car),
      ],
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint, IconData icon, {TextInputType? keyboardType}) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: AppTheme.tacticalRed),
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.grey),
        filled: true,
        fillColor: Colors.grey[900],
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      ),
    );
  }

  Widget _buildBottomControls() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: List.generate(
              _pages.length,
              (index) => Container(
                margin: const EdgeInsets.only(right: 8),
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _currentPage == index ? AppTheme.tacticalRed : Colors.grey,
                ),
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              if (_currentPage == _pages.length - 1) {
                _completeOnboarding();
              } else {
                _pageController.nextPage(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.tacticalRed),
            child: Text(_currentPage == _pages.length - 1 ? "GET STARTED" : "NEXT"),
          ),
        ],
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

  OnboardingData({
    required this.title,
    required this.description,
    required this.icon,
    this.permission,
    this.isProfilePage = false,
  });
}
