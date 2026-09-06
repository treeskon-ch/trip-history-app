class CheckinModel {
  final double lat;
  final double lng;
  final String? timestamp;
  final String? message;
  final String? imageUrl;

  CheckinModel({
    required this.lat,
    required this.lng,
    this.timestamp,
    this.message,
    this.imageUrl,
  });

  factory CheckinModel.fromJson(Map<String, dynamic> json) {
    return CheckinModel(
      lat: (json['lat'] as num).toDouble(),
      lng: (json['lng'] as num).toDouble(),
      timestamp: json['timestamp']?.toString(),
      message: json['message']?.toString(),
      imageUrl: json['imageUrl']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'lat': lat,
      'lng': lng,
      if (timestamp != null) 'timestamp': timestamp,
      if (message != null) 'message': message,
      if (imageUrl != null) 'imageUrl': imageUrl,
    };
  }
}
