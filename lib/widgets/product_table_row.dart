import 'package:flutter/material.dart';
import '../models/product.dart';

class ProductTableRow extends StatelessWidget {
  final Product product;

  const ProductTableRow({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    return Table(
      children: [
        TableRow(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  product.name,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.bold,
                    fontSize: 12.0, // Reduced font size
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                product.dp.toStringAsFixed(2),
                style: const TextStyle(fontFamily: 'Poppins'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
