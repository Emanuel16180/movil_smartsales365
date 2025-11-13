// lib/screens/initial_home_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:proyect_movil/screens/profile_screen.dart'; // <-- Importa la nueva pantalla de perfil
import 'package:proyect_movil/screens/cart_modal_screen.dart'; // <-- Importa la pantalla del carrito
import 'package:sizer/sizer.dart'; // <-- Importa Sizer
import '../models/product_model.dart';
import '../models/category_model.dart';
import '../services/cart_service.dart';
import '../services/product_service.dart';
import '../services/category_service.dart';
import '../models/product_response_model.dart';
import '../widgets/product_card.dart';

class InitialHomeScreen extends StatefulWidget {
  const InitialHomeScreen({super.key});

  @override
  State<InitialHomeScreen> createState() => _InitialHomeScreenState();
}

class _InitialHomeScreenState extends State<InitialHomeScreen> {
  late Future<List<Category>> _categoriesFuture;
  final ProductService _productService = ProductService();

  late stt.SpeechToText _speech;
  bool _isListening = false;
  final TextEditingController _searchController = TextEditingController();

  List<Product> _products = [];
  String _searchQuery = '';
  int? _selectedCategoryId;

  final ScrollController _scrollController = ScrollController();
  bool _isLoading = true;
  bool _isLoadingMore = false;
  String? _nextPageUrl;

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    _categoriesFuture = CategoryService().fetchCategories();
    _fetchProducts();

    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 100) {
        _loadMoreProducts();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    _speech.stop();
    super.dispose();
  }

  // --- LÓGICA DE VOZ (Sin cambios) ---
  void _listen() async {
    if (!_isListening) {
      bool available = await _speech.initialize(
        onError: (val) => print('onError: $val'),
        onStatus: (val) {
          if (val == 'done') {
            setState(() => _isListening = false);
            _processVoiceCommand(_searchController.text);
          }
        },
      );
      if (available) {
        setState(() => _isListening = true);
        _speech.listen(
          onResult: (val) => setState(() {
            _searchController.text = val.recognizedWords;
          }),
        );
      }
    } else {
      setState(() => _isListening = false);
      _speech.stop();
    }
  }

  void _processVoiceCommand(String text) {
    final command = text.toLowerCase();
    const keyword = "comprar ";
    if (command.startsWith(keyword)) {
      final productName = text.substring(keyword.length);
      _findAndAddToCart(productName);
    } else {
      _onSearchChanged(text);
    }
  }

  void _findAndAddToCart(String productName) {
    if (productName.isEmpty) return;
    final query = productName.toLowerCase();
    Product? foundProduct;
    try {
      foundProduct = _products.firstWhere(
        (p) => p.name.toLowerCase().contains(query),
      );
    } catch (e) {
      foundProduct = null;
    }
    if (!mounted) return;
    if (foundProduct != null) {
      final cart = Provider.of<CartService>(context, listen: false);
      cart.addToCart(foundProduct);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('"${foundProduct.name}" añadido al carrito!'),
          backgroundColor: Colors.green,
        ),
      );
      _searchController.clear();
      _onSearchChanged('');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No se encontró un producto llamado "$productName"'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // --- LÓGICA DE PRODUCTOS (Sin cambios) ---
  Future<void> _fetchProducts() async {
    setState(() {
      _isLoading = true;
      _products.clear();
      _nextPageUrl = null;
    });
    try {
      final ProductListResponse response = await _productService.fetchProducts(
        categoryId: _selectedCategoryId,
        search: _searchQuery.isNotEmpty ? _searchQuery : null,
      );
      if(mounted) {
        setState(() {
          _products = response.products;
          _nextPageUrl = response.nextUrl;
          _isLoading = false;
        });
      }
    } catch (e) {
      if(mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar productos: $e')),
        );
      }
    }
  }

  Future<void> _loadMoreProducts() async {
    if (_isLoadingMore || _nextPageUrl == null) return;
    if(mounted) setState(() { _isLoadingMore = true; });
    try {
      final ProductListResponse response = await _productService.fetchProducts(
        url: _nextPageUrl,
        categoryId: _selectedCategoryId,
        search: _searchQuery.isNotEmpty ? _searchQuery : null,
      );
      if(mounted) {
        setState(() {
          _products.addAll(response.products);
          _nextPageUrl = response.nextUrl;
          _isLoadingMore = false;
        });
      }
    } catch (e) {
      if(mounted) setState(() { _isLoadingMore = false; });
    }
  }

  void _onSearchChanged(String value) {
    setState(() {
      _searchQuery = value;
    });
    _fetchProducts();
  }

  void _onCategorySelected(int? categoryId) {
    setState(() {
      _selectedCategoryId = categoryId;
    });
    _fetchProducts();
  }

  // --- WIDGET NUEVO: Encabezado ---
  Widget _buildHeader() {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
      child: Column(
        children: [
          // Fila de Título y Perfil
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'SmartSales365',
                style: theme.textTheme.headlineMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications_outlined),
                    onPressed: () {
                      // TODO: Lógica de notificaciones
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.shopping_cart_outlined),
                    onPressed: () {
                       Navigator.push(
                          context,
                          MaterialPageRoute(
                            fullscreenDialog: true,
                            builder: (context) => const CartModalScreen(),
                          ),
                        );
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.person_outline),
                    onPressed: () {
                      // --- NAVEGACIÓN A PERFIL ---
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ProfileScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: 2.h),
          // Fila de Búsqueda y Filtros
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _searchController,
                  onChanged: _onSearchChanged,
                  decoration: InputDecoration(
                    hintText: 'Buscar productos...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: IconButton(
                      icon: Icon(_isListening ? Icons.mic : Icons.mic_none),
                      onPressed: _listen,
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              SizedBox(width: 2.w),
              IconButton(
                style: IconButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: theme.colorScheme.onPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.tune), // Icono de filtros
                onPressed: () {
                  // TODO: Lógica para filtros
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- WIDGET NUEVO: Categorías (Estilo actualizado) ---
  Widget _buildCategories() {
    return FutureBuilder<List<Category>>(
      future: _categoriesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
              height: 50, child: Center(child: CircularProgressIndicator()));
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const SizedBox.shrink(); // No mostrar nada si no hay
        }

        final categories = snapshot.data!;
        return SizedBox(
          height: 50,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: categories.length + 1, // +1 para "Todos"
            padding: EdgeInsets.symmetric(horizontal: 4.w),
            itemBuilder: (context, index) {
              final bool isAllCategory = index == 0;
              final category = isAllCategory ? null : categories[index - 1];
              final isSelected = (isAllCategory && _selectedCategoryId == null) ||
                                 (!isAllCategory && _selectedCategoryId == category!.id);

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: ChoiceChip(
                  label: Text(isAllCategory ? "Todos" : category!.name),
                  selected: isSelected,
                  backgroundColor: Colors.white,
                  selectedColor: Theme.of(context).colorScheme.primary,
                  labelStyle: TextStyle(
                    color: isSelected
                        ? Colors.white
                        : Colors.black87,
                  ),
                  onSelected: (_) => _onCategorySelected(
                    isAllCategory ? null : category!.id,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(
                      color: isSelected
                          ? Theme.of(context).colorScheme.primary
                          : Colors.grey[300]!,
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Esta pantalla ahora es un Scaffold
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            // 1. El nuevo encabezado
            _buildHeader(),
            
            // 2. Las nuevas categorías
            _buildCategories(),
            SizedBox(height: 2.h),

            // 3. La lista de productos
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _products.isEmpty
                      ? const Center(child: Text("No se encontraron productos"))
                      : GridView.builder(
                          controller: _scrollController,
                          itemCount: _products.length + (_isLoadingMore ? 1 : 0),
                          padding: EdgeInsets.symmetric(horizontal: 4.w),
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 0.65, // Ajustado para el nuevo card
                            crossAxisSpacing: 3.w,
                            mainAxisSpacing: 3.w,
                          ),
                          itemBuilder: (context, index) {
                            if (index == _products.length) {
                              return const Center(child: CircularProgressIndicator());
                            }
                            return ProductCard(product: _products[index]);
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}