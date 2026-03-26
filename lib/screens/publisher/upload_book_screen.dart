import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/api_service.dart';

class UploadBookScreen extends StatefulWidget {
  const UploadBookScreen({super.key});

  @override
  State<UploadBookScreen> createState() => _UploadBookScreenState();
}

class _UploadBookScreenState extends State<UploadBookScreen>
    with SingleTickerProviderStateMixin {

  String? selectedFileName;
  String? selectedFilePath;

  final nameController = TextEditingController();
  final isbnController = TextEditingController();

  bool isUploading = false;

  late AnimationController controller;
  late Animation<double> fadeAnim;
  late Animation<Offset> slideAnim;

  @override
  void initState() {
    super.initState();

    controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    fadeAnim =
        CurvedAnimation(parent: controller, curve: Curves.easeOut);

    slideAnim = Tween(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(
        CurvedAnimation(parent: controller, curve: Curves.easeOut));

    controller.forward();
  }

  @override
  void dispose() {
    controller.dispose();
    nameController.dispose();
    isbnController.dispose();
    super.dispose();
  }

  // ================= PICK PDF =================
  Future pickFile() async {

    FilePickerResult? result =
    await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result != null) {
      setState(() {
        selectedFileName = result.files.single.name;
        selectedFilePath = result.files.single.path;
      });
    }
  }

  // ================= REGISTER BOOK =================
  Future registerBook() async {

    if (nameController.text.isEmpty ||
        isbnController.text.isEmpty ||
        selectedFilePath == null) {

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please fill all fields & upload PDF"),
        ),
      );
      return;
    }

    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("User not logged in"),
        ),
      );
      return;
    }

    final email = user.email!;

    setState(() => isUploading = true);

    try {

      await ApiService.registerBookPDF(
        selectedFilePath!,
        nameController.text,
        email,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Book Registered Successfully"),
        ),
      );

      // reset form
      setState(() {
        selectedFileName = null;
        selectedFilePath = null;
      });

      nameController.clear();
      isbnController.clear();

    } catch (e) {

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Upload Failed: $e"),
        ),
      );

    }

    setState(() => isUploading = false);
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FB),

      body: Container(
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

        child: SafeArea(
          child: FadeTransition(
            opacity: fadeAnim,
            child: SlideTransition(
              position: slideAnim,
              child: Padding(
                padding: const EdgeInsets.all(20),

                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    const Text(
                      "Register Your Book",
                      style: TextStyle(
                        fontSize: 26,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 6),

                    const Text(
                      "Secure your authorship with Authentix",
                      style: TextStyle(color: Colors.white70),
                    ),

                    const SizedBox(height: 25),

                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(22),

                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(28),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.15),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            )
                          ],
                        ),

                        child: ListView(
                          children: [

                            buildField("Author Name", nameController),
                            buildField("ISBN Number", isbnController),

                            const SizedBox(height: 20),

                            GestureDetector(
                              onTap: pickFile,

                              child: Container(
                                height: 160,

                                decoration: BoxDecoration(
                                  borderRadius:
                                  BorderRadius.circular(22),

                                  border: Border.all(
                                    color: const Color(0xFF1B263B),
                                    width: 1.6,
                                  ),

                                  color: const Color(0xFF1B263B)
                                      .withOpacity(0.05),
                                ),

                                child: Column(
                                  mainAxisAlignment:
                                  MainAxisAlignment.center,

                                  children: [

                                    Icon(
                                      selectedFileName == null
                                          ? Icons.cloud_upload_outlined
                                          : Icons.check_circle,

                                      size: 60,
                                      color: const Color(0xFF1B263B),
                                    ),

                                    const SizedBox(height: 12),

                                    Text(
                                      selectedFileName ??
                                          "Upload Book (PDF)",

                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            const SizedBox(height: 35),

                            SizedBox(
                              height: 54,

                              child: ElevatedButton(

                                onPressed:
                                isUploading ? null : registerBook,

                                style: ElevatedButton.styleFrom(
                                  elevation: 6,
                                  backgroundColor:
                                  const Color(0xFF1B263B),

                                  shape: RoundedRectangleBorder(
                                    borderRadius:
                                    BorderRadius.circular(18),
                                  ),
                                ),

                                child: isUploading
                                    ? const CircularProgressIndicator(
                                  color: Colors.white,
                                )
                                    : const Text(
                                  "Embed Watermark & Register",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ],
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

  Widget buildField(
      String label, TextEditingController controller) {

    return Padding(
      padding: const EdgeInsets.only(bottom: 15),

      child: TextField(
        controller: controller,

        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: const Color(0xFFF4F6FB),

          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }
}