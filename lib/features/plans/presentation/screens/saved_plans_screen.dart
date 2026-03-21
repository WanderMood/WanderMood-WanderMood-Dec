import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:wandermood/features/plans/domain/models/activity.dart';
import 'package:wandermood/core/services/plan_storage_service.dart';

class SavedPlansScreen extends StatelessWidget {
  const SavedPlansScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Saved Plans',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: PlanStorageService().getSavedPlans(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error loading saved plans',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
            );
          }

          final plans = snapshot.data ?? [];

          if (plans.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.bookmark_border,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No saved plans yet',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[800],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Your saved plans will appear here',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pushReplacementNamed('/home');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2A6049),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Create New Plan',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: plans.length,
            itemBuilder: (context, index) {
              final plan = plans[index];
              return _buildPlanCard(context, plan);
            },
          );
        },
      ),
    );
  }

  Widget _buildPlanCard(BuildContext context, Map<String, dynamic> plan) {
    final activities = (plan['activities'] as List).cast<Activity>();
    final date = DateTime.parse(plan['date']);
    final formattedDate = '${date.day}/${date.month}/${date.year}';

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey[200]!),
      ),
      child: InkWell(
        onTap: () {
          // Navigate to plan details
          Navigator.of(context).pushNamed(
            '/plan-details',
            arguments: plan,
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      plan['name'] ?? 'Unnamed Plan',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Text(
                    formattedDate,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '${activities.length} Activities',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.schedule,
                    size: 16,
                    color: Colors.grey[600],
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${activities.first.startTime.hour}:${activities.first.startTime.minute.toString().padLeft(2, '0')} - ${activities.last.startTime.hour}:${activities.last.startTime.minute.toString().padLeft(2, '0')}',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () {
                      // Navigate to booking screen
                      Navigator.of(context).pushNamed(
                        '/plan-booking',
                        arguments: plan,
                      );
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFF2A6049),
                      padding: EdgeInsets.zero,
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      'Book Now',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
} 