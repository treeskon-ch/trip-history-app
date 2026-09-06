class PlanLocation {
  final double lat;
  final double lng;
  final String? address;

  PlanLocation({
    required this.lat,
    required this.lng,
    this.address,
  });

  factory PlanLocation.fromJson(Map<String, dynamic> json) {
    return PlanLocation(
      lat: (json['lat'] as num).toDouble(),
      lng: (json['lng'] as num).toDouble(),
      address: json['address']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'lat': lat,
      'lng': lng,
      if (address != null) 'address': address,
    };
  }
}

class PlanModel {
  final String id;
  final String title;
  final String? driverId;
  final PlanLocation origin;
  final PlanLocation destination;
  final String status;
  final String? createdAt;

  PlanModel({
    required this.id,
    required this.title,
    this.driverId,
    required this.origin,
    required this.destination,
    required this.status,
    this.createdAt,
  });

  factory PlanModel.fromJson(Map<String, dynamic> json) {
    return PlanModel(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      driverId: json['driverId']?.toString(),
      origin: PlanLocation.fromJson(json['origin']),
      destination: PlanLocation.fromJson(json['destination']),
      status: json['status']?.toString() ?? 'pending',
      createdAt: json['createdAt']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      if (driverId != null) 'driverId': driverId,
      'origin': origin.toJson(),
      'destination': destination.toJson(),
      'status': status,
      if (createdAt != null) 'createdAt': createdAt,
    };
  }
}
