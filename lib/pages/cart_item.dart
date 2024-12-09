class CartItem {
  final String categoryId;
  final String name;
  double price;  // Make the price mutable
  int quantity;

  CartItem({
    required this.categoryId,
    required this.name,
    required this.price,
    required this.quantity,
  });

  // Method to update the price of a product
  void updatePrice(double newPrice) {
    price = newPrice;
  }

  double get totalPrice => price * quantity; // Calculate total price for this item
}
