import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/rendering.dart';
import 'package:screenshot/screenshot.dart';
import 'package:provider/provider.dart';
// import 'package:share_plus/share_plus.dart'; // <-- Add this import
import 'package:share_plus/share_plus.dart';
// import 'package:image_picker/image_picker.dart'; // if you're using XFile
import 'package:path_provider/path_provider.dart';
import 'dart:io'; // <-- Add this import
import 'dart:ui' as ui; // <-- Add this import
import '../data/product_repository.dart';
import '../models/product.dart';
import '../theme/theme_provider.dart';
import 'settings_screen.dart';
import '../models/history_item.dart';
import 'history_screen.dart';
import '../services/history_service.dart';
import 'dart:ui';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter/services.dart';

class CalculatorScreen extends StatefulWidget {
  const CalculatorScreen({super.key});

  @override
  State<CalculatorScreen> createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends State<CalculatorScreen> {
  final ProductRepository _productRepository = ProductRepository();
  final List<Product> _products = [];
  final List<CalculationItem> _calculationItems = [];
  final TextEditingController _stockistNameController = TextEditingController();
  final TextEditingController _stripsController = TextEditingController();
  final ScreenshotController screenshotController = ScreenshotController();
  final GlobalKey _tableScreenshotKey = GlobalKey(); // <-- Add this line
  Product? _selectedProduct;
  double _totalValue = 0.0;
  final GlobalKey _tableKey = GlobalKey();
  final Map<CalculationItem, GlobalKey> _itemKeys = {};
  int? _editingStripsIndex; // Track which row is being edited
  final Map<int, TextEditingController> _stripsEditControllers = {};
  bool _hasNotifications = false;
  final List<String> _notifications = [];
  bool _isNotificationEnabled = true;
  late List<HistoryItem> _history; // Change from final to late

  @override
  void initState() {
    super.initState();
    _products.addAll(_productRepository.getAllProducts());
    _history = []; // Initialize empty list
    _loadHistory(); // Load history after initialization
  }

  @override
  void dispose() {
    _stockistNameController.dispose();
    _stripsController.dispose();
    _stripsEditControllers.forEach((_, c) => c.dispose());
    super.dispose();
  }

  void _showNotification(String message, {bool isError = false}) {
    if (!_isNotificationEnabled) return;

    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);

    setState(() {
      _hasNotifications = true;
      _notifications.add(message);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        behavior: SnackBarBehavior.floating,
        dismissDirection: DismissDirection.none, // Make it non-dismissible
        onVisible: () {}, // Fixed: Use proper VoidCallback type
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        margin: EdgeInsets.only(
          bottom:
              MediaQuery.of(context).size.height -
              150, // Changed from 100 to 150
          left: 16,
          right: 16,
        ),
        content: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: (isError ? Colors.red : Colors.blue).withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: (isError ? Colors.red : Colors.blue).withOpacity(0.2),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    isError ? Icons.error : Icons.info_outline,
                    color: isError ? Colors.red : Colors.blue,
                    size: 24,
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      message,
                      style: TextStyle(
                        color: themeProvider.textColor,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        duration: Duration(seconds: isError ? 3 : 2),
      ),
    );

    // Clear notification status after some time
    Future.delayed(Duration(seconds: isError ? 3 : 2), () {
      if (mounted) {
        setState(() {
          _notifications.remove(message);
          _hasNotifications = _notifications.isNotEmpty;
        });
      }
    });
  }

  void _addToCalculation() {
    if (_selectedProduct == null || _stripsController.text.isEmpty) {
      _showNotification(
        'Please select a product and enter number of strips',
        isError: true,
      );
      return;
    }

    final strips = int.tryParse(_stripsController.text);
    if (strips == null || strips <= 0) {
      _showNotification('Please enter a valid number of strips', isError: true);
      return;
    }

    final value = _selectedProduct!.dp * strips;
    final newItem = CalculationItem(
      product: _selectedProduct!,
      strips: strips,
      value: value,
      stockistName: _stockistNameController.text,
    );

    setState(() {
      _itemKeys[newItem] = GlobalKey();
      _calculationItems.add(newItem);
      _calculateTotal();
    });

    _stripsController.clear();
  }

  void _calculateTotal() {
    double total = 0.0;
    for (var item in _calculationItems) {
      total += item.value;
    }
    setState(() {
      _totalValue = total;
    });
  }

  void _removeItem(int index) async {
    final item = _calculationItems[index];
    setState(() {
      _calculationItems.removeAt(index);
      _itemKeys.remove(item);
      _stripsEditControllers.remove(index); // Clear the controller
      _calculateTotal();
    });
  }

  void _clearAll() async {
    bool? confirm = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Clear All Items'),
            content: const Text('Are you sure you want to clear all items?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Clear'),
              ),
            ],
          ),
    );

    if (confirm == true) {
      // Animate all items out
      for (var i = _calculationItems.length - 1; i >= 0; i--) {
        await Future.delayed(Duration(milliseconds: 50));
        setState(() {
          _calculationItems.removeAt(i);
          _stripsEditControllers.clear(); // Clear all controllers
          _calculateTotal();
        });
      }

      // Clear all fields
      setState(() {
        _stockistNameController.clear();
        _selectedProduct = null; // Clear selected product
      });

      _showNotification('All items cleared');
    }
  }

  Future<void> _shareScreenshot() async {
    try {
      // Wait for the next frame to ensure the table is rendered
      await Future.delayed(const Duration(milliseconds: 100));

      final RenderRepaintBoundary boundary =
          _tableScreenshotKey.currentContext!.findRenderObject()
              as RenderRepaintBoundary;
      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final ByteData? byteData = await image.toByteData(
        format: ui.ImageByteFormat.png,
      );
      final Uint8List imageBytes = byteData!.buffer.asUint8List();

      // Save image to a temporary file
      final directory = await getTemporaryDirectory();
      final imagePath =
          '${directory.path}/order_table_${DateTime.now().millisecondsSinceEpoch}.png';
      final imageFile = File(imagePath);
      await imageFile.writeAsBytes(imageBytes);

      // Share the image file
      await Share.shareXFiles(
        [XFile(imageFile.path)],
        subject: 'Order Details',
        text:
            'The total value of ${_stockistNameController.text.isEmpty ? "Unknown" : _stockistNameController.text}\'s orders for today is ₹${_totalValue.toStringAsFixed(2)}',
      );

      // Add to history after successful share
      final historyItem = HistoryItem(
        stockistName: _stockistNameController.text,
        items:
            _calculationItems
                .map(
                  (item) => {
                    'name': item.product.name,
                    'strips': item.strips,
                    'value': item.value,
                  },
                )
                .toList(),
        totalValue: _totalValue,
        timestamp: DateTime.now(),
      );

      setState(() {
        _history.insert(0, historyItem); // Add to start of list
      });
      await HistoryService.saveHistory(_history); // Add this

      _showNotification('Screenshot shared successfully');
    } catch (e) {
      _showNotification('Failed to share screenshot: $e', isError: true);
    }
  }

  void _toggleNotifications() {
    setState(() {
      _isNotificationEnabled = !_isNotificationEnabled;
    });
  }

  Future<void> _loadHistory() async {
    final savedHistory = await HistoryService.loadHistory();
    if (mounted) {
      setState(() {
        _history = savedHistory;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      backgroundColor: themeProvider.primaryColor,
      appBar: AppBar(
        backgroundColor: themeProvider.primaryColor,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.calculate, color: Colors.blue, size: 28),
            SizedBox(width: 10),
            Text(
              'Order Calculator', // Changed from 'Order Calculator' in app bar
              style: TextStyle(
                color: themeProvider.textColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(
              _isNotificationEnabled
                  ? (_hasNotifications
                      ? Icons.notifications_active
                      : Icons.notifications_outlined)
                  : Icons.notifications_off_outlined,
              color: _hasNotifications ? Colors.blue : themeProvider.textColor,
            ),
            onPressed: _toggleNotifications,
          ),
          SizedBox(width: 8),
        ],
        centerTitle: true,
        elevation: 0,
      ),
      drawer: ClipRRect(
        borderRadius: const BorderRadius.only(
          topRight: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Drawer(
            elevation: 0,
            backgroundColor: themeProvider.primaryColor.withOpacity(0.7),
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.only(
                topRight: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.only(
                    top: 60,
                    bottom: 40,
                    left: 20,
                    right: 20,
                  ),
                  alignment: Alignment.centerLeft,
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: Colors.blue.withOpacity(0.2),
                        radius: 30,
                        child: Icon(
                          Icons.build_circle_outlined,
                          color: Colors.blue,
                          size: 30,
                        ),
                      ),
                      const SizedBox(width: 15),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'JB Calculator', // Changed from 'Utility App JB'
                            style: TextStyle(
                              color: themeProvider.textColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                          Text(
                            'v1.0.0',
                            style: TextStyle(
                              color: themeProvider.textColorSecondary,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const Divider(),
                Expanded(
                  child: ListView(
                    padding: EdgeInsets.zero,
                    children: [
                      Animate(
                        effects: [
                          FadeEffect(duration: 300.ms),
                          SlideEffect(
                            begin: const Offset(0, -0.1),
                            end: const Offset(0, 0),
                            duration: 300.ms,
                          ),
                        ],
                        child: Container(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: ListTile(
                            leading: const Icon(
                              Icons.calculate,
                              color: Colors.blue,
                            ),
                            title: Text(
                              'Calculator',
                              style: TextStyle(color: themeProvider.textColor),
                            ),
                            onTap: () {
                              Navigator.pop(context);
                            },
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),

                      Animate(
                        effects: [
                          FadeEffect(duration: 300.ms),
                          SlideEffect(
                            begin: const Offset(0, -0.1),
                            end: const Offset(0, 0),
                            duration: 300.ms,
                          ),
                        ],
                        child: Container(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: ListTile(
                            leading: const Icon(
                              Icons.card_giftcard,
                              color: Colors.green,
                            ),
                            title: Text(
                              'Incentives',
                              style: TextStyle(color: themeProvider.textColor),
                            ),
                            onTap: () {
                              Navigator.pop(context);
                              // Remove the navigation to IncentiveCalculatorPage
                              // Navigator.push(
                              //   context,
                              //   MaterialPageRoute(
                              //     builder: (context) => const IncentiveCalculatorPage(),
                              //   ),
                              // );
                              _showNotification(
                                'Incentives feature Coming Soon',
                              );
                            },
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                      Animate(
                        effects: [
                          FadeEffect(duration: 300.ms),
                          SlideEffect(
                            begin: const Offset(0, -0.1),
                            end: const Offset(0, 0),
                            duration: 300.ms,
                          ),
                        ],
                        child: Container(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: ListTile(
                            leading: const Icon(
                              Icons.history,
                              color: Colors.purple,
                            ),
                            title: Text(
                              'History',
                              style: TextStyle(color: themeProvider.textColor),
                            ),
                            onTap: () {
                              Navigator.pop(context);
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (context) => HistoryScreen(
                                        history: _history,
                                        onClearHistory: () {
                                          setState(() {
                                            _history.clear();
                                          });
                                          Navigator.pop(context);
                                          _showNotification('History cleared');
                                        },
                                      ),
                                ),
                              );
                            },
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                      Animate(
                        effects: [
                          FadeEffect(duration: 300.ms),
                          SlideEffect(
                            begin: const Offset(0, -0.1),
                            end: const Offset(0, 0),
                            duration: 300.ms,
                          ),
                        ],
                        child: Container(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: ListTile(
                            leading: const Icon(
                              Icons.settings,
                              color: Colors.orange,
                            ),
                            title: Text(
                              'Settings',
                              style: TextStyle(color: themeProvider.textColor),
                            ),
                            onTap: () {
                              Navigator.pop(context);
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const SettingsScreen(),
                                ),
                              );
                            },
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(),
              ],
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Your input form widgets...
            // ...existing code...
            Screenshot(
              controller: screenshotController,
              child: SingleChildScrollView(
                child: Animate(
                  effects: [
                    FadeEffect(duration: 300.ms),
                    SlideEffect(
                      begin: const Offset(0, -0.1),
                      end: const Offset(0, 0),
                      duration: 300.ms,
                    ),
                  ],
                  child: Container(
                    color: themeProvider.primaryColor,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Center(
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 20.0),
                              child: Text(
                                'Calculate product values based on strips',
                                style: TextStyle(
                                  color: themeProvider.textColorSecondary,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.all(
                              12,
                            ), // Reduced padding
                            child: Animate(
                              effects: [
                                FadeEffect(duration: 300.ms),
                                SlideEffect(
                                  begin: const Offset(0, -0.1),
                                  end: const Offset(0, 0),
                                  duration: 300.ms,
                                ),
                              ],
                              child: Container(
                                decoration: BoxDecoration(
                                  color: themeProvider.secondaryColor,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(
                                    10,
                                  ), // Reduced padding
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Stockist Name',
                                        style: TextStyle(
                                          color: themeProvider.textColor,
                                          fontSize: 12, // Smaller font
                                        ),
                                      ),
                                      const SizedBox(
                                        height: 6,
                                      ), // Less vertical space
                                      TextFormField(
                                        controller: _stockistNameController,
                                        style: TextStyle(
                                          color: themeProvider.textColor,
                                          fontSize: 12,
                                        ),
                                        // Add input formatter for text only
                                        inputFormatters: [
                                          FilteringTextInputFormatter.allow(
                                            RegExp(r'[a-zA-Z\s]'),
                                          ),
                                        ],
                                        // Add keyboard type
                                        keyboardType: TextInputType.text,
                                        textCapitalization:
                                            TextCapitalization.words,
                                        decoration: InputDecoration(
                                          hintText: 'Enter stockist name',
                                          hintStyle: TextStyle(
                                            color: themeProvider.textColor
                                                .withOpacity(0.5),
                                            fontSize: 11,
                                          ),
                                          filled: true,
                                          fillColor: themeProvider.primaryColor,
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                            borderSide: BorderSide.none,
                                          ),
                                          contentPadding:
                                              const EdgeInsets.symmetric(
                                                vertical: 10,
                                                horizontal: 12,
                                              ), // Compact
                                        ),
                                        onChanged: (_) {
                                          setState(() {});
                                        },
                                      ),
                                      const SizedBox(height: 12),
                                      Text(
                                        'Select Product',
                                        style: TextStyle(
                                          color: themeProvider.textColor,
                                          fontSize: 12,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      DropdownButtonFormField<Product>(
                                        value: _selectedProduct,
                                        isExpanded: true,
                                        style: TextStyle(
                                          color: themeProvider.textColor,
                                          fontSize: 12,
                                        ),
                                        decoration: InputDecoration(
                                          hintText: 'Choose a product',
                                          hintStyle: TextStyle(
                                            color: themeProvider.textColor
                                                .withOpacity(0.5),
                                            fontSize: 11,
                                          ),
                                          filled: true,
                                          fillColor: themeProvider.primaryColor,
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                            borderSide: BorderSide.none,
                                          ),
                                          contentPadding:
                                              const EdgeInsets.symmetric(
                                                vertical: 10,
                                                horizontal: 12,
                                              ),
                                        ),
                                        dropdownColor:
                                            themeProvider.secondaryColor,
                                        items:
                                            _products.map((Product product) {
                                              return DropdownMenuItem<Product>(
                                                value: product,
                                                child: Row(
                                                  children: [
                                                    Expanded(
                                                      child: Text(
                                                        product.name,
                                                        style: TextStyle(
                                                          color:
                                                              themeProvider
                                                                  .textColor,
                                                          fontSize: 12,
                                                        ),
                                                        overflow:
                                                            TextOverflow
                                                                .ellipsis,
                                                        maxLines: 1,
                                                      ),
                                                    ),
                                                    Text(
                                                      ' (₹${product.dp})',
                                                      style: TextStyle(
                                                        color: themeProvider
                                                            .textColor
                                                            .withOpacity(0.8),
                                                        fontSize: 11,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              );
                                            }).toList(),
                                        onChanged: (Product? newValue) {
                                          setState(() {
                                            _selectedProduct = newValue;
                                          });
                                        },
                                      ),
                                      const SizedBox(height: 12),
                                      Text(
                                        'Number of Strips',
                                        style: TextStyle(
                                          color: themeProvider.textColor,
                                          fontSize: 12,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      TextFormField(
                                        controller: _stripsController,
                                        style: TextStyle(
                                          color: themeProvider.textColor,
                                          fontSize: 12,
                                        ),
                                        keyboardType: TextInputType.number,
                                        inputFormatters: [
                                          FilteringTextInputFormatter
                                              .digitsOnly,
                                        ],
                                        decoration: InputDecoration(
                                          hintText: 'Enter number of strips',
                                          hintStyle: TextStyle(
                                            color: themeProvider.textColor
                                                .withOpacity(0.5),
                                            fontSize: 11,
                                          ),
                                          filled: true,
                                          fillColor: themeProvider.primaryColor,
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                            borderSide: BorderSide.none,
                                          ),
                                          contentPadding:
                                              const EdgeInsets.symmetric(
                                                vertical: 10,
                                                horizontal: 12,
                                              ),
                                        ),
                                      ),
                                      const SizedBox(height: 14),
                                      SizedBox(
                                        width: double.infinity,
                                        child: ElevatedButton(
                                          onPressed: _addToCalculation,
                                          style: ElevatedButton.styleFrom(
                                            foregroundColor: Colors.white,
                                            backgroundColor: Colors.blue,
                                            padding: const EdgeInsets.symmetric(
                                              vertical:
                                                  12, // Less vertical padding
                                            ),
                                            textStyle: const TextStyle(
                                              fontSize: 15,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                          ),
                                          child: const Text(
                                            'Add to Calculation',
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          RepaintBoundary(
                            key: _tableScreenshotKey,
                            child: Container(
                              width:
                                  double.infinity, // Added to ensure full width
                              margin: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 20,
                              ),
                              decoration: BoxDecoration(
                                color: themeProvider.primaryColor.withOpacity(
                                  0.8,
                                ),
                                borderRadius: BorderRadius.circular(15),
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment:
                                    CrossAxisAlignment.center, // Center items
                                children: [
                                  if (_stockistNameController.text.isNotEmpty)
                                    Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 12, // Reduced padding
                                        horizontal: 16,
                                      ),
                                      decoration: BoxDecoration(
                                        color: themeProvider.primaryColor,
                                        borderRadius: BorderRadius.only(
                                          topLeft: Radius.circular(10),
                                          topRight: Radius.circular(10),
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.person,
                                            color: Colors.blue,
                                          ),
                                          SizedBox(width: 10),
                                          Text(
                                            'Stockist: ${_stockistNameController.text}',
                                            style: TextStyle(
                                              color: themeProvider.textColor,
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  Container(
                                    width: double.infinity,
                                    decoration: BoxDecoration(
                                      color:
                                          themeProvider.isDarkMode
                                              ? themeProvider.primaryColor
                                                  .withOpacity(0.8)
                                              : Colors
                                                  .white, // White background in light theme
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 16,
                                      horizontal:
                                          24, // Increased horizontal padding
                                    ),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          flex: 4,
                                          child: Text(
                                            'SKU Name',
                                            style: TextStyle(
                                              color:
                                                  themeProvider.isDarkMode
                                                      ? Colors.white
                                                      : Colors
                                                          .black, // Fix header color for light theme
                                              fontWeight: FontWeight.w500,
                                              fontSize:
                                                  12, // Reduced from 14 to 12 for headers
                                            ),
                                          ),
                                        ),
                                        Expanded(
                                          flex: 2,
                                          child: Text(
                                            'DP',
                                            style: TextStyle(
                                              color:
                                                  themeProvider.isDarkMode
                                                      ? Colors.white
                                                      : Colors.black,
                                              fontWeight: FontWeight.w500,
                                              fontSize:
                                                  12, // Reduced from 14 to 12 for headers
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                        ),
                                        Expanded(
                                          flex: 2,
                                          child: Text(
                                            'Strips',
                                            style: TextStyle(
                                              color:
                                                  themeProvider.isDarkMode
                                                      ? Colors.white
                                                      : Colors.black,
                                              fontWeight: FontWeight.w500,
                                              fontSize:
                                                  12, // Reduced from 14 to 12 for headers
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                        ),
                                        Expanded(
                                          flex: 3,
                                          child: Text(
                                            'Value',
                                            style: TextStyle(
                                              color:
                                                  themeProvider.isDarkMode
                                                      ? Colors.white
                                                      : Colors.black,
                                              fontWeight: FontWeight.w500,
                                              fontSize:
                                                  12, // Reduced from 14 to 12 for headers
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    decoration: BoxDecoration(
                                      color:
                                          themeProvider.isDarkMode
                                              ? themeProvider.primaryColor
                                                  .withOpacity(0.8)
                                              : Colors
                                                  .white, // White background in light theme
                                    ),
                                    child:
                                        _calculationItems.isEmpty
                                            ? Center(
                                              child:
                                                  Text(
                                                    'No products added yet',
                                                  ).animate().fade(),
                                            )
                                            : ListView.builder(
                                              shrinkWrap: true,
                                              physics:
                                                  NeverScrollableScrollPhysics(), // Prevent nested scrolling
                                              padding: EdgeInsets.zero,
                                              itemCount:
                                                  _calculationItems.length,
                                              itemBuilder: (context, index) {
                                                final item =
                                                    _calculationItems[index];
                                                // Only create the controller if it doesn't exist
                                                _stripsEditControllers
                                                    .putIfAbsent(
                                                      index,
                                                      () =>
                                                          TextEditingController(
                                                            text:
                                                                item.strips
                                                                    .toString(),
                                                          ),
                                                    );
                                                return Container(
                                                      padding:
                                                          const EdgeInsets.symmetric(
                                                            vertical: 8,
                                                            horizontal: 10,
                                                          ),
                                                      decoration: BoxDecoration(
                                                        color:
                                                            themeProvider
                                                                    .isDarkMode
                                                                ? themeProvider
                                                                    .primaryColor
                                                                    .withOpacity(
                                                                      0.8,
                                                                    )
                                                                : Colors.white,
                                                        border: Border(
                                                          bottom: BorderSide(
                                                            color:
                                                                themeProvider
                                                                        .isDarkMode
                                                                    ? Colors
                                                                        .white
                                                                        .withOpacity(
                                                                          0.1,
                                                                        )
                                                                    : Colors
                                                                        .black
                                                                        .withOpacity(
                                                                          0.1,
                                                                        ),
                                                            width: 0.5,
                                                          ),
                                                        ),
                                                      ),
                                                      child: Row(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .center,
                                                        children: [
                                                          // Delete Icon
                                                          GestureDetector(
                                                            onTap:
                                                                () =>
                                                                    _removeItem(
                                                                      index,
                                                                    ),
                                                            child: Padding(
                                                              padding:
                                                                  const EdgeInsets.only(
                                                                    right: 8.0,
                                                                  ),
                                                              child: Icon(
                                                                Icons.close,
                                                                color: Colors
                                                                    .red
                                                                    .withOpacity(
                                                                      0.7,
                                                                    ),
                                                                size: 18,
                                                              ),
                                                            ),
                                                          ),
                                                          // Product name
                                                          Expanded(
                                                            flex: 4,
                                                            child: Text(
                                                              item.product.name,
                                                              style: TextStyle(
                                                                color:
                                                                    themeProvider
                                                                            .isDarkMode
                                                                        ? Colors
                                                                            .white
                                                                        : Colors
                                                                            .black,
                                                                fontSize: 12,
                                                              ),
                                                              overflow:
                                                                  TextOverflow
                                                                      .ellipsis,
                                                            ),
                                                          ),
                                                          // DP value
                                                          Expanded(
                                                            flex: 2,
                                                            child: Text(
                                                              '₹${item.product.dp}',
                                                              style: TextStyle(
                                                                color:
                                                                    themeProvider
                                                                            .isDarkMode
                                                                        ? Colors
                                                                            .white
                                                                        : Colors
                                                                            .black,
                                                                fontSize: 12,
                                                              ),
                                                              textAlign:
                                                                  TextAlign
                                                                      .center,
                                                            ),
                                                          ),
                                                          // Strips value
                                                          Expanded(
                                                            flex: 2,
                                                            child: GestureDetector(
                                                              onTap: () {
                                                                setState(() {
                                                                  _editingStripsIndex =
                                                                      index;
                                                                });
                                                              },
                                                              child:
                                                                  _editingStripsIndex ==
                                                                          index
                                                                      ? TextFormField(
                                                                        controller:
                                                                            _stripsEditControllers[index],
                                                                        keyboardType:
                                                                            TextInputType.number,
                                                                        inputFormatters: [
                                                                          FilteringTextInputFormatter
                                                                              .digitsOnly,
                                                                        ],
                                                                        autofocus:
                                                                            true,
                                                                        style: TextStyle(
                                                                          color:
                                                                              themeProvider.isDarkMode
                                                                                  ? Colors.white
                                                                                  : Colors.black,
                                                                          fontSize:
                                                                              12,
                                                                        ),
                                                                        textAlign:
                                                                            TextAlign.center,
                                                                        onFieldSubmitted: (
                                                                          value,
                                                                        ) {
                                                                          final newStrips = int.tryParse(
                                                                            value,
                                                                          );
                                                                          if (newStrips !=
                                                                                  null &&
                                                                              newStrips >
                                                                                  0) {
                                                                            setState(() {
                                                                              final newValue =
                                                                                  item.product.dp *
                                                                                  newStrips;
                                                                              _calculationItems[index] = CalculationItem(
                                                                                product:
                                                                                    item.product,
                                                                                strips:
                                                                                    newStrips,
                                                                                value:
                                                                                    newValue,
                                                                                stockistName:
                                                                                    item.stockistName,
                                                                              );
                                                                              _editingStripsIndex =
                                                                                  null;
                                                                              _calculateTotal();
                                                                            });
                                                                          }
                                                                        },
                                                                      )
                                                                      : Text(
                                                                        item.strips
                                                                            .toString(),
                                                                        style: TextStyle(
                                                                          color:
                                                                              themeProvider.isDarkMode
                                                                                  ? Colors.white
                                                                                  : Colors.black,
                                                                          fontSize:
                                                                              12,
                                                                        ),
                                                                        textAlign:
                                                                            TextAlign.center,
                                                                      ),
                                                            ),
                                                          ),
                                                          // Total value
                                                          Expanded(
                                                            flex: 3,
                                                            child: Text(
                                                              '₹${item.value.toStringAsFixed(2)}',
                                                              style: TextStyle(
                                                                color:
                                                                    themeProvider
                                                                            .isDarkMode
                                                                        ? Colors
                                                                            .white
                                                                        : Colors
                                                                            .black,
                                                                fontSize: 12,
                                                              ),
                                                              textAlign:
                                                                  TextAlign
                                                                      .center,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    )
                                                    .animate()
                                                    .fadeIn(
                                                      duration: 300.ms,
                                                      delay: (50 * index).ms,
                                                    )
                                                    .slideY(
                                                      begin: 0.2,
                                                      end: 0,
                                                      curve:
                                                          Curves.easeOutQuart,
                                                      duration: 400.ms,
                                                      delay: (50 * index).ms,
                                                    )
                                                    .custom(
                                                      duration: 200.ms,
                                                      builder:
                                                          (
                                                            context,
                                                            value,
                                                            child,
                                                          ) => Opacity(
                                                            opacity:
                                                                _calculationItems
                                                                        .isEmpty
                                                                    ? 0.0
                                                                    : 1.0,
                                                            child: child,
                                                          ),
                                                    );
                                              },
                                            ),
                                  ),
                                  Column(
                                    children: [
                                      Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 15,
                                          horizontal:
                                              24, // Increased horizontal padding
                                        ),
                                        decoration: BoxDecoration(
                                          color: themeProvider.primaryColor,
                                          borderRadius: BorderRadius.only(
                                            bottomLeft: Radius.circular(10),
                                            bottomRight: Radius.circular(10),
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            Expanded(
                                              flex: 3,
                                              child: Text(
                                                'Total',
                                                style: TextStyle(
                                                  color:
                                                      themeProvider.textColor,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 16,
                                                ),
                                              ),
                                            ),
                                            Expanded(
                                              flex: 2,
                                              child: SizedBox(),
                                            ),
                                            Expanded(
                                              flex: 3,
                                              child: Text(
                                                '₹${_totalValue.toStringAsFixed(2)}',
                                                style: TextStyle(
                                                  color:
                                                      themeProvider.textColor,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 16,
                                                ),
                                                textAlign: TextAlign.center,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                          if (_calculationItems.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 16.0),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: [
                                  ElevatedButton.icon(
                                    onPressed: _clearAll,
                                    icon: const Icon(Icons.clear_all),
                                    label: const Text('Clear All'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 20,
                                        vertical: 10,
                                      ),
                                    ),
                                  ),
                                  ElevatedButton.icon(
                                    onPressed: _shareScreenshot,
                                    icon: const Icon(Icons.share),
                                    label: const Text('Share'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 20,
                                        vertical: 10,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          SizedBox(
                            height: MediaQuery.of(context).padding.bottom,
                          ), // Add safe area padding
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CalculationItem {
  final Product product;
  final String stockistName;
  final int strips;
  final double value;

  CalculationItem({
    required this.product,
    required this.strips,
    required this.value,
    required this.stockistName,
  });
}
