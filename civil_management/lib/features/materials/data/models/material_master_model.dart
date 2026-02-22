class MaterialMaster {
  final String id;
  final String name;

  MaterialMaster({required this.id, required this.name});

  factory MaterialMaster.fromJson(Map<String, dynamic> json) {
    return MaterialMaster(
      id: json['id'] as String,
      name: json['name'] as String,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MaterialMaster && other.id == id && other.name == name;
  }

  @override
  int get hashCode => id.hashCode ^ name.hashCode;
}
