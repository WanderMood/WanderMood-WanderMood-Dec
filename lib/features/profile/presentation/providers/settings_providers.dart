import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Subscription Model
class Subscription {
  final String id;
  final String userId;
  final String planType; // 'free' or 'premium'
  final String status; // 'active', 'cancelled', 'expired'
  final DateTime? startedAt;
  final DateTime? expiresAt;

  Subscription({
    required this.id,
    required this.userId,
    required this.planType,
    required this.status,
    this.startedAt,
    this.expiresAt,
  });

  factory Subscription.fromSupabase(Map<String, dynamic> data) {
    return Subscription(
      id: data['id'] as String,
      userId: data['user_id'] as String,
      planType: data['plan_type'] as String? ?? 'free',
      status: data['status'] as String? ?? 'active',
      startedAt: data['started_at'] != null
          ? DateTime.parse(data['started_at'] as String)
          : null,
      expiresAt: data['expires_at'] != null
          ? DateTime.parse(data['expires_at'] as String)
          : null,
    );
  }
}

// Subscription Provider
final subscriptionProvider = FutureProvider<Subscription?>((ref) async {
  final supabase = Supabase.instance.client;
  final user = supabase.auth.currentUser;
  
  if (user == null) return null;

  try {
    final response = await supabase
        .from('subscriptions')
        .select()
        .eq('user_id', user.id)
        .maybeSingle();

    if (response != null) {
      return Subscription.fromSupabase(response);
    }

    // Create default free subscription if none exists
    final defaultSub = {
      'user_id': user.id,
      'plan_type': 'free',
      'status': 'active',
    };

    final insertResponse = await supabase
        .from('subscriptions')
        .insert(defaultSub)
        .select()
        .single();

    return Subscription.fromSupabase(insertResponse);
  } catch (e) {
    // Return null on error, will default to free
    return null;
  }
});

// Account Security Model
class AccountSecurity {
  final String id;
  final String userId;
  final DateTime? passwordChangedAt;
  final bool twoFactorEnabled;
  final String? twoFactorSecret;

  AccountSecurity({
    required this.id,
    required this.userId,
    this.passwordChangedAt,
    this.twoFactorEnabled = false,
    this.twoFactorSecret,
  });

  factory AccountSecurity.fromSupabase(Map<String, dynamic> data) {
    return AccountSecurity(
      id: data['id'] as String,
      userId: data['user_id'] as String,
      passwordChangedAt: data['password_changed_at'] != null
          ? DateTime.parse(data['password_changed_at'] as String)
          : null,
      twoFactorEnabled: data['two_factor_enabled'] as bool? ?? false,
      twoFactorSecret: data['two_factor_secret'] as String?,
    );
  }
}

// Account Security Provider
final accountSecurityProvider = FutureProvider<AccountSecurity?>((ref) async {
  final supabase = Supabase.instance.client;
  final user = supabase.auth.currentUser;
  
  if (user == null) return null;

  try {
    final response = await supabase
        .from('account_security')
        .select()
        .eq('user_id', user.id)
        .maybeSingle();

    if (response != null) {
      return AccountSecurity.fromSupabase(response);
    }

    // Create default security record if none exists
    final defaultSecurity = {
      'user_id': user.id,
      'two_factor_enabled': false,
    };

    final insertResponse = await supabase
        .from('account_security')
        .insert(defaultSecurity)
        .select()
        .single();

    return AccountSecurity.fromSupabase(insertResponse);
  } catch (e) {
    return null;
  }
});

// Active Session Model
class ActiveSession {
  final String id;
  final String userId;
  final String? deviceName;
  final String? deviceType;
  final String? ipAddress;
  final String? location;
  final DateTime lastActiveAt;
  final DateTime createdAt;
  final bool isCurrent;

  ActiveSession({
    required this.id,
    required this.userId,
    this.deviceName,
    this.deviceType,
    this.ipAddress,
    this.location,
    required this.lastActiveAt,
    required this.createdAt,
    this.isCurrent = false,
  });

  factory ActiveSession.fromSupabase(Map<String, dynamic> data) {
    return ActiveSession(
      id: data['id'] as String,
      userId: data['user_id'] as String,
      deviceName: data['device_name'] as String?,
      deviceType: data['device_type'] as String?,
      ipAddress: data['ip_address'] as String?,
      location: data['location'] as String?,
      lastActiveAt: DateTime.parse(data['last_active_at'] as String),
      createdAt: DateTime.parse(data['created_at'] as String),
      isCurrent: data['is_current'] as bool? ?? false,
    );
  }
}

// Active Sessions Provider
final activeSessionsProvider = FutureProvider<List<ActiveSession>>((ref) async {
  final supabase = Supabase.instance.client;
  final user = supabase.auth.currentUser;
  
  if (user == null) return [];

  try {
    final response = await supabase
        .from('active_sessions')
        .select()
        .eq('user_id', user.id)
        .order('last_active_at', ascending: false);

    return (response as List)
        .map((data) => ActiveSession.fromSupabase(data as Map<String, dynamic>))
        .toList();
  } catch (e) {
    return [];
  }
});

// Data Export Model
class DataExport {
  final String id;
  final String userId;
  final String exportType;
  final String? fileUrl;
  final int? fileSizeBytes;
  final DateTime? expiresAt;
  final DateTime createdAt;

  DataExport({
    required this.id,
    required this.userId,
    required this.exportType,
    this.fileUrl,
    this.fileSizeBytes,
    this.expiresAt,
    required this.createdAt,
  });

  factory DataExport.fromSupabase(Map<String, dynamic> data) {
    return DataExport(
      id: data['id'] as String,
      userId: data['user_id'] as String,
      exportType: data['export_type'] as String? ?? 'full',
      fileUrl: data['file_url'] as String?,
      fileSizeBytes: data['file_size_bytes'] as int?,
      expiresAt: data['expires_at'] != null
          ? DateTime.parse(data['expires_at'] as String)
          : null,
      createdAt: DateTime.parse(data['created_at'] as String),
    );
  }
}

// Data Exports Provider
final dataExportsProvider = FutureProvider<List<DataExport>>((ref) async {
  final supabase = Supabase.instance.client;
  final user = supabase.auth.currentUser;
  
  if (user == null) return [];

  try {
    final response = await supabase
        .from('data_exports')
        .select()
        .eq('user_id', user.id)
        .order('created_at', ascending: false)
        .limit(10);

    return (response as List)
        .map((data) => DataExport.fromSupabase(data as Map<String, dynamic>))
        .toList();
  } catch (e) {
    return [];
  }
});

