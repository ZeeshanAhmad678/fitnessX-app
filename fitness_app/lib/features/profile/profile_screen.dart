import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fitness_app/constants/app_colors.dart';
import 'package:fitness_app/features/auth/auth_service.dart'; // Ensure this is imported
import 'package:fitness_app/providers/cloudinary_service.dart'; // Ensure this is imported
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final User? currentUser = FirebaseAuth.instance.currentUser;
  final CloudinaryService _cloudinaryService = CloudinaryService();

  bool _isEditing = false;
  bool _isLoading = false;

  // Controllers
  late TextEditingController _nameController;
  late TextEditingController _programController; // 1. NEW CONTROLLER
  late TextEditingController _heightController;
  late TextEditingController _weightController;
  late TextEditingController _ageController;

  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _programController = TextEditingController(); // Init
    _heightController = TextEditingController();
    _weightController = TextEditingController();
    _ageController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _programController.dispose(); // Dispose
    _heightController.dispose();
    _weightController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  // --- ACTIONS ---

  Future<void> _pickImage() async {
    if (!_isEditing) return;
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Gallery'),
              onTap: () async {
                Navigator.of(context).pop();
                final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
                if (image != null) setState(() => _selectedImage = File(image.path));
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Camera'),
              onTap: () async {
                Navigator.of(context).pop();
                final XFile? image = await _picker.pickImage(source: ImageSource.camera);
                if (image != null) setState(() => _selectedImage = File(image.path));
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveProfile() async {
    setState(() => _isLoading = true);

    try {
      Map<String, dynamic> updateData = {
        'firstName': _nameController.text.trim(),
        'programTitle': _programController.text.trim(), // Save Program Name
        'height': double.tryParse(_heightController.text) ?? 0,
        'weight': double.tryParse(_weightController.text) ?? 0,
        'age': int.tryParse(_ageController.text) ?? 0,
      };

      if (_selectedImage != null) {
        String? imageUrl = await _cloudinaryService.uploadImage(_selectedImage);
        if (imageUrl != null) {
          updateData['photoUrl'] = imageUrl;
        }
      }

      await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser!.uid)
          .update(updateData);

      setState(() => _isEditing = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Profile Updated Successfully!")),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Logic to send reset email
  // Improved Reset Password Logic
  Future<void> _resetPassword(String email) async {
    // 1. Validation check
    if (email.isEmpty || !email.contains('@') || email == "No Email") {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error: Invalid email address found.")),
      );
      return;
    }

    // 2. Show Confirmation Dialog first
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Reset Password"),
        content: Text("Send a password reset link to $email?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryBlue),
            child: const Text("Send Email", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return; // Stop if user cancelled

    // 3. Send Request with Loading Indicator
    try {
      // Show loading snackbar
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Sending email..."), duration: Duration(seconds: 1)),
      );

      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);

      if (mounted) {
        // Success Message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Link sent! Check your inbox at $email"),
            backgroundColor: Colors.green,
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      // Firebase specific errors (e.g. User not found)
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: ${e.message}"), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }
   // --- SHOWCASE FUNCTIONS ---

  void _showAchievements() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Your Achievements"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildBadge(Icons.local_fire_department, Colors.orange, "Burner"),
                _buildBadge(Icons.directions_run, Colors.blue, "Runner"),
                _buildBadge(Icons.fitness_center, Colors.purple, "Lifter"),
              ],
            ),
            const SizedBox(height: 20),
            const Text("You have completed 12 workouts this month! Keep it up!", textAlign: TextAlign.center, style: TextStyle(color: AppColors.grayText)),
          ],
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text("Close"))],
      ),
    );
  }

  Widget _buildBadge(IconData icon, Color color, String label) {
    return Column(
      children: [
        CircleAvatar(radius: 25, backgroundColor: color.withOpacity(0.2), child: Icon(icon, color: color)),
        const SizedBox(height: 5),
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
      ],
    );
  }

  void _showActivityHistory() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Activity History", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 15),
            _buildHistoryItem("Full Body Workout", "Yesterday, 10:00 AM", "45 mins"),
            _buildHistoryItem("Morning Yoga", "Oct 24, 7:00 AM", "30 mins"),
            _buildHistoryItem("Cardio Blast", "Oct 22, 6:30 PM", "20 mins"),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryItem(String title, String date, String duration) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: AppColors.borderColor, borderRadius: BorderRadius.circular(10)),
        child: const Icon(Icons.history, color: AppColors.primaryBlue),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text("$date • $duration"),
    );
  }

  void _showWorkoutProgress() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Workout Progress"),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("This Week", style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 10),
            LinearProgressIndicator(value: 0.7, color: AppColors.primaryBlue, backgroundColor: AppColors.borderColor),
            SizedBox(height: 5),
            Text("70% of weekly goal reached", style: TextStyle(fontSize: 12, color: AppColors.grayText)),
            SizedBox(height: 20),
            Text("Calories Burned", style: TextStyle(fontWeight: FontWeight.bold)),
            Text("2,450 kcal", style: TextStyle(fontSize: 24, color: AppColors.secondaryBlue, fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text("Awesome"))],
      ),
    );
  }

  void _showContactUs() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Contact Us"),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(leading: Icon(Icons.email, color: AppColors.primaryBlue), title: Text("support@fitnessx.com")),
            ListTile(leading: Icon(Icons.phone, color: AppColors.primaryBlue), title: Text("+1 (800) 123-4567")),
            ListTile(leading: Icon(Icons.location_on, color: AppColors.primaryBlue), title: Text("123 Fitness St, Workout City")),
          ],
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text("Close"))],
      ),
    );
  }

  void _showPrivacyPolicy() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(25),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Privacy Policy", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              SizedBox(height: 20),
              Text("1. Data Collection", style: TextStyle(fontWeight: FontWeight.bold)),
              Text("We collect your height, weight, and activity data to improve your fitness plan.", style: TextStyle(color: AppColors.grayText)),
              SizedBox(height: 15),
              Text("2. Data Usage", style: TextStyle(fontWeight: FontWeight.bold)),
              Text("Your data is safe with us. We do not sell your personal information to third parties.", style: TextStyle(color: AppColors.grayText)),
              SizedBox(height: 15),
              Text("3. Security", style: TextStyle(fontWeight: FontWeight.bold)),
              Text("We use industry-standard encryption to protect your account.", style: TextStyle(color: AppColors.grayText)),
            ],
          ),
        ),
      ),
    );
  }

  void _showSettings() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Settings", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            SwitchListTile(
              title: const Text("Push Notifications"),
              value: true, 
              activeColor: AppColors.primaryBlue,
              onChanged: (val) {},
            ),
            SwitchListTile(
              title: const Text("Dark Mode"),
              value: false, 
              activeColor: AppColors.primaryBlue,
              onChanged: (val) {},
            ),
            SwitchListTile(
              title: const Text("Sound Effects"),
              value: true, 
              activeColor: AppColors.primaryBlue,
              onChanged: (val) {},
            ),
          ],
        ),
      ),
    );
  }
  // --- UI ---

  @override
  Widget build(BuildContext context) {
    if (currentUser == null) return const Scaffold(body: Center(child: Text("Login required")));

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Profile", style: TextStyle(color: AppColors.blackText, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        actions: [
          // 2. LOGOUT BUTTON (3 Dots)
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_horiz, color: AppColors.blackText),
            onSelected: (value) async {
              if (value == 'logout') {
                await AuthService().signOut();
                if (context.mounted) context.go('/login');
              }
            },
            itemBuilder: (BuildContext context) => [
              const PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, color: Colors.red, size: 20),
                    SizedBox(width: 10),
                    Text("Logout", style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          )
        ],
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('users').doc(currentUser!.uid).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (!snapshot.hasData || !snapshot.data!.exists) return const Center(child: Text("User not found"));

          var userData = snapshot.data!.data() as Map<String, dynamic>;

          // Fill controllers if not editing
          if (!_isEditing) {
            _nameController.text = userData['firstName'] ?? "";
            _programController.text = userData['programTitle'] ?? "Lose a Fat Program"; // Default text
            _heightController.text = (userData['height'] ?? 0).toString();
            _weightController.text = (userData['weight'] ?? 0).toString();
            _ageController.text = (userData['age'] ?? 0).toString();
          }

          String? photoUrl = userData['photoUrl'];
          String email = userData['email'] ?? currentUser!.email ?? "No Email";

          return SingleChildScrollView(
            padding: const EdgeInsets.all(25),
            child: Column(
              children: [
                // --- TOP SECTION: Avatar, Name, Program, Edit Button ---
                Row(
                  children: [
                    GestureDetector(
                      onTap: _pickImage,
                      child: Stack(
                        children: [
                          CircleAvatar(
                            radius: 30,
                            backgroundColor: AppColors.borderColor,
                            backgroundImage: _selectedImage != null
                                ? FileImage(_selectedImage!) as ImageProvider
                                : (photoUrl != null && photoUrl.isNotEmpty
                                    ? NetworkImage(photoUrl)
                                    : const AssetImage("assets/images/user_avatar.png") as ImageProvider),
                          ),
                          if (_isEditing)
                            Positioned(
                              bottom: 0, right: 0,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(color: AppColors.secondaryBlue, shape: BoxShape.circle),
                                child: const Icon(Icons.camera_alt, size: 12, color: Colors.white),
                              ),
                            )
                        ],
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _isEditing 
                            ? TextField(
                                controller: _nameController, 
                                decoration: const InputDecoration(isDense: true, contentPadding: EdgeInsets.zero, hintText: "Name"),
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              )
                            : Text(userData['firstName'] ?? "User", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          
                          // 3. EDITABLE PROGRAM TEXT
                          _isEditing
                            ? TextField(
                                controller: _programController,
                                decoration: const InputDecoration(isDense: true, contentPadding: EdgeInsets.zero, hintText: "Program Name"),
                                style: const TextStyle(color: AppColors.grayText, fontSize: 12),
                              )
                            : Text(userData['programTitle'] ?? "Lose a Fat Program", style: const TextStyle(color: AppColors.grayText, fontSize: 12)),
                        ],
                      ),
                    ),
                    ElevatedButton(
                      onPressed: _isLoading 
                        ? null 
                        : () {
                            if (_isEditing) _saveProfile();
                            else setState(() => _isEditing = true);
                          },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isEditing ? AppColors.success : AppColors.primaryBlue,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      ),
                      child: _isLoading 
                        ? const SizedBox(width: 15, height: 15, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : Text(_isEditing ? "Save" : "Edit", style: const TextStyle(fontSize: 12, color: Colors.white)),
                    )
                  ],
                ),
                
                const SizedBox(height: 30),
                
                // --- STATS ROW ---
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildEditableStatCard(_heightController, "Height", "cm"),
                    _buildEditableStatCard(_weightController, "Weight", "kg"),
                    _buildEditableStatCard(_ageController, "Age", "yo"),
                  ],
                ),

                const SizedBox(height: 30),

                // --- 2. PERSONAL DATA SECTION (New) ---
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.05), spreadRadius: 5, blurRadius: 10)],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Personal Data", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 15),
                      
                      // Email Display
                      Row(
                        children: [
                          const Icon(Icons.email_outlined, color: AppColors.primaryBlue, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text("Email", style: TextStyle(fontSize: 10, color: AppColors.grayText)),
                                Text(email, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                              ],
                            ),
                          )
                        ],
                      ),
                      const SizedBox(height: 15),
                      
                      // Reset Password Button
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () => _resetPassword(email),
                          icon: const Icon(Icons.lock_reset, size: 18),
                          label: const Text("Reset Password"),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.secondaryBlue,
                            side: const BorderSide(color: AppColors.secondaryBlue),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      )
                    ],
                  ),
                ),

                const SizedBox(height: 30),

                // --- ACCOUNT SECTION ---
               // --- ACCOUNT SECTION ---
                _buildSectionHeader("Account"),
                const SizedBox(height: 15),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.05), spreadRadius: 5, blurRadius: 10)],
                  ),
                  child: Column(
                    children: [
                      // Pass the function name without ()
                      _buildProfileOption(Icons.emoji_events_outlined, "Achievement", _showAchievements),
                      _buildProfileOption(Icons.history, "Activity History", _showActivityHistory),
                      _buildProfileOption(Icons.insights, "Workout Progress", _showWorkoutProgress),
                    ],
                  ),
                ),
                
                const SizedBox(height: 30),

                // --- OTHER SECTION ---
                // --- OTHER SECTION ---
                _buildSectionHeader("Other"),
                const SizedBox(height: 15),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.05), spreadRadius: 5, blurRadius: 10)],
                  ),
                  child: Column(
                    children: [
                      _buildProfileOption(Icons.mail_outline, "Contact Us", _showContactUs),
                      _buildProfileOption(Icons.privacy_tip_outlined, "Privacy Policy", _showPrivacyPolicy),
                      _buildProfileOption(Icons.settings_outlined, "Settings", _showSettings),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // --- HELPERS ---
  
  Widget _buildEditableStatCard(TextEditingController controller, String label, String unit) {
    return Container(
      width: 100,
      padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.05), spreadRadius: 2, blurRadius: 10)],
      ),
      child: Column(
        children: [
          _isEditing
            ? TextField(
                controller: controller,
                textAlign: TextAlign.center,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: AppColors.secondaryBlue, fontWeight: FontWeight.bold, fontSize: 16),
                decoration: const InputDecoration(isDense: true, border: InputBorder.none),
              )
            : Text("${controller.text}$unit", style: const TextStyle(color: AppColors.secondaryBlue, fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 5),
          Text(label, style: const TextStyle(color: AppColors.grayText, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Container(alignment: Alignment.centerLeft, child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)));
  }

 // Update this helper function to accept an 'onTap' callback
  Widget _buildProfileOption(IconData icon, String title, VoidCallback onTap) {
    return Column(
      children: [
        ListTile(
          leading: Icon(icon, color: AppColors.primaryBlue),
          title: Text(title, style: const TextStyle(fontSize: 14, color: AppColors.grayText)),
          trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
          contentPadding: EdgeInsets.zero,
          onTap: onTap, // NOW IT IS CLICKABLE
        ),
        const Divider(height: 1),
      ],
    );
  }
}