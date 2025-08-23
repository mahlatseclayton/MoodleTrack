import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/token_service.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:learning_app/screens/notifications_screen.dart';
import 'AppData.dart';
import 'firebase_options.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fluttertoast/fluttertoast.dart';

// ...
// Future<void> main() async {
//
//   WidgetsFlutterBinding.ensureInitialized();
//   await Firebase.initializeApp(
//     options: DefaultFirebaseOptions.currentPlatform,
//   );
//   runApp(const MyApp());
// }
import 'dart:io';
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('Firebase initialized!');
  } catch (e) {
    print('Firebase failed to initialize: $e');
  }

  runApp(const AuthCheck());
}

class AuthCheck extends StatelessWidget {
  const AuthCheck({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          if (snapshot.hasData) {
            // User already logged in
            return MainPage();
          } else {
            // New user (not logged in yet)
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
      body: SafeArea(child: Stack(
        children: [
          Container(
            height:double.infinity,
            width:double.infinity,

            decoration: BoxDecoration(
              image:DecorationImage(image: AssetImage("images/background1.jpg"),
                  fit: BoxFit.cover),
            ),
            child:       Container(
              width: double.infinity,
              height: 300,
              decoration:BoxDecoration(
                color: (Colors.grey[900] ?? Colors.grey[900])!.withOpacity(.65),
              ),
            ),
          ),
          SingleChildScrollView(
              child:Column(

                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Padding(padding:EdgeInsets.only(top:190,left: 10),
                    child:  Column(

                      children: [

                        Text("Welcome ",style:TextStyle(
                          color: Colors.grey[400],
                          fontSize: 50,

                          fontWeight: FontWeight.bold,
                        )
                        ),
                        Text("to ",style:TextStyle(
                          color: Colors.grey[400],
                          fontSize: 50,
                          fontWeight: FontWeight.bold,
                        )
                        ),
                        Text("Mentee",style:TextStyle(
                          color: Colors.grey[400],
                          fontSize: 50,
                          fontWeight: FontWeight.bold,
                        )
                        ),
                        Text("Growth Tracker",style:TextStyle(
                          color: Colors.grey[400],
                          fontSize: 50,
                          fontWeight: FontWeight.bold,
                        )
                        ),
                        Text("Mentor. Connect. Elevate.",style:TextStyle(
                          color: Colors.grey[200],
                          fontSize: 23,
                          fontWeight: FontWeight.bold,
                        )
                        ),
                      ],
                    ),
                  ),




                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        margin:const EdgeInsets.all(40),
                        padding:const EdgeInsets.all(25),



                        child: ElevatedButton.icon(
                          onPressed: (){
                            // button click
                            Navigator.push(context, MaterialPageRoute(builder: (_)=>LoginPage()),);
                          },
                          icon:const Icon(Icons.login),
                          label:const Text("Sign In"
                            ,style: TextStyle(
                              fontSize: 18,
                            ),),
                          style:ElevatedButton.styleFrom(
                            padding: const EdgeInsets.only(left:32,right: 32,top: 18,bottom: 18),
                          ),
                        ),
                      ),
                    ],

                  ),
                  Container(
                    height:2,
                    width: double.infinity,
                    color: Colors.grey[300],
                  ),
                  TextButton.icon(
                    onPressed: (){
                      Navigator.push(context, MaterialPageRoute(builder: (_)=>SignUpScreen()),);
                    },
                    label: Text("Don't have an account? Sign Up",style:TextStyle(
                      color: Colors.white,
                    ),
                    ),
                  ),
                ],
              )
          ),
        ],
      ),
      ),

    );

  }
}


class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}
class _LoginPageState extends State<LoginPage> {
  bool isLogin = true;
  bool isLoading = false;
  final _formKey = GlobalKey<FormState>();
  bool isCustomer = true; //student
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passController = TextEditingController();
  Future<String?> _getMoodleToken(String username, String password) async {
    try {
      final response = await http.get(
        Uri.parse(
            'https://courses.ms.wits.ac.za/moodle/login/token.php?'
                'username=$username&password=$password&service=moodle_mobile_app'
        ),
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
  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isLoading = true);

    try {

      final email = emailController.text.trim(); // removed .toLowerCase()
      final Username=email.substring(0,7);
      final password = passController.text.trim();
      final token = await _getMoodleToken(Username, password);

      if (token != null) {
        // STORE THE TOKEN - This is the key step!
        await TokenService.storeToken(token);


        // Sign in with email and password
        UserCredential userCredential = await FirebaseAuth.instance
            .signInWithEmailAndPassword(
          email: email,
          password: password,
        );

        // Check if email is verified
        if (!userCredential.user!.emailVerified) {
          await FirebaseAuth.instance.signOut();
          throw FirebaseAuthException(
            code: 'email-not-verified',
            message: 'Please verify your email first',
          );
        }

        // Login successful - navigate to home
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) =>
              MainPage(

              )),
        );
      }
    } on FirebaseAuthException catch (e) {
      String message;
      switch (e.code) {
        case 'user-not-found':
          message = 'No user found with this email';
          break;
        case 'wrong-password':
          message = 'Incorrect password';
          break;
        case 'email-not-verified':
          message = 'Please verify your email first';
          break;
        default:
          message = 'Login failed: ${e.message}';
      }
      Fluttertoast.showToast(msg: message);
    } catch (e) {
      Fluttertoast.showToast(msg: ' ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          backgroundColor: Colors.grey[500],
          title:Text("Login Page",style:TextStyle(
            color:Colors.white,
            fontWeight: FontWeight.bold,
          ))
      ),
      backgroundColor: Colors.grey[600],
      body: SafeArea(
        child: Stack(
          children: [
            Container(
              width: double.infinity,
              height: double.infinity,
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage("images/background1.jpg"),
                  fit: BoxFit.cover,
                ),
              ),
              child:Container(
                width: double.infinity,
                height: double.infinity,
                color: (Colors.grey[900] ?? Colors.grey[900])!.withOpacity(.65),
              ),
            ),

            Center(
              child: SingleChildScrollView(
                child: Container(
                  margin: const EdgeInsets.all(25),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 10,
                        spreadRadius: 3,
                      ),
                    ],
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        // Login/Sign up toggle
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  isLogin = true;
                                });
                              },
                              child: Column(
                                children: [
                                  Text(
                                    "Login",
                                    style: TextStyle(
                                      fontSize: 19.0,
                                      fontWeight: FontWeight.bold,
                                      color: isLogin ? Colors.indigo[900] : Colors.cyan[200],
                                    ),
                                  ),
                                  Container(
                                    height: 3,
                                    width: 55,
                                    margin: const EdgeInsets.only(top: 5),
                                    color: Colors.orange[300],
                                  ),
                                ],
                              ),
                            ),
                            GestureDetector(
                              onTap: () {
                                setState(() async {
                                  final bool result = await Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (_) => const SignUpScreen()),
                                  );
                                  if (result == false) {
                                    isLogin = true;
                                  } else {
                                    isLogin = false;
                                  }
                                });
                              },
                              child: Column(
                                children: [
                                  Text(
                                    "Sign Up",
                                    style: TextStyle(
                                      fontSize: 19.0,
                                      fontWeight: FontWeight.bold,
                                      color: isLogin ? Colors.cyan[200] : Colors.indigo[900],
                                    ),
                                  ),
                                  Container(
                                    height: 3,
                                    width: 55,
                                    margin: const EdgeInsets.only(top: 5),
                                    color: Colors.orange[300],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),

                        // Email TextFormField
                        TextFormField(
                          controller: emailController,
                          decoration: InputDecoration(
                            prefixIcon: Icon(Icons.email, color: Colors.indigo[900]),
                            hintText: "Enter your email",
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your email';
                            }
                            if (!value.contains('@')) {
                              return 'Please enter a valid email';
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 10),
                        // Password TextFormField
                        TextFormField(
                          controller: passController,
                          obscureText: true,
                          decoration: InputDecoration(
                            prefixIcon: Icon(Icons.lock, color: Colors.indigo[900]),
                            hintText: "Enter your password",
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your password';
                            }
                            if (value.length < 8) {
                              return 'Password must be at least 8 characters';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 7),
                        // Forgot password
                        Align(
                          alignment: Alignment.centerRight,
                          child: GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => ForgotPasswordPage()),
                              );
                            },
                            child: Text(
                              "Forgot password?",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Colors.indigo[900],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 15),
                        // Sign In button
                        ElevatedButton.icon(
                          onPressed: isLoading ? null : _login,
                          icon: isLoading
                              ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.5,
                            ),
                          )
                              : Icon(Icons.login),
                          label: Text(isLoading ? "Signing in..." : "Sign In"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.indigo[900],
                            foregroundColor: Colors.grey[300],
                            textStyle: const TextStyle(fontSize: 18),
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
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

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _auth = FirebaseAuth.instance;
  bool isLoading = false;
  bool isSignUp = true;
  final TextEditingController nameController=TextEditingController();
  final TextEditingController surNameController=TextEditingController();
  final TextEditingController passController=TextEditingController();
  final TextEditingController cpassController=TextEditingController();
  final TextEditingController emailController=TextEditingController();
  // final email
  @override
  void showToast(String message) {
    Fluttertoast.showToast(
      msg: message,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: Colors.red,
      textColor: Colors.white,
      fontSize: 16,
    );
  }
  bool verifyForm(){
    if(nameController.text.isEmpty||passController.text.isEmpty ||cpassController.text.isEmpty|| surNameController.text.isEmpty||emailController.text.isEmpty){
      return false;
    }
    return true;
  }

  bool validInput(){
    // check email validity..
    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
    if (!emailRegex.hasMatch(emailController.text.trim())) {

      return false;
    }
    return true;

  }
  String? validatePass(String password) {
    if (password.length < 8) {
      return "Password must be at least 8 characters long.";
    }

    if (!RegExp(r'[A-Z]').hasMatch(password)) {
      return "Add at least one uppercase letter.";
    }

    if (!RegExp(r'[a-z]').hasMatch(password)) {
      return "Add at least one lowercase letter.";
    }

    if (!RegExp(r'[0-9]').hasMatch(password)) {
      return "Add at least one digit.";
    }

    if (!RegExp(r'[!@#\$&*~]').hasMatch(password)) {
      return "Add at least one special character (!@#\$&*~).";
    }

    return null;
  }
bool spaceCheck(String x){
    if(x.contains(" ")){
      return false;
    }
    return true;
}
  Future<void> registerUser({
    required String uid,
    required String email,
    required String fullName,
    required String surName,
  }) async {
    await FirebaseFirestore.instance.collection('users').doc(uid).set({
      'uid': uid,
      'email': email,
      'fullName': fullName,
      'surName': surName,
      'isVerified': false,
      'createdAt': Timestamp.now(),
    });
  }



  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.grey[500],
        title:Text("Sign Up Page",style:TextStyle(
          color:Colors.white,
          fontWeight: FontWeight.bold,
        ))
      ),
      backgroundColor: Colors.grey[600],
      body: SafeArea(
        child: Stack(
          children: [
            // Background image covers entire screen
            Container(
              height: double.infinity,
              width: double.infinity,
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage("images/background1.jpg"),
                  fit: BoxFit.cover,
                ),
              ),
              child:Container(
                width: double.infinity,
                height: double.infinity,
                color: (Colors.grey[900] ?? Colors.grey[900])!.withOpacity(.65),
              ),
            ),


            // Top title text, centered horizontally, positioned near top with padding
            Positioned(
              top: 60,
              left: 0,
              right: 0,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "Create",
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 38,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    "New",
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 38,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    "Account",
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 38,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),


            Positioned.fill(
              top: 220,
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 25),
                child: Center(
                  child: Container(
                    constraints: const BoxConstraints(
                      maxWidth: 500,
                    ),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 10,
                          spreadRadius: 3,
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Login/Sign up toggle
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            GestureDetector(
                              onTap: () {
                                isSignUp = false;
                               Navigator.push(context, MaterialPageRoute(builder: (_)=>LoginPage()));
                              },
                              child: Column(
                                children: [
                                  Text(
                                    "Login",
                                    style: TextStyle(
                                      fontSize: 19.0,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.cyan[200],
                                    ),
                                  ),
                                  Container(
                                    height: 3,
                                    width: 55,
                                    margin: const EdgeInsets.only(top: 5),
                                    color: Colors.orange[300],
                                  ),
                                ],
                              ),
                            ),
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  isSignUp = true;
                                });
                              },
                              child: Column(
                                children: [
                                  Text(
                                    "Sign Up",
                                    style: TextStyle(
                                      fontSize: 19.0,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.indigo[900],
                                    ),
                                  ),
                                  Container(
                                    height: 3,
                                    width: 55,
                                    margin: const EdgeInsets.only(top: 5),
                                    color: Colors.orange[300],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),

                        // Name field
                        TextField(
                          controller: nameController,
                          decoration: InputDecoration(
                            prefixIcon: Icon(Icons.person, color: Colors.indigo[900]),
                            hintText: "Enter your name",
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                          ),
                        ),

                        const SizedBox(height: 15),

                        // Surname field
                        TextField(
                          controller: surNameController,
                          decoration: InputDecoration(
                            prefixIcon: Icon(Icons.person, color: Colors.indigo[900]),
                            hintText: "Enter your surname",
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                          ),
                        ),

                        const SizedBox(height: 15),

                        // Email field
                        TextField(
                          controller: emailController,
                          decoration: InputDecoration(
                            prefixIcon: Icon(Icons.email, color: Colors.indigo[900]),
                            hintText: "Enter your email",
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                          ),
                          keyboardType: TextInputType.emailAddress,
                        ),

                        const SizedBox(height: 15),

                        // Password field
                        TextField(
                          controller: passController,
                          obscureText: true,
                          decoration: InputDecoration(
                            prefixIcon: Icon(Icons.lock, color: Colors.indigo[900]),
                            hintText: "Enter new password",
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                          ),
                        ),

                        const SizedBox(height: 15),

                        // Confirm password field
                        TextField(
                          controller: cpassController,
                          obscureText: true,
                          decoration: InputDecoration(
                            prefixIcon: Icon(Icons.lock, color: Colors.indigo[900]),
                            hintText: "Confirm password",
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Register & Verify button
                    // Register & Verify button
                    ElevatedButton.icon(
                      onPressed: isLoading
                          ? null
                          : () async {
                        setState(() => isLoading = true);

                        try {
                          // 1. Form validations
                          if (!verifyForm()) {
                            Fluttertoast.showToast(msg: "All fields are required");
                            setState(() => isLoading = false);
                            return;
                          }

                          // 2. Password validation
                          final String? passValidation = validatePass(passController.text.trim());
                          if (passValidation != null) {
                            Fluttertoast.showToast(msg: passValidation);
                            setState(() => isLoading = false);
                            return;
                          }

                          // 3. Email format validation
                          if (!validInput()) {
                            Fluttertoast.showToast(msg: "Please enter a valid email address");
                            setState(() => isLoading = false);
                            return;
                          }

                          // 4. Password match validation
                          if (cpassController.text.trim() != passController.text.trim()) {
                            Fluttertoast.showToast(msg: "Passwords do not match");
                            setState(() => isLoading = false);
                            return;
                          }

                          final email = emailController.text.trim();
                          final fullName = nameController.text.trim();
                          final surName = surNameController.text.trim();

                          // 5. Space check validation
                          if (!spaceCheck(fullName) ||
                              !spaceCheck(surName) ||
                              !spaceCheck(email)) {
                            Fluttertoast.showToast(msg: "Spaces not allowed in name/surname/email");
                            setState(() => isLoading = false);
                            return;
                          }

                          // 6. Check if email already exists
                          List<String> methods = await FirebaseAuth.instance.fetchSignInMethodsForEmail(email);
                          if (methods.isNotEmpty) {
                            Fluttertoast.showToast(msg: "This email is already registered");
                            setState(() => isLoading = false);
                            return;
                          }

                          // 7. Create user in Firebase Auth
                          UserCredential userCredential = await FirebaseAuth.instance
                              .createUserWithEmailAndPassword(
                            email: email,
                            password: passController.text.trim(),
                          );

                          final uid = userCredential.user!.uid;

                          // 8. Save user profile to Firestore
                          await registerUser(
                            uid: uid,
                            email: email,
                            fullName: fullName,
                            surName: surName,
                          );

                          // 9. Send verification email
                          await userCredential.user?.sendEmailVerification();
                          Fluttertoast.showToast(
                            msg: "Verification email sent to $email",
                            backgroundColor: Colors.blue,
                            toastLength: Toast.LENGTH_LONG,
                          );

                          // 10. Clear input fields
                          nameController.clear();
                          surNameController.clear();
                          emailController.clear();
                          passController.clear();
                          cpassController.clear();

                          // 11. Check verification status
                          await userCredential.user?.reload();
                          final currentUser = FirebaseAuth.instance.currentUser;

                          if (currentUser != null && currentUser.emailVerified) {
                            Fluttertoast.showToast(
                              msg: "Email verified successfully!",
                              backgroundColor: Colors.green,
                            );
                            Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => LoginPage()));
                          } else {
                            Fluttertoast.showToast(
                              msg: "Please check your email and click the verification link",
                              backgroundColor: Colors.orange,
                            );
                          }
                        } on FirebaseAuthException catch (e) {
                          Fluttertoast.showToast(
                            msg: "Error: ${e.message ?? 'Authentication failed'}",
                            backgroundColor: Colors.red,
                          );
                        } catch (e) {
                          Fluttertoast.showToast(
                            msg: "An error occurred: ${e.toString()}",
                            backgroundColor: Colors.red,
                          );
                        } finally {
                          setState(() => isLoading = false);
                        }
                      },
                      icon: isLoading
                          ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      )
                          : const Icon(Icons.check_circle),
                      label: isLoading
                          ? const Text("Processing...")
                          : const Text("Register & Verify"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.indigo[800],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        textStyle: const TextStyle(fontSize: 16),
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

class ForgotPasswordPage extends StatefulWidget {
  @override
  _ForgotPasswordPageState createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  bool isLoading = false;
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwController = TextEditingController();
  final TextEditingController cpasswController = TextEditingController();

  Future<void> _sendPasswordResetEmail() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isLoading = true);

    try {
      final email = emailController.text.trim();
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);

      Fluttertoast.showToast(
        msg: "Password reset email sent. Please check your inbox.",
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.BOTTOM,
      );
     emailController.clear();
      Navigator.pop(context);
    } on FirebaseAuthException catch (e) {
      String message;
      switch (e.code) {
        case 'user-not-found':
          message = 'No user found with this email.';
          break;
        case 'invalid-email':
          message = 'The email address is not valid.';
          break;
        default:
          message = 'Failed to send reset email: ${e.message}';
      }
      Fluttertoast.showToast(msg: message);
    } catch (e) {
      Fluttertoast.showToast(msg: 'Error: ${e.toString()}');
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(

      appBar:AppBar(
        backgroundColor: Colors.grey[500],
        title: Text(
          "Reset Page",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      backgroundColor: Colors.grey[600],
      body: SafeArea(
        child: Stack(
          children: [
            Container(
              width: double.infinity,
              height: double.infinity,
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage("images/background1.jpg"),
                  fit: BoxFit.cover,
                ),

              ),
              child:Container(
                width: double.infinity,
                height: double.infinity,
                color: (Colors.grey[900] ?? Colors.grey[900])!.withOpacity(.65),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  SizedBox(height: 30),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                  Center(
                    child: Container(
                      height: 250,
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 10,
                            spreadRadius: 3,
                          ),
                        ],
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            TextFormField(
                              controller: emailController,
                              keyboardType: TextInputType.emailAddress,
                              decoration: InputDecoration(
                                border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(15)),
                                prefixIcon: Icon(Icons.email, color: Colors.indigo[900]),
                                hintText: "Enter your email",
                              ),
                              validator: (value) {
                                if (value == null ||
                                    value.isEmpty ||
                                    !value.contains('@')) {
                                  return 'Please enter a valid email';
                                }
                                return null;
                              },
                            ),
                            SizedBox(height: 12),
                            ElevatedButton.icon(
                              onPressed: isLoading ? null : _sendPasswordResetEmail,
                              icon: isLoading
                                  ? SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                                  : Icon(Icons.security),
                              label: Text(isLoading ? "Sending..." : "Send Reset Email"),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.indigo[900],
                                foregroundColor: Colors.grey[300],
                                textStyle: TextStyle(fontSize: 18),
                                padding: EdgeInsets.symmetric(
                                    horizontal: 18, vertical: 12),
                              ),
                            ),
                            // Optional: keep these fields but disabled with explanation
                            SizedBox(height: 20),
                            Text(
                              "You will receive an email to reset your password.\nPlease check your inbox.",
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.black54),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
        ],
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
//mentee home page
class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}
class _MainPageState extends State<MainPage> {
  bool isPost = true;

  Future<void> hidePostForUser(String postId) async {
    final userId = FirebaseAuth.instance.currentUser!.uid;
    final userRef = FirebaseFirestore.instance.collection('users').doc(userId);

    await userRef.update({
      'hiddenPosts': FieldValue.arrayUnion([postId]),
    });
  }

  final TextEditingController postController = TextEditingController();
  // Add a map to store controllers for each post
  final Map<String, TextEditingController> _commentControllers = {};

  // Helper method to get or create a controller for a post
  TextEditingController _getCommentController(String postId) {
    if (!_commentControllers.containsKey(postId)) {
      _commentControllers[postId] = TextEditingController();
    }
    return _commentControllers[postId]!;
  }

  //dispose all controllers when the widget is disposed
  @override
  void dispose() {
    _commentControllers.values.forEach((controller) => controller.dispose());
    super.dispose();
  }


  Future<void> uploadPost(String type, bool showRealUsername) async {
    try {
      final userId = FirebaseAuth.instance.currentUser!.uid;

      // Fetch user doc
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
      print('Document exists? ${userDoc.exists}');
      if (!userDoc.exists) {
        Fluttertoast.showToast(msg: "User data not found!");
        return;
      }

      final realUserName = userDoc.data()?['fullName'] ?? 'Unknown';
      final surName = userDoc.data()?['surName'] ?? 'Unknown';
      final username = realUserName + " " + surName;

      // Decide username based on the boolean flag
      final displayUserName = showRealUsername ? username : 'Anonymous ******';

      String postText = postController.text;

      await FirebaseFirestore.instance.collection('posts').add({
        'userId': userId,
        'userName': displayUserName,
        'text': postText,
        'like': 0,
        'likedBy': [], // Added array to track users who liked the post
        'timestamp': FieldValue.serverTimestamp(),
      });
      postController.clear();
      Fluttertoast.showToast(msg: '$type uploaded');
    } catch (e) {
      Fluttertoast.showToast(msg: "Failed: $e");
    }
  }
 Future<void>uploadComment(String comment,String postId,String userId)async{
    //get post documents
   try{
     final postDoc=FirebaseFirestore.instance.collection('posts').doc(postId).get();
     //use the post id to create a comment table
     await  FirebaseFirestore.instance.collection('comments').add({
       'postId':postId,
       'comment':comment,
       'timestamp':FieldValue.serverTimestamp(),
       'userId': userId,
       'userName': FirebaseAuth.instance.currentUser?.displayName ?? 'Anonymous',
       'timestamp': FieldValue.serverTimestamp(),
     }

     );
     Fluttertoast.showToast(msg: "comment sent");
   }catch(e,stackTrace){
     Fluttertoast.showToast(msg: "error : $e");
   }


 }

  Future<void> addLike(String postId, List<dynamic> currentLikedBy) async {
    final userId = FirebaseAuth.instance.currentUser!.uid;
    final postRef = FirebaseFirestore.instance.collection('posts').doc(postId);

    if (currentLikedBy.contains(userId)) {
      await postRef.update({
                    'like': FieldValue.increment(-1),
                    'likedBy': FieldValue.arrayRemove([userId]),
                  });

    } else {
      await postRef.update({
        'like': FieldValue.increment(1),
        'likedBy': FieldValue.arrayUnion([userId]),
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.grey[400],
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.black,
        selectedFontSize: 14,
        unselectedFontSize: 14,
        onTap: (value) {
          if (value == 0) {
            //tasks
            Navigator.push(context, MaterialPageRoute(builder: (_) => TasksPage()));
          } else if (value == 1) {
            //meetings
            Navigator.push(context, MaterialPageRoute(builder: (_) => Planner()));
          } else if (value == 2) {
            // helpline
            Navigator.push(context, MaterialPageRoute(builder: (_) => HelpPage()));
          }
        },
        items: [
          BottomNavigationBarItem(
            label: 'Tasks',
            icon: Badge(
              backgroundColor: Colors.red,
              label: Text("", style: TextStyle(color: Colors.white)),
              child: Icon(Icons.alarm, color: Colors.indigo[900]),
            ),
          ),
          BottomNavigationBarItem(
            label: 'Planner',
            backgroundColor: Colors.red,
            icon:  Icon(Icons.map, color: Colors.indigo[900]),
          ),
          BottomNavigationBarItem(
            label: 'HelpLine',
            icon: Icon(Icons.help, color: Colors.indigo[900]),
          ),
        ],
      ),
      appBar: AppBar(
        backgroundColor: Colors.grey[200],
        title: Text(
          "Home",
          style: TextStyle(color: Colors.black),
        ),
      ),
      body: SafeArea(
        bottom: false,
        child: Container(
          color: Colors.white,
          child: Column(
            children: [
              // Header Section
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: postController,
                        textAlign: TextAlign.center,
                        decoration: InputDecoration(
                          hintText: "Write your post/question here",
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 15),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),

              // Post Type Selector
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[500],
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      GestureDetector(
                        onTap: () => setState(() => isPost = true),
                        onDoubleTap: () {
                          setState(() {
                            if (isPost) {
                              if (postController.text.isEmpty || postController.text == "") {
                                Fluttertoast.showToast(msg: "Post can not be empty");
                                return;
                              }
                              uploadPost("Post", true);
                            }
                          });
                        },
                        child: Container(
                          width: 90,
                          height: 40,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            color: isPost ? Colors.blue : Colors.grey[500],
                          ),
                          child: Align(
                            alignment: Alignment.center,
                            child: Text(
                              "Post",
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => setState(() => isPost = false),
                        onDoubleTap: () {
                          setState(() {
                            if (!isPost) {
                              if (postController.text.isEmpty || postController.text == "") {
                                Fluttertoast.showToast(msg: "Post can not be empty");
                                return;
                              }
                              uploadPost("Anonymous Post", false);
                            }
                          });
                        },
                        child: Container(
                          width: 130,
                          height: 40,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            color: isPost ? Colors.grey[500] : Colors.blue,
                          ),
                          child: Align(
                            alignment: Alignment.center,
                            child: Text(
                              "Post Anonymously",
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 15),

              // Main Content Area - Scrollable ListView
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('posts')
                      .orderBy('timestamp', descending: true)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(child: CircularProgressIndicator());
                    }
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return Center(child: Text("No posts yet."));
                    }

                    final docs = snapshot.data!.docs;
                    final currentUserId = FirebaseAuth.instance.currentUser!.uid;

                    return ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      itemCount: docs.length,
                      itemBuilder: (context, index) {
                        // Extract data from Firestore doc
                        final postData = docs[index].data() as Map<String, dynamic>;
                        final postUserId = postData['userId'];
                        final username = (postUserId == currentUserId) ? "You" : (postData['userName'] ?? 'Unknown user');
                        final text = postData['text'] ?? '';
                        final postId = docs[index].id;
                        final postLike = postData['like'] ?? 0;
                        final likedBy = List<String>.from(postData['likedBy'] ?? []);
                        final isLiked = likedBy.contains(currentUserId); // EDITED: Check if current user liked the post

                        return  Container(
                          margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [

                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    username,
                                    style: TextStyle(
                                      color: Colors.indigo[800],
                                      fontSize: 17,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  IconButton(
                                    onPressed: () {
                                      if (currentUserId == postUserId) {
                                        //
                                        showDialog(
                                          context: context,
                                          builder: (_) => AlertDialog(
                                            title: const Text("Delete Post"),
                                            content: const Text("Are you sure you want to delete this post?"),
                                            actions: [
                                              TextButton(
                                                onPressed: () => Navigator.pop(context),
                                                child: const Text("Cancel"),
                                              ),
                                              TextButton(
                                                onPressed: () async {
                                                  FirebaseFirestore.instance
                                                      .collection('posts')
                                                      .doc(docs[index].id)
                                                      .delete();


                                                  Navigator.pop(context);
                                                },
                                                child: const Text("Delete", style: TextStyle(color: Colors.red)),
                                              ),
                                            ],
                                          ),
                                        );
                                        //

                                      } else {
                                        Fluttertoast.showToast(
                                            msg: "Allowed to delete personal posts only.");
                                      }
                                    },
                                    icon: Icon(Icons.delete, color: Colors.red[700]),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 4),

                              // Post text
                              Text(
                                text,
                                style: const TextStyle(fontSize: 15, height: 1.3),
                              ),

                              const SizedBox(height: 8),

                              // Like button row
                              Row(
                                children: [
                                  IconButton(
                                    onPressed: () {
                                      addLike(postId, likedBy);
                                    },
                                    icon: Badge(
                                      label: Text(
                                        postLike.toString(),
                                        style: const TextStyle(color: Colors.white, fontSize: 12),
                                      ),
                                      child: Icon(
                                        isLiked ? Icons.favorite : Icons.favorite_border,
                                        color: isLiked ? Colors.red : Colors.grey,
                                      ),
                                    ),
                                  ),
                                  const Spacer(),
                                ],
                              ),

                              const Divider(height: 16),

                              // Reply / Comment Input
                              Row(
                                children: [
                                  Expanded(
                                    child: TextField(
                                      controller:  _getCommentController(postId),
                                      decoration: InputDecoration(
                                        hintText: "Add a reply...",
                                        isDense: true,
                                        contentPadding:
                                        const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(15),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                 IconButton(
                                    onPressed: () {
                                      String commentText = _getCommentController(postId).text;
                                      uploadComment(commentText, postId,currentUserId);

                                      _getCommentController(postId).clear();
                                    },
                                    icon: const Icon(Icons.send, size: 22),
                                    style: ElevatedButton.styleFrom(


                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 6),

                              // View Comments link
                              GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => PostCommentsPage(postId:postId,userId:currentUserId),
                                    ),
                                  );
                                },
                                child: Text(
                                  "View comments",
                                  style: TextStyle(
                                    decoration: TextDecoration.underline,
                                    color: Colors.blue[800],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );

                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
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

      body:NotificationsScreen(),

    );
  }
}




class HelpPage extends StatefulWidget {
  const HelpPage({super.key});

  @override
  State<HelpPage> createState() => _HelpPageState();
}

class _HelpPageState extends State<HelpPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.grey[500],
        title: Text("HelpLine",style:TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),),
      ),
    );
  }
}


class PostCommentsPage extends StatefulWidget {
  final String postId;
  final String userId;

  const PostCommentsPage({
    Key? key,
    required this.postId,
    required this.userId,
  }) : super(key: key);

  @override
  State<PostCommentsPage> createState() => _PostCommentsPageState();
}

class _PostCommentsPageState extends State<PostCommentsPage> {
  late Future<DocumentSnapshot<Map<String, dynamic>>> postFuture;
  late final Stream<QuerySnapshot<Map<String, dynamic>>> commentsStream;
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _commentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    postFuture = FirebaseFirestore.instance
        .collection('posts')
        .doc(widget.postId)
        .get();

    commentsStream = FirebaseFirestore.instance
        .collection('comments')
        .where('postId', isEqualTo: widget.postId)
    .orderBy('timestamp',descending:false)
        .snapshots();
  }

  Future<void> addLike() async {
    try {
      final userId = FirebaseAuth.instance.currentUser!.uid;
      final postRef = FirebaseFirestore.instance.collection('posts').doc(widget.postId);

      // Get fresh data to ensure we have current state
      final postDoc = await postRef.get();
      final currentLikedBy = List<String>.from(postDoc['likedBy'] ?? []);

      if (currentLikedBy.contains(userId)) {
        await postRef.update({
          'like': FieldValue.increment(-1),
          'likedBy': FieldValue.arrayRemove([userId]),
        });
      } else {
        await postRef.update({
          'like': FieldValue.increment(1),
          'likedBy': FieldValue.arrayUnion([userId]),
        });
      }

      // Refresh the post data
      setState(() {
        postFuture = postRef.get();
      });
    } catch (e) {
      Fluttertoast.showToast(msg: "Error liking post: $e");
    }
  }

  Future<void> addComment(String comment) async {
    try {
      if (comment.trim().isEmpty) return;
      final userId= widget.userId;
      final userDoc= await FirebaseFirestore.instance.collection('users').doc(userId).get();
      final displayName=userDoc.data()?['fullName']+" "+userDoc.data()?['surName'];

      await FirebaseFirestore.instance.collection('comments').add({
        'postId': widget.postId, // Consistent field name
        'comment': comment,
        'userId': widget.userId,
        'userName': displayName,
        'timestamp': FieldValue.serverTimestamp(),
      });
      _commentController.clear();
    } catch (e) {
      Fluttertoast.showToast(msg: "Error adding comment: $e");
    }
  }

  void deletePost() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Delete Post"),
        content: const Text("Are you sure you want to delete this post?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () async {
              try {
                // Delete post and its comments
                final batch = FirebaseFirestore.instance.batch();

                // Delete post
                batch.delete(FirebaseFirestore.instance.collection('posts').doc(widget.postId));

                // Delete all comments for this post
                final comments = await FirebaseFirestore.instance
                    .collection('comments')
                    .where('postId', isEqualTo: widget.postId)
                    .get();

                for (var doc in comments.docs) {
                  batch.delete(doc.reference);
                }

                await batch.commit();

                if (mounted) {
                  Navigator.pop(context);
                  Navigator.pop(context);
                }
              } catch (e) {
                if (mounted) Navigator.pop(context);
                Fluttertoast.showToast(msg: "Error deleting post: $e");
              }
            },
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Post & Comments')),
      body: Column(
        children: [
          // Post with like/comment/delete
          FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
            future: postFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.all(20.0),
                  child: CircularProgressIndicator(),
                );
              }
              if (!snapshot.hasData || !snapshot.data!.exists) {
                return const Padding(
                  padding: EdgeInsets.all(20.0),
                  child: Text('Post not found'),
                );
              }
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _scrollController.jumpTo(
                  _scrollController.position.maxScrollExtent,
                );
              });
              final postData = snapshot.data!.data()!;
              final likedBy = List<String>.from(postData['likedBy'] ?? []);
              final isLiked = likedBy.contains(widget.userId);
              final likeCount = postData['like'] ?? 0;

              return Card(
                margin: const EdgeInsets.all(8),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        postData['userName'] ?? 'Unknown User',
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(postData['text'] ?? ''),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          IconButton(
                            icon: Icon(
                              isLiked
                                  ? Icons.favorite
                                  : Icons.favorite_border,
                              color: isLiked ? Colors.red : Colors.grey,
                            ),
                            onPressed: addLike, // Simplified call
                          ),
                          Text("$likeCount"),
                          const SizedBox(width: 16),
                          if (postData['userId'] == widget.userId) ...[
                            const SizedBox(width: 16),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: deletePost,
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),

          const Divider(),

          // Comments
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: commentsStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('No comments yet.'));
                }

                final comments = snapshot.data!.docs;
                return ListView.builder(
                  controller: _scrollController,
                  itemCount: comments.length,
                  itemBuilder: (context, index) {
                    final commentData = comments[index].data();
                    return ListTile(
                      leading: const CircleAvatar(child: Icon(Icons.person)),
                      title: Text(commentData['userName'] ?? 'Anonymous'),
                      subtitle: Text(commentData['comment']),
                    );
                  },
                );
              },
            ),
          ),

          // Comment Input
          SafeArea(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Colors.grey[300]!)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _commentController,
                      decoration: const InputDecoration(
                        hintText: "Add a comment...",
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.send),
                    onPressed: () {
                      final comment = _commentController.text.trim();
                      if (comment.isNotEmpty) {
                        addComment(comment);
                      }
                    },
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
class Planner extends StatefulWidget {
  const Planner({super.key});

  @override
  State<Planner> createState() => _PlannerState();
}

class _PlannerState extends State<Planner> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(onPressed: (){
            Navigator.push(context, MaterialPageRoute(builder: (_)=>addEvent()));
      },
      backgroundColor: Colors.indigo[900],
      child: Icon(
        Icons.add,
        color: Colors.white,
      ),),
      appBar: AppBar(
        title: Text("Planner"),
        backgroundColor: Colors.grey[200],
      ),
      body: ListView.builder(
        itemCount: 8,
        padding: EdgeInsets.all(12),
        itemBuilder: (context, index) {
          final String eventName = "Assignment 3";
          final String eventDescription = "I have to submit this.";
          final DateTime eventDate = DateTime.now();
          final String startTime = "17:00";
          final String endTime = "18:00";

          return Card(
            margin: EdgeInsets.symmetric(vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 3,
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        eventName,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        onPressed: () {},
                        icon: Icon(Icons.delete, color: Colors.red),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.calendar_today, size: 18, color: Colors.indigo[900]),
                      SizedBox(width: 6),
                      Text(
                        "${eventDate.day}/${eventDate.month}/${eventDate.year}",
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.access_time, size: 18, color: Colors.indigo[900]),
                          SizedBox(width: 4),
                          Text(
                            "Start: $startTime",
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Icon(Icons.access_time, size: 18, color: Colors.indigo[900]),
                          SizedBox(width: 4),
                          Text(
                            "End: $endTime",
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ],
                  ),
                  SizedBox(height: 12),
                  Text(
                    eventDescription,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[800],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
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
  Map<String, bool> daysSelected = {
    "Monday": false,
    "Tuesday": false,
    "Wednesday": false,
    "Thursday": false,
    "Friday": false,
    "Saturday": false,
    "Sunday": false,
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Add Event"),
        backgroundColor: Colors.grey[200],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Event Name
            TextField(
              decoration: InputDecoration(
                labelText: "Event Name",
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 12),

            // Description
            TextField(
              decoration: InputDecoration(
                labelText: "Description",
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            SizedBox(height: 12),

            // Start Time
            TextField(
              decoration: InputDecoration(
                labelText: "Start Time",
                border: OutlineInputBorder(),
                hintText: "HH:MM",
              ),
            ),
            SizedBox(height: 12),

            // End Time
            TextField(
              decoration: InputDecoration(
                labelText: "End Time",
                border: OutlineInputBorder(),
                hintText: "HH:MM",
              ),
            ),
            SizedBox(height: 12),

            // Date of Event
            TextField(
              decoration: InputDecoration(
                labelText: "Date of Event",
                border: OutlineInputBorder(),
                hintText: "DD/MM/YYYY",
                prefixIcon: Icon(Icons.calendar_today),
              ),
            ),
            SizedBox(height: 24),

            // Day selection with checkboxes
            Text(
              "Select Reminder Days:",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Column(
              children: daysSelected.keys.map((day) {
                return CheckboxListTile(
                  title: Text(day),
                  value: daysSelected[day],
                  onChanged: (bool? value) {
                    setState(() {
                      daysSelected[day] = value!;
                    });
                  },
                  controlAffinity: ListTileControlAffinity.leading,
                );
              }).toList(),
            ),
            SizedBox(height: 24),

            // Add Button
            ElevatedButton(
              onPressed: () {
                // Action to add event to DB (UI only)
              },
              style: ElevatedButton.styleFrom(
                minimumSize: Size(double.infinity, 50),
                backgroundColor: Colors.indigo[800],
              ),
              child: Text("Add Event",style: TextStyle(color:Colors.white),),
            ),
          ],
        ),
      ),
    );
  }
}







