import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/quote_model.dart';

class QuoteService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Fetch quotes from external API (Quotable)
  Future<List<QuoteModel>> fetchQuotes({int count = 5}) async {
    try {
      final response = await http.get(
        Uri.parse('https://api.quotable.io/quotes/random?limit=$count'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((quote) {
          return QuoteModel(
            id: quote['_id'] ?? '',
            text: quote['content'] ?? '',
            author: quote['author'] ?? 'Unknown',
          );
        }).toList();
      } else {
        // Fallback quotes if API fails
        return _getFallbackQuotes();
      }
    } catch (e) {
      // Return fallback quotes on error
      return _getFallbackQuotes();
    }
  }

  // Fallback quotes in case API is unavailable
  List<QuoteModel> _getFallbackQuotes() {
    return [
      QuoteModel(
        id: '1',
        text: 'The only way to do great work is to love what you do.',
        author: 'Steve Jobs',
      ),
      QuoteModel(
        id: '2',
        text: 'Success is not final, failure is not fatal: it is the courage to continue that counts.',
        author: 'Winston Churchill',
      ),
      QuoteModel(
        id: '3',
        text: 'The future depends on what you do today.',
        author: 'Mahatma Gandhi',
      ),
      QuoteModel(
        id: '4',
        text: 'Don\'t watch the clock; do what it does. Keep going.',
        author: 'Sam Levenson',
      ),
      QuoteModel(
        id: '5',
        text: 'The only limit to our realization of tomorrow is our doubts of today.',
        author: 'Franklin D. Roosevelt',
      ),
      QuoteModel(
        id: '6',
        text: 'Habits are the compound interest of self-improvement.',
        author: 'James Clear',
      ),
      QuoteModel(
        id: '7',
        text: 'Small changes, remarkable results.',
        author: 'Atomic Habits',
      ),
      QuoteModel(
        id: '8',
        text: 'Every day is a new beginning.',
        author: 'Anonymous',
      ),
    ];
  }

  // Add quote to favorites
  Future<void> addToFavorites(String userId, QuoteModel quote) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('favorites')
          .doc('quotes')
          .collection('quotes')
          .doc(quote.id)
          .set(quote.toMap());
    } catch (e) {
      throw 'Error adding quote to favorites: $e';
    }
  }

  // Remove quote from favorites
  Future<void> removeFromFavorites(String userId, String quoteId) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('favorites')
          .doc('quotes')
          .collection('quotes')
          .doc(quoteId)
          .delete();
    } catch (e) {
      throw 'Error removing quote from favorites: $e';
    }
  }

  // Get user's favorite quotes
  Stream<List<QuoteModel>> getFavoriteQuotes(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('favorites')
        .doc('quotes')
        .collection('quotes')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => QuoteModel.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  // Check if a quote is in favorites
  Future<bool> isQuoteFavorite(String userId, String quoteId) async {
    try {
      final doc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('favorites')
          .doc('quotes')
          .collection('quotes')
          .doc(quoteId)
          .get();
      
      return doc.exists;
    } catch (e) {
      return false;
    }
  }

  // Toggle favorite status
  Future<void> toggleFavorite(String userId, QuoteModel quote) async {
    try {
      final isFavorite = await isQuoteFavorite(userId, quote.id);
      
      if (isFavorite) {
        await removeFromFavorites(userId, quote.id);
      } else {
        await addToFavorites(userId, quote);
      }
    } catch (e) {
      throw 'Error toggling favorite: $e';
    }
  }
}
