import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_theme.dart';
import '../../core/constants/campus_locations.dart';
import '../../core/models/item_model.dart';
import '../../providers/app_providers.dart';
import '../widgets/status_badge.dart';
import 'item_details_screen.dart';

class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  late final MapController _mapController;
  ItemModel? _selectedItem;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filteredItems = ref.watch(filteredItemsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Campus Item Map'),
        actions: [
          IconButton(
            icon: const Icon(Icons.my_location),
            tooltip: 'Center on Campus',
            onPressed: () {
              _mapController.move(
                const LatLng(
                  CampusConstants.defaultLatitude,
                  CampusConstants.defaultLongitude,
                ),
                16.0,
              );
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: const MapOptions(
              initialCenter: LatLng(
                CampusConstants.defaultLatitude,
                CampusConstants.defaultLongitude,
              ),
              initialZoom: 16.0,
              minZoom: 14.0,
              maxZoom: 18.5,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.codechefvit.finderskeepers',
              ),
              MarkerLayer(
                markers: filteredItems.map((item) {
                  final isSelected = _selectedItem?.id == item.id;
                  Color pinColor;
                  if (item.status == ItemStatus.returned) {
                    pinColor = AppTheme.statusReturned;
                  } else if (item.status == ItemStatus.claimed) {
                    pinColor = AppTheme.statusClaimed;
                  } else if (item.isLost) {
                    pinColor = AppTheme.statusLost;
                  } else {
                    pinColor = AppTheme.statusFound;
                  }

                  return Marker(
                    point: LatLng(item.latitude, item.longitude),
                    width: isSelected ? 48 : 38,
                    height: isSelected ? 48 : 38,
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedItem = item;
                        });
                        _mapController.move(
                          LatLng(item.latitude, item.longitude),
                          16.5,
                        );
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        decoration: BoxDecoration(
                          color: pinColor,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: pinColor.withValues(alpha: 0.4),
                              blurRadius: isSelected ? 12 : 6,
                              spreadRadius: isSelected ? 3 : 1,
                            ),
                          ],
                          border: Border.all(
                            color: Colors.white,
                            width: isSelected ? 3 : 2,
                          ),
                        ),
                        child: Icon(
                          item.isLost ? Icons.search : Icons.inventory_2,
                          color: Colors.white,
                          size: isSelected ? 24 : 18,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),

          // Top Info Banner: Privacy Guarantee
          Positioned(
            top: 12,
            left: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.92),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.cardBorder),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Icon(Icons.privacy_tip_outlined,
                      size: 16, color: AppTheme.primaryBlue),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Privacy Notice: Markers show approximate campus zones (${filteredItems.length} items visible).',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF334155),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Bottom Preview Card when a pin is selected
          if (_selectedItem != null)
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: Card(
                elevation: 6,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          StatusBadge(type: _selectedItem!.type, compact: true),
                          const SizedBox(width: 8),
                          StatusBadge(status: _selectedItem!.status, compact: true),
                          const Spacer(),
                          IconButton(
                            icon: const Icon(Icons.close, size: 18),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            onPressed: () {
                              setState(() {
                                _selectedItem = null;
                              });
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _selectedItem!.title,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0F172A),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.location_on,
                              size: 14, color: AppTheme.primaryBlue),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              _selectedItem!.campusLocationName,
                              style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFF64748B),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    ItemDetailsScreen(item: _selectedItem!),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                          child: const Text('View Full Details & Claim'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
