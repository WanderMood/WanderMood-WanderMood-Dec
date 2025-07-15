import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'core/router/router.dart';
import 'features/recommendations/presentation/pages/recommendations_page.dart';
import 'features/mood/presentation/pages/mood_page.dart';
import 'features/weather/presentation/pages/weather_page.dart';
import 'features/auth/application/auth_service.dart';
import 'core/constants/supabase_constants.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Try to load environment variables, but don't fail if .env doesn't exist
    try {
    await dotenv.load(fileName: ".env");
    } catch (e) {
      debugPrint('No .env file found, using hardcoded constants: $e');
    }

    // Get Supabase credentials with fallback to constants
    final supabaseUrl = dotenv.env['SUPABASE_URL']?.isNotEmpty == true 
        ? dotenv.env['SUPABASE_URL']! 
        : SupabaseConstants.supabaseUrl;
    final supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY']?.isNotEmpty == true 
        ? dotenv.env['SUPABASE_ANON_KEY']! 
        : SupabaseConstants.supabaseAnonKey;

    debugPrint('🔧 Full Supabase URL: $supabaseUrl');
    debugPrint('🔧 Supabase Key: ${supabaseAnonKey.substring(0, 20)}...');

    // Initialize Supabase with updated configuration
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
      debug: true,
      authOptions: const FlutterAuthClientOptions(
        authFlowType: AuthFlowType.pkce,
      ),
    );

    // Verify the client is using the correct URL
    debugPrint('🔧 Supabase client URL after init: ${Supabase.instance.client.supabaseUrl}');

    // Ensure demo account exists
    final authService = AuthService();
    await authService.ensureDemoAccount();

    runApp(
      const ProviderScope(
        child: WanderMoodApp(),
      ),
    );
  } catch (e) {
    debugPrint('Error initializing app: $e');
    runApp(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: Text('Error initializing app: $e'),
          ),
        ),
      ),
    );
  }
}

class WanderMoodApp extends ConsumerWidget {
  const WanderMoodApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    
    return MaterialApp.router(
      title: 'WanderMood',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      routerConfig: router,
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const RecommendationsPage(),
    const MoodPage(),
    const WeatherPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.travel_explore),
            label: 'Aanbevelingen',
          ),
          NavigationDestination(
            icon: Icon(Icons.mood),
            label: 'Mood',
          ),
          NavigationDestination(
            icon: Icon(Icons.wb_sunny),
            label: 'Weer',
          ),
        ],
      ),
    );
  }
}
