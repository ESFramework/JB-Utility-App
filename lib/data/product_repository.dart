import '../models/product.dart';

class ProductRepository {
  static final List<Product> products = [
    Product(name: 'BISOTAB 2.5', dp: 59.61),
    Product(name: 'BISOTAB 5', dp: 87.99),
    Product(name: 'BISOTAB T 2.5', dp: 76.39),
    Product(name: 'BISOTAB T 5', dp: 88.74),
    Product(name: 'CILACAR M 10/25', dp: 154.45),
    Product(name: 'CILACAR M 10/50', dp: 188.79),
    Product(name: 'CILACAR TC 6.25', dp: 159.86),
    Product(name: 'CILACAR TC 12.5', dp: 166.28),
    Product(name: 'CILACAR C 6.25', dp: 94.74), 
    Product(name: 'CILACAR C 12.5', dp: 107.27),
    Product(name: 'CILACAR Nb 2.5', dp: 113.62),
    Product(name: 'CILACAR Nb 5', dp: 139.43),
    Product(name: 'DAPACOSE 5', dp: 93.94),
    Product(name: 'DAPACOSE 10', dp: 112.73),
    Product(name: 'DAPACOSE M 10', dp: 93.58),
    Product(name: 'DAPACOSE M Forte 10', dp: 98.35),
    // Product(name: 'DAPACOSE M Forte 5', dp: 59.69),
    // Product(name: 'DAPACOSE S 10/50', dp: 98.25),
    Product(name: 'DAPACOSE S 10/100', dp: 115.79),
    // Product(name: 'DAPACOSE S 5/50', dp: 70.07),
    Product(name: 'DAPACOSE TRIO 500', dp: 147.65),
    Product(name: 'DAPACOSE TRIO 1000', dp: 155.43),
  ];

  List<Product> getAllProducts() {
    return products;
  }

  List<Product> searchProducts(String query) {
    if (query.isEmpty) {
      return products;
    }

    return products
        .where(
          (product) => product.name.toLowerCase().contains(query.toLowerCase()),
        )
        .toList();
  }
}
