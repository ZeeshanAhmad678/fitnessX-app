import 'dart:async'; // REQUIRED for StreamSubscription
import 'package:cloud_firestore/cloud_firestore.dart'; // FIXES: FirebaseFirestore, Timestamp
import 'package:firebase_auth/firebase_auth.dart'; // FIXES: FirebaseAuth, User
import 'package:fitness_app/constants/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:pedometer/pedometer.dart'; 
import 'package:permission_handler/permission_handler.dart'; 

class ActivityTrackerScreen extends StatefulWidget {
  const ActivityTrackerScreen({super.key});

  @override
  State<ActivityTrackerScreen> createState() => _ActivityTrackerScreenState();
}

class _ActivityTrackerScreenState extends State<ActivityTrackerScreen> {
  final User? currentUser = FirebaseAuth.instance.currentUser;
  
  bool _isEditing = false;
  bool _isLoading = false;

  late TextEditingController _waterController;
  late TextEditingController _stepsController;

  // --- STEP COUNTER VARIABLES ---
  late Stream<StepCount> _stepCountStream;
  String _liveSteps = "0"; 
  int _initialStepCount = -1; // To reset steps to 0 on app start
  bool _hasShownStepCongrats = false; // NEW: Prevents spamming the dialog
  StreamSubscription<StepCount>? _subscription;

  @override
  void initState() {
    super.initState();
    _waterController = TextEditingController();
    _stepsController = TextEditingController();
    
    // Initialize Pedometer when screen loads
    _initPedometer();
  }

  // --- LOGIC: PEDOMETER ---
  void _initPedometer() async {
    // 1. Request Permission
    var status = await Permission.activityRecognition.request();
    
    if (status.isGranted) {
      // 2. Listen to the sensor
      _stepCountStream = Pedometer.stepCountStream;
      
      _subscription = _stepCountStream.listen(
        _onStepCount,
        onError: (error) {
           print("Pedometer Error: $error");
           if(mounted) setState(() => _liveSteps = "Error");
        },
        cancelOnError: true,
      );
    } else {
      if(mounted) setState(() => _liveSteps = "No Perms");
    }
  }

  void _onStepCount(StepCount event) {
    if (mounted) {
      // Logic to start count from 0 when app opens
      if (_initialStepCount == -1) {
        setState(() {
          _initialStepCount = event.steps;
        });
      }

      int sessionSteps = event.steps - _initialStepCount;
      if (sessionSteps < 0) sessionSteps = 0; // Safety check

      setState(() {
        _liveSteps = sessionSteps.toString();
      });

      // --- NEW: CHECK IF GOAL REACHED ---
      int targetSteps = int.tryParse(_stepsController.text) ?? 2400; // Default if text is weird
      
      // If we crossed the target AND haven't shown the popup yet
      if (sessionSteps >= targetSteps && !_hasShownStepCongrats && targetSteps > 0) {
        _hasShownStepCongrats = true; // Mark as shown so it doesn't popup again on next step
        
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text("🏆 Step Goal Crushed!"),
            content: Text("You just hit $targetSteps steps. Keep moving!"),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text("Awesome"))
            ],
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _waterController.dispose();
    _stepsController.dispose();
    _subscription?.cancel(); // Stop listening to save battery
    super.dispose();
  }

  // --- LOGIC: WATER & SAVING ---
  int _parseWaterTarget(String target) {
    String clean = target.toLowerCase().replaceAll(RegExp(r'[^0-9.]'), '');
    double val = double.tryParse(clean) ?? 0;
    if (target.toLowerCase().contains('l') || val < 20) return (val * 1000).toInt();
    return val.toInt();
  }

  Future<void> _addWater(int amountMl, int currentTotal, int targetMl) async {
    try {
      int newTotal = currentTotal + amountMl;
      await FirebaseFirestore.instance.collection('users').doc(currentUser!.uid).update({'currentWaterIntake': newTotal});
      
      // Congratulate if goal reached
      if (currentTotal < targetMl && newTotal >= targetMl && mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text("🎉 Hydration Goal Reached!"),
            content: const Text("Amazing job! You hit your water target."),
            actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text("Dismiss"))],
          ),
        );
      }
    } catch (e) {
      debugPrint("Error: $e");
    }
  }

  Future<void> _saveTargets() async {
    setState(() => _isLoading = true);
    try {
      await FirebaseFirestore.instance.collection('users').doc(currentUser!.uid).update({
        'targetWater': _waterController.text.trim(),
        'targetSteps': _stepsController.text.trim(),
      });
      // Reset the flag if they change the target so they can get congratulated again
      _hasShownStepCongrats = false; 
      setState(() => _isEditing = false);
    } catch (e) {
      if(mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      if(mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (currentUser == null) return const Scaffold(body: Center(child: Text("Login required")));

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text("Activity Tracker", style: TextStyle(color: AppColors.blackText, fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [IconButton(icon: const Icon(Icons.more_horiz, color: AppColors.blackText), onPressed: () {})],
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('users').doc(currentUser!.uid).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (!snapshot.hasData || !snapshot.data!.exists) return const Center(child: Text("User data not found"));

          var userData = snapshot.data!.data() as Map<String, dynamic>;
          
          if (!_isEditing) {
            _waterController.text = userData['targetWater'] ?? "8L";
            _stepsController.text = userData['targetSteps'] ?? "2400";
          }

          int currentWater = userData['currentWaterIntake'] ?? 0;
          int targetWaterMl = _parseWaterTarget(_waterController.text);
          int waterLeft = targetWaterMl - currentWater;
          if (waterLeft < 0) waterLeft = 0;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. TODAY TARGET SECTION
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.primaryBlue.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text("Today Target", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          GestureDetector(
                            onTap: _isLoading ? null : () {
                              if (_isEditing) _saveTargets();
                              else setState(() => _isEditing = true);
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(gradient: AppColors.blueGradient, borderRadius: BorderRadius.circular(10)),
                              child: _isLoading 
                                ? const SizedBox(width: 15, height: 15, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                : Text(_isEditing ? "Save" : "Edit", style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 15),
                      Row(
                        children: [
                          // WATER CARD
                          Expanded(child: _buildEditableCard(controller: _waterController, title: "Water Intake", icon: Icons.local_drink, isEditing: _isEditing, color: Colors.white)),
                          const SizedBox(width: 15),
                          
                          // STEPS CARD (Updated with Live Sensor Data)
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 10),
                              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15)),
                              child: Row(
                                children: [
                                  const Icon(Icons.directions_walk, color: AppColors.primaryBlue, size: 30),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        // Editable Target
                                        _isEditing
                                            ? SizedBox(height: 30, child: TextField(controller: _stepsController, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.secondaryBlue), decoration: const InputDecoration(isDense: true, contentPadding: EdgeInsets.zero, border: UnderlineInputBorder())))
                                            : Text("Target: ${_stepsController.text}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.secondaryBlue)),
                                        
                                        const SizedBox(height: 5),
                                        
                                        // LIVE STEPS DISPLAY
                                        Text(
                                          "$_liveSteps Steps", 
                                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.green),
                                        ),
                                        const Text("Live Sensor", style: TextStyle(fontSize: 9, color: AppColors.grayText)),
                                      ],
                                    ),
                                  )
                                ],
                              ),
                            ),
                          ),
                        ],
                      )
                    ],
                  ),
                ),
                
                const SizedBox(height: 30),

                // 2. WATER INTAKE TRACKER
                const Text("Drunk Water", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                const SizedBox(height: 15),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildWaterBtn(100, currentWater, targetWaterMl),
                      _buildWaterBtn(200, currentWater, targetWaterMl),
                      _buildWaterBtn(300, currentWater, targetWaterMl),
                      _buildWaterBtn(500, currentWater, targetWaterMl),
                      _buildWaterBtn(1000, currentWater, targetWaterMl),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: waterLeft == 0 ? AppColors.success.withOpacity(0.1) : const Color(0xFFFFEEEE), 
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: waterLeft == 0 ? AppColors.success : Colors.redAccent.withOpacity(0.5))
                  ),
                  child: Column(
                    children: [
                      Text(
                        waterLeft == 0 ? "Target Achieved!" : "$waterLeft ml",
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: waterLeft == 0 ? AppColors.success : Colors.redAccent),
                      ),
                      const SizedBox(height: 5),
                      Text(waterLeft == 0 ? "Great job keeping hydrated." : "Remaining to reach goal", style: const TextStyle(color: AppColors.grayText, fontSize: 12)),
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

  // Helper Widgets
  Widget _buildWaterBtn(int amount, int current, int target) {
    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: GestureDetector(
        onTap: () => _addWater(amount, current, target),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.primaryBlue.withOpacity(0.3)),
          ),
          child: Text("+${amount}ml", style: const TextStyle(color: AppColors.primaryBlue, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }

  Widget _buildEditableCard({
    required TextEditingController controller,
    required String title,
    required IconData icon,
    required bool isEditing,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 10),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(15)),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primaryBlue, size: 30),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                isEditing
                    ? SizedBox(height: 30, child: TextField(controller: controller, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.secondaryBlue), decoration: const InputDecoration(isDense: true, contentPadding: EdgeInsets.zero, border: UnderlineInputBorder())))
                    : Text(controller.text.isEmpty ? "0" : controller.text, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.secondaryBlue)),
                const SizedBox(height: 5),
                Text(title, style: const TextStyle(fontSize: 10, color: AppColors.grayText)),
              ],
            ),
          )
        ],
      ),
    );
  }
}