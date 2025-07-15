import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'traveler_profile_screen.dart';

class TravelersDiscoveryScreen extends StatefulWidget {
  const TravelersDiscoveryScreen({Key? key}) : super(key: key);

  @override
  State<TravelersDiscoveryScreen> createState() => _TravelersDiscoveryScreenState();
}

class _TravelersDiscoveryScreenState extends State<TravelersDiscoveryScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedFilter = 'All';
  String _selectedLocation = 'All Locations';
  bool _showFilters = false;

  final List<String> _filterOptions = [
    'All',
    'Adventure Seekers',
    'Culture Explorers',
    'Beach Lovers',
    'Solo Wanderers',
    'Food Enthusiasts',
    'Photography Lovers',
  ];

  final List<String> _locationOptions = [
    'All Locations',
    'Rotterdam',
    'Amsterdam',
    'Utrecht',
    'The Hague',
    'Nearby (5km)',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF2D3748)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Discover Travelers',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF2D3748),
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _showFilters ? Icons.filter_list : Icons.filter_list_outlined,
              color: _showFilters ? const Color(0xFF12B347) : const Color(0xFF718096),
            ),
            onPressed: () {
              setState(() {
                _showFilters = !_showFilters;
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search travelers by name or interests...',
                hintStyle: GoogleFonts.poppins(
                  color: const Color(0xFF9CA3AF),
                  fontSize: 14,
                ),
                prefixIcon: const Icon(
                  Icons.search,
                  color: Color(0xFF9CA3AF),
                ),
                filled: true,
                fillColor: const Color(0xFFF7FAFC),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              style: GoogleFonts.poppins(fontSize: 14),
              onChanged: (value) {
                setState(() {
                  // Trigger search
                });
              },
            ),
          ),

          // Filters Section
          if (_showFilters) _buildFiltersSection(),

          // Results Header
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Row(
              children: [
                Text(
                  '${_getFilteredTravelers().length} travelers found',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF2D3748),
                  ),
                ),
                const Spacer(),
                if (_selectedFilter != 'All' || _selectedLocation != 'All Locations')
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedFilter = 'All';
                        _selectedLocation = 'All Locations';
                        _searchController.clear();
                      });
                    },
                    child: Text(
                      'Clear filters',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: const Color(0xFF12B347),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Travelers Grid
          Expanded(
            child: _buildTravelersGrid(),
          ),
        ],
      ),
    );
  }

  Widget _buildFiltersSection() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Interest Filter
          Text(
            'Travel Style',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF2D3748),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _filterOptions.map((filter) {
              final isSelected = _selectedFilter == filter;
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedFilter = filter;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isSelected 
                        ? const Color(0xFF12B347) 
                        : const Color(0xFFF7FAFC),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected 
                          ? const Color(0xFF12B347) 
                          : const Color(0xFFE2E8F0),
                    ),
                  ),
                  child: Text(
                    filter,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? Colors.white : const Color(0xFF718096),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 16),

          // Location Filter
          Text(
            'Location',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF2D3748),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _locationOptions.map((location) {
              final isSelected = _selectedLocation == location;
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedLocation = location;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isSelected 
                        ? const Color(0xFF667eea) 
                        : const Color(0xFFF7FAFC),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected 
                          ? const Color(0xFF667eea) 
                          : const Color(0xFFE2E8F0),
                    ),
                  ),
                  child: Text(
                    location,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? Colors.white : const Color(0xFF718096),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildTravelersGrid() {
    final travelers = _getFilteredTravelers();
    
    if (travelers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.person_search,
              size: 64,
              color: const Color(0xFF9CA3AF),
            ),
            const SizedBox(height: 16),
            Text(
              'No travelers found',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF2D3748),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try adjusting your filters or search terms',
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: const Color(0xFF718096),
              ),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.8,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: travelers.length,
      itemBuilder: (context, index) {
        final traveler = travelers[index];
        return _buildTravelerCard(traveler);
      },
    );
  }

  Widget _buildTravelerCard(Map<String, dynamic> traveler) {
    return GestureDetector(
      onTap: () => _openTravelerProfile(traveler),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            // Profile Image and Online Status
            Expanded(
              flex: 3,
              child: Stack(
                children: [
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: _getTravelerColor(traveler['name']),
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(16),
                      ),
                    ),
                    child: Center(
                      child: Text(
                        traveler['name'][0].toUpperCase(),
                        style: GoogleFonts.poppins(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  
                  // Online status
                  if (traveler['isOnline'] == true)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: const Color(0xFF12B347),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                      ),
                    ),

                  // Mutual friends indicator
                  if (traveler['mutualFriends'] > 0)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '${traveler['mutualFriends']} mutual',
                          style: GoogleFonts.poppins(
                            fontSize: 8,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF2D3748),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Traveler Info
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Name and Age
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            traveler['name'],
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF2D3748),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          '${traveler['age']}',
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: const Color(0xFF718096),
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 2),
                    
                    // Travel Style
                    Text(
                      traveler['travelStyle'],
                      style: GoogleFonts.poppins(
                        fontSize: 10,
                        color: const Color(0xFF12B347),
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    
                    const SizedBox(height: 2),
                    
                    // Location
                    Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          size: 10,
                          color: const Color(0xFF718096),
                        ),
                        const SizedBox(width: 2),
                        Expanded(
                          child: Text(
                            traveler['location'],
                            style: GoogleFonts.poppins(
                              fontSize: 9,
                              color: const Color(0xFF718096),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    
                    const Spacer(),
                    
                    // Connect Button
                    SizedBox(
                      width: double.infinity,
                      height: 28,
                      child: ElevatedButton(
                        onPressed: () => _connectWithTraveler(traveler),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF12B347),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(6),
                          ),
                          elevation: 0,
                          padding: EdgeInsets.zero,
                        ),
                        child: Text(
                          'Connect',
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getTravelerColor(String name) {
    final colors = [
      const Color(0xFF12B347),
      const Color(0xFF667eea),
      const Color(0xFFFF6B6B),
      const Color(0xFF4ECDC4),
      const Color(0xFFFFE66D),
      const Color(0xFF8E2DE2),
    ];
    return colors[name.hashCode % colors.length];
  }

  List<Map<String, dynamic>> _getFilteredTravelers() {
    List<Map<String, dynamic>> travelers = _getAllTravelers();
    
    // Apply search filter
    if (_searchController.text.isNotEmpty) {
      final searchTerm = _searchController.text.toLowerCase();
      travelers = travelers.where((traveler) {
        return traveler['name'].toLowerCase().contains(searchTerm) ||
               traveler['travelStyle'].toLowerCase().contains(searchTerm) ||
               traveler['location'].toLowerCase().contains(searchTerm);
      }).toList();
    }
    
    // Apply travel style filter
    if (_selectedFilter != 'All') {
      travelers = travelers.where((traveler) {
        return traveler['travelStyle'] == _selectedFilter;
      }).toList();
    }
    
    // Apply location filter
    if (_selectedLocation != 'All Locations') {
      if (_selectedLocation == 'Nearby (5km)') {
        travelers = travelers.where((traveler) {
          return traveler['distance'] <= 5.0;
        }).toList();
      } else {
        travelers = travelers.where((traveler) {
          return traveler['location'].contains(_selectedLocation);
        }).toList();
      }
    }
    
    return travelers;
  }

  List<Map<String, dynamic>> _getAllTravelers() {
    return [
      {
        'name': 'Sarah',
        'age': 28,
        'travelStyle': 'Adventure Seekers',
        'location': 'Rotterdam, Netherlands',
        'distance': 2.1,
        'isOnline': true,
        'mutualFriends': 3,
        'bio': 'Love hiking and exploring hidden gems',
      },
      {
        'name': 'Marco',
        'age': 32,
        'travelStyle': 'Culture Explorers',
        'location': 'Amsterdam, Netherlands',
        'distance': 15.3,
        'isOnline': false,
        'mutualFriends': 1,
        'bio': 'Museum enthusiast and history lover',
      },
      {
        'name': 'Luna',
        'age': 26,
        'travelStyle': 'Beach Lovers',
        'location': 'The Hague, Netherlands',
        'distance': 8.7,
        'isOnline': true,
        'mutualFriends': 0,
        'bio': 'Coastal adventures and sunset chaser',
      },
      {
        'name': 'Alex',
        'age': 29,
        'travelStyle': 'Solo Wanderers',
        'location': 'Utrecht, Netherlands',
        'distance': 12.4,
        'isOnline': true,
        'mutualFriends': 2,
        'bio': 'Digital nomad exploring Europe',
      },
      {
        'name': 'Emma',
        'age': 24,
        'travelStyle': 'Food Enthusiasts',
        'location': 'Rotterdam, Netherlands',
        'distance': 1.8,
        'isOnline': false,
        'mutualFriends': 0,
        'bio': 'Foodie seeking culinary adventures',
      },
      {
        'name': 'David',
        'age': 35,
        'travelStyle': 'Photography Lovers',
        'location': 'Amsterdam, Netherlands',
        'distance': 16.1,
        'isOnline': true,
        'mutualFriends': 1,
        'bio': 'Capturing beautiful moments worldwide',
      },
      {
        'name': 'Sophie',
        'age': 27,
        'travelStyle': 'Adventure Seekers',
        'location': 'Rotterdam, Netherlands',
        'distance': 3.2,
        'isOnline': true,
        'mutualFriends': 4,
        'bio': 'Rock climbing and extreme sports',
      },
      {
        'name': 'Tom',
        'age': 31,
        'travelStyle': 'Culture Explorers',
        'location': 'Utrecht, Netherlands',
        'distance': 11.8,
        'isOnline': false,
        'mutualFriends': 0,
        'bio': 'Art galleries and local traditions',
      },
      {
        'name': 'Maya',
        'age': 25,
        'travelStyle': 'Beach Lovers',
        'location': 'The Hague, Netherlands',
        'distance': 9.1,
        'isOnline': true,
        'mutualFriends': 1,
        'bio': 'Surfing and beach volleyball',
      },
      {
        'name': 'Jake',
        'age': 30,
        'travelStyle': 'Solo Wanderers',
        'location': 'Rotterdam, Netherlands',
        'distance': 4.5,
        'isOnline': false,
        'mutualFriends': 2,
        'bio': 'Backpacking through Europe solo',
      },
    ];
  }

  void _connectWithTraveler(Map<String, dynamic> traveler) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Connect with ${traveler['name']}?',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              traveler['bio'],
              style: GoogleFonts.poppins(fontSize: 14),
            ),
            const SizedBox(height: 12),
            if (traveler['mutualFriends'] > 0)
              Text(
                'You have ${traveler['mutualFriends']} mutual friend${traveler['mutualFriends'] > 1 ? 's' : ''}',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: const Color(0xFF12B347),
                  fontWeight: FontWeight.w600,
                ),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Connection request sent to ${traveler['name']}!'),
                  backgroundColor: const Color(0xFF12B347),
                  behavior: SnackBarBehavior.floating,
                  action: SnackBarAction(
                    label: 'View Profile',
                    textColor: Colors.white,
                    onPressed: () => _openTravelerProfile(traveler),
                  ),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF12B347),
            ),
            child: Text('Send Request'),
          ),
        ],
      ),
    );
  }

  void _openTravelerProfile(Map<String, dynamic> traveler) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TravelerProfileScreen(traveler: traveler),
      ),
    );
  }
} 