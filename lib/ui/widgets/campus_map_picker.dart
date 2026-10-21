import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../core/constants/app_theme.dart';
import '../../core/constants/campus_locations.dart';

class SelectedLocationResult {
  final double latitude;
  final double longitude;
  final String locationId;
  final String locationName;
  final String specificDetails;
  final bool isWithinCampus;

  const SelectedLocationResult({
    required this.latitude,
    required this.longitude,
    required this.locationId,
    required this.locationName,
    required this.specificDetails,
    required this.isWithinCampus,
  });
}

class CampusMapPickerDialog extends StatefulWidget {
  final double initialLat;
  final double initialLng;
  final String? initialLocationId;
  final String? initialDetails;

  const CampusMapPickerDialog({
    super.key,
    this.initialLat = CampusConstants.defaultLatitude,
    this.initialLng = CampusConstants.defaultLongitude,
    this.initialLocationId,
    this.initialDetails,
  });

  static Future<SelectedLocationResult?> show(
    BuildContext context, {
    double initialLat = CampusConstants.defaultLatitude,
    double initialLng = CampusConstants.defaultLongitude,
    String? initialLocationId,
    String? initialDetails,
  }) {
    return showDialog<SelectedLocationResult>(
      context: context,
      barrierDismissible: false,
      builder: (_) => CampusMapPickerDialog(
        initialLat: initialLat,
        initialLng: initialLng,
        initialLocationId: initialLocationId,
        initialDetails: initialDetails,
      ),
    );
  }

  @override
  State<CampusMapPickerDialog> createState() => _CampusMapPickerDialogState();
}

class _CampusMapPickerDialogState extends State<CampusMapPickerDialog> {
  late final MapController _mapController;
  late double _currentLat;
  late double _currentLng;
  late CampusLocation _nearestLandmark;
  final _searchController = TextEditingController();
  final _detailsController = TextEditingController();
  bool _isSearching = false;
  List<CampusLocation> _searchResults = [];

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _currentLat = widget.initialLat;
    _currentLng = widget.initialLng;
    _detailsController.text = widget.initialDetails ?? '';

    if (widget.initialLocationId != null) {
      _nearestLandmark = CampusConstants.findById(widget.initialLocationId!);
    } else {
      _nearestLandmark = CampusConstants.findNearest(_currentLat, _currentLng);
    }

    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _mapController.dispose();
    _searchController.dispose();
    _detailsController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) {
      setState(() {
        _isSearching = false;
        _searchResults = [];
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _searchResults = CampusConstants.locations.where((loc) {
        return loc.name.toLowerCase().contains(query) ||
            loc.zone.toLowerCase().contains(query) ||
            loc.description.toLowerCase().contains(query);
      }).toList();
    });
  }

  void _selectLandmark(CampusLocation loc) {
    setState(() {
      _currentLat = loc.latitude;
      _currentLng = loc.longitude;
      _nearestLandmark = loc;
      _searchController.clear();
      _isSearching = false;
    });
    _mapController.move(LatLng(loc.latitude, loc.longitude), 17.0);
  }

  void _onMapTap(TapPosition tapPosition, LatLng point) {
    setState(() {
      _currentLat = point.latitude;
      _currentLng = point.longitude;
      _nearestLandmark = CampusConstants.findNearest(
        point.latitude,
        point.longitude,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = AppTheme.isDark(context);
    final isWithinCampus = CampusConstants.isWithinCampusBounds(
      _currentLat,
      _currentLng,
    );

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      backgroundColor: AppTheme.cardColor(context),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: AppTheme.borderColor(context)),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720, maxHeight: 760),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Modal Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: isDark
                    ? AppTheme.surfaceDarkSubtle
                    : Colors.grey.shade50,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
                border: Border(
                  bottom: BorderSide(color: AppTheme.borderColor(context)),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryIndigo.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.place_rounded,
                      color: AppTheme.primaryIndigo,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Mark Location on VIT Campus Map',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimaryColor(context),
                          ),
                        ),
                        Text(
                          'Click anywhere on campus or search for a building',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.textSecondaryColor(context),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    tooltip: 'Cancel',
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // Search Bar & Quick Landmarks
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Column(
                children: [
                  TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search building (SJT, TT, Library, Food Mall, Hostels...)',
                      prefixIcon: const Icon(Icons.search, size: 20),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 18),
                              onPressed: () => _searchController.clear(),
                            )
                          : null,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                    ),
                  ),
                  if (_isSearching) ...[
                    const SizedBox(height: 6),
                    Container(
                      constraints: const BoxConstraints(maxHeight: 180),
                      decoration: BoxDecoration(
                        color: AppTheme.cardColor(context),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppTheme.borderColor(context),
                        ),
                        boxShadow: AppTheme.subtleCardShadow,
                      ),
                      child: _searchResults.isEmpty
                          ? Padding(
                              padding: const EdgeInsets.all(12),
                              child: Text(
                                'No matching campus buildings found',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  color: AppTheme.textMutedColor(context),
                                ),
                              ),
                            )
                          : ListView.separated(
                              shrinkWrap: true,
                              itemCount: _searchResults.length,
                              separatorBuilder: (_, _) => Divider(
                                height: 1,
                                color: AppTheme.borderColor(context),
                              ),
                              itemBuilder: (ctx, idx) {
                                final loc = _searchResults[idx];
                                return ListTile(
                                  dense: true,
                                  leading: const Icon(
                                    Icons.apartment,
                                    size: 18,
                                    color: AppTheme.primaryIndigo,
                                  ),
                                  title: Text(
                                    loc.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                    ),
                                  ),
                                  subtitle: Text(
                                    '${loc.zone} • ${loc.description}',
                                    style: const TextStyle(fontSize: 11),
                                  ),
                                  onTap: () => _selectLandmark(loc),
                                );
                              },
                            ),
                    ),
                  ] else ...[
                    const SizedBox(height: 8),
                    // Quick Landmark Filter Pills
                    SizedBox(
                      height: 32,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          _buildQuickLandmarkChip('sjt', 'SJT'),
                          _buildQuickLandmarkChip('tt', 'Tech Tower'),
                          _buildQuickLandmarkChip('lib', 'Library'),
                          _buildQuickLandmarkChip('food_mall', 'Food Mall'),
                          _buildQuickLandmarkChip('smv', 'SMV Block'),
                          _buildQuickLandmarkChip('mb', 'Main Building'),
                          _buildQuickLandmarkChip(
                            'mens_hostel',
                            "Men's Hostels",
                          ),
                          _buildQuickLandmarkChip(
                            'womens_hostel',
                            "Ladies' Hostels",
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Interactive Map View
            Expanded(
              child: Stack(
                children: [
                  FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: LatLng(_currentLat, _currentLng),
                      initialZoom: 16.5,
                      minZoom: 14.0,
                      maxZoom: 19.0,
                      onTap: _onMapTap,
                    ),
                    children: [
                      TileLayer(
                        urlTemplate:
                            'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.codechefvit.refind',
                      ),
                      // Pulse Circle on Chosen Location
                      CircleLayer(
                        circles: [
                          CircleMarker(
                            point: LatLng(_currentLat, _currentLng),
                            radius: 35,
                            useRadiusInMeter: true,
                            color: AppTheme.primaryIndigo.withValues(
                              alpha: 0.2,
                            ),
                            borderColor: AppTheme.primaryIndigo,
                            borderStrokeWidth: 2,
                          ),
                        ],
                      ),
                      // Marker
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: LatLng(_currentLat, _currentLng),
                            width: 48,
                            height: 48,
                            alignment: Alignment.topCenter,
                            child: const Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.location_on,
                                  color: AppTheme.statusLost,
                                  size: 38,
                                  shadows: [
                                    Shadow(
                                      color: Colors.black26,
                                      blurRadius: 4,
                                      offset: Offset(0, 2),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  // Floating Map Controls (Zoom + Center)
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Column(
                      children: [
                        _buildMapActionButton(
                          icon: Icons.add,
                          tooltip: 'Zoom In',
                          onTap: () {
                            final currentZoom = _mapController.camera.zoom;
                            _mapController.move(
                              LatLng(_currentLat, _currentLng),
                              currentZoom + 1,
                            );
                          },
                        ),
                        const SizedBox(height: 6),
                        _buildMapActionButton(
                          icon: Icons.remove,
                          tooltip: 'Zoom Out',
                          onTap: () {
                            final currentZoom = _mapController.camera.zoom;
                            _mapController.move(
                              LatLng(_currentLat, _currentLng),
                              currentZoom - 1,
                            );
                          },
                        ),
                        const SizedBox(height: 6),
                        _buildMapActionButton(
                          icon: Icons.my_location,
                          tooltip: 'Reset to VIT Center',
                          onTap: () {
                            _mapController.move(
                              const LatLng(
                                CampusConstants.defaultLatitude,
                                CampusConstants.defaultLongitude,
                              ),
                              16.5,
                            );
                          },
                        ),
                      ],
                    ),
                  ),

                  // Bottom Overlay Banner: Nearest Landmark & Geofence Status
                  Positioned(
                    bottom: 12,
                    left: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.cardColor(context)
                            .withValues(alpha: 0.95),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppTheme.borderColor(context),
                        ),
                        boxShadow: AppTheme.subtleCardShadow,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isWithinCampus
                                ? Icons.check_circle
                                : Icons.warning_amber_rounded,
                            color: isWithinCampus
                                ? AppTheme.statusReturned
                                : AppTheme.accentAmber,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Nearest: ${_nearestLandmark.name}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12.5,
                                    color: AppTheme.textPrimaryColor(context),
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  'Coords: ${_currentLat.toStringAsFixed(4)}, ${_currentLng.toStringAsFixed(4)} • '
                                  '${isWithinCampus ? "Inside Campus Boundary" : "Off-Campus Area"}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: AppTheme.textSecondaryColor(context),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Specific Floor/Room Input & Confirmation Actions
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark
                    ? AppTheme.surfaceDarkSubtle
                    : Colors.grey.shade50,
                border: Border(
                  top: BorderSide(color: AppTheme.borderColor(context)),
                ),
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(20),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: _detailsController,
                    decoration: InputDecoration(
                      labelText:
                          'Specific Floor / Lab / Room / Spot Notes (Optional)',
                      hintText: 'e.g. 4th floor Lab 402 near front row, Food Mall Table 8',
                      prefixIcon: const Icon(
                        Icons.edit_location_alt_outlined,
                        size: 20,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      fillColor: AppTheme.cardColor(context),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.check, size: 18),
                        label: const Text('Confirm Location'),
                        onPressed: () {
                          Navigator.pop(
                            context,
                            SelectedLocationResult(
                              latitude: _currentLat,
                              longitude: _currentLng,
                              locationId: _nearestLandmark.id,
                              locationName: _nearestLandmark.name,
                              specificDetails: _detailsController.text.trim(),
                              isWithinCampus: isWithinCampus,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickLandmarkChip(String id, String label) {
    final isSelected = _nearestLandmark.id == id;
    final isDark = AppTheme.isDark(context);

    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: ActionChip(
        label: Text(label),
        labelStyle: TextStyle(
          fontSize: 11.5,
          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          color: isSelected ? Colors.white : AppTheme.textPrimaryColor(context),
        ),
        backgroundColor: isSelected
            ? AppTheme.primaryIndigo
            : (isDark
                  ? AppTheme.surfaceDarkSubtle
                  : AppTheme.surfaceLightSubtle),
        side: BorderSide(
          color: isSelected
              ? AppTheme.primaryIndigo
              : AppTheme.borderColor(context),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 0),
        onPressed: () {
          final loc = CampusConstants.findById(id);
          _selectLandmark(loc);
        },
      ),
    );
  }

  Widget _buildMapActionButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardColor(context),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.borderColor(context)),
        boxShadow: AppTheme.subtleCardShadow,
      ),
      child: IconButton(
        icon: Icon(icon, size: 18),
        tooltip: tooltip,
        constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
        padding: EdgeInsets.zero,
        onPressed: onTap,
      ),
    );
  }
}
