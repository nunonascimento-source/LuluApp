class Measurement {
  int? id;
  DateTime date;
  String time; // store as HH:mm
  int glicemia;
  double insulina;
  String? observations;

  Measurement({
    this.id,
    required this.date,
    required this.time,
    required this.glicemia,
    required this.insulina,
    this.observations,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'time': time,
      'glicemia': glicemia,
      'insulina': insulina,
      'observations': observations,
    };
  }

  factory Measurement.fromMap(Map<String, dynamic> map) {
    return Measurement(
      id: map['id'] as int?,
      date: DateTime.parse(map['date'] as String),
      time: map['time'] as String,
      glicemia: map['glicemia'] as int,
      insulina: (map['insulina'] as num).toDouble(),
      observations: map['observations'] as String?,
    );
  }
}
