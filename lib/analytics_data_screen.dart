import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class AnalyticsDataScreen extends StatefulWidget {
  const AnalyticsDataScreen({super.key});

  @override
  State<AnalyticsDataScreen> createState() => _AnalyticsDataScreenState();
}

class _AnalyticsDataScreenState extends State<AnalyticsDataScreen>
    with SingleTickerProviderStateMixin {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late TabController _tabController;

  // Data storage for each section
  List<Map<String, dynamic>> _mostClickedProperties = [];
  List<Map<String, dynamic>> _clickTrends = [];
  List<Map<String, dynamic>> _propertyTypePerformance = [];
  List<Map<String, dynamic>> _hourlyPatterns = [];
  List<Map<String, dynamic>> _userEngagement = [];
  List<Map<String, dynamic>> _conversionFunnel = [];
  List<Map<String, dynamic>> _deviceAnalytics = [];

  bool _isLoading = true;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 7, vsync: this);
    _loadAllData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAllData() async {
    setState(() {
      _isLoading = true;
      _error = '';
    });

    try {
      await Future.wait([
        _loadMostClickedProperties(),
        _loadClickTrends(),
        _loadPropertyTypePerformance(),
        _loadHourlyPatterns(),
        _loadUserEngagement(),
        _loadConversionFunnel(),
        _loadDeviceAnalytics(),
      ]);
    } catch (e) {
      setState(() {
        _error = 'Failed to load analytics data: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // 1. Most Clicked Properties
  Future<void> _loadMostClickedProperties() async {
    try {
      final response = await _firestore
          .collection('property_clicks')
          .where('is_developer', isEqualTo: false)
          .orderBy('created_at', descending: true)
          .limit(10)
          .get();

      _mostClickedProperties = response.docs.map((doc) => {
        'id': doc.id,
        ...doc.data(),
      }).toList();
    } catch (e) {
      print('Error loading most clicked properties: $e');
      _mostClickedProperties = [];
    }
  }

  // 2. Click Trends (7 days)
  Future<void> _loadClickTrends() async {
    try {
      final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));
      final response = await _firestore
          .collection('property_clicks')
          .where('created_at', isGreaterThanOrEqualTo: Timestamp.fromDate(sevenDaysAgo))
          .orderBy('created_at')
          .get();

      _clickTrends = response.docs.map((doc) => {
        'id': doc.id,
        ...doc.data(),
      }).toList();
    } catch (e) {
      print('Error loading click trends: $e');
      _clickTrends = [];
    }
  }

  // 3. Property Type Performance
  Future<void> _loadPropertyTypePerformance() async {
    try {
      final response = await _firestore
          .collection('properties')
          .get();

      _propertyTypePerformance = response.docs.map((doc) => {
        'id': doc.id,
        ...doc.data(),
      }).toList();
    } catch (e) {
      print('Error loading property type performance: $e');
      _propertyTypePerformance = [];
    }
  }

  // 4. Hourly Click Patterns
  Future<void> _loadHourlyPatterns() async {
    try {
      final response = await _firestore
          .collection('property_clicks')
          .orderBy('created_at', descending: true)
          .limit(100)
          .get();

      _hourlyPatterns = response.docs.map((doc) => {
        'id': doc.id,
        ...doc.data(),
      }).toList();
    } catch (e) {
      print('Error loading hourly patterns: $e');
      _hourlyPatterns = [];
    }
  }

  // 5. User Engagement
  Future<void> _loadUserEngagement() async {
    try {
      final response = await _firestore
          .collection('property_clicks')
          .orderBy('created_at', descending: true)
          .limit(50)
          .get();

      _userEngagement = response.docs.map((doc) => {
        'id': doc.id,
        ...doc.data(),
      }).toList();
    } catch (e) {
      print('Error loading user engagement: $e');
      _userEngagement = [];
    }
  }

  // 6. Conversion Funnel
  Future<void> _loadConversionFunnel() async {
    try {
      final response = await _firestore
          .collection('property_clicks')
          .where('click_type', whereIn: ['view', 'phone', 'whatsapp'])
          .orderBy('created_at', descending: true)
          .get();

      _conversionFunnel = response.docs.map((doc) => {
        'id': doc.id,
        ...doc.data(),
      }).toList();
    } catch (e) {
      print('Error loading conversion funnel: $e');
      _conversionFunnel = [];
    }
  }

  // 7. Device Analytics
  Future<void> _loadDeviceAnalytics() async {
    try {
      final response = await _firestore
          .collection('property_clicks')
          .orderBy('created_at', descending: true)
          .limit(100)
          .get();

      _deviceAnalytics = response.docs.map((doc) => {
        'id': doc.id,
        ...doc.data(),
      }).toList();
    } catch (e) {
      print('Error loading device analytics: $e');
      _deviceAnalytics = [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Property Analytics'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAllData,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Top Properties'),
            Tab(text: 'Daily Trends'),
            Tab(text: 'Property Types'),
            Tab(text: 'Hourly Patterns'),
            Tab(text: 'User Engagement'),
            Tab(text: 'Conversions'),
            Tab(text: 'Devices'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error.isNotEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error, size: 64, color: Colors.red[300]),
                      const SizedBox(height: 16),
                      Text(_error, style: const TextStyle(fontSize: 16)),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadAllData,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildMostClickedPropertiesTab(),
                    _buildClickTrendsTab(),
                    _buildPropertyTypePerformanceTab(),
                    _buildHourlyPatternsTab(),
                    _buildUserEngagementTab(),
                    _buildConversionFunnelTab(),
                    _buildDeviceAnalyticsTab(),
                  ],
                ),
    );
  }

  // Tab 1: Most Clicked Properties
  Widget _buildMostClickedPropertiesTab() {
    return ListView.builder(
      itemCount: _mostClickedProperties.length,
      itemBuilder: (context, index) {
        final property = _mostClickedProperties[index];
        return Padding(
          padding: const EdgeInsets.all(8.0),
          child: Card(
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.white,
                child: Text('${index + 1}'),
              ),
              title: Text(
                property['title'] ?? 'No Title',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(property['location'] ?? 'No Location'),
                  Text('Price: ₹${property['price'] ?? 'N/A'}'),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      _buildStatChip(
                          '👀 ${property['total_clicks']}', Colors.blue),
                      const SizedBox(width: 8),
                      _buildStatChip(
                          '👥 ${property['unique_users']}', Colors.green),
                      const SizedBox(width: 8),
                      _buildStatChip(
                          '📞 ${property['phone_clicks']}', Colors.orange),
                    ],
                  ),
                ],
              ),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('💬 ${property['whatsapp_clicks']}'),
                  Text('🗺️ ${property['map_clicks']}'),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // Tab 2: Click Trends
  Widget _buildClickTrendsTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _clickTrends.length,
      itemBuilder: (context, index) {
        final trend = _clickTrends[index];
        final date = DateTime.parse(trend['click_date']);
        final formattedDate = DateFormat('MMM dd, yyyy').format(date);

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  formattedDate,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildTrendStat('Total Clicks', '${trend['total_clicks']}',
                        Icons.touch_app),
                    _buildTrendStat('Unique Users', '${trend['unique_users']}',
                        Icons.people),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildTrendStat(
                        'Views', '${trend['view_clicks']}', Icons.visibility),
                    _buildTrendStat(
                        'Phone', '${trend['phone_clicks']}', Icons.phone),
                    _buildTrendStat('WhatsApp', '${trend['whatsapp_clicks']}',
                        Icons.message),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Tab 3: Property Type Performance
  Widget _buildPropertyTypePerformanceTab() {
    return ListView.builder(
      itemCount: _propertyTypePerformance.length,
      itemBuilder: (context, index) {
        final typeData = _propertyTypePerformance[index];
        final avgClicks = double.tryParse(
                typeData['avg_clicks_per_property']?.toString() ?? '0') ??
            0;

        return Padding(
          padding: const EdgeInsets.all(8.0),
          child: Card(
            child: ListTile(
              leading: const Icon(Icons.home, size: 40),
              title: Text(
                typeData['property_type'] ?? 'Unknown Type',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Properties: ${typeData['total_properties']}'),
                  Text('Avg Clicks: ${avgClicks.toStringAsFixed(1)}'),
                  Text('Total Clicks: ${typeData['total_clicks']}'),
                  Text('Total Users: ${typeData['total_unique_users']}'),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // Tab 4: Hourly Patterns
  Widget _buildHourlyPatternsTab() {
    return ListView.builder(
      itemCount: _hourlyPatterns.length,
      itemBuilder: (context, index) {
        final hourData = _hourlyPatterns[index];
        final hour =
            int.tryParse(hourData['hour_of_day']?.toString() ?? '0') ?? 0;
        final timeString =
            '${hour.toString().padLeft(2, '0')}:00 - ${(hour + 1).toString().padLeft(2, '0')}:00';

        return Padding(
          padding: const EdgeInsets.all(8.0),
          child: Card(
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: _getHourColor(hour),
                child: Text('${hour}h'),
              ),
              title: Text(timeString),
              subtitle: Row(
                children: [
                  Text('Clicks: ${hourData['total_clicks']}'),
                  const SizedBox(width: 16),
                  Text('Users: ${hourData['unique_users']}'),
                ],
              ),
              trailing: _buildClickIntensityBar(
                  int.tryParse(hourData['total_clicks']?.toString() ?? '0') ??
                      0),
            ),
          ),
        );
      },
    );
  }

  // Tab 5: User Engagement
  Widget _buildUserEngagementTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _userEngagement.length,
      itemBuilder: (context, index) {
        final user = _userEngagement[index];
        final fingerprint = user['user_fingerprint'] ?? '';
        final shortFingerprint =
            fingerprint.length > 8 ? fingerprint.substring(0, 8) : fingerprint;

        return Padding(
          padding: const EdgeInsets.all(8.0),
          child: Card(
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.purple,
                foregroundColor: Colors.white,
                child: Text('#${index + 1}'),
              ),
              title: Text('User: ...$shortFingerprint'),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Properties Viewed: ${user['properties_viewed']}'),
                  Text('Total Clicks: ${user['total_clicks']}'),
                  Text('First Visit: ${_formatDateTime(user['first_visit'])}'),
                  Text('Last Visit: ${_formatDateTime(user['last_visit'])}'),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // Tab 6: Conversion Funnel
  Widget _buildConversionFunnelTab() {
    return ListView.builder(
      itemCount: _conversionFunnel.length,
      itemBuilder: (context, index) {
        final property = _conversionFunnel[index];
        final conversionRate = double.tryParse(
                property['conversion_rate_percent']?.toString() ?? '0') ??
            0;

        return Padding(
          padding: const EdgeInsets.all(8.0),
          child: Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  property['title'] ?? 'No Title',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildConversionStat(
                        'Views', '${property['views']}', Icons.visibility),
                    _buildConversionStat(
                        'Phone', '${property['phone_calls']}', Icons.phone),
                    _buildConversionStat('WhatsApp',
                        '${property['whatsapp_clicks']}', Icons.message),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Text('Conversion Rate: ',
                        style: TextStyle(fontWeight: FontWeight.w500)),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getConversionRateColor(conversionRate),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${conversionRate.toStringAsFixed(1)}%',
                        style: const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Tab 7: Device Analytics
  Widget _buildDeviceAnalyticsTab() {
    return ListView.builder(
      itemCount: _deviceAnalytics.length,
      itemBuilder: (context, index) {
        final device = _deviceAnalytics[index];

        return Padding(
          padding: const EdgeInsets.all(8.0),
          child: Card(
            child: ListTile(
              leading: _getDeviceIcon(device['device_type'] ?? ''),
              title:
                  Text('${device['device_type']} - ${device['browser_name']}'),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Total Clicks: ${device['total_clicks']}'),
                  Text('Unique Users: ${device['unique_users']}'),
                  Text('Properties Clicked: ${device['properties_clicked']}'),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // Helper Widgets
  Widget _buildStatChip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        text,
        style:
            TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w500),
      ),
    );
  }

  Widget _buildTrendStat(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 24, color: Theme.of(context).primaryColor),
        const SizedBox(height: 4),
        Text(value,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  Widget _buildConversionStat(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 20),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  Widget _buildClickIntensityBar(int clicks) {
    final maxClicks = _hourlyPatterns.isNotEmpty
        ? _hourlyPatterns
            .map((h) => int.tryParse(h['total_clicks']?.toString() ?? '0') ?? 0)
            .reduce((a, b) => a > b ? a : b)
        : 100;
    final intensity = clicks / maxClicks;

    return Container(
      width: 60,
      height: 8,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        color: Colors.grey[200],
      ),
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: intensity,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            color: Theme.of(context).primaryColor,
          ),
        ),
      ),
    );
  }

  // Helper Methods
  Color _getHourColor(int hour) {
    if (hour >= 6 && hour < 12) return Colors.orange; // Morning
    if (hour >= 12 && hour < 18) return Colors.blue; // Afternoon
    if (hour >= 18 && hour < 22) return Colors.green; // Evening
    return Colors.purple; // Night
  }

  Color _getConversionRateColor(double rate) {
    if (rate >= 15) return Colors.green;
    if (rate >= 10) return Colors.orange;
    return Colors.red;
  }

  Icon _getDeviceIcon(String deviceType) {
    switch (deviceType.toLowerCase()) {
      case 'mobile':
        return const Icon(Icons.phone_android, color: Colors.green);
      case 'tablet':
        return const Icon(Icons.tablet, color: Colors.blue);
      case 'desktop':
        return const Icon(Icons.desktop_windows, color: Colors.purple);
      default:
        return const Icon(Icons.device_unknown, color: Colors.grey);
    }
  }

  String _formatDateTime(String? dateTimeStr) {
    if (dateTimeStr == null) return 'N/A';
    try {
      final dateTime = DateTime.parse(dateTimeStr);
      return DateFormat('MMM dd, HH:mm').format(dateTime);
    } catch (e) {
      return 'Invalid Date';
    }
  }
}
