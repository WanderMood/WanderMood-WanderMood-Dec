import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wandermood/core/presentation/widgets/swirl_background.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

class MoodHistoryScreen extends ConsumerStatefulWidget {
  const MoodHistoryScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<MoodHistoryScreen> createState() => _MoodHistoryScreenState();
}

class _MoodHistoryScreenState extends ConsumerState<MoodHistoryScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<String> _tabLabels = ['Weekly', 'Monthly', 'All'];
  
  // Sample mood data for demonstration
  final List<Map<String, dynamic>> _moodData = [
    {
      'date': DateTime.now().subtract(const Duration(days: 0)),
      'mood': 'Happy',
      'notes': 'Had a great day exploring Golden Gate Park!',
      'value': 4.5,
      'emoji': '😊',
    },
    {
      'date': DateTime.now().subtract(const Duration(days: 1)),
      'mood': 'Relaxed',
      'notes': 'Spent the morning at a café reading.',
      'value': 4.0,
      'emoji': '😌',
    },
    {
      'date': DateTime.now().subtract(const Duration(days: 2)),
      'mood': 'Energetic',
      'notes': 'Went hiking in the morning, felt great!',
      'value': 4.8,
      'emoji': '🤩',
    },
    {
      'date': DateTime.now().subtract(const Duration(days: 3)),
      'mood': 'Tired',
      'notes': 'Long day at work, need rest.',
      'value': 2.5,
      'emoji': '😓',
    },
    {
      'date': DateTime.now().subtract(const Duration(days: 4)),
      'mood': 'Average',
      'notes': 'Nothing special today.',
      'value': 3.0,
      'emoji': '😐',
    },
    {
      'date': DateTime.now().subtract(const Duration(days: 5)),
      'mood': 'Excited',
      'notes': 'Planning a weekend trip!',
      'value': 4.7,
      'emoji': '😃',
    },
    {
      'date': DateTime.now().subtract(const Duration(days: 6)),
      'mood': 'Calm',
      'notes': 'Peaceful day at home.',
      'value': 3.8,
      'emoji': '😌',
    },
    {
      'date': DateTime.now().subtract(const Duration(days: 7)),
      'mood': 'Stressed',
      'notes': 'Busy workday, lots of meetings.',
      'value': 2.0,
      'emoji': '😩',
    },
    {
      'date': DateTime.now().subtract(const Duration(days: 8)),
      'mood': 'Happy',
      'notes': 'Met friends for dinner.',
      'value': 4.3,
      'emoji': '😊',
    },
    {
      'date': DateTime.now().subtract(const Duration(days: 9)),
      'mood': 'Curious',
      'notes': 'Visited a new museum.',
      'value': 4.0,
      'emoji': '🧐',
    },
    {
      'date': DateTime.now().subtract(const Duration(days: 10)),
      'mood': 'Relaxed',
      'notes': 'Day off, just relaxing.',
      'value': 3.9,
      'emoji': '😌',
    },
  ];
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabLabels.length, vsync: this);
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SwirlBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Text(
            'Mood History',
            style: GoogleFonts.museoModerno(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF12B347),
            ),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => Navigator.pop(context),
          ),
          bottom: TabBar(
            controller: _tabController,
            labelColor: const Color(0xFF12B347),
            unselectedLabelColor: Colors.black54,
            indicatorColor: const Color(0xFF12B347),
            tabs: _tabLabels.map((label) => Tab(text: label)).toList(),
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildWeeklyView(),
            _buildMonthlyView(),
            _buildAllTimeView(),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          backgroundColor: const Color(0xFF12B347),
          child: const Icon(Icons.add),
          onPressed: () {
            // Add new mood entry
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Add new mood entry'),
                behavior: SnackBarBehavior.floating,
              ),
            );
          },
        ),
      ),
    );
  }
  
  // Build the weekly mood view with graph and list
  Widget _buildWeeklyView() {
    // Filter to only show the last 7 days
    final weeklyData = _moodData.where((entry) {
      final today = DateTime.now();
      final entryDate = entry['date'] as DateTime;
      final difference = today.difference(entryDate).inDays;
      return difference < 7;
    }).toList();
    
    return _buildMoodView(weeklyData, true);
  }
  
  // Build the monthly mood view
  Widget _buildMonthlyView() {
    // Filter to only show the last 30 days
    final monthlyData = _moodData.where((entry) {
      final today = DateTime.now();
      final entryDate = entry['date'] as DateTime;
      final difference = today.difference(entryDate).inDays;
      return difference < 30;
    }).toList();
    
    return _buildMoodView(monthlyData, false);
  }
  
  // Build the all-time mood view
  Widget _buildAllTimeView() {
    return _buildMoodView(_moodData, false);
  }
  
  // Common builder for mood views
  Widget _buildMoodView(List<Map<String, dynamic>> data, bool showDetailedGraph) {
    return SafeArea(
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Mood graph
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 220,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Mood Trend',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Expanded(
                          child: _buildMoodGraph(data, showDetailedGraph),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  Text(
                    'Mood Entries',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Mood entries list
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final entry = data[index];
                return _buildMoodEntryCard(entry);
              },
              childCount: data.length,
            ),
          ),
          
          // Bottom padding
          const SliverToBoxAdapter(
            child: SizedBox(height: 80),
          ),
        ],
      ),
    );
  }
  
  // Build mood graph
  Widget _buildMoodGraph(List<Map<String, dynamic>> data, bool showDetailedLabels) {
    // Sort data by date
    final sortedData = List.from(data)
      ..sort((a, b) => (a['date'] as DateTime).compareTo(b['date'] as DateTime));
    
    // Create line chart data
    final spots = sortedData.map((entry) {
      final date = entry['date'] as DateTime;
      final value = entry['value'] as double;
      
      // Use days from today as x-axis
      final daysFromToday = DateTime.now().difference(date).inDays.toDouble();
      return FlSpot(daysFromToday, value);
    }).toList();
    
    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: true,
          getDrawingHorizontalLine: (value) => FlLine(
            color: Colors.grey.shade200,
            strokeWidth: 1,
          ),
          getDrawingVerticalLine: (value) => FlLine(
            color: Colors.grey.shade200,
            strokeWidth: 1,
          ),
        ),
        titlesData: FlTitlesData(
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              getTitlesWidget: (value, meta) {
                if (value % 1 != 0) return const Text('');
                
                final days = value.toInt();
                if (showDetailedLabels) {
                  // For weekly view, show each day
                  if (days < 7) {
                    final date = DateTime.now().subtract(Duration(days: days));
                    return Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        DateFormat('E').format(date),
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          color: Colors.grey[600],
                        ),
                      ),
                    );
                  }
                } else {
                  // For monthly view, show less labels
                  if (days % 5 == 0 && days < 30) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        '$days days ago',
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          color: Colors.grey[600],
                        ),
                      ),
                    );
                  }
                }
                return const Text('');
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 25,
              getTitlesWidget: (value, meta) {
                if (value == 1) return const Text('Low');
                if (value == 3) return const Text('Mid');
                if (value == 5) return const Text('High');
                return const Text('');
              },
            ),
          ),
        ),
        borderData: FlBorderData(
          show: false,
        ),
        minX: 0,
        maxX: showDetailedLabels ? 6 : 30,
        minY: 1,
        maxY: 5,
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: const Color(0xFF12B347),
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) {
                return FlDotCirclePainter(
                  radius: 5,
                  color: const Color(0xFF12B347),
                  strokeColor: Colors.white,
                  strokeWidth: 2,
                );
              },
            ),
            belowBarData: BarAreaData(
              show: true,
              color: const Color(0xFF12B347).withOpacity(0.1),
            ),
          ),
        ],
      ),
    );
  }
  
  // Build mood entry card
  Widget _buildMoodEntryCard(Map<String, dynamic> entry) {
    final date = entry['date'] as DateTime;
    final mood = entry['mood'] as String;
    final notes = entry['notes'] as String;
    final emoji = entry['emoji'] as String;
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: 1,
      child: InkWell(
        onTap: () {
          // View detailed mood entry
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              // Date column
              Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    DateFormat('dd').format(date),
                    style: GoogleFonts.poppins(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF12B347),
                    ),
                  ),
                  Text(
                    DateFormat('MMM').format(date),
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              
              // Separator
              Container(
                width: 1,
                height: 50,
                margin: const EdgeInsets.symmetric(horizontal: 16),
                color: Colors.grey[300],
              ),
              
              // Mood info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          emoji,
                          style: const TextStyle(
                            fontSize: 24,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          mood,
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          DateFormat('h:mm a').format(date),
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notes,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.grey[800],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 