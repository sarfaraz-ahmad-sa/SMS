import 'package:flutter/material.dart';

import '../Widgets/jinn_ui.dart';
import '../Widgets/saas_scaffold.dart';
import '../theme/app_theme.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _Book {
  final String title;
  final String author;
  final String code;
  final bool available;
  const _Book(this.title, this.author, this.code, this.available);
}

class _LibraryScreenState extends State<LibraryScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  static const List<_Book> _books = <_Book>[
    _Book('Introduction to Algorithms', 'Cormen', 'CS-0142', true),
    _Book('Physics for Scientists', 'Serway', 'PHY-0088', true),
    _Book('Organic Chemistry', 'Clayden', 'CHE-0034', false),
    _Book('A Brief History of Time', 'Stephen Hawking', 'SCI-0118', true),
    _Book('Pride and Prejudice', 'Jane Austen', 'LIT-0043', true),
    _Book('The Selfish Gene', 'Richard Dawkins', 'BIO-0081', false),
    _Book('Calculus', 'James Stewart', 'MTH-0174', true),
    _Book('Clean Code', 'Robert C. Martin', 'CS-0199', true),
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _books
        .where(( _Book book) => '${book.title} ${book.author} ${book.code}'.toLowerCase().contains(_query.toLowerCase()))
        .toList(growable: false);

    return SaasScaffold(
      title: 'Library',
      activeRoute: '/modules',
      activeModuleId: 'library',
      body: JinnPage(
        maxWidth: 1220,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const JinnResponsiveGrid(
              minItemWidth: 180,
              childAspectRatio: 2.35,
              children: <Widget>[
                _LibraryMetric('Total Books', '8,642', Icons.library_books_rounded, AppColors.pastelBlue, Color(0xFF4E68D8)),
                _LibraryMetric('Available', '7,914', Icons.check_circle_rounded, AppColors.pastelGreen, Color(0xFF27936B)),
                _LibraryMetric('Issued', '728', Icons.assignment_return_rounded, AppColors.pastelGold, Color(0xFFD89614)),
                _LibraryMetric('Overdue', '19', Icons.error_rounded, AppColors.pastelRose, Color(0xFFE05D65)),
              ],
            ),
            const SizedBox(height: 18),
            JinnCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const JinnSectionHeader(
                    title: 'Book Catalogue',
                    subtitle: 'Search by title, author or catalogue code.',
                  ),
                  const SizedBox(height: 13),
                  JinnSearchField(
                    controller: _searchController,
                    hintText: 'Search books or authors...',
                    onChanged: (String value) => setState(() => _query = value.trim()),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            if (filtered.isEmpty)
              const JinnEmptyState(
                icon: Icons.menu_book_outlined,
                title: 'No books found',
                message: 'Try another title, author or catalogue code.',
              )
            else
              LayoutBuilder(
                builder: (BuildContext context, BoxConstraints constraints) {
                  final compact = constraints.maxWidth < 720;
                  if (compact) {
                    return Column(
                      children: filtered
                          .map(( _Book book) => Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: _BookCard(book: book),
                              ))
                          .toList(growable: false),
                    );
                  }
                  return JinnResponsiveGrid(
                    minItemWidth: 350,
                    children: filtered.map(( _Book book) => _BookCard(book: book)).toList(growable: false),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}

class _LibraryMetric extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color background;
  final Color foreground;
  const _LibraryMetric(this.label, this.value, this.icon, this.background, this.foreground);

  @override
  Widget build(BuildContext context) {
    return JinnCard(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
      child: Row(
        children: <Widget>[
          JinnIconBadge(icon: icon, color: foreground, background: background, size: 42),
          const SizedBox(width: 10),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
              Text(label, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ],
      ),
    );
  }
}

class _BookCard extends StatelessWidget {
  final _Book book;
  const _BookCard({required this.book});

  @override
  Widget build(BuildContext context) {
    return JinnCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: <Widget>[
          const JinnIconBadge(icon: Icons.menu_book_rounded, color: Color(0xFF7B5DC7), background: AppColors.pastelPurple, size: 48),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(book.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Text('${book.author}  ·  ${book.code}', maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
          const SizedBox(width: 8),
          JinnStatusPill(
            label: book.available ? 'Available' : 'Issued',
            color: book.available ? AppColors.success : AppColors.danger,
          ),
        ],
      ),
    );
  }
}
