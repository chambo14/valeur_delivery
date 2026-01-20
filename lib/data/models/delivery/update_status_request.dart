import 'location_data.dart';

class UpdateStatusRequest {
  final String status;
  final String? notes;
  final LocationData? location;

  UpdateStatusRequest({
    required this.status,
    this.notes,
    this.location,
  });

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      'status': status,
    };

    if (notes != null && notes!.isNotEmpty) {
      json['notes'] = notes;
    }

    if (location != null) {
      json['location'] = location!.toJson();
    }

    return json;
  }

  @override
  String toString() => 'UpdateStatusRequest(status: $status, notes: $notes, location: $location)';
}