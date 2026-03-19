import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:wandermood/core/providers/supabase_provider.dart';

/// Provider for the SchemaHelper
final schemaHelperProvider = Provider<SchemaHelper>((ref) {
  final supabaseClient = ref.watch(supabaseClientProvider);
  return SchemaHelper(supabaseClient);
});

/// Helper class to manage database schema
class SchemaHelper {
  final SupabaseClient _client;
  
  SchemaHelper(this._client);
  
  /// Create the scheduled_activities table if it doesn't exist
  Future<void> createScheduledActivitiesTable() async {
    try {
      print('SchemaHelper: Attempting to create scheduled_activities table');
      
      // First, try to query the table to see if it exists
      try {
        final response = await _client.from('scheduled_activities').select('id').limit(1);
        print('SchemaHelper: Table already exists, got response: $response');
        return; // Table exists, so we're good
      } catch (queryError) {
        print('SchemaHelper: Table query failed: $queryError');
        // Proceed with table creation if query failed
      }
      
      // Option 1: Try to execute SQL directly
      // Note: This only works if your Supabase database has the appropriate permissions
      // and SQL execution is enabled for your API key
      try {
        // SQL to create the table
        const sql = '''
        CREATE TABLE IF NOT EXISTS public.scheduled_activities (
          id SERIAL PRIMARY KEY,
          user_id UUID NOT NULL,
          activity_id TEXT NOT NULL,
          name TEXT NOT NULL,
          description TEXT,
          image_url TEXT,
          start_time TIMESTAMP WITH TIME ZONE NOT NULL,
          duration INTEGER NOT NULL,
          location_name TEXT,
          latitude DOUBLE PRECISION,
          longitude DOUBLE PRECISION,
          is_confirmed BOOLEAN DEFAULT FALSE,
          tags TEXT,
          payment_type TEXT,
          scheduled_date DATE,
          created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
          UNIQUE(user_id, activity_id)
        );
        ''';
        
        // Attempt to execute SQL directly using the REST API
        // This might work depending on your Supabase setup
        await _client.rpc('execute_sql', params: {'query': sql});
        print('SchemaHelper: Table created successfully via execute_sql RPC');
        return;
      } catch (sqlError) {
        print('SchemaHelper: Direct SQL execution failed: $sqlError');
        // Continue to next approach
      }
      
      // Option 2: Try to use the default table creation approach
      try {
        await _client.from('scheduled_activities').insert({
          'user_id': 'temp-user-id',
          'activity_id': 'temp-activity-id',
          'name': 'Temporary Activity',
          'description': 'This is a temporary record to test table auto-creation',
          'image_url': 'https://example.com/image.jpg',
          'start_time': DateTime.now().toIso8601String(),
          'duration': 60,
          'latitude': 0.0,
          'longitude': 0.0,
          'tags': 'test',
          'payment_type': 'free',
          'scheduled_date': DateTime.now().toIso8601String().substring(0, 10),
        });
        
        // If we get here, it means the table exists (maybe it was auto-created)
        print('SchemaHelper: Table exists or was auto-created successfully');
        
        // Delete the temporary record
        try {
          await _client.from('scheduled_activities')
            .delete()
            .eq('activity_id', 'temp-activity-id');
        } catch (deleteError) {
          print('SchemaHelper: Error deleting temp record: $deleteError');
        }
        
        return;
      } catch (insertError) {
        print('SchemaHelper: Test insertion failed: $insertError');
      }
      
      // If all attempts fail, log instructions for manual creation
      print('SchemaHelper: Automatic table creation failed. Please run this SQL in the Supabase dashboard:');
      print('''
      CREATE TABLE IF NOT EXISTS public.scheduled_activities (
        id SERIAL PRIMARY KEY,
        user_id UUID NOT NULL,
        activity_id TEXT NOT NULL,
        name TEXT NOT NULL,
        description TEXT,
        image_url TEXT,
        start_time TIMESTAMP WITH TIME ZONE NOT NULL,
        duration INTEGER NOT NULL,
        location_name TEXT,
        latitude DOUBLE PRECISION,
        longitude DOUBLE PRECISION,
        is_confirmed BOOLEAN DEFAULT FALSE,
        tags TEXT,
        payment_type TEXT,
        scheduled_date DATE,
        created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
        UNIQUE(user_id, activity_id)
      );
      ''');
      
      print('SchemaHelper: Using in-memory storage instead since table creation failed');
    } catch (e) {
      print('SchemaHelper: General error creating table: $e');
      // Don't rethrow - just log the error
    }
  }
} 
 
 
 