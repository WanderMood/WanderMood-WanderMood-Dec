import '../../../performance/performance_demo.dart';

class HomeScreen extends StatefulWidget {
  // ... (existing code)
}

class _HomeScreenState extends State<HomeScreen> {
  // ... (existing code)

  Widget _buildQuickActions() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick Actions',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _ActionCard(
                  icon: Icons.add,
                  title: 'Add Entry',
                  subtitle: 'Capture the moment',
                  onTap: () => context.push('/diary/create'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ActionCard(
                  icon: Icons.explore,
                  title: 'Explore',
                  subtitle: 'Find new places',
                  onTap: () => context.push('/explore'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _ActionCard(
                  icon: Icons.analytics,
                  title: 'Insights',
                  subtitle: 'Your travel stats',
                  onTap: () => context.push('/insights'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ActionCard(
                  icon: Icons.speed,
                  title: 'Performance',
                  subtitle: 'Test optimizations',
                  onTap: () async {
                    // Run performance demo
                    await PerformanceDemo.runDemo();
                    PerformanceDemo.showPerformanceStats();
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _ActionCard(
                  icon: Icons.dashboard,
                  title: '🚀 Advanced Performance',
                  subtitle: 'Real-time analytics',
                  onTap: () => context.push('/advanced-performance'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ActionCard(
                  icon: Icons.rocket_launch,
                  title: '⚡ Ultimate Performance',
                  subtitle: 'Phase 4C Enterprise',
                  onTap: () => context.push('/ultimate-performance'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ... (rest of the existing code)
} 