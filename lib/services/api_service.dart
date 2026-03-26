import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class ApiService {

  // 🌐 Render Backend URL
  static const String baseUrl =
      "https://authentix-api.onrender.com";

  // ================= REGISTER BOOK =================
  static Future<dynamic> registerBookPDF(
      String filePath,
      String name,
      String email) async {

    try {

      var request = http.MultipartRequest(
        "POST",
        Uri.parse("$baseUrl/register"),
      );

      // 📄 FILE
      request.files.add(
        await http.MultipartFile.fromPath(
          "file",
          filePath,
        ),
      );

      // 📌 FORM DATA
      request.fields["author_name"] = name;
      request.fields["author_email"] = email;

      var response = await request.send()
          .timeout(const Duration(seconds: 30));

      var res = await http.Response.fromStream(response);

      if (res.statusCode == 200) {
        return jsonDecode(res.body);
      } else {
        throw Exception("Server Error: ${res.statusCode}");
      }

    } catch (e) {
      throw Exception("Upload failed: $e");
    }
  }

  // ================= VERIFY BOOK =================
  static Future<dynamic> verifyBook(File file) async {

    try {

      var request = http.MultipartRequest(
        "POST",
        Uri.parse("$baseUrl/verify"),
      );

      request.files.add(
        await http.MultipartFile.fromPath(
          "file",
          file.path,
        ),
      );

      var response = await request.send()
          .timeout(const Duration(seconds: 30));

      var res = await http.Response.fromStream(response);

      if (res.statusCode == 200) {
        return jsonDecode(res.body);
      } else {
        throw Exception("Verification failed");
      }

    } catch (e) {
      throw Exception("Verify Error: $e");
    }
  }

  // ================= GET MY BOOKS =================
  static Future<List<dynamic>> getMyBooks(String email) async {

    try {

      final response = await http.get(
        Uri.parse("$baseUrl/my-books?email=$email"),
      ).timeout(const Duration(seconds: 20));

      if (response.statusCode == 200) {

        final data = jsonDecode(response.body);

        if (data is List) {
          return data;
        } else {
          return [];
        }

      } else {
        throw Exception("Failed to load books");
      }

    } catch (e) {
      throw Exception("API Error: $e");
    }
  }
}