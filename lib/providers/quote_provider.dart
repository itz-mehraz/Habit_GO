import 'package:flutter/material.dart';
import '../models/quote_model.dart';
import '../services/quote_service.dart';

class QuoteProvider extends ChangeNotifier {
  final QuoteService _quoteService = QuoteService();
  
  List<QuoteModel> _quotes = [];
  List<QuoteModel> _favoriteQuotes = [];
  bool _isLoading = false;
  String? _error;
  bool _isRefreshing = false;

  List<QuoteModel> get quotes => _quotes;
  List<QuoteModel> get favoriteQuotes => _favoriteQuotes;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isRefreshing => _isRefreshing;

  QuoteProvider() {
    _loadQuotes();
  }

  // Load quotes from API
  Future<void> _loadQuotes() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final fetchedQuotes = await _quoteService.fetchQuotes(count: 8);
      _quotes = fetchedQuotes;
      _error = null;
    } catch (e) {
      _error = 'Error loading quotes: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Refresh quotes
  Future<void> refreshQuotes() async {
    _isRefreshing = true;
    notifyListeners();

    try {
      final fetchedQuotes = await _quoteService.fetchQuotes(count: 8);
      _quotes = fetchedQuotes;
      _error = null;
    } catch (e) {
      _error = 'Error refreshing quotes: $e';
    } finally {
      _isRefreshing = false;
      notifyListeners();
    }
  }

  // Load favorite quotes from Firebase
  Stream<List<QuoteModel>> getFavoriteQuotes(String userId) {
    return _quoteService.getFavoriteQuotes(userId);
  }

  // Set favorite quotes
  void setFavoriteQuotes(List<QuoteModel> favoriteQuotes) {
    _favoriteQuotes = favoriteQuotes;
    notifyListeners();
  }

  // Toggle favorite status
  Future<void> toggleFavorite(String userId, QuoteModel quote) async {
    try {
      await _quoteService.toggleFavorite(userId, quote);
      
      // Update local state
      final isFavorite = _favoriteQuotes.any((q) => q.id == quote.id);
      
      if (isFavorite) {
        _favoriteQuotes.removeWhere((q) => q.id == quote.id);
      } else {
        _favoriteQuotes.add(quote);
      }
      
      notifyListeners();
    } catch (e) {
      _error = 'Error toggling favorite: $e';
      notifyListeners();
    }
  }

  // Check if quote is favorite
  bool isQuoteFavorite(String quoteId) {
    return _favoriteQuotes.any((quote) => quote.id == quoteId);
  }

  // Add quote to favorites
  Future<void> addToFavorites(String userId, QuoteModel quote) async {
    try {
      await _quoteService.addToFavorites(userId, quote);
      
      if (!_favoriteQuotes.any((q) => q.id == quote.id)) {
        _favoriteQuotes.add(quote);
        notifyListeners();
      }
    } catch (e) {
      _error = 'Error adding to favorites: $e';
      notifyListeners();
    }
  }

  // Remove quote from favorites
  Future<void> removeFromFavorites(String userId, String quoteId) async {
    try {
      await _quoteService.removeFromFavorites(userId, quoteId);
      
      _favoriteQuotes.removeWhere((quote) => quote.id == quoteId);
      notifyListeners();
    } catch (e) {
      _error = 'Error removing from favorites: $e';
      notifyListeners();
    }
  }

  // Alias for UI compatibility
  Future<void> favoriteQuote(String userId, QuoteModel quote) async {
    await addToFavorites(userId, quote);
  }

  Future<void> unfavoriteQuote(String userId, String quoteId) async {
    await removeFromFavorites(userId, quoteId);
  }

  // Get random quote
  QuoteModel? getRandomQuote() {
    if (_quotes.isEmpty) return null;
    
    final random = DateTime.now().millisecondsSinceEpoch;
    final index = random % _quotes.length;
    return _quotes[index];
  }

  // Get quotes by author
  List<QuoteModel> getQuotesByAuthor(String author) {
    return _quotes.where((quote) => 
      quote.author.toLowerCase().contains(author.toLowerCase())
    ).toList();
  }

  // Search quotes
  List<QuoteModel> searchQuotes(String query) {
    if (query.isEmpty) return _quotes;
    
    final lowercaseQuery = query.toLowerCase();
    return _quotes.where((quote) =>
      quote.text.toLowerCase().contains(lowercaseQuery) ||
      quote.author.toLowerCase().contains(lowercaseQuery)
    ).toList();
  }

  // Get motivational quotes (filtered)
  List<QuoteModel> getMotivationalQuotes() {
    final motivationalKeywords = [
      'success', 'motivation', 'inspiration', 'achievement',
      'goal', 'dream', 'perseverance', 'determination',
      'strength', 'courage', 'hope', 'belief'
    ];
    
    return _quotes.where((quote) {
      final lowercaseText = quote.text.toLowerCase();
      return motivationalKeywords.any((keyword) =>
        lowercaseText.contains(keyword)
      );
    }).toList();
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Get quote statistics
  Map<String, dynamic> getQuoteStats() {
    return {
      'totalQuotes': _quotes.length,
      'favoriteQuotes': _favoriteQuotes.length,
      'uniqueAuthors': _quotes.map((q) => q.author).toSet().length,
      'averageQuoteLength': _quotes.isEmpty ? 0 : 
        _quotes.map((q) => q.text.length).reduce((a, b) => a + b) / _quotes.length,
    };
  }
}
