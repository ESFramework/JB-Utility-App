class Product {
  final String name;
  final double dp; // Price per strip/unit

  Product({required this.name, required this.dp});
}

class CartItem {
  final Product product;
  int quantity;
  double get totalPrice => product.dp * quantity;

  CartItem({required this.product, this.quantity = 1});
}
