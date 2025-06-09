import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/place.dart';

part 'saved_places_provider.g.dart';

@riverpod
class SavedPlaces extends _$SavedPlaces {
  static const String _savedPlacesKey = 'saved_places';

  @override
  Future<List<Place>> build() async {
    return await _loadSavedPlaces();
  }

  Future<List<Place>> _loadSavedPlaces() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedPlacesJson = prefs.getString(_savedPlacesKey);
      
      if (savedPlacesJson != null) {
        final List<dynamic> jsonList = json.decode(savedPlacesJson);
        return jsonList.map((json) => Place.fromJson(json)).toList();
      }
      
      return [];
    } catch (e) {
      print('Error loading saved places: $e');
      return [];
    }
  }

  Future<void> _savePlacesToStorage(List<Place> places) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = places.map((place) => place.toJson()).toList();
      await prefs.setString(_savedPlacesKey, json.encode(jsonList));
    } catch (e) {
      print('Error saving places: $e');
    }
  }

  Future<void> toggleSave(Place place) async {
    final currentPlaces = state.value ?? [];
    final isCurrentlySaved = currentPlaces.any((p) => p.id == place.id);
    
    List<Place> updatedPlaces;
    if (isCurrentlySaved) {
      // Remove from saved
      updatedPlaces = currentPlaces.where((p) => p.id != place.id).toList();
    } else {
      // Add to saved with current date
      final placeWithDate = place.copyWith(dateAdded: DateTime.now());
      updatedPlaces = [...currentPlaces, placeWithDate];
    }
    
    // Update state
    state = AsyncValue.data(updatedPlaces);
    
    // Save to storage
    await _savePlacesToStorage(updatedPlaces);
  }

  bool isSaved(String placeId) {
    final currentPlaces = state.value ?? [];
    return currentPlaces.any((place) => place.id == placeId);
  }

  Future<void> removeSaved(String placeId) async {
    final currentPlaces = state.value ?? [];
    final updatedPlaces = currentPlaces.where((p) => p.id != placeId).toList();
    
    state = AsyncValue.data(updatedPlaces);
    await _savePlacesToStorage(updatedPlaces);
  }
} 