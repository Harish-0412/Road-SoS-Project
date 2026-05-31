enum FacilityType { hospital, police, towing, mechanic }

class Facility {
  final String id;
  final String name;
  final double latitude;
  final double longitude;
  final FacilityType type;
  final String phoneNumber;
  final double ptsScore; // Priority Trauma Score

  Facility({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.type,
    required this.phoneNumber,
    required this.ptsScore,
  });
}
