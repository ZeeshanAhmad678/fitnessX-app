import 'package:fitness_app/constants/app_colors.dart';
import 'package:fitness_app/features/home/activity_tracker_screen.dart';
import 'package:fitness_app/features/profile/profile_screen.dart';      
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; 
import 'package:firebase_auth/firebase_auth.dart';    
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';


class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  // 1. UPDATED PAGE LIST (Only 3 Pages now)
  final List<Widget> _pages = [
    const HomeDashboard(),          // Index 0
    const ActivityTrackerScreen(),  // Index 1 (The Middle Page)
    const ProfileScreen(),          // Index 2
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      
      // BODY: Switches between the 3 pages
      body: _pages[_selectedIndex],

      // IMPROVED NAVBAR UI
      bottomNavigationBar: Container(
        // 1. Add Shadow and Rounded Corners for better UX
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(30),
            topRight: Radius.circular(30),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              spreadRadius: 0,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        // 2. ClipRRect ensures the ripple doesn't go outside the rounded corners
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(30),
            topRight: Radius.circular(30),
          ),
          child: Theme(
            // 3. THIS REMOVES THE SPREADING CLICK ANIMATION
            data: Theme.of(context).copyWith(
              splashColor: Colors.transparent,
              highlightColor: Colors.transparent,
            ),
            child: BottomNavigationBar(
              items: const <BottomNavigationBarItem>[
                BottomNavigationBarItem(
                  icon: Icon(Icons.home_filled),
                  label: 'Home',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.bar_chart_rounded), 
                  label: 'Activity',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.person_outline),
                  label: 'Profile',
                ),
              ],
              currentIndex: _selectedIndex,
              type: BottomNavigationBarType.fixed,
              backgroundColor: Colors.white,
              selectedItemColor: AppColors.secondaryBlue, 
              unselectedItemColor: AppColors.grayText,
              showSelectedLabels: false, // Clean look
              showUnselectedLabels: false,
              elevation: 0, // We added our own shadow above
              onTap: _onItemTapped,
            ),
          ),
        ),
      ),
    );
  }
}


class HomeDashboard extends StatefulWidget {
  const HomeDashboard({super.key});

  @override
  State<HomeDashboard> createState() => _HomeDashboardState();
}

class _HomeDashboardState extends State<HomeDashboard> {
  final User? currentUser = FirebaseAuth.instance.currentUser;
  
  // Local State for Activities
  List<Map<String, dynamic>> _localActivities = [];

  final List<Map<String, String>> _quotes = [
    {"text": "The only bad workout is the one that didn't happen.", "author": "Unknown"},
    {"text": "Fitness is not about being better than someone else. It’s about being better than you were yesterday.", "author": "Khloe Kardashian"},
    {"text": "Don't limit your challenges. Challenge your limits.", "author": "Jerry Dunn"},
    {"text": "Action is the foundational key to all success.", "author": "Pablo Picasso"},
    {"text": "Motivation is what gets you started. Habit is what keeps you going.", "author": "Jim Ryun"},
    {"text": "What hurts today makes you stronger tomorrow.", "author": "Jay Cutler"},
  ];

  @override
  void initState() {
    super.initState();
    _loadActivities(); // Load data when screen opens
  }

  
  Future<void> _loadActivities() async {
    final prefs = await SharedPreferences.getInstance();
    final String key = 'activities_${currentUser?.uid}';
    final String? data = prefs.getString(key);

    if (data != null) {
      // 1. Decode the data
      List<dynamic> decoded = jsonDecode(data);
      List<Map<String, dynamic>> loadedList = List<Map<String, dynamic>>.from(decoded);

      // 2. Filter: Remove items older than 24 hours
      final now = DateTime.now();
      bool needsSave = false; // Flag to check if we modified the list

      loadedList.removeWhere((item) {
        final activityTime = DateTime.parse(item['timestamp']);
        final difference = now.difference(activityTime);
        
        // If difference is 24 hours or more, return true to REMOVE it
        if (difference.inHours >= 24) {
          needsSave = true; // We found old data, so we need to save the cleaner list
          return true;
        }
        return false;
      });

      // 3. Update UI
      setState(() {
        _localActivities = loadedList;
      });

      // 4. Update Storage (Clean up the old data permanently)
      if (needsSave) {
        await prefs.setString(key, jsonEncode(loadedList));
      }
    }
  }

  // 2. Add Activity
  Future<void> _addActivity(String title) async {
    final prefs = await SharedPreferences.getInstance();
    final String key = 'activities_${currentUser?.uid}';

    // Create new activity object
    final newActivity = {
      'title': title,
      'timestamp': DateTime.now().toIso8601String(), // Store time as String
    };

    setState(() {
      _localActivities.insert(0, newActivity); // Add to top of list
    });

    // Save to phone storage
    await prefs.setString(key, jsonEncode(_localActivities));
  }

  // 3. Delete Activity
  Future<void> _deleteActivity(int index) async {
    final prefs = await SharedPreferences.getInstance();
    final String key = 'activities_${currentUser?.uid}';

    setState(() {
      _localActivities.removeAt(index);
    });

    // Update phone storage
    await prefs.setString(key, jsonEncode(_localActivities));
  }

  // --- BMI LOGIC (Kept from before) ---
  Map<String, dynamic> _calculateBMI(double heightCm, double weightKg) {
    if (heightCm <= 0 || weightKg <= 0) {
      return {"bmi": "0.0", "msg": "Update Profile", "color": Colors.grey};
    }
    double heightM = heightCm / 100;
    double bmi = weightKg / (heightM * heightM);
    
    if (bmi < 18.5) return {"bmi": bmi.toStringAsFixed(1), "msg": "You are Underweight", "color": Colors.orangeAccent};
    if (bmi < 25) return {"bmi": bmi.toStringAsFixed(1), "msg": "You have Normal Weight", "color": AppColors.secondaryBlue};
    return {"bmi": bmi.toStringAsFixed(1), "msg": "You are Overweight", "color": Colors.redAccent};
  }

  // --- DIALOG ---
  void _showAddActivityDialog(BuildContext context) {
    TextEditingController activityController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Add New Activity"),
          content: TextField(
            controller: activityController,
            decoration: const InputDecoration(hintText: "e.g., Drank 500ml Water"),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
            ElevatedButton(
              onPressed: () {
                if (activityController.text.isNotEmpty) {
                  _addActivity(activityController.text.trim());
                  Navigator.pop(context);
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryBlue),
              child: const Text("Add", style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (currentUser == null) return const Center(child: Text("Loading..."));

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(currentUser!.uid).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        
        var userData = snapshot.data!.data() as Map<String, dynamic>;
        String firstName = userData['firstName'] ?? "User";
        double height = double.tryParse(userData['height'].toString()) ?? 0;
        double weight = double.tryParse(userData['weight'].toString()) ?? 0;
        var bmiData = _calculateBMI(height, weight);

        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Welcome Back,", style: TextStyle(fontSize: 12, color: AppColors.grayText)),
                Text(firstName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.blackText)),
              ],
            ),
            actions: [
              // Notification Icon with Hardcoded Messages
              PopupMenuButton<String>(
                icon: const Icon(Icons.notifications_none, color: AppColors.blackText),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                offset: const Offset(0, 50), // Moves the menu down slightly
                itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                  const PopupMenuItem<String>(
                    enabled: false, // Makes it a header, not clickable
                    child: Text("Notifications", style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  const PopupMenuDivider(),
                  const PopupMenuItem<String>(
                    value: '1',
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(
                        backgroundColor: Colors.orangeAccent,
                        radius: 15,
                        child: Icon(Icons.local_fire_department, color: Colors.white, size: 16),
                      ),
                      title: Text("Don't miss your workout!", style: TextStyle(fontSize: 14)),
                      subtitle: Text("2 hours ago", style: TextStyle(fontSize: 12, color: Colors.grey)),
                    ),
                  ),
                  const PopupMenuItem<String>(
                    value: '2',
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(
                        backgroundColor: Colors.blueAccent,
                        radius: 15,
                        child: Icon(Icons.water_drop, color: Colors.white, size: 16),
                      ),
                      title: Text("Drink water now", style: TextStyle(fontSize: 14)),
                      subtitle: Text("30 mins ago", style: TextStyle(fontSize: 12, color: Colors.grey)),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 10), // Small spacing at the end
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // BMI Section
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(gradient: AppColors.blueGradient, borderRadius: BorderRadius.circular(20)),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("BMI (Body Mass Index)", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 10),
                            Text(bmiData['msg'], style: const TextStyle(color: Colors.white, fontSize: 14)),
                            const SizedBox(height: 5),
                            Text(bmiData['bmi'], style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                      Container(
                        width: 80, height: 80,
                        decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
                        child: Center(child: Text("Kg/m²", style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 10))),
                      )
                    ],
                  ),
                ),
                const SizedBox(height: 30),
                // --- PASTE THIS WHERE THE GRAPH WAS ---
                const Text("Quote of the Day", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 15),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.primaryBlue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.primaryBlue.withOpacity(0.2)),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.format_quote_rounded, color: AppColors.secondaryBlue, size: 40),
                      const SizedBox(height: 10),
                      Text(
                        // Picks a quote based on the day
                        "\"${_quotes[DateTime.now().day % _quotes.length]['text']}\"",
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 16, fontStyle: FontStyle.italic, color: AppColors.blackText, height: 1.5),
                      ),
                      const SizedBox(height: 15),
                      Text(
                        "- ${_quotes[DateTime.now().day % _quotes.length]['author']}",
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.grayText),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 25),
                
              
                const SizedBox(height: 25),

                // LATEST ACTIVITY HEADER
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Latest Activity", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    TextButton.icon(
                      onPressed: () => _showAddActivityDialog(context),
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text("Add New"),
                      style: TextButton.styleFrom(foregroundColor: AppColors.grayText),
                    )
                  ],
                ),
                const SizedBox(height: 10),

                // LOCAL STORAGE ACTIVITY LIST
                _localActivities.isEmpty
                  ? const Padding(padding: EdgeInsets.all(20), child: Center(child: Text("No activities yet", style: TextStyle(color: Colors.grey))))
                  : ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _localActivities.length,
                      itemBuilder: (context, index) {
                        final item = _localActivities[index];
                        
                        // Calculate Time Ago
                        final dt = DateTime.parse(item['timestamp']);
                        final diff = DateTime.now().difference(dt);
                        String timeAgo = diff.inMinutes < 60 ? "${diff.inMinutes} mins ago" 
                                       : diff.inHours < 24 ? "${diff.inHours} hours ago" 
                                       : "${diff.inDays} days ago";

                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(10), // reduced padding slightly
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(15),
                            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 5))],
                          ),
                          child: ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: const CircleAvatar(
                              backgroundColor: Color(0xFFEBB4B4),
                              radius: 25,
                              child: Icon(Icons.fitness_center, color: Colors.white, size: 20),
                            ),
                            title: Text(item['title'], style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                            subtitle: Text(timeAgo, style: const TextStyle(fontSize: 12, color: AppColors.grayText)),
                            
                            // 3-DOT MENU FOR DELETION
                            trailing: PopupMenuButton<String>(
                              icon: const Icon(Icons.more_vert, color: AppColors.grayText),
                              onSelected: (value) {
                                if (value == 'delete') {
                                  _deleteActivity(index);
                                }
                              },
                              itemBuilder: (context) => [
                                const PopupMenuItem(
                                  value: 'delete',
                                  child: Row(
                                    children: [
                                      Icon(Icons.delete, color: Colors.red, size: 20),
                                      SizedBox(width: 10),
                                      Text("Delete", style: TextStyle(color: Colors.red)),
                                    ],
                                  ),
                                )
                              ],
                            ),
                          ),
                        );
                      },
                    ),
              ],
            ),
          ),
        );
      },
    );
  }
}