class TripModel {
  final String? tripId;
  final String? userId;
  final String? status;
  final String? startTime;
  final String? endTime;
  final double? distance;
  final String? imageUrl;

  TripModel({
    this.tripId,
    this.userId,
    this.status,
    this.startTime,
    this.endTime,
    this.distance,
    this.imageUrl,
  });

  factory TripModel.fromJson(Map<String, dynamic> json) {
    return TripModel(
      tripId: (json['id'] ?? json['tripId'])?.toString(),
      userId: json['userId']?.toString(),
      status: json['status']?.toString(),
      startTime: json['startTime']?.toString(),
      endTime: json['endTime']?.toString(),
      distance: (json['distance'] as num?)?.toDouble(),
      imageUrl: json['imageUrl']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (tripId != null) 'tripId': tripId,
      if (userId != null) 'userId': userId,
      if (status != null) 'status': status,
      if (startTime != null) 'startTime': startTime,
      if (endTime != null) 'endTime': endTime,
      if (distance != null) 'distance': distance,
      if (imageUrl != null) 'imageUrl': imageUrl,
    };
  }
}
