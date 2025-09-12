import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../services/token_service.dart';
import 'package:http/http.dart' as http;
import 'package:learning_app/services/Notification.dart';
import 'dart:convert';
import 'package:learning_app/screens/notifications_screen.dart';
import 'calendar_provider.dart';
import 'firebase_options.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'moodle_api_service.dart';
import 'moodle_calendar_widget.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:learning_app/LocalNotificationsService.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

// Create a single instance of the plugin
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
FlutterLocalNotificationsPlugin();
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Initialize Firebase
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('Firebase initialized successfully');
  } catch (e) {
    print('Firebase initialization failed: $e');
  }

  // Initialize notifications service - this will be done again in AuthCheck but that's okay
  try {
    await LocalNotificationsService.initialize();
    print('LocalNotificationsService initialized successfully in main');
  } catch (e) {
    print('LocalNotificationsService initialization failed: $e');
  }

  runApp(AuthCheck());
}

class AuthCheck extends StatefulWidget {
  const AuthCheck({super.key});

  @override
  State<AuthCheck> createState() => _AuthCheckState();
}
class _AuthCheckState extends State<AuthCheck> {
  bool _notificationsInitialized = false;

  @override
  void initState() {
    super.initState();

    _checkNotificationStatus();
  }

  Future<void> _checkNotificationStatus() async {
    try {
      // Just check if notifications are working
      final pending = await LocalNotificationsService.getPendingNotifications();


      final canScheduleExact = await LocalNotificationsService.canScheduleExactNotifications();


      setState(() {
        _notificationsInitialized = true;
      });


    } catch (e) {

      try {
        await LocalNotificationsService.initialize();

        setState(() {
          _notificationsInitialized = true;
        });
      } catch (e2) {
        print('AuthCheck - Re-initialization failed: $e2');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    print('AuthCheck build called, notifications initialized: $_notificationsInitialized');

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      routes: {
        "/notifications": (context) => const Notifications_screen(),
      },
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 20),
                    Text('Loading...'),
                  ],
                ),
              ),
            );
          }

          if (snapshot.hasData) {

            return MainPage();
          } else {

            return const Homepage();
          }
        },
      ),
    );
  }
}
class Homepage extends StatefulWidget {
  const Homepage({super.key});

  @override
  State<Homepage> createState() => _HomepageState();
}
class _HomepageState extends State<Homepage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            // Background with gradient overlay
            Container(
              height: double.infinity,
              width: double.infinity,
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage("images/background1.png"),
                  fit: BoxFit.cover,
                ),
              ),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(0.7),
                      Colors.black.withOpacity(0.5),
                      Colors.black.withOpacity(0.3),
                    ],
                  ),
                ),
              ),
            ),

            // Main Content
            SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // App Title & Slogan
                  Padding(
                    padding: const EdgeInsets.only(top: 190, left: 10),
                    child: Column(
                      children: [
                        Text(
                          "Welcome to",
                          style: TextStyle(
                            color: Colors.grey[300],
                            fontSize: 42,
                            fontWeight: FontWeight.w300,
                            letterSpacing: 1.5,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          "MoodleTrack",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 58,
                            fontWeight: FontWeight.bold,
                            shadows: [
                              Shadow(
                                blurRadius: 10.0,
                                color: Colors.black.withOpacity(0.5),
                                offset: const Offset(2.0, 2.0),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 15),
                        Text(
                          "Stay on Time. Stay on Track.",
                          style: TextStyle(
                            color: Colors.grey[300],
                            fontSize: 20,
                            fontWeight: FontWeight.w500,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Sign In Button
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        margin: const EdgeInsets.all(40),
                        padding: const EdgeInsets.all(25),
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => LoginPage()),
                            );
                          },
                          icon: const Icon(Icons.login, size: 28),
                          label: const Text(
                            "Sign In",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            foregroundColor: Colors.white,
                            backgroundColor: Colors.orange[700],
                            padding: const EdgeInsets.symmetric(
                                horizontal: 40, vertical: 18),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            shadowColor: Colors.black.withOpacity(0.4),
                            elevation: 8,
                          ),
                        ),
                      ),
                    ],
                  ),

                  // Divider
                  Container(
                    height: 1,
                    width: double.infinity,
                    color: Colors.grey[400]!.withOpacity(0.5),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  State<LoginPage> createState() => _LoginPageState();
}
class _LoginPageState extends State<LoginPage> {
  bool isLoading = false;
  bool _obscurePassword = true;
  final _formKey = GlobalKey<FormState>();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passController = TextEditingController();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  Future<String?> _getMoodleToken(String username, String password) async {
    try {
      final response = await http.get(
        Uri.parse(
            'https://courses.ms.wits.ac.za/moodle/login/token.php?username=$username&password=$password&service=moodle_mobile_app'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['token']?.toString();
      } else {
        print('Token request failed: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Token error: $e');
      return null;
    }
  }
  Future<UserCredential?> _createFirebaseUser(String email, String password) async {
    try {
      print('🔥 Creating new Firebase user for: $email');

      return await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      print('Firebase creation failed: ${e.code} - ${e.message}');

      switch (e.code) {
        case 'weak-password':
          Fluttertoast.showToast(msg: "Password is too weak");
          break;
        case 'email-already-in-use':
          Fluttertoast.showToast(msg: "Email already registered");
          break;
        case 'invalid-email':
          Fluttertoast.showToast(msg: "Invalid email format");
          break;
        case 'operation-not-allowed':
          Fluttertoast.showToast(msg: "Email/password authentication is disabled");
          break;
        case 'network-request-failed':
          Fluttertoast.showToast(msg: "Network error. Check your connection");
          break;
        default:
          Fluttertoast.showToast(msg: "Registration failed: ${e.message}");
      }
      return null;
    } catch (e) {
      print('Unexpected Firebase auth error: $e');
      Fluttertoast.showToast(msg: "Authentication error: ${e.toString()}");
      return null;
    }
  }
  Future<UserCredential?> _signInFirebaseUser(String email, String password) async {
    try {
      print('🔥 Signing in existing Firebase user: $email');

      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      print('Firebase sign in failed: ${e.code} - ${e.message}');

      switch (e.code) {
        case 'user-not-found':
        case 'invalid-credential':
        case 'wrong-password':
        // These are expected for new users - don't show error
          print('User not found in Firebase - will create new user');
          return null;
        case 'user-disabled':
          Fluttertoast.showToast(msg: "Account has been disabled");
          break;
        case 'too-many-requests':
          Fluttertoast.showToast(msg: "Too many failed attempts. Try again later");
          break;
        case 'network-request-failed':
          Fluttertoast.showToast(msg: "Network error. Check your connection");
          break;
        default:
          Fluttertoast.showToast(msg: "Sign in failed: ${e.message}");
      }
      return null;
    } catch (e) {
      print('Unexpected Firebase sign in error: $e');
      return null;
    }
  }

  Future<bool> _userExistsInFirestore(String studentNumber) async {
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(studentNumber)
          .get();
      return userDoc.exists;
    } catch (e) {
      print('Error checking user existence: $e');
      return false;
    }
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isLoading = true);

    try {
      final email = emailController.text.trim();
      final password = passController.text.trim();

      // Validate email format
      if (!email.contains('@students.wits.ac.za')) {
        Fluttertoast.showToast(msg: "Please use your Wits student email");
        return;
      }

      // Extract student number (should be 7 digits)
      final emailParts = email.split('@');
      if (emailParts.isEmpty || emailParts[0].length != 7) {
        Fluttertoast.showToast(msg: "Invalid student number format");
        return;
      }

      final username = emailParts[0]; // Moodle student number

      // Validate password strength for Firebase
      if (password.length < 6) {
        Fluttertoast.showToast(msg: "Password must be at least 6 characters");
        return;
      }

      print('🔐 Step 1: Attempting Moodle authentication for: $username');

      // STEP 1: Authenticate with Moodle FIRST
      final token = await _getMoodleToken(username, password);

      if (token == null) {
        print('❌ Moodle authentication failed');
        Fluttertoast.showToast(msg: "Invalid Wits student credentials");
        return;
      }

      print('✅ Step 1 Complete: Moodle authentication successful');

      // STEP 2: Store Moodle token
      await TokenService.storeToken(token);

      // STEP 3: Check if this is a returning user or new user
      print('🔍 Step 2: Checking if user exists in system...');

      // First try to sign in existing Firebase user
      UserCredential? userCredential = await _signInFirebaseUser(email, password);

      if (userCredential == null) {
        // User doesn't exist in Firebase, check if they exist in Firestore
        bool existsInFirestore = await _userExistsInFirestore(username);

        if (existsInFirestore) {
          // Edge case: User exists in Firestore but not in Firebase Auth
          // This shouldn't happen, but let's handle it
          print('⚠️ User exists in Firestore but not in Firebase Auth');
          Fluttertoast.showToast(msg: "Account sync issue. Please contact support.");
          return;
        }

        // STEP 4: Create new Firebase user (only for genuinely new users)
        print('✅ Step 3: New user detected. Creating Firebase account...');
        userCredential = await _createFirebaseUser(email, password);

        if (userCredential == null) {
          throw Exception('Could not create Firebase user');
        }

        print('✅ Step 3 Complete: New Firebase user created: ${userCredential.user?.uid}');

        // STEP 5: Create user profile in Firestore
        print('📝 Step 4: Creating user profile in Firestore...');
        await _registerUser(username, email);
        print('✅ Step 4 Complete: User profile created');

        Fluttertoast.showToast(msg: "Account created successfully!");
      } else {
        // STEP 4: Update existing user
        print('✅ Step 3: Existing user signed in: ${userCredential.user?.uid}');

        // Update user info in Firestore
        print('🔄 Step 4: Updating user profile...');
        await _registerUser(username, email);
        print('✅ Step 4 Complete: User profile updated');

        Fluttertoast.showToast(msg: "Welcome back!");
      }

      // STEP 6: Store student number for later use
      await _storeStudentNumber(username);

      // STEP 7: Navigate to MainPage
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => MainPage()),
        );
      }

    } catch (e) {
      print('❌ Login error: $e');
      Fluttertoast.showToast(msg: "Login failed: ${e.toString()}");
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }


  Future<void> _registerUser(String userId, String email) async {
    try {
      final userDoc = FirebaseFirestore.instance.collection('users').doc(userId);
      final snapshot = await userDoc.get();

      if (snapshot.exists) {
        // Update existing user
        await userDoc.update({
          'email': email,
          'lastLogin': FieldValue.serverTimestamp(),
        });
        print('🔄 Updated existing user profile: $userId');
      } else {
        // Create new user profile
        await userDoc.set({
          'userId': userId,
          'email': email,
          'createdAt': FieldValue.serverTimestamp(),
          'lastLogin': FieldValue.serverTimestamp(),
        });
        print('✅ Created new user profile: $userId');
      }
    } catch (e) {
      print('❌ Firestore user error: $e');
      Fluttertoast.showToast(msg: "User profile creation failed");
      rethrow; // Re-throw to handle in login function
    }
  }
  //

  Future<void> _storeStudentNumber(String studentNumber) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('student_number', studentNumber);
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.orange[500],
        elevation: 0,
        title: Text(
          "Login to MoodleTrack",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      backgroundColor: Colors.grey[100],
      body: SafeArea(
        child: Stack(
          children: [
            // Background image with gradient overlay
            Container(
              width: double.infinity,
              height: double.infinity,
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage("images/background1.jpg"),
                  fit: BoxFit.cover,
                ),
              ),
              child: Container(
                width: double.infinity,
                height: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.orange[700]!.withOpacity(0.8),
                      Colors.orange[600]!.withOpacity(0.6),
                      Colors.orange[400]!.withOpacity(0.4),
                    ],
                  ),
                ),
              ),
            ),

            // Login Form
            Center(
              child: SingleChildScrollView(
                child: Container(
                  margin: const EdgeInsets.all(25),
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.92),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 15,
                        spreadRadius: 2,
                        offset: Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Header
                        Icon(
                          Icons.school,
                          size: 50,
                          color: Colors.orange[800],
                        ),
                        const SizedBox(height: 15),
                        Text(
                          "Moodle Login",
                          style: TextStyle(
                            fontSize: 26.0,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange[700],
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          "Enter your Wits student credentials",
                          style: TextStyle(
                            fontSize: 14.0,
                            color: Colors.grey[700],
                          ),
                        ),
                        const SizedBox(height: 25),

                        // Email Field
                        TextFormField(
                          controller: emailController,
                          decoration: InputDecoration(
                            prefixIcon: Icon(Icons.email, color: Colors.orange[700]),
                            hintText: "e.g., 1234567@students.wits.ac.za",
                            labelText: "Student Email",
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey[400]!),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.orange[700]!, width: 2),
                            ),
                            filled: true,
                            fillColor: Colors.grey[50],
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your student email';
                            }
                            if (!value.endsWith('@students.wits.ac.za')) {
                              return 'Must be a valid Wits student email';
                            }
                            if (value.length < 16) {
                              return 'Invalid student email format';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),

                        // Password Field
                        TextFormField(
                          controller: passController,
                          obscureText: _obscurePassword,
                          decoration: InputDecoration(
                            prefixIcon: Icon(Icons.lock, color: Colors.orange[700]),
                            hintText: "Enter your Moodle password",
                            labelText: "Password",
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey[400]!),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.orange[700]!, width: 2),
                            ),
                            filled: true,
                            fillColor: Colors.grey[50],
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword ? Icons.visibility : Icons.visibility_off,
                                color: Colors.grey[600],
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your password';
                            }
                            if (value.length < 6) {
                              return 'Password must be at least 6 characters';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 25),

                        // Login Button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: isLoading ? null : _login,
                            style: ElevatedButton.styleFrom(
                              foregroundColor: Colors.white,
                              backgroundColor: Colors.orange[700],
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 5,
                              shadowColor: Colors.orange[300],
                            ),
                            child: isLoading
                                ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2.5,
                              ),
                            )
                                : Text(
                              "Sign In",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 15),

                        // Help text
                        Text(
                          "Use your Wits student portal credentials",
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 13,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
class _DrawerTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _DrawerTile({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(icon, color: Colors.white, size: 26),
        title: Text(
          title,
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        onTap: onTap,
        contentPadding: EdgeInsets.symmetric(horizontal: 16),
      ),
    );
  }
}
class TasksPage extends StatefulWidget {
  const TasksPage({super.key});

  @override
  State<TasksPage> createState() => _TasksPageState();
}

class _TasksPageState extends State<TasksPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.orange[700],
        elevation: 4,
        title: Text(
          'Tasks & Notifications',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        iconTheme: IconThemeData(color: Colors.white),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(15),
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.orange[50]!,
              Colors.orange[100]!,
            ],
          ),
        ),
        child: NotificationsScreen(),
      ),
    );
  }
}

class Planner extends StatefulWidget {
  const Planner({super.key});

  @override
  State<Planner> createState() => _PlannerState();
}

class _PlannerState extends State<Planner> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => addEvent()));
        },
        backgroundColor: Colors.orange[700],
        elevation: 8,
        child: Icon(
          Icons.add,
          color: Colors.white,
          size: 32,
        ),
      ),
      appBar: AppBar(
        title: Text(
          "My Planner",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        backgroundColor: Colors.orange[700],
        iconTheme: IconThemeData(color: Colors.white),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(15),
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.orange[50]!,
              Colors.orange[100]!,
            ],
          ),
        ),
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('events')
              .orderBy("date", descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.orange[700]!),
                    ),
                    SizedBox(height: 20),
                    Text(
                      "Loading events...",
                      style: TextStyle(
                        color: Colors.orange[800],
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              );
            }
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.event_note,
                      size: 70,
                      color: Colors.orange[300],
                    ),
                    SizedBox(height: 20),
                    Text(
                      "No events planned yet",
                      style: TextStyle(
                        fontSize: 20,
                        color: Colors.orange[800],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 10),
                    Text(
                      "Tap the + button to add your first event",
                      style: TextStyle(
                        color: Colors.orange[600],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              );
            }

            final docs = snapshot.data!.docs;

            return ListView.builder(
              itemCount: docs.length,
              padding: EdgeInsets.all(16),
              itemBuilder: (context, index) {
                final data = docs[index].data() as Map<String, dynamic>;
                final String eventName = data['eventName'];
                final String eventDescription = data['description'];
                final Timestamp eventDate = data['date'];
                final String endTime = data["endTime"];
                final DateTime date = eventDate.toDate();
                String formattedDate =
                    "${date.day}/${date.month}/${date.year}";
                String formattedTime =
                    "${date.hour.toString().padLeft(2, '0')}:${date.minute
                    .toString().padLeft(2, '0')}";

                return Container(
                  margin: EdgeInsets.symmetric(vertical: 8),
                  child: Card(
                    elevation: 6,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.white,
                            Colors.orange[50]!,
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.orange.withOpacity(0.1),
                            blurRadius: 10,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Stack(
                        children: [
                          // Orange accent strip
                          Positioned(
                            left: 0,
                            top: 0,
                            bottom: 0,
                            child: Container(
                              width: 6,
                              decoration: BoxDecoration(
                                color: Colors.orange[400],
                                borderRadius: BorderRadius.only(
                                  topLeft: Radius.circular(16),
                                  bottomLeft: Radius.circular(16),
                                ),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(
                                left: 20, right: 12, top: 20, bottom: 20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Event header with delete button
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        eventName,
                                        style: TextStyle(
                                          fontSize: 22,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.orange[900],
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    IconButton(
                                      onPressed: () {
                                        showDialog(
                                          context: context,
                                          builder: (_) => AlertDialog(
                                            backgroundColor: Colors.white,
                                            title: Text(
                                              "Delete Event",
                                              style: TextStyle(
                                                color: Colors.orange[900],
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            content: Text(
                                                "Are you sure you want to delete this event?"),
                                            actions: [
                                              TextButton(
                                                onPressed: () =>
                                                    Navigator.pop(context),
                                                child: Text(
                                                  "Cancel",
                                                  style: TextStyle(
                                                      color: Colors.grey[600]),
                                                ),
                                              ),
                                              TextButton(
                                                onPressed: () async {
                                                  FirebaseFirestore.instance
                                                      .collection('events')
                                                      .doc(docs[index].id)
                                                      .delete();
                                                  Navigator.pop(context);
                                                  ScaffoldMessenger.of(context)
                                                      .showSnackBar(
                                                    SnackBar(
                                                      content: Text(
                                                          "Event deleted successfully"),
                                                      backgroundColor:
                                                      Colors.orange[700],
                                                    ),
                                                  );
                                                },
                                                child: Text(
                                                  "Delete",
                                                  style: TextStyle(
                                                      color: Colors.red),
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                      icon: Icon(Icons.delete,
                                          color: Colors.redAccent),
                                      tooltip: "Delete Event",
                                    ),
                                  ],
                                ),
                                SizedBox(height: 15),

                                // Date and time information
                                Row(
                                  children: [
                                    Icon(Icons.calendar_today,
                                        size: 22, color: Colors.orange[700]),
                                    SizedBox(width: 10),
                                    Text(
                                      formattedDate,
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.grey[800],
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 10),

                                Row(
                                  mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(Icons.access_time,
                                            size: 22, color: Colors.orange[700]),
                                        SizedBox(width: 8),
                                        Text(
                                          "Start: $formattedTime",
                                          style: TextStyle(
                                            fontSize: 16,
                                            color: Colors.grey[700],
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Row(
                                      children: [
                                        Icon(Icons.access_time,
                                            size: 22, color: Colors.orange[700]),
                                        SizedBox(width: 8),
                                        Text(
                                          "End: $endTime",
                                          style: TextStyle(
                                            fontSize: 16,
                                            color: Colors.grey[700],
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                SizedBox(height: 15),

                                // Description
                                Container(
                                  width: double.infinity,
                                  padding: EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: Colors.orange.withOpacity(0.08),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: Colors.orange.withOpacity(0.2),
                                      width: 1,
                                    ),
                                  ),
                                  child: Text(
                                    eventDescription,
                                    style: TextStyle(
                                      fontSize: 15,
                                      color: Colors.grey[800],
                                      height: 1.4,
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
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class addEvent extends StatefulWidget {
  const addEvent({super.key});

  @override
  State<addEvent> createState() => _addEventState();
}

class _addEventState extends State<addEvent> {
  final TextEditingController date = TextEditingController();
  final TextEditingController startTime = TextEditingController();
  final TextEditingController endTime = TextEditingController();
  final TextEditingController description = TextEditingController();
  final TextEditingController eventName = TextEditingController();
  final _formkey = GlobalKey<FormState>();

  DateTime parseDateTime(String dateStr, String timeStr) {
    // Split date
    final parts = dateStr.split("/");
    int day = int.parse(parts[0]);
    int month = int.parse(parts[1]);
    int year = int.parse(parts[2]);

    // Split time
    final timeParts = timeStr.split(":");
    int hour = int.parse(timeParts[0]);
    int minute = int.parse(timeParts[1]);

    // Create DateTime
    return DateTime(year, month, day, hour, minute);
  }

  Future<void> uploadEvent(String eventName, String description, String dateStr,
      String timeStr, String endTime) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    final date = parseDateTime(dateStr, timeStr);
    try {
      await FirebaseFirestore.instance.collection('events').add({
        'userId': userId,
        'startTime': timeStr,
        'endTime': endTime,
        'date': date,
        'description': description ?? "Unknown",
        'eventName': eventName ?? "Unknown",
      });
      Fluttertoast.showToast(
          msg: "Event added successfully!",
          backgroundColor: Colors.orange[700],
          textColor: Colors.white);
    } catch (e) {
      Fluttertoast.showToast(
          msg: "Failed to add event",
          backgroundColor: Colors.red,
          textColor: Colors.white);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Add New Event",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        backgroundColor: Colors.orange[700],
        iconTheme: IconThemeData(color: Colors.white),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(15),
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.orange[50]!,
              Colors.orange[100]!,
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Form(
            key: _formkey,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.event,
                          size: 50,
                          color: Colors.orange[700],
                        ),
                        SizedBox(height: 10),
                        Text(
                          "Plan Your Event",
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange[900],
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 5),
                  Center(
                    child: Text(
                      "Fill in the details below to create a new event",
                      style: TextStyle(
                        color: Colors.orange[700],
                        fontSize: 14,
                      ),
                    ),
                  ),
                  SizedBox(height: 25),

                  // Event Name
                  TextFormField(
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return "Event name is required";
                      }
                      return null;
                    },
                    controller: eventName,
                    decoration: InputDecoration(
                      labelText: "Event Name",
                      labelStyle: TextStyle(color: Colors.orange[700]),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.orange[300]!),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.orange[700]!, width: 2),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      prefixIcon: Icon(Icons.event, color: Colors.orange[700]),
                    ),
                  ),
                  SizedBox(height: 16),

                  // Description
                  TextFormField(
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return "Description is required";
                      }
                      return null;
                    },
                    controller: description,
                    decoration: InputDecoration(
                      labelText: "Description",
                      labelStyle: TextStyle(color: Colors.orange[700]),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.orange[300]!),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.orange[700]!, width: 2),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    maxLines: 3,
                  ),
                  SizedBox(height: 16),

                  // Time inputs in a row
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return "Start time is required";
                            }
                            if (!RegExp(r'^(?:[01]\d|2[0-3]):[0-5]\d$')
                                .hasMatch(value!)) {
                              return "Invalid time format (HH:MM)";
                            }
                            return null;
                          },
                          controller: startTime,
                          decoration: InputDecoration(
                            labelText: "Start Time",
                            labelStyle: TextStyle(color: Colors.orange[700]),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.orange[300]!),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide:
                              BorderSide(color: Colors.orange[700]!, width: 2),
                            ),
                            filled: true,
                            fillColor: Colors.white,
                            hintText: "HH:MM",
                            prefixIcon:
                            Icon(Icons.access_time, color: Colors.orange[700]),
                          ),
                        ),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return "End time is required";
                            }
                            if (!RegExp(r'^(?:[01]\d|2[0-3]):[0-5]\d$')
                                .hasMatch(value!)) {
                              return "Invalid time format (HH:MM)";
                            }
                            return null;
                          },
                          controller: endTime,
                          decoration: InputDecoration(
                            labelText: "End Time",
                            labelStyle: TextStyle(color: Colors.orange[700]),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.orange[300]!),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide:
                              BorderSide(color: Colors.orange[700]!, width: 2),
                            ),
                            filled: true,
                            fillColor: Colors.white,
                            hintText: "HH:MM",
                            prefixIcon:
                            Icon(Icons.access_time, color: Colors.orange[700]),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),

                  // Date
                  TextFormField(
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return "Date is required";
                      }
                      if (!RegExp(r'^\d{2}/\d{1,2}/\d{4}$').hasMatch(value!)) {
                        return "Invalid date format (DD/MM/YYYY)";
                      }
                      return null;
                    },
                    controller: date,
                    decoration: InputDecoration(
                      labelText: "Date of Event",
                      labelStyle: TextStyle(color: Colors.orange[700]),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.orange[300]!),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.orange[700]!, width: 2),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      hintText: "DD/MM/YYYY",
                      prefixIcon: Icon(Icons.calendar_today, color: Colors.orange[700]),
                    ),
                  ),
                  SizedBox(height: 30),

                  // Submit Button
                  SizedBox(
                    width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () async {
                          if (_formkey.currentState!.validate()) {
                            final event_name = eventName.text.toString();
                            final str_time = startTime.text.toString();
                            final end_time = endTime.text.toString();
                            final desc = description.text.toString();
                            final dt = date.text.toString();

                            print('=== DEBUG EVENT CREATION ===');
                            print('Event Name: $event_name');
                            print('Start Time: $str_time');
                            print('End Time: $end_time');
                            print('Date: $dt');
                            print('Description: $desc');

                            try {
                              // Parse start time
                              final eventStartDateTime = parseDateTime(dt, str_time);
                              print('DEBUG - Parsed eventStartDateTime: $eventStartDateTime');

                              // Get South African timezone location
                              final saTimezone = tz.getLocation('Africa/Johannesburg');

                              // Convert to TZDateTime with South African timezone
                              final tzNotificationTime = tz.TZDateTime.from(eventStartDateTime, saTimezone);

                              // IMPORTANT: Use the same timezone for current time comparison!
                              final currentTime = tz.TZDateTime.now(saTimezone);

                              print('Event scheduled for (Johannesburg): $tzNotificationTime');
                              print('Current time (Johannesburg): $currentTime');

                              final difference = tzNotificationTime.difference(currentTime);
                              print('Time difference: ${difference.inMinutes} minutes (${difference.inSeconds} seconds)');
                              print('Is future: ${tzNotificationTime.isAfter(currentTime)}');

                              // Upload event to Firestore
                              await uploadEvent(event_name, desc, dt, str_time, end_time);
                              print('Event uploaded to Firestore');

                              // Only schedule if the notification time is in the future
                              if (tzNotificationTime.isAfter(currentTime)) {

                                // Check if we can schedule exact notifications
                                bool canScheduleExact = await LocalNotificationsService.canScheduleExactNotifications();
                                print('Can schedule exact notifications: $canScheduleExact');

                                if (!canScheduleExact) {
                                  print('Requesting exact alarm permission...');
                                  await LocalNotificationsService.requestExactAlarmsPermission();
                                }

                                final notificationId = eventStartDateTime.millisecondsSinceEpoch ~/ 1000;
                                print('Scheduling notification with ID: $notificationId');


                                await LocalNotificationsService.scheduleNotification(
                                  id: notificationId,
                                  title: "Upcoming Event: $event_name",
                                  body: "Your event '$event_name' is starting now!",
                                  scheduledTime: tzNotificationTime,
                                );

                                final pending = await LocalNotificationsService.getPendingNotifications();
                                print('Total pending notifications: ${pending.length}');

                                for (var notification in pending) {
                                  print('Pending notification - ID: ${notification.id}, Title: ${notification.title}');
                                }

                              } else {

                                Fluttertoast.showToast(
                                  msg: "Event is ${difference.inMinutes.abs()} minutes in the past, notification skipped.",
                                  backgroundColor: Colors.orange[700],
                                  textColor: Colors.white,
                                  toastLength: Toast.LENGTH_LONG,
                                );
                              }

                              // Clear form
                              eventName.clear();
                              description.clear();
                              startTime.clear();
                              endTime.clear();
                              date.clear();
                              _formkey.currentState?.reset();

                              Navigator.pop(context);

                            } catch (e, stackTrace) {
                              print('Error creating event: $e');
                              print('Stack trace: $stackTrace');
                              Fluttertoast.showToast(
                                msg: "Error creating event: ${e.toString()}",
                                backgroundColor: Colors.red,
                                textColor: Colors.white,
                                toastLength: Toast.LENGTH_LONG,
                              );
                            }
                          } else {
                            print('Form validation failed');
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange[700],
                          padding: EdgeInsets.symmetric(vertical: 18),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 4,
                          shadowColor: Colors.orange.withOpacity(0.3),
                        ),
                        child: Text(
                          "Add Event",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      )


                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class Notifications_screen extends StatelessWidget {
  const Notifications_screen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Notifications",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.orange[700],
        iconTheme: IconThemeData(color: Colors.white),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(15),
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.orange[50]!,
              Colors.orange[100]!,
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.notifications_active,
                size: 60,
                color: Colors.orange[400],
              ),
              SizedBox(height: 20),
              Text(
                "Notification Center",
                style: TextStyle(
                  fontSize: 22,
                  color: Colors.orange[800],
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 10),
              Text(
                "Your notifications will appear here",
                style: TextStyle(
                  color: Colors.orange[600],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


class AboutUsPage extends StatelessWidget {
  final String appName;
  const AboutUsPage({super.key, this.appName = "MoodleTrack"});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "About $appName",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.orange[600],
        iconTheme: IconThemeData(color: Colors.white),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(15),
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.orange[50]!,
              Colors.orange[100]!,
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 680),
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  // App Logo/Icon
                  Center(
                    child: Icon(
                      Icons.school,
                      size: 80,
                      color: Colors.orange[700],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // App Name
                  Center(
                    child: Text(
                      appName,
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w700,
                        color: Colors.orange[700],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Description
                  Text(
                    "Your all-in-one student companion at Wits. MoodleTrack helps you stay on top of your courses, tasks, and deadlines effortlessly.",
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[700],
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),

                  // Features Card
                  Card(
                    elevation: 4,
                    shadowColor: Colors.orange.withOpacity(0.2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.white,
                            Colors.orange[50]!,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Center(
                            child: Text(
                              "What MoodleTrack Offers",
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                                color: Colors.orange[800],
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          _FeatureRow(
                            icon: Icons.event_note_outlined,
                            title: "Tasks & Deadlines",
                            subtitle: "View all your course tasks and upcoming due dates in one place.",
                            color: Colors.orange[700]!,
                          ),
                          _FeatureRow(
                            icon: Icons.calendar_today_outlined,
                            title: "Calendar View",
                            subtitle: "See your upcoming events and deadlines at a glance.",
                            color: Colors.orange[700]!,
                          ),
                          _FeatureRow(
                            icon: Icons.notifications_active_outlined,
                            title: "Reminders & Notifications",
                            subtitle: "Set reminders for events and get notified so you never miss anything.",
                            color: Colors.orange[700]!,
                          ),
                          _FeatureRow(
                            icon: Icons.assignment_outlined,
                            title: "Planner",
                            subtitle: "Plan and organize your academic schedule effectively.",
                            color: Colors.orange[700]!,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Why MoodleTrack
                  Text(
                    "Why MoodleTrack Exists",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: Colors.orange[800],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "$appName brings your Moodle courses and student life together so you can focus on learning and staying organized. We understand the challenges of managing multiple courses and deadlines, and we're here to make your academic journey smoother.",
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[700],
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Tags
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: const [
                      _Tag(label: "Tasks", color: Colors.orange),
                      _Tag(label: "Calendar", color: Colors.orange),
                      _Tag(label: "Reminders", color: Colors.orange),

                      _Tag(label: "Planner", color: Colors.orange),

                    ],
                  ),
                  const SizedBox(height: 40),

                  // Developer Info
                  Divider(color: Colors.orange[300]),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: Colors.orange[700],
                        child: Text(
                          "MC",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Developed by Mahlatse Clayton Maredi",
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.orange[800],
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              "For Wits University Students",
                              style: TextStyle(
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Version Info
                  Center(
                    child: Text(
                      "Version 1.0.0",
                      style: TextStyle(
                        color: Colors.grey[500],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;

  const _FeatureRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 28, color: color),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.orange[800],
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  final String label;
  final Color color;

  const _Tag({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  String? token;
  bool _isInitializing = true;
  String? _username;
  String? _fullName;

  @override
  void initState() {
    super.initState();
    _initializeServices();
  }

  Future<void> _initializeServices() async {
    try {
      final retrievedToken = await TokenService.getToken();
      setState(() {
        token = retrievedToken;
        _isInitializing = false;
      });

      // Get user info from Moodle after token is retrieved
      if (token != null) {
        await _getMoodleUserInfo();
      }
    } catch (error) {
      print('❌ Error initializing services: $error');
      setState(() {
        _isInitializing = false;
      });
    }
  }

  /// ✅ Get user information from Moodle using the stored token
  Future<void> _getMoodleUserInfo() async {
    try {
      // First, try to get basic site info which includes user details
      final siteInfoResponse = await http.get(
        Uri.parse(
            'https://courses.ms.wits.ac.za/moodle/webservice/rest/server.php?wstoken=$token&wsfunction=core_webservice_get_site_info&moodlewsrestformat=json'),
      );

      if (siteInfoResponse.statusCode == 200) {
        final siteData = json.decode(siteInfoResponse.body);
        final String username = siteData['username']?.toString() ?? '';
        final String fullname = siteData['fullname']?.toString() ?? '';

        if (fullname.isNotEmpty) {
          setState(() {
            _username = username;
            _fullName = fullname;
          });
          print('✅ Retrieved Moodle user: $fullname ($username)');
          return;
        }
      }

      // If site info doesn't contain full name, try to get user profile
      await _getUserProfileFromMoodle();

    } catch (e) {
      print('❌ Error getting Moodle user info: $e');
      // Fallback to student number from email
      _getUsernameFromEmail();
    }
  }

  /// ✅ Get detailed user profile from Moodle
  Future<void> _getUserProfileFromMoodle() async {
    try {
      // Get current user's ID first from site info
      final siteInfoResponse = await http.get(
        Uri.parse(
            'https://courses.ms.wits.ac.za/moodle/webservice/rest/server.php?wstoken=$token&wsfunction=core_webservice_get_site_info&moodlewsrestformat=json'),
      );

      if (siteInfoResponse.statusCode == 200) {
        final siteData = json.decode(siteInfoResponse.body);
        final int userId = siteData['userid'] ?? 0;

        if (userId > 0) {
          // Now get user profile details
          final profileResponse = await http.get(
            Uri.parse(
                'https://courses.ms.wits.ac.za/moodle/webservice/rest/server.php?wstoken=$token&wsfunction=core_user_get_users_by_field&field=id&values[0]=$userId&moodlewsrestformat=json'),
          );

          if (profileResponse.statusCode == 200) {
            final profileData = json.decode(profileResponse.body);
            if (profileData is List && profileData.isNotEmpty) {
              final user = profileData[0];
              final String fullname = user['fullname']?.toString() ?? '';
              final String username = user['username']?.toString() ?? '';

              if (fullname.isNotEmpty) {
                setState(() {
                  _fullName = fullname;
                  _username = username;
                });
                print('✅ Retrieved Moodle profile: $fullname ($username)');
                return;
              }
            }
          }
        }
      }

      // If all else fails, fallback to email
      _getUsernameFromEmail();

    } catch (e) {
      print('❌ Error getting Moodle profile: $e');
      _getUsernameFromEmail();
    }
  }

  /// ✅ Fallback: Get username from Firebase Auth email
  Future<void> _getUsernameFromEmail() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && user.email != null) {
      // Extract student number from email (e.g., 1234567@students.wits.ac.za)
      final email = user.email!;
      if (email.contains('@students.wits.ac.za')) {
        final studentNumber = email.split('@').first;
        setState(() {
          _username = studentNumber;
          _fullName = 'Student $studentNumber';
        });
      } else {
        setState(() {
          _username = user.email!.split('@').first;
          _fullName = user.displayName ?? 'User';
        });
      }
    } else {
      setState(() {
        _fullName = 'Student';
      });
    }
  }

  Future<void> logoutMoodle() async {
    await TokenService.clearToken();
  }

  Future<void> logOutFirebase() async {
    await FirebaseAuth.instance.signOut();
  }

  @override
  Widget build(BuildContext context) {
    if (_isInitializing) {
      return Scaffold(
        backgroundColor: Colors.orange[50],
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.orange[600]!),
              ),
              SizedBox(height: 20),
              Text(
                "Loading your calendar...",
                style: TextStyle(
                  color: Colors.orange[600],
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final moodleService = MoodleApiService(
      token: token ?? '',
      domain: 'https://courses.ms.wits.ac.za/moodle',
    );

    return ChangeNotifierProvider(
      create: (context) {
        final provider = CalendarProvider(moodleService: moodleService);
        provider.loadEvents();
        return provider;
      },
      child: Scaffold(
        backgroundColor: Colors.orange[50],
        drawer: Drawer(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.orange[200]!,
                  Colors.orange[100]!,
                  Colors.orange[50]!,
                ],
              ),
            ),
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                // Drawer Header
                Container(
                  height: 220,
                  padding: const EdgeInsets.only(top: 50, left: 20, bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.orange[400]!.withOpacity(0.9),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(30),
                      bottomRight: Radius.circular(30),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        radius: 40,
                        backgroundColor: Colors.white,
                        backgroundImage: AssetImage('images/user.png'),
                      ),
                      SizedBox(width: 15),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _fullName ?? "Welcome",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 2,
                            ),
                            SizedBox(height: 5),
                            if (_username != null)
                              Text(
                                "@${_username!}",
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.8),
                                  fontSize: 14,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            SizedBox(height: 8),
                            Text(
                              "MoodleTrack Student",
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Drawer Items
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 20),
                  child: Column(
                    children: [
                      _DrawerTile(
                        icon: Icons.person,
                        title: "About Us",
                        onTap: () {
                          Navigator.push(context,
                              MaterialPageRoute(builder: (_) => AboutUsPage()));
                        },
                      ),
                      SizedBox(height: 10),
                      _DrawerTile(
                        icon: Icons.logout,
                        title: "Log Out",
                        onTap: () async {
                          await logOutFirebase();
                          await logoutMoodle();
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(builder: (context) => Homepage()),
                                (route) => false,
                          );
                        },
                      ),
                    ],
                  ),
                )
              ],
            ),
          ),
        ),
        // ... rest of the build method remains the same
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: Colors.orange.withOpacity(0.1),
                blurRadius: 10,
                spreadRadius: 2,
              ),
            ],
          ),
          child: BottomNavigationBar(
            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.white,
            selectedItemColor: Colors.orange[700],
            unselectedItemColor: Colors.grey[600],
            selectedFontSize: 14,
            unselectedFontSize: 14,
            elevation: 8,
            onTap: (value) {
              if (value == 0) {
                Navigator.push(
                    context, MaterialPageRoute(builder: (_) => TasksPage()));
              } else if (value == 1) {
                Navigator.push(
                    context, MaterialPageRoute(builder: (_) => Planner()));
              }
            },
            items: [
              BottomNavigationBarItem(
                label: 'Tasks',
                icon: Icon(Icons.task_alt, size: 28),
              ),
              BottomNavigationBarItem(
                label: 'Planner',
                icon: Icon(Icons.calendar_today, size: 28),
              ),
            ],
          ),
        ),
        appBar: AppBar(
          backgroundColor: Colors.orange[700],
          elevation: 0,
          title: Text(
            'Moodle Calendar',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          iconTheme: IconThemeData(color: Colors.white),
        ),
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.orange[50]!,
                Colors.orange[100]!,
              ],
            ),
          ),
          child: Consumer<CalendarProvider>(
            builder: (context, provider, child) {
              if (provider.isLoading) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.orange[700]!),
                      ),
                      SizedBox(height: 20),
                      Text(
                        "Loading events...",
                        style: TextStyle(
                          color: Colors.orange[700],
                        ),
                      ),
                    ],
                  ),
                );
              }
              if (provider.errorMessage != null) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 50,
                        color: Colors.orange[600],
                      ),
                      SizedBox(height: 20),
                      Text(
                        'Error: ${provider.errorMessage}',
                        style: TextStyle(
                          color: Colors.orange[800],
                          fontSize: 16,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () => provider.loadEvents(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange[700],
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text('Retry'),
                      ),
                    ],
                  ),
                );
              }
              if (provider.events.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.event_note,
                        size: 60,
                        color: Colors.orange[300],
                      ),
                      SizedBox(height: 20),
                      Text(
                        'No events available',
                        style: TextStyle(
                          color: Colors.orange[800],
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: 10),
                      Text(
                        'Check back later for upcoming events',
                        style: TextStyle(
                          color: Colors.orange[600],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                );
              }
              return MoodleCalendarWidget();
            },
          ),
        ),
      ),
    );
  }
}




