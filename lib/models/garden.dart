class Garden {
  final String id;
  final String name;
  final double width;
  final double height;
  final bool isPublic;

  Garden({
    required this.id,
    required this.name,
    required this.width,
    required this.height,
    required this.isPublic,
  });

  factory Garden.fromMap(Map<String, dynamic> data, String id) {
    return Garden(
      id: id,
      name: data['name'],
      width: data['width'],
      height: data['height'],
      isPublic: data['isPublic'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'width': width,
      'height': height,
      'isPublic': isPublic,
    };
  }
}
