import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/user_profile_service.dart';
import 'splash_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  Map<String, String> _userProfile = {};
  List<EmergencyContact> _contacts = [];
  bool _isEditingProfile = false;

  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _vehicleController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final profile = await UserProfileService.getProfile();
    final contacts = await UserProfileService.getEmergencyContacts();
    setState(() {
      _userProfile = profile;
      _contacts = contacts;
      _nameController.text = profile['name'] ?? '';
      _phoneController.text = profile['phone'] ?? '';
      _vehicleController.text = profile['vehicle'] ?? '';
    });
  }

  Future<void> _saveProfile() async {
    await UserProfileService.saveProfile(
      name: _nameController.text,
      phone: _phoneController.text,
      vehicle: _vehicleController.text,
    );
    setState(() => _isEditingProfile = false);
    _loadUserData();
  }

  Future<void> _logout() async {
    await UserProfileService.logout();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const SplashScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Settings"),
        backgroundColor: AppTheme.charcoalNight,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: AppTheme.tacticalRed),
            onPressed: _logout,
          )
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildProfileHeader(),
            _buildEmergencyContactsSection(),
            const SizedBox(height: 30),
            _buildSectionHeader("App Info"),
            _buildSettingTile(Icons.info_outline, "Version", "1.0.0-beta"),
            _buildSettingTile(Icons.description_outlined, "Terms of Service", "View legal documents"),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "USER PROFILE",
                style: TextStyle(color: AppTheme.tacticalRed, fontWeight: FontWeight.bold, letterSpacing: 1.2),
              ),
              IconButton(
                icon: Icon(_isEditingProfile ? Icons.check : Icons.edit, color: Colors.grey, size: 20),
                onPressed: () {
                  if (_isEditingProfile) {
                    _saveProfile();
                  } else {
                    setState(() => _isEditingProfile = true);
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (_isEditingProfile) ...[
            _buildEditField(_nameController, "Name", Icons.person),
            const SizedBox(height: 10),
            _buildEditField(_phoneController, "Phone", Icons.phone),
            const SizedBox(height: 10),
            _buildEditField(_vehicleController, "Vehicle", Icons.directions_car),
          ] else ...[
            _buildProfileInfo(Icons.person, _userProfile['name'] ?? 'Not Set'),
            const SizedBox(height: 8),
            _buildProfileInfo(Icons.phone, _userProfile['phone'] ?? 'Not Set'),
            const SizedBox(height: 8),
            _buildProfileInfo(Icons.directions_car, _userProfile['vehicle'] ?? 'Not Set'),
          ],
        ],
      ),
    );
  }

  Widget _buildEditField(TextEditingController controller, String hint, IconData icon) {
    return TextField(
      controller: controller,
      style: const TextStyle(color: Colors.white, fontSize: 14),
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: AppTheme.tacticalRed, size: 18),
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.grey),
        filled: true,
        fillColor: Colors.black,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(vertical: 0),
      ),
    );
  }

  Widget _buildProfileInfo(IconData icon, String value) {
    return Row(
      children: [
        Icon(icon, color: Colors.grey, size: 18),
        const SizedBox(width: 12),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 15)),
      ],
    );
  }

  Widget _buildEmergencyContactsSection() {
    return Column(
      children: [
        _buildSectionHeader("Emergency Contacts (Up to 3)"),
        ...List.generate(3, (index) {
          final contact = index < _contacts.length ? _contacts[index] : null;
          return _buildContactTile(index + 1, contact);
        }),
      ],
    );
  }

  Widget _buildContactTile(int priority, EmergencyContact? contact) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: contact != null ? AppTheme.tacticalRed : Colors.grey[800],
        radius: 18,
        child: Text("$priority", style: const TextStyle(color: Colors.white, fontSize: 12)),
      ),
      title: Text(contact?.name ?? "Add Contact", style: TextStyle(color: contact != null ? Colors.white : Colors.grey)),
      subtitle: Text(contact?.phone ?? "Priority $priority contact", style: const TextStyle(fontSize: 12)),
      trailing: const Icon(Icons.chevron_right, color: Colors.grey),
      onTap: () => _showContactEditDialog(priority, contact),
    );
  }

  void _showContactEditDialog(int priority, EmergencyContact? contact) {
    final nameCtrl = TextEditingController(text: contact?.name);
    final phoneCtrl = TextEditingController(text: contact?.phone);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: Text("Contact Priority $priority", style: const TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildEditField(nameCtrl, "Name", Icons.person),
            const SizedBox(height: 10),
            _buildEditField(phoneCtrl, "Phone", Icons.phone),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              final newContact = EmergencyContact(name: nameCtrl.text, phone: phoneCtrl.text, priority: priority);
              List<EmergencyContact> updatedContacts = List.from(_contacts);
              int existingIndex = updatedContacts.indexWhere((c) => c.priority == priority);
              if (existingIndex != -1) {
                updatedContacts[existingIndex] = newContact;
              } else {
                updatedContacts.add(newContact);
              }
              updatedContacts.sort((a, b) => a.priority.compareTo(b.priority));
              await UserProfileService.saveEmergencyContacts(updatedContacts);
              if (!mounted) return;
              Navigator.pop(context);
              _loadUserData();
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title.toUpperCase(),
          style: const TextStyle(color: AppTheme.tacticalRed, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1.2),
        ),
      ),
    );
  }

  Widget _buildSettingTile(IconData icon, String title, String subtitle) {
    return ListTile(
      leading: Icon(icon, color: Colors.white70),
      title: Text(title, style: const TextStyle(color: Colors.white)),
      subtitle: Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 12)),
      trailing: const Icon(Icons.chevron_right, color: Colors.grey),
      onTap: () {},
    );
  }
}
