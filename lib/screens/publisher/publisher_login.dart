import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'publisher_dashboard.dart';

class PublisherLoginScreen extends StatefulWidget {
  const PublisherLoginScreen({super.key});

  @override
  State<PublisherLoginScreen> createState() =>
      _PublisherLoginScreenState();
}

class _PublisherLoginScreenState extends State<PublisherLoginScreen>
    with SingleTickerProviderStateMixin {

  final FirebaseAuth _auth = FirebaseAuth.instance;

  final TextEditingController emailController =
  TextEditingController();

  final TextEditingController passwordController =
  TextEditingController();

  bool isLogin = true;
  bool isLoading = false;

  late AnimationController controller;
  late Animation<double> fadeAnim;
  late Animation<Offset> slideAnim;

  @override
  void initState() {
    super.initState();

    controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    fadeAnim =
        CurvedAnimation(parent: controller, curve: Curves.easeOut);

    slideAnim = Tween(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(
        CurvedAnimation(parent: controller, curve: Curves.easeOut));

    controller.forward();
  }

  // ================= REGISTER (MAIL ONLY HERE) =================
  Future registerUser() async {
    FocusScope.of(context).unfocus();

    if (emailController.text.isEmpty ||
        passwordController.text.isEmpty) {
      showMsg("Enter Email & Password");
      return;
    }

    try {
      setState(() => isLoading = true);

      UserCredential userCredential =
      await _auth.createUserWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      // ⭐ SEND VERIFICATION MAIL ONLY DURING REGISTER
      await userCredential.user!.sendEmailVerification();

      showMsg("Verification Email Sent 📧 Check Gmail");

      await _auth.signOut();
    } on FirebaseAuthException catch (e) {
      showMsg(e.message ?? "Register Failed");
    }

    setState(() => isLoading = false);
  }

  // ================= LOGIN (NO MAIL SENT) =================
  Future loginUser() async {
    FocusScope.of(context).unfocus();

    if (emailController.text.isEmpty ||
        passwordController.text.isEmpty) {
      showMsg("Enter Email & Password");
      return;
    }

    try {
      setState(() => isLoading = true);

      await _auth.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const PublisherDashboard(),
        ),
      );

    } on FirebaseAuthException catch (e) {
      showMsg(e.message ?? "Login Failed");
    }

    setState(() => isLoading = false);
  }

  void showMsg(String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  void dispose() {
    controller.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF0D1B2A),
              Color(0xFF1B263B),
              Color(0xFF415A77),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: FadeTransition(
            opacity: fadeAnim,
            child: SlideTransition(
              position: slideAnim,
              child: Container(
                margin:
                const EdgeInsets.symmetric(horizontal: 24),
                padding: const EdgeInsets.all(26),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [

                    const Icon(Icons.verified_user,
                        size: 42,
                        color: Color(0xFF1B263B)),

                    const SizedBox(height: 20),

                    Text(
                      isLogin
                          ? "Publisher Login"
                          : "Create Publisher Account",
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 25),

                    Row(
                      mainAxisAlignment:
                      MainAxisAlignment.center,
                      children: [
                        toggleTab("Login", isLogin, () {
                          setState(() => isLogin = true);
                        }),
                        toggleTab("Register", !isLogin, () {
                          setState(() => isLogin = false);
                        }),
                      ],
                    ),

                    const SizedBox(height: 25),

                    TextField(
                      controller: emailController,
                      style:
                      const TextStyle(color: Colors.black87),
                      decoration: InputDecoration(
                        prefixIcon:
                        const Icon(Icons.email),
                        labelText: "Email",
                        filled: true,
                        fillColor:
                        const Color(0xFFF4F6FB),
                        border: OutlineInputBorder(
                          borderRadius:
                          BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),

                    const SizedBox(height: 15),

                    TextField(
                      controller: passwordController,
                      obscureText: true,
                      style:
                      const TextStyle(color: Colors.black87),
                      decoration: InputDecoration(
                        prefixIcon:
                        const Icon(Icons.lock),
                        labelText: "Password",
                        filled: true,
                        fillColor:
                        const Color(0xFFF4F6FB),
                        border: OutlineInputBorder(
                          borderRadius:
                          BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),

                    const SizedBox(height: 30),

                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                          const Color(0xFF1B263B),
                          shape: RoundedRectangleBorder(
                            borderRadius:
                            BorderRadius.circular(18),
                          ),
                        ),
                        onPressed: isLoading
                            ? null
                            : isLogin
                            ? loginUser
                            : registerUser,
                        child: isLoading
                            ? const CircularProgressIndicator(
                            color: Colors.white)
                            : Text(
                          isLogin
                              ? "LOGIN"
                              : "REGISTER",
                          style: const TextStyle(
                              fontWeight:
                              FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget toggleTab(
      String text, bool active, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration:
        const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(
            horizontal: 22, vertical: 9),
        margin:
        const EdgeInsets.symmetric(horizontal: 6),
        decoration: BoxDecoration(
          color: active
              ? const Color(0xFF1B263B)
              : Colors.transparent,
          borderRadius:
          BorderRadius.circular(22),
          border:
          Border.all(color: const Color(0xFF1B263B)),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: active
                ? Colors.white
                : const Color(0xFF1B263B),
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
