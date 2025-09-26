import 'package:flutter/material.dart';
import '../models/location.dart';
import '../services/location_service.dart';
import 'location_registration_screen.dart';

class LocationListScreen extends StatefulWidget {
  const LocationListScreen({Key? key}) : super(key: key);

  @override
  State<LocationListScreen> createState() => _LocationListScreenState();
}

class _LocationListScreenState extends State<LocationListScreen> {
  final _locationService = LocationService();
  List<Location> _locations = [];
  Location? _currentLocation;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeLocationService();
  }

  Future<void> _initializeLocationService() async {
    await _locationService.initialize();
    
    // 위치 변경 콜백 설정
    _locationService.onLocationChanged = (location) {
      setState(() {
        _currentLocation = location;
      });
    };
    
    await _loadLocations();
  }

  Future<void> _loadLocations() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final locations = _locationService.savedLocations;
      final currentLocation = _locationService.currentLocation;
      
      setState(() {
        _locations = locations;
        _currentLocation = currentLocation;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('위치 목록을 불러오는 중 오류가 발생했습니다: $e')),
      );
    }
  }

  Future<void> _navigateToRegistration({Location? locationToEdit}) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => LocationRegistrationScreen(locationToEdit: locationToEdit),
      ),
    );

    if (result == true) {
      await _loadLocations();
    }
  }

  Future<void> _deleteLocation(Location location) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('위치 삭제'),
        content: Text('${location.name} 위치를 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('삭제'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _locationService.deleteLocation(location.id);
        await _loadLocations();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('위치가 삭제되었습니다.')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('삭제 중 오류가 발생했습니다: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _locationService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('위치 관리'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadLocations,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _locations.isEmpty
              ? _buildEmptyState()
              : _buildLocationList(),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToRegistration(),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.location_off,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            '등록된 위치가 없습니다',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '위치를 등록하면 해당 위치에서\n할일 알림을 받을 수 있습니다',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _navigateToRegistration(),
            icon: const Icon(Icons.add_location),
            label: const Text('위치 등록하기'),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationList() {
    return Column(
      children: [
        if (_currentLocation != null) _buildCurrentLocationCard(),
        Expanded(
          child: ListView.builder(
            itemCount: _locations.length,
            itemBuilder: (context, index) {
              final location = _locations[index];
              final isCurrentLocation = _currentLocation?.id == location.id;
              
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: isCurrentLocation ? Colors.green : Colors.blue,
                    child: Icon(
                      isCurrentLocation ? Icons.location_on : Icons.location_off,
                      color: Colors.white,
                    ),
                  ),
                  title: Text(
                    location.name,
                    style: TextStyle(
                      fontWeight: isCurrentLocation ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('WiFi: ${location.wifiSSID}'),
                      if (location.wifiBSSID != null)
                        Text('BSSID: ${location.wifiBSSID}'),
                      if (isCurrentLocation)
                        const Text(
                          '현재 위치',
                          style: TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                    ],
                  ),
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) {
                      switch (value) {
                        case 'edit':
                          _navigateToRegistration(locationToEdit: location);
                          break;
                        case 'delete':
                          _deleteLocation(location);
                          break;
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: ListTile(
                          leading: Icon(Icons.edit),
                          title: Text('수정'),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: ListTile(
                          leading: Icon(Icons.delete, color: Colors.red),
                          title: Text('삭제', style: TextStyle(color: Colors.red)),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCurrentLocationCard() {
    return Card(
      margin: const EdgeInsets.all(16),
      color: Colors.green[50],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              Icons.location_on,
              color: Colors.green[700],
              size: 32,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '현재 위치',
                    style: TextStyle(
                      color: Colors.green[700],
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    _currentLocation!.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'WiFi: ${_currentLocation!.wifiSSID}',
                    style: TextStyle(
                      color: Colors.green[600],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}









