import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/favorite_feature.dart';

class FavoritesService {
  static const String _favoritesKey = 'user_favorites';

  // Load user favorites from storage
  static Future<List<FavoriteFeature>> loadFavorites() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final favoritesJson = prefs.getStringList(_favoritesKey);

      if (favoritesJson == null || favoritesJson.isEmpty) {
        // Return default favorites if none saved
        return FavoriteFeature.defaultFavorites;
      }

      final favorites = <FavoriteFeature>[];
      for (final favoriteString in favoritesJson) {
        try {
          final favoriteMap = json.decode(favoriteString);
          favorites.add(FavoriteFeature.fromJson(favoriteMap));
        } catch (e) {
          print('Error loading favorite: $e');
        }
      }

      // Sort by order
      favorites.sort((a, b) => a.order.compareTo(b.order));

      // Ensure chat is always first
      final chatIndex = favorites.indexWhere((f) => f.type == FeatureType.chat);
      if (chatIndex > 0) {
        final chat = favorites.removeAt(chatIndex);
        favorites.insert(0, chat);
      }

      return favorites;
    } catch (e) {
      print('Error loading favorites: $e');
      return FavoriteFeature.defaultFavorites;
    }
  }

  // Save user favorites to storage
  static Future<void> saveFavorites(List<FavoriteFeature> favorites) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final favoritesJson = favorites
          .map((favorite) => json.encode(favorite.toJson()))
          .toList();
      await prefs.setStringList(_favoritesKey, favoritesJson);
    } catch (e) {
      print('Error saving favorites: $e');
    }
  }

  // Add a feature to favorites
  static Future<List<FavoriteFeature>> addToFavorites(FeatureType type) async {
    final currentFavorites = await loadFavorites();

    // Check if already in favorites
    if (currentFavorites.any((f) => f.type == type)) {
      return currentFavorites;
    }

    // Find the feature in all available features
    final allFeatures = FavoriteFeature.allAvailableFeatures;
    final featureToAdd = allFeatures.firstWhere((f) => f.type == type);

    // Add with next order number
    final newOrder = currentFavorites.isEmpty
        ? 0
        : currentFavorites.map((f) => f.order).reduce((a, b) => a > b ? a : b) +
              1;
    final newFavorite = FavoriteFeature(
      type: featureToAdd.type,
      title: featureToAdd.title,
      icon: featureToAdd.icon,
      order: newOrder,
    );

    final updatedFavorites = [...currentFavorites, newFavorite];
    await saveFavorites(updatedFavorites);
    return updatedFavorites;
  }

  // Remove a feature from favorites
  static Future<List<FavoriteFeature>> removeFromFavorites(
    FeatureType type,
  ) async {
    final currentFavorites = await loadFavorites();

    // Don't allow removing chat
    if (type == FeatureType.chat) {
      return currentFavorites;
    }

    final updatedFavorites = currentFavorites
        .where((f) => f.type != type)
        .toList();
    await saveFavorites(updatedFavorites);
    return updatedFavorites;
  }

  // Reorder favorites
  static Future<List<FavoriteFeature>> reorderFavorites(
    List<FavoriteFeature> favorites,
  ) async {
    // Ensure chat is always first
    final chatIndex = favorites.indexWhere((f) => f.type == FeatureType.chat);
    if (chatIndex > 0) {
      final chat = favorites.removeAt(chatIndex);
      favorites.insert(0, chat);
    }

    // Update order numbers
    for (int i = 0; i < favorites.length; i++) {
      favorites[i] = FavoriteFeature(
        type: favorites[i].type,
        title: favorites[i].title,
        icon: favorites[i].icon,
        order: i,
      );
    }

    await saveFavorites(favorites);
    return favorites;
  }

  // Get available features that are not in favorites
  static Future<List<FavoriteFeature>> getAvailableFeaturesToAdd() async {
    final currentFavorites = await loadFavorites();
    final allFeatures = FavoriteFeature.allAvailableFeatures;

    return allFeatures
        .where(
          (feature) => !currentFavorites.any(
            (favorite) => favorite.type == feature.type,
          ),
        )
        .toList();
  }

  // Check if a feature is in favorites
  static Future<bool> isInFavorites(FeatureType type) async {
    final favorites = await loadFavorites();
    return favorites.any((f) => f.type == type);
  }
}
