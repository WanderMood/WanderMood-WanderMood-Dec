import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final databaseServiceProvider = Provider<DatabaseService>((ref) {
  return DatabaseService();
});

class DatabaseService {
  final SupabaseClient _supabase = Supabase.instance.client;
  
  /// Voert een SQL migratie uit vanuit een bestand
  Future<void> executeMigration(String sqlFilePath) async {
    try {
      // Laad het SQL bestand
      final sqlContent = await rootBundle.loadString(sqlFilePath);
      
      // Maak een verbinding met de Supabase postgres client
      // Note: Dit vereist uitgebreide permissies, werkt alleen in development
      // For production, migrations moeten via Supabase Dashboard worden toegepast
      await _supabase.rpc('exec_sql', params: {'sql_query': sqlContent});
      
      if (kDebugMode) debugPrint('Migration executed: $sqlFilePath');
    } catch (e) {
      if (kDebugMode) debugPrint('Migration error: $e');
      rethrow;
    }
  }
  
  /// Controleert of een tabel bestaat
  Future<bool> tableExists(String tableName) async {
    try {
      final result = await _supabase
          .rpc('check_table_exists', params: {'table_name': tableName});
      
      return result ?? false;
    } catch (e) {
      if (kDebugMode) debugPrint('Table check error: $e');
      return false;
    }
  }
  
  /// Controleert of de database schema up-to-date is
  Future<bool> isDatabaseInitialized() async {
    // Controleer of de basis tabellen bestaan
    final moodsTableExists = await tableExists('moods');
    
    return moodsTableExists;
  }
  
  /// Initialiseert de database als deze nog niet is geïnitialiseerd
  Future<void> initializeDatabase() async {
    if (await isDatabaseInitialized()) {
      if (kDebugMode) debugPrint('Database already initialized');
      return;
    }
    
    // Voer migraties uit in volgorde
    await executeMigration('lib/core/database/migrations/mood_table_migration.sql');
    
    if (kDebugMode) debugPrint('Database initialization complete');
  }
} 