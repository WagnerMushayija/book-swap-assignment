import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/book_provider.dart';
import '../../providers/notification_provider.dart';
import '../../widgets/book_card.dart';
import '../../widgets/notification_badge.dart';
import '../home/post_book_screen.dart';

class BrowseListings extends StatefulWidget {
  const BrowseListings({super.key});

  @override
  State<BrowseListings> createState() => _BrowseListingsState();
}

class _BrowseListingsState extends State<BrowseListings> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<BookProvider>();
    final filteredBooks = prov.browse.where((book) {
      if (_searchQuery.isEmpty) return true;
      return book.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          book.author.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Find a New Story')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search for titles or authors...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
              ),
              onChanged: (value) => setState(() => _searchQuery = value),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '${filteredBooks.length} adventures waiting...',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ),
          ),
          Expanded(
            child: filteredBooks.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Text(
                        _searchQuery.isEmpty
                            ? 'The library is quiet...\nTap the + button to add a book!'
                            : 'No stories found for "$_searchQuery".',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[700],
                          height: 1.5,
                        ),
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    itemCount: filteredBooks.length,
                    itemBuilder: (c, i) {
                      final b = filteredBooks[i];
                      return BookCard(
                        book: b,
                        onSwap: () async {
                          try {
                            await prov.requestSwap(b);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Swap request sent for "${b.title}"!',
                                  ),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Oops! $e'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          }
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const PostBookScreen()),
        ),
        icon: const Icon(Icons.add),
        label: const Text('Add Book'),
        backgroundColor: Theme.of(context).colorScheme.primary, // Hot Pink
        foregroundColor: Colors.white,
      ),
    );
  }
}
