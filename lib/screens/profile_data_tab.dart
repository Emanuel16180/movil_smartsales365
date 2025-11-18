// lib/screens/profile_data_tab.dart
import 'package:flutter/material.dart';
import 'package:proyect_movil/models/user_model.dart';
import 'package:proyect_movil/services/user_service.dart';

class ProfileDataTab extends StatefulWidget {
  const ProfileDataTab({super.key});

  @override
  State<ProfileDataTab> createState() => _ProfileDataTabState();
}

class _ProfileDataTabState extends State<ProfileDataTab> {
  final UserService _userService = UserService();
  late Future<UserModel> _profileFuture;
  bool _isEditing = false;
  bool _isSaving = false;

  final _formKey = GlobalKey<FormState>();
  // Inicializamos inmediatamente para evitar LateInitializationError
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  void _loadProfile() {
    _profileFuture = _userService.getUserProfile();
    _profileFuture.then((user) {
      if (mounted) {
        // Actualizamos los controladores solo si el widget sigue vivo
        _firstNameController.text = user.firstName ?? '';
        _lastNameController.text = user.lastName ?? '';
        _phoneController.text = user.phoneNumber ?? '';
        _addressController.text = user.address ?? '';
      }
    }).catchError((error) {
      // Manejo silencioso de errores aquí, ya lo muestra el FutureBuilder
    });
  }

  void _toggleEdit() {
    setState(() {
      _isEditing = !_isEditing;
    });
  }

  Future<void> _saveProfile() async {
    if (_formKey.currentState == null || !_formKey.currentState!.validate()) {
      return;
    }
      
    setState(() => _isSaving = true);
    
    Map<String, dynamic> updatedData = {
      'first_name': _firstNameController.text,
      'last_name': _lastNameController.text,
      'phone_number': _phoneController.text,
      'address': _addressController.text,
    };

    try {
      await _userService.updateUserProfile(updatedData);
      if(mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Perfil actualizado con éxito'), backgroundColor: Colors.green),
        );
      }
      _loadProfile(); // Recargar datos
      if(mounted) {
        setState(() {
          _isEditing = false;
          _isSaving = false;
        });
      }
    } catch (e) {
        if(mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al guardar: $e'), backgroundColor: Colors.red),
        );
        }
      if(mounted) setState(() => _isSaving = false);
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<UserModel>(
      future: _profileFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text('Error al cargar el perfil: ${snapshot.error}'),
            ),
          );
        }
        if (!snapshot.hasData) {
          return const Center(child: Text('No se encontró el perfil.'));
        }

        final user = snapshot.data!;
        return _buildProfileView(user);
      },
    );
  }

  Widget _buildProfileView(UserModel user) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Form(
        key: _formKey,
        child: Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          color: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Información de la cuenta',
                      style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    IconButton(
                      icon: Icon(_isEditing ? Icons.close : Icons.edit_outlined, color: theme.colorScheme.primary),
                      onPressed: _toggleEdit,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildInfoRow(
                  context,
                  icon: Icons.person_outline,
                  label: 'Nombre',
                  value: user.firstName ?? '',
                  controller: _firstNameController,
                ),
                const Divider(height: 24),
                _buildInfoRow(
                  context,
                  icon: Icons.person_outline,
                  label: 'Apellido',
                  value: user.lastName ?? '',
                  controller: _lastNameController,
                ),
                const Divider(height: 24),
                _buildInfoRow(
                  context,
                  icon: Icons.mail_outline,
                  label: 'Correo',
                  value: user.email,
                  isEditable: false, 
                ),
                const Divider(height: 24),
                  _buildInfoRow(
                  context,
                  icon: Icons.phone_outlined,
                  label: 'Teléfono',
                  value: user.phoneNumber ?? '',
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                ),
                  const Divider(height: 24),
                  _buildInfoRow(
                  context,
                  icon: Icons.home_outlined,
                  label: 'Dirección',
                  value: user.address ?? '',
                  controller: _addressController,
                  keyboardType: TextInputType.streetAddress,
                ),
                if (_isEditing) ...[
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: _isSaving
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Icon(Icons.save_outlined),
                      label: Text(_isSaving ? 'Guardando...' : 'Guardar Cambios'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)
                        ),
                      ),
                      onPressed: _isSaving ? null : _saveProfile,
                    ),
                  )
                ]
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    TextEditingController? controller,
    bool isEditable = true,
    TextInputType? keyboardType,
  }) {
    final theme = Theme.of(context);
    bool isEditingThisField = _isEditing && isEditable && controller != null;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: Colors.grey[600], size: 20),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
              ),
              const SizedBox(height: 4),
              if (isEditingThisField)
                TextFormField(
                  controller: controller,
                  keyboardType: keyboardType,
                  decoration: const InputDecoration(
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(vertical: 4),
                    border: UnderlineInputBorder(),
                  ),
                  validator: (val) {
                    // Validación opcional: permitir vacío si así lo deseas
                    return null;
                  },
                )
              else
                Text(
                  value.isEmpty ? 'No especificado' : value,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: value.isEmpty ? Colors.grey[500] : Colors.black
                  ),
                ),
            ],
          ),
        )
      ],
    );
  }
}