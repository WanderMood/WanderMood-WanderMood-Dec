import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/presentation/widgets/swirl_background.dart';
import '../../application/auth_provider.dart';

class AuthTestScreen extends ConsumerStatefulWidget {
  const AuthTestScreen({super.key});

  @override
  ConsumerState<AuthTestScreen> createState() => _AuthTestScreenState();
}

class _AuthTestScreenState extends ConsumerState<AuthTestScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  
  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isAuthenticated = ref.watch(isAuthenticatedProvider);
    final authActions = ref.read(authActionsProvider);
    final isLoading = ref.watch(authLoadingProvider);
    final error = ref.watch(authErrorProvider);
    final currentProfile = ref.watch(currentUserProfileProvider);
    
    return SwirlBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text(
            'Auth Test',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: Padding(
          padding: const EdgeInsets.all(20),
          child: isAuthenticated 
              ? _buildAuthenticatedView(currentProfile)
              : _buildSignInView(authActions, isLoading, error),
        ),
      ),
    );
  }
  
  Widget _buildSignInView(AuthActions authActions, bool isLoading, String? error) {
    return Column(
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Sign Up / Sign In',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),
                
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Full Name',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                
                TextField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Password',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                
                if (error != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      error,
                      style: TextStyle(color: Colors.red.shade700),
                    ),
                  ),
                
                const SizedBox(height: 16),
                
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: isLoading ? null : () => _signUp(authActions),
                        child: isLoading 
                            ? const CircularProgressIndicator()
                            : const Text('Sign Up'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: isLoading ? null : () => _signIn(authActions),
                        child: const Text('Sign In'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildAuthenticatedView(AsyncValue<dynamic> currentProfile) {
    return currentProfile.when(
      data: (profile) {
        if (profile == null) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text('Profile not found'),
            ),
          );
        }
        
        return Column(
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 30,
                          backgroundImage: profile.avatarUrl != null 
                              ? NetworkImage(profile.avatarUrl!)
                              : null,
                          child: profile.avatarUrl == null 
                              ? Text(
                                  profile.initials,
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                )
                              : null,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                profile.displayName,
                                style: GoogleFonts.poppins(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                '@${profile.username}',
                                style: GoogleFonts.poppins(
                                  color: Colors.grey[600],
                                ),
                              ),
                              if (profile.bio?.isNotEmpty == true)
                                Text(
                                  profile.bio!,
                                  style: GoogleFonts.poppins(fontSize: 14),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 16),
                    const Divider(),
                    
                    // Stats
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStat('Posts', profile.postsCount.toString()),
                        _buildStat('Followers', profile.followersCount.toString()),
                        _buildStat('Following', profile.followingCount.toString()),
                        _buildStat('Level', profile.level.toString()),
                      ],
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Travel Style
                    if (profile.travelVibes.isNotEmpty)
                      Wrap(
                        spacing: 8,
                        children: profile.travelVibes.map((vibe) => Chip(
                          label: Text(vibe),
                          backgroundColor: const Color(0xFF4CAF50).withOpacity(0.1),
                        )).toList(),
                      ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            ElevatedButton(
              onPressed: () => ref.read(authActionsProvider).signOut(),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Sign Out'),
            ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text('Error: $error'),
        ),
      ),
    );
  }
  
  Widget _buildStat(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }
  
  Future<void> _signUp(AuthActions authActions) async {
    final result = await authActions.signUp(
      email: _emailController.text.trim(),
      password: _passwordController.text,
      name: _nameController.text.trim(),
    );
    
    if (result.isSuccess) {
      _showSuccess('Account created successfully!');
    }
  }
  
  Future<void> _signIn(AuthActions authActions) async {
    final result = await authActions.signIn(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );
    
    if (result.isSuccess) {
      _showSuccess('Signed in successfully!');
    }
  }
  
  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }
} 