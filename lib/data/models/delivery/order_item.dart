class OrderItem {
  final String? uuid;
  final String? name;
  final int? quantity;
  final String? description;
  final String? price;

  OrderItem({
    this.uuid,
    this.name,
    this.quantity,
    this.description,
    this.price,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      uuid: json['uuid'] as String?,
      name: json['name'] as String?,
      quantity: json['quantity'] as int?,
      description: json['description'] as String?,
      price: json['price'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'uuid': uuid,
    'name': name,
    'quantity': quantity,
    'description': description,
    'price': price,
  };

  @override
  String toString() => 'OrderItem(name: $name, qty: $quantity)';
}