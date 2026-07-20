import 'package:flutter/material.dart';

import 'package:school_management/theme/app_theme.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({Key? key}) : super(key: key);

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _Book {
  final String title;
  final String author;
  final bool available;
  const _Book(this.title, this.author, this.available);
}

class _LibraryScreenState extends State<LibraryScreen> {
  final _search = TextEditingController();
  String _query = '';

  static const _books = [
    _Book('Introduction to Algorithms', 'Cormen', true),
    _Book('Physics for Scientists', 'Serway', true),
    _Book('Organic Chemistry', 'Clayden', false),
    _Book('A Brief History of Time', 'Stephen Hawking', true),
    _Book('Pride and Prejudice', 'Jane Austen', true),
    _Book('The Selfish Gene', 'Richard Dawkins', false),
    _Book('Calculus', 'James Stewart', true),
    _Book('Clean Code', 'Robert C. Martin', true),
  ];

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _books
        .where((b) =>
            b.title.toLowerCase().contains(_query.toLowerCase()) ||
            b.author.toLowerCase().contains(_query.toLowerCase()))
        .toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Library')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _search,
              onChanged: (v) => setState(() => _query = v),
              decoration: InputDecoration(
                hintText: 'Search books or authors',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _query.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _search.clear();
                          setState(() => _query = '');
                        },
                      ),
              ),
            ),
          ),
          Expanded(
            child: filtered.isEmpty
                ? const Center(child: Text('No books found'))
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (_, i) {
                      final b = filtered[i];
                      return Card(
                        child: ListTile(
                          leading: const CircleAvatar(
                            backgroundColor: Color(0x1A8B5CF6),
                            child: Icon(Icons.menu_book,
                                color: Color(0xFF8B5CF6)),
                          ),
                          title: Text(b.title,
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text(b.author),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: (b.available
                                      ? AppColors.success
                                      : AppColors.danger)
                                  .withOpacity(0.12),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              b.available ? 'Available' : 'Issued',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: b.available
                                    ? AppColors.success
                                    : AppColors.danger,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
