import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../providers/book_provider.dart';
import '../../providers/notification_provider.dart';
import '../../models/book.dart';
import '../../widgets/book_card.dart';
import '../../widgets/notification_badge.dart';
import 'post_book_screen.dart';

class MyListings extends StatelessWidget {
  const MyListings({super.key});

  void _confirmDelete(BuildContext context, BookProvider prov, Book book) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove from Shelf?'),
        content: Text(
          'Are you sure you want to remove "${book.title}" from your shelf?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Nevermind'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              prov.delete(book.id);
            },
            child: const Text(
              'Yes, Remove',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final notifications = context.watch<NotificationProvider>();
    final theme = Theme.of(context);

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('My Shelf'),
          bottom: TabBar(
            indicatorColor: theme.colorScheme.primary, // Hot Pink
            indicatorWeight: 3,
            labelColor: theme.colorScheme.primary,
            unselectedLabelColor: Colors.black54,
            tabs: [
              const Tab(text: 'My Books'),
              Tab(
                child: NotificationBadge(
                  count: notifications.unreadMyOffers,
                  child: const Text('My Offers'),
                ),
              ),
              Tab(
                child: NotificationBadge(
                  count: notifications.unreadIncomingOffers,
                  child: const Text('Requests'),
                ),
              ),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildMyBooks(context),
            _buildMyOffers(context),
            _buildIncomingOffers(context),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const PostBookScreen()),
          ),
          backgroundColor: theme.colorScheme.primary,
          foregroundColor: Colors.white,
          child: const Icon(Icons.add),
        ),
      ),
    );
  }

  // The rest of the logic remains unchanged.
  // ... (All other methods like _buildMyBooks, _buildMyOffers, etc., are the same)
  Widget _buildMyBooks(BuildContext context) {
    final prov = context.watch<BookProvider>();
    return prov.mine.isEmpty
        ? const Center(
            child: Text(
              'Your shelf is empty!\nAdd a book to start swapping.',
              textAlign: TextAlign.center,
            ),
          )
        : ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            itemCount: prov.mine.length,
            itemBuilder: (c, i) {
              final b = prov.mine[i];
              return BookCard(
                book: b,
                ownerActions: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit_outlined),
                      tooltip: 'Edit',
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => PostBookScreen(editing: b),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      tooltip: 'Delete',
                      onPressed: () => _confirmDelete(context, prov, b),
                    ),
                  ],
                ),
              );
            },
          );
  }

  Widget _buildMyOffers(BuildContext context) {
    final prov = context.watch<BookProvider>();
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: prov.myOffers,
      builder: (context, snapshot) {
        if (!snapshot.hasData)
          return const Center(child: CircularProgressIndicator());
        final offers = snapshot.data!.docs;
        if (offers.isEmpty)
          return const Center(child: Text('You haven\'t made any offers yet!'));
        return ListView.builder(
          itemCount: offers.length,
          itemBuilder: (context, i) {
            final offer = offers[i].data();
            return _buildOfferCard(context, offer, false);
          },
        );
      },
    );
  }

  Widget _buildIncomingOffers(BuildContext context) {
    final prov = context.watch<BookProvider>();
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: prov.incomingOffers,
      builder: (context, snapshot) {
        if (!snapshot.hasData)
          return const Center(child: CircularProgressIndicator());
        final offers = snapshot.data!.docs;
        if (offers.isEmpty)
          return const Center(child: Text('No swap requests right now.'));
        return ListView.builder(
          itemCount: offers.length,
          itemBuilder: (context, i) {
            final offer = offers[i].data();
            return _buildOfferCard(context, offer, true, offers[i].id);
          },
        );
      },
    );
  }

  Widget _buildOfferCard(
    BuildContext context,
    Map<String, dynamic> offer,
    bool isIncoming, [
    String? swapId,
  ]) {
    final status = offer['status'] ?? 'Pending';
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        title: Text('Offer for Book ID: ${offer['bookId']}'),
        subtitle: Text('Current Status: $status'),
        trailing: _buildTrailingWidget(
          context,
          offer,
          status,
          isIncoming,
          swapId,
        ),
      ),
    );
  }

  Widget _buildTrailingWidget(
    BuildContext context,
    Map<String, dynamic> offer,
    String status,
    bool isIncoming,
    String? swapId,
  ) {
    if (isIncoming && status == 'Pending') {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(
              Icons.check_circle_outline,
              color: Colors.green,
              size: 28,
            ),
            onPressed: () => context.read<BookProvider>().acceptSwap(
              swapId!,
              offer['bookId'],
            ),
            tooltip: 'Accept',
          ),
          IconButton(
            icon: const Icon(Icons.highlight_off, color: Colors.red, size: 28),
            onPressed: () => context.read<BookProvider>().rejectSwap(
              swapId!,
              offer['bookId'],
            ),
            tooltip: 'Reject',
          ),
        ],
      );
    }

    if (status == 'Accepted') {
      return ElevatedButton(
        onPressed: () => _showCompleteDialog(context, swapId!, offer),
        style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
        child: const Text('Complete'),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _getStatusColor(status),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  void _showCompleteDialog(
    BuildContext context,
    String swapId,
    Map<String, dynamic> offer,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Complete Swap'),
        content: const Text(
          'Did you successfully complete the swap? This will allow you to rate your partner.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Not Yet'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<BookProvider>().completeSwap(
                swapId,
                offer['bookId'],
              );
              _showRatingDialog(
                context,
                offer['senderId'] ?? offer['receiverId'],
              );
            },
            child: const Text('Yes, Complete!'),
          ),
        ],
      ),
    );
  }

  void _showRatingDialog(BuildContext context, String userId) {
    int rating = 5;
    final commentController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rate Your Swap Partner'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            StatefulBuilder(
              builder: (context, setState) {
                return Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (index) {
                    return IconButton(
                      onPressed: () => setState(() => rating = index + 1),
                      icon: Icon(
                        index < rating
                            ? Icons.star_rounded
                            : Icons.star_border_rounded,
                        color: Colors.amber,
                        size: 32,
                      ),
                    );
                  }),
                );
              },
            ),
            const SizedBox(height: 16),
            TextField(
              controller: commentController,
              decoration: const InputDecoration(
                hintText: 'How was your experience?',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Skip'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Implement rating submission logic
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Thanks for your feedback!')),
              );
            },
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Pending':
        return Colors.orange;
      case 'Accepted':
        return Colors.green;
      case 'Rejected':
        return Colors.red;
      case 'Completed':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }
}
