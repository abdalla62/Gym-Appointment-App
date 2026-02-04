class Availability {
  final String id;
  final String trainer;
  final String date;
  final List<Slot> slots;

  Availability({
    required this.id,
    required this.trainer,
    required this.date,
    required this.slots,
  });

  factory Availability.fromJson(Map<String, dynamic> json) {
    return Availability(
      id: json['_id'],
      trainer: json['trainer'],
      date: json['date'],
      slots: (json['slots'] as List).map((i) => Slot.fromJson(i)).toList(),
    );
  }
}

class Slot {
  final String time;
  final bool isBooked;

  Slot({
    required this.time,
    required this.isBooked,
  });

  factory Slot.fromJson(Map<String, dynamic> json) {
    return Slot(
      time: json['time'],
      isBooked: json['isBooked'] ?? false,
    );
  }
}
