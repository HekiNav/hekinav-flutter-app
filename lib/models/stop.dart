class Stop{
  String code;
  String name;

  Stop({
    required this.code,
    required this.name,
  });

  factory Stop.fromJson(Map<String, dynamic> json) {
    return Stop(
      code: json['code'],
      name: json['name'],
    );
  }
}