import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/quote_provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/quote_card.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final quoteProvider = Provider.of<QuoteProvider>(context, listen: false);

    if (authProvider.user != null) {
      quoteProvider.getFavoriteQuotes(authProvider.user!.uid).listen((favorites) {
        quoteProvider.setFavoriteQuotes(favorites);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Favorite Quotes'),
        centerTitle: true,
        elevation: 0,
      ),
      body: Consumer<QuoteProvider>(
        builder: (context, quoteProvider, child) {
          final favorites = quoteProvider.favoriteQuotes;

          if (favorites.isEmpty) {
            return _buildEmptyState();
          }

          return RefreshIndicator(
            onRefresh: () async {
              await _loadFavorites();
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: favorites.length,
              itemBuilder: (context, index) {
                final quote = favorites[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: QuoteCard(
                    quote: quote,
                    showActions: true,
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.favorite_border,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No favorite quotes yet',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start adding quotes to your favorites\nfrom the home screen!',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
