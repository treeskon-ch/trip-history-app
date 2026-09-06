class LocationModel {
  final String? userId;
  final double lat;
  final double lng;
  final double? speed;
  final String? timestamp;

  LocationModel({
    this.userId,
    required this.lat,
    required this.lng,
    this.speed,
    this.timestamp,
  });

  factory LocationModel.fromJson(Map<String, dynamic> json) {
    return LocationModel(
      userId: json['userId']?.toString(),
      lat: (json['lat'] as num).toDouble(),
      lng: (json['lng'] as num).toDouble(),
      speed: (json['speed'] as num?)?.toDouble(),
      timestamp: json['timestamp']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (userId != null) 'userId': userId,
      'lat': lat,
      'lng': lng,
      if (speed != null) 'speed': speed,
      if (timestamp != null) 'timestamp': timestamp,
    };
  }
}
