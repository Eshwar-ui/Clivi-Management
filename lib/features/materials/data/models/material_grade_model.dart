class MaterialGrade {
  final String id;
  final String materialId;
  final String gradeName;

  MaterialGrade({
    required this.id,
    required this.materialId,
    required this.gradeName,
  });

  factory MaterialGrade.fromJson(Map<String, dynamic> json) {
    return MaterialGrade(
      id: json['id'] as String,
      materialId: json['material_id'] as String,
      gradeName: json['grade_name'] as String,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MaterialGrade &&
        other.id == id &&
        other.materialId == materialId &&
        other.gradeName == gradeName;
  }

  @override
  int get hashCode => id.hashCode ^ materialId.hashCode ^ gradeName.hashCode;
}
