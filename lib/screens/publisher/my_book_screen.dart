import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/api_service.dart';

class MyBooksScreen extends StatefulWidget {
  const MyBooksScreen({super.key});

  @override
  State<MyBooksScreen> createState() => _MyBooksScreenState();
}

class _MyBooksScreenState extends State<MyBooksScreen> {

  late Future<List<dynamic>> booksFuture;

  @override
  void initState() {
    super.initState();

    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      booksFuture = ApiService.getMyBooks(user.email!);
    }
  }

  Future<void> refreshBooks() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      setState(() {
        booksFuture = ApiService.getMyBooks(user.email!);
      });
    }
  }

  @override
  Widget build(BuildContext context) {

    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(
          child: Text("User not logged in"),
        ),
      );
    }

    return Scaffold(

      appBar: AppBar(
        title: const Text("My Books"),
      ),

      body: FutureBuilder<List<dynamic>>(

        future: booksFuture,

        builder: (context, snapshot) {

          // 🔄 LOADING
          if (snapshot.connectionState ==
              ConnectionState.waiting) {

            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          // ❌ ERROR
          if (snapshot.hasError) {

            return Center(
              child: Text(
                "Error loading books\n${snapshot.error}",
                textAlign: TextAlign.center,
              ),
            );
          }

          // 📭 EMPTY
          if (!snapshot.hasData ||
              snapshot.data!.isEmpty) {

            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [

                  Icon(
                    Icons.menu_book_outlined,
                    size: 60,
                    color: Colors.grey,
                  ),

                  SizedBox(height: 10),

                  Text(
                    "No Books Uploaded Yet",
                    style: TextStyle(fontSize: 16),
                  ),
                ],
              ),
            );
          }

          final books = snapshot.data!;

          // 📚 LIST
          return RefreshIndicator(

            onRefresh: refreshBooks,

            child: ListView.builder(

              itemCount: books.length,

              itemBuilder: (context, index) {

                final book =
                books[index] as Map<String, dynamic>;

                return Card(

                  margin: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6),

                  elevation: 3,

                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),

                  child: ListTile(

                    leading: const Icon(
                      Icons.book,
                      color: Colors.indigo,
                    ),

                    title: Text(
                      book["author_name"] ?? "Unknown Author",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    subtitle: Text(
                      "Watermark ID: ${book["watermark_id"] ?? "-"}",
                    ),

                    trailing: Text(
                      book["timestamp"] ?? "",
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}