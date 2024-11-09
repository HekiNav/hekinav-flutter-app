class Start {
  DateTime scheduled;
  DateTime? estimated;
  String? delay;

  Start({
    required this.scheduled,
    required this.estimated,
    required this.delay,
  });

  factory Start.fromJson(Map<String, dynamic> json) {
    return Start(
      scheduled: DateTime.parse(json['scheduledTime']),
      estimated: json['estimated']?['time'] == null
          ? null
          : DateTime.parse(json['estimated']?['time']),
      delay: json['estimated']?['delay'],
    );
  }
}

class End {
  DateTime scheduled;
  DateTime? estimated;
  String? delay;

  End({
    required this.scheduled,
    required this.estimated,
    required this.delay,
  });

  factory End.fromJson(Map<String, dynamic> json) {
    return End(
      scheduled: DateTime.parse(json['scheduledTime']),
      estimated: json['estimated']?['time'] == null
          ? null
          : DateTime.parse(json['estimated']?['time']),
      delay: json['estimated']?['delay'],
    );
  }
}