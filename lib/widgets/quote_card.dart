import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import '../models/quote_model.dart';
import '../providers/quote_provider.dart';
import '../providers/auth_provider.dart';

class QuoteCard extends StatelessWidget {
  final QuoteModel quote;
  final bool showActions;

  const QuoteCard({
    super.key,
    required this.quote,
    this.showActions = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        padding: const EdgeInsets.all(20.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF6750A4).withOpacity(0.1),
              Colors.white.withOpacity(0.8),
            ],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Quote text
            Text(
              '"${quote.text}"',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontStyle: FontStyle.italic,
                height: 1.5,
                color: Theme.of(context).colorScheme.onSurface,
              ),
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 16),

            // Author
            Row(
              children: [
                Icon(
                  Icons.person_outline,
                  size: 16,
                  color: Colors.grey[600],
                ),
                const SizedBox(width: 6),
                Text(
                  '— ${quote.author}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF6750A4),
                  ),
                ),
                const Spacer(),
                // Actions
                if (showActions) _buildActions(context),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActions(BuildContext context) {
    return Consumer2<QuoteProvider, AuthProvider>(
      builder: (context, quoteProvider, authProvider, child) {
        if (authProvider.user == null) return const SizedBox.shrink();

        final isFavorite = quoteProvider.isQuoteFavorite(quote.id);

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Copy button
            IconButton(
              onPressed: () => _copyToClipboard(context),
              icon: Icon(
                Icons.copy_outlined,
                size: 20,
                color: Colors.grey[600],
              ),
              tooltip: 'Copy quote',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(
                minWidth: 32,
                minHeight: 32,
              ),
            ),
            // Favorite button
            IconButton(
              onPressed: () => _toggleFavorite(context),
              icon: Icon(
                isFavorite ? Icons.favorite : Icons.favorite_border,
                size: 20,
                color: isFavorite ? Colors.red : Colors.grey[600],
              ),
              tooltip: isFavorite ? 'Remove from favorites' : 'Add to favorites',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(
                minWidth: 32,
                minHeight: 32,
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _copyToClipboard(BuildContext context) async {
    try {
      await Clipboard.setData(ClipboardData(
        text: '"${quote.text}" — ${quote.author}',
      ));
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Quote copied to clipboard!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to copy quote: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _toggleFavorite(BuildContext context) async {
    final quoteProvider = Provider.of<QuoteProvider>(context, listen: false);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    if (authProvider.user == null) return;

    try {
      await quoteProvider.toggleFavorite(authProvider.user!.uid, quote);
      
      if (context.mounted) {
        final isFavorite = quoteProvider.isQuoteFavorite(quote.id);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isFavorite 
                  ? 'Added to favorites!' 
                  : 'Removed from favorites!'
            ),
            backgroundColor: isFavorite ? Colors.green : Colors.orange,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
