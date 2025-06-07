
class Laptop {
  final String laptopId;
  final String userId;
  final String name;
  final String? brand;
  final String? model;
  final DateTime? purchaseDate;
  final String? os;
  final String? ram;
  final String? storage;
  final String? cpu;
  final String? gpu;
  final String? imageId;
  final DateTime createdAt;
  final DateTime updatedAt;

  Laptop({
    required this.laptopId,
    required this.userId,
    required this.name,
    this.brand,
    this.model,
    this.purchaseDate,
    this.os,
    this.ram,
    this.storage,
    this.cpu,
    this.gpu,
    this.imageId,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Laptop.fromJson(Map<String, dynamic> json) {
    return Laptop(
      laptopId: json['laptop_id'],
      userId: json['user_id'],
      name: json['name'],
      brand: json['brand'],
      model: json['model'],
      purchaseDate: json['purchase_date'] != null
          ? DateTime.parse(json['purchase_date'])
          : null,
      os: json['os'],
      ram: json['ram'],
      storage: json['storage'],
      cpu: json['cpu'],
      gpu: json['gpu'],
      imageId: json['image_id'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'laptop_id': laptopId,
      'user_id': userId,
      'name': name,
      'brand': brand,
      'model': model,
      'purchase_date': purchaseDate?.toIso8601String(),
      'os': os,
      'ram': ram,
      'storage': storage,
      'cpu': cpu,
      'gpu': gpu,
      'image_id': imageId,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  Laptop copyWith({
    String? laptopId,
    String? userId,
    String? name,
    String? brand,
    String? model,
    DateTime? purchaseDate,
    String? os,
    String? ram,
    String? storage,
    String? cpu,
    String? gpu,
    String? imageId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Laptop(
      laptopId: laptopId ?? this.laptopId,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      brand: brand ?? this.brand,
      model: model ?? this.model,
      purchaseDate: purchaseDate ?? this.purchaseDate,
      os: os ?? this.os,
      ram: ram ?? this.ram,
      storage: storage ?? this.storage,
      cpu: cpu ?? this.cpu,
      gpu: gpu ?? this.gpu,
      imageId: imageId ?? this.imageId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
