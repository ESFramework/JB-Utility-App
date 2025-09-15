import 'package:flutter/material.dart';
import '../data/product_repository.dart';
import '../models/product.dart';
import 'cart_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ProductRepository _productRepository = ProductRepository();
  List<Product> _products = [];
  List<CartItem> _cartItems = [];
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _products = _productRepository.getAllProducts();
  }

  void _addToCart(Product product) {
    setState(() {
      bool itemExists = false;
      for (int i = 0; i < _cartItems.length; i++) {
        if (_cartItems[i].product.name == product.name) {
          _cartItems[i].quantity++;
          itemExists = true;
          break;
        }
      }
      if (!itemExists) {
        _cartItems.add(CartItem(product: product));
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${product.name} added to cart'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void _searchProducts(String query) {
    setState(() {
      _searchQuery = query;
      _products = _productRepository.searchProducts(query);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Utility App - Products'),
        backgroundColor: Colors.blue,
        actions: [
          Badge(
            label: Text(_cartItems.isEmpty ? '' : _cartItems.length.toString()),
            isLabelVisible: _cartItems.isNotEmpty,
            child: IconButton(
              icon: const Icon(Icons.shopping_cart),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CartScreen(cartItems: _cartItems),
                  ),
                ).then((updatedCart) {
                  if (updatedCart != null) {
                    setState(() {
                      _cartItems = updatedCart as List<CartItem>;
                    });
                  }
                });
              },
            ),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: const InputDecoration(
                labelText: 'Search Products',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: _searchProducts,
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _products.length,
              itemBuilder: (context, index) {
                final product = _products[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ListTile(
                    title: Text(product.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('Price: ₹${product.dp.toStringAsFixed(2)}'),
                    trailing: IconButton(
                      icon: const Icon(Icons.add_shopping_cart),
                      onPressed: () => _addToCart(product),
                      color: Colors.blue,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
