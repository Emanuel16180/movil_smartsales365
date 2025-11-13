import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // <-- Necesario para el carrito
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../models/product_model.dart'; // <-- Necesario
import '../models/category_model.dart';
import '../services/cart_service.dart'; // <-- Necesario
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

  // --- LÓGICA DE VOZ MEJORADA ---

  void _listen() async {
    if (!_isListening) {
      bool available = await _speech.initialize(
        onError: (val) => print('onError: $val'),
        // Detecta cuándo el usuario deja de hablar
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
      // Si el usuario toca el botón mientras escucha, detiene
      setState(() => _isListening = false);
      _speech.stop();
    }
  }

  // Procesa el texto final de la voz
  void _processVoiceCommand(String text) {
    final command = text.toLowerCase();
    const keyword = "comprar "; // La palabra clave que buscamos

    if (command.startsWith(keyword)) {
      // Es un comando de compra
      final productName = text.substring(keyword.length);
      _findAndAddToCart(productName);
    } else {
      // No es un comando, es una búsqueda normal
      _onSearchChanged(text);
    }
  }

  // Busca el producto en la lista y lo añade al carrito
  void _findAndAddToCart(String productName) {
    if (productName.isEmpty) return;

    final query = productName.toLowerCase();
    Product? foundProduct;

    try {
      // Busca el primer producto en la lista que contenga el nombre dicho
      foundProduct = _products.firstWhere(
        (p) => p.name.toLowerCase().contains(query),
      );
    } catch (e) {
      foundProduct = null;
    }

    if (foundProduct != null) {
      // Producto encontrado: Añadir al carrito
      final cart = Provider.of<CartService>(context, listen: false);
      cart.addToCart(foundProduct);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('"${foundProduct.name}" añadido al carrito!'),
          backgroundColor: Colors.green,
        ),
      );
      // Limpia la búsqueda
      _searchController.clear();
      _onSearchChanged(''); // Opcional: refresca la lista

    } else {
      // Producto no encontrado
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No se encontró un producto llamado "$productName"'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // --- FIN DE LÓGICA DE VOZ ---

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
      setState(() {
        _products = response.products;
        _nextPageUrl = response.nextUrl;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cargar productos: $e')),
      );
    }
  }

  Future<void> _loadMoreProducts() async {
    if (_isLoadingMore || _nextPageUrl == null) return;
    setState(() { _isLoadingMore = true; });

    try {
      final ProductListResponse response = await _productService.fetchProducts(
        url: _nextPageUrl,
        categoryId: _selectedCategoryId,
        search: _searchQuery.isNotEmpty ? _searchQuery : null,
      );
      setState(() {
        _products.addAll(response.products);
        _nextPageUrl = response.nextUrl;
        _isLoadingMore = false;
      });
    } catch (e) {
      setState(() { _isLoadingMore = false; });
    }
  }

  // Se llama cuando el usuario escribe en la barra
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

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(10),
      child: Column(
        children: [
          TextFormField(
            controller: _searchController,
            // Importante: El onChanged llama a la búsqueda normal
            onChanged: _onSearchChanged,
            decoration: InputDecoration(
              hintText: 'Buscar o decir "Comprar..."',
              prefixIcon: const Icon(Icons.search, color: Color(0xFF8B1E3F)),
              suffixIcon: IconButton(
                icon: Icon(_isListening ? Icons.mic : Icons.mic_none),
                color: const Color(0xFF8B1E3F),
                onPressed: _listen,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xFF8B1E3F)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide:
                    const BorderSide(color: Color(0xFF8B1E3F), width: 2),
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Categorías (sin cambios)
          FutureBuilder<List<Category>>(
            future: _categoriesFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SizedBox(
                    height: 40,
                    child: Center(child: CircularProgressIndicator()));
              }
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const SizedBox(
                    height: 40, child: Text("No se encontraron categorías"));
              }

              final categories = snapshot.data!;
              return SizedBox(
                height: 40,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: categories.length + 1,
                  itemBuilder: (context, index) {
                    final isSelected = index == 0
                        ? _selectedCategoryId == null
                        : _selectedCategoryId == categories[index - 1].id;

                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: ChoiceChip(
                        label: Text(
                            index == 0 ? "Todos" : categories[index - 1].name),
                        selected: isSelected,
                        selectedColor: const Color(0xFF8B1E3F),
                        backgroundColor: const Color(0xFFEFD4D5),
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : Colors.black87,
                        ),
                        onSelected: (_) => _onCategorySelected(
                            index == 0 ? null : categories[index - 1].id),
                      ),
                    );
                  },
                ),
              );
            },
          ),
          const SizedBox(height: 10),

          // Lista de Productos (sin cambios)
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _products.isEmpty
                    ? const Center(child: Text("No se encontraron productos"))
                    : GridView.builder(
                        controller: _scrollController,
                        itemCount: _products.length,
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.7,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                        ),
                        itemBuilder: (context, index) {
                          return ProductCard(product: _products[index]);
                        },
                      ),
          ),
          if (_isLoadingMore)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: CircularProgressIndicator(),
            ),
        ],
      ),
    );
  }
}