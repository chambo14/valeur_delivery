class OrderItem {
  final String? name;
  final int? quantity;
  final String? description;

  OrderItem({
    this.name,
    this.quantity,
    this.description,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      name: json['name'] as String?,
      quantity: json['quantity'] as int?,
      description: json['description'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'quantity': quantity,
      'description': description,
    };
  }

  OrderItem copyWith({
    String? name,
    int? quantity,
    String? description,
  }) {
    return OrderItem(
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
      description: description ?? this.description,
    );
  }

  @override
  String toString() => 'OrderItem(name: $name, quantity: $quantity)';
}