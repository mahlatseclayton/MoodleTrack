import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
import 'dart:io';  // Add this import

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print(' Firebase initialized!');
  } catch (e) {
    print(' Firebase failed to initialize: $e');
  }

  runApp(const MyApp());
}



class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home:const Homepage(),
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
                // color: (Colors.purple[900] ?? Colors.purple[900])!.withOpacity(.),
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

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isLoading = true);

    try {
      final email = emailController.text.trim(); // removed .toLowerCase()
      final password = passController.text.trim();

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
        MaterialPageRoute(builder: (context) => mainPage()),
      );

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
            ),
            Positioned(
              top: 20,
              left: 20,
              child: Text(
                "Login",
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 29,
                  fontWeight: FontWeight.bold,
                ),
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
  Future<bool> registerUser(String email, String password, String fullName,String schoolName,String surname) async {
    try {
      // Create user in Firebase Auth
      UserCredential cred = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);

      // Send email verification
      await cred.user!.sendEmailVerification();

      // Save user to Firestore with isVerified = false
      await FirebaseFirestore.instance.collection('users').doc(cred.user!.uid).set({
        'uid': cred.user!.uid,
        'email': email,
        'fullName': fullName,
        'surName':surname,
        'schoolName':schoolName,
        'isVerified': false,
        'createdAt': Timestamp.now(),
      });

      print('success');
      return true;
    } catch (e) {
      print('Registration failed: $e');

      return false;
    }
  }

  Widget build(BuildContext context) {
    return Scaffold(
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

            // Form container, scrollable, centered horizontally and positioned below title
            Positioned.fill(
              top: 220, // pushes container below the title text nicely
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 25),
                child: Center(
                  child: Container(
                    constraints: const BoxConstraints(
                      maxWidth: 500, // optional max width for bigger screens
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
                                Navigator.pop(context);
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

                              // 5. Space check validation
                              if (!spaceCheck(nameController.text) ||
                                  !spaceCheck(surNameController.text) ||
                                  !spaceCheck(emailController.text)) {
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

                              // 7. Create user if all validations pass
                              UserCredential userCredential = await FirebaseAuth.instance
                                  .createUserWithEmailAndPassword(
                                email: email,
                                password: passController.text.trim(),
                              );

                              // 8. Send verification email
                              await userCredential.user?.sendEmailVerification();
                              Fluttertoast.showToast(
                                msg: "Verification email sent to $email",
                                backgroundColor: Colors.blue,
                                toastLength: Toast.LENGTH_LONG,
                              );
                              nameController.clear();
                              surNameController.clear();
                              emailController.clear();
                              passController.clear();
                              cpassController.clear();
                              // 9. CORRECTED: Check verification status with reload
                              await userCredential.user?.reload();
                              final currentUser = FirebaseAuth.instance.currentUser;

                              if (currentUser != null && currentUser.emailVerified) {
                                Fluttertoast.showToast(
                                  msg: "Email verified successfully!",
                                  backgroundColor: Colors.green,
                                );
                                // Only navigate if you want to
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
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Reset Page",
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 35,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
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

class mainPage extends StatefulWidget {
  const mainPage({super.key});

  @override
  State<mainPage> createState() => _mainPageState();
}

class _mainPageState extends State<mainPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body:Text("Welcome to the main page,",style: TextStyle(
        fontSize: 40,
      ),)
    );
  }
}








