class CartItem {
  final String categoryId;
  final String name;
  final String imagePath;
  double price; // Price dapat diubah (mutable)
  int quantity;

  CartItem({
    required this.categoryId,
    required this.imagePath,
    required this.name,
    required this.price,
    required this.quantity,
  });

  // Method untuk memperbarui harga produk
  void updatePrice(double newPrice) {
    price = newPrice;
  }

  // Getter untuk menghitung total harga berdasarkan price dan quantity
  double get totalPrice => price * quantity;

  // Method untuk memperbarui jumlah produk
  void updateQuantity(int newQuantity) {
    quantity = newQuantity;
  }
}
