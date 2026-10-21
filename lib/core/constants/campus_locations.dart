class CampusLocation {
  final String id;
  final String name;
  final String zone;
  final double latitude;
  final double longitude;
  final String description;

  const CampusLocation({
    required this.id,
    required this.name,
    required this.zone,
    required this.latitude,
    required this.longitude,
    required this.description,
  });
}

class CampusConstants {
  // Center of Campus (VIT Vellore)
  static const double defaultLatitude = 12.9698;
  static const double defaultLongitude = 79.1559;

  static const List<CampusLocation> locations = [
    CampusLocation(
      id: 'sjt',
      name: 'Silver Jubilee Tower (SJT)',
      zone: 'Academic - North',
      latitude: 12.9712,
      longitude: 79.1593,
      description: 'CSE, IT, SCOPE Labs & Classrooms',
    ),
    CampusLocation(
      id: 'tt',
      name: 'Technology Tower (TT)',
      zone: 'Academic - Central',
      latitude: 12.9701,
      longitude: 79.1578,
      description: 'ECE, SENSE & Faculty Offices',
    ),
    CampusLocation(
      id: 'lib',
      name: 'Central Library (Periyar EVR)',
      zone: 'Academic - Central',
      latitude: 12.9692,
      longitude: 79.1565,
      description: 'Reading halls, digital library, circulation',
    ),
    CampusLocation(
      id: 'anna_aud',
      name: 'Anna Auditorium',
      zone: 'Cultural - Central',
      latitude: 12.9688,
      longitude: 79.1555,
      description: 'Main auditorium, student hub',
    ),
    CampusLocation(
      id: 'food_mall',
      name: 'Food Mall & Gazebo',
      zone: 'Amenities - Central',
      latitude: 12.9695,
      longitude: 79.1560,
      description: 'Food court, outdoor seating',
    ),
    CampusLocation(
      id: 'smv',
      name: 'SMV Block',
      zone: 'Academic - South',
      latitude: 12.9681,
      longitude: 79.1548,
      description: 'Mechanical & Civil Engineering',
    ),
    CampusLocation(
      id: 'gdn',
      name: 'GDN Block',
      zone: 'Academic - West',
      latitude: 12.9675,
      longitude: 79.1539,
      description: 'Biotech, Science labs',
    ),
    CampusLocation(
      id: 'mb',
      name: 'Main Building (Dr. MGR Block)',
      zone: 'Admin - Central',
      latitude: 12.9699,
      longitude: 79.1552,
      description: 'Administrative offices, admissions',
    ),
    CampusLocation(
      id: 'mens_hostel',
      name: "Men's Hostel Blocks (Q / P / M / L)",
      zone: 'Residential - East',
      latitude: 12.9725,
      longitude: 79.1620,
      description: 'Men student residential area',
    ),
    CampusLocation(
      id: 'womens_hostel',
      name: "Ladies' Hostel Complex",
      zone: 'Residential - West',
      latitude: 12.9660,
      longitude: 79.1520,
      description: 'Women student residential area',
    ),
    CampusLocation(
      id: 'sports_complex',
      name: 'Outdoor Stadium & Sports Complex',
      zone: 'Sports - North',
      latitude: 12.9730,
      longitude: 79.1580,
      description: 'Running track, badminton courts, gym',
    ),
    CampusLocation(
      id: 'main_gate',
      name: 'Main Gate & Security Post',
      zone: 'Security / Transit',
      latitude: 12.9680,
      longitude: 79.1585,
      description: 'Campus entry security desk',
    ),
  ];

  static CampusLocation findById(String id) {
    return locations.firstWhere(
      (loc) => loc.id == id,
      orElse: () => locations.first,
    );
  }

  static bool isWithinCampusBounds(double lat, double lng) {
    // Geofencing bounding box around VIT Vellore campus
    return lat >= 12.9580 && lat <= 12.9800 && lng >= 79.1450 && lng <= 79.1720;
  }

  static CampusLocation findNearest(double lat, double lng) {
    CampusLocation nearest = locations.first;
    double minDistance = double.infinity;
    for (final loc in locations) {
      final d =
          (loc.latitude - lat) * (loc.latitude - lat) +
          (loc.longitude - lng) * (loc.longitude - lng);
      if (d < minDistance) {
        minDistance = d;
        nearest = loc;
      }
    }
    return nearest;
  }
}
