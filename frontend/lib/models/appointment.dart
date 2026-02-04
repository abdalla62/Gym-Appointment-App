class Appointment {
  final String id;
  final String date;
  final String time;
  final String status;
  final String? trainerId;
  final String? trainerName;
  final String? userId;
  final String? userName;
  final String? userEmail;
  final String? notes;
  final String scolor;
  final double price;

  Appointment({
    required this.id,
    required this.date,
    required this.time,
    required this.status,
    this.trainerId,
    this.trainerName,
    this.userId,
    this.userName,
    this.userEmail,
    this.notes,
    this.scolor = '#FF7F27',
    this.price = 50.0,
  });

  factory Appointment.fromJson(Map<String, dynamic> json) {
    return Appointment(
      id: json['_id'],
      date: json['date'],
      time: json['time'],
      status: json['status'],
      trainerId: json['trainer'] is Map ? json['trainer']['_id'] : json['trainer'],
      trainerName: json['trainer'] is Map ? json['trainer']['name'] : 'Unknown Trainer',
      userId: json['user'] is Map ? json['user']['_id'] : json['user'],
      userName: json['user'] is Map ? json['user']['name'] : 'Unknown User',
      userEmail: json['user'] is Map ? json['user']['email'] : null,
      notes: json['notes'],
      scolor: json['scolor'] ?? '#FF7F27',
      price: (json['price'] ?? 50.0).toDouble(),
    );
  }
}
