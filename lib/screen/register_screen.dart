import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mini_flutter_proyect/navigation/routes.dart';
import 'package:mini_flutter_proyect/services/realtime_database_service.dart';
import 'package:mini_flutter_proyect/services/storage_service.dart';
import 'package:mini_flutter_proyect/utils/app_colors.dart';
import 'package:mini_flutter_proyect/utils/image_utils.dart';
import 'package:permission_handler/permission_handler.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _idController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool obscurePassword = true;
  bool obscureConfirmPassword = true;

  String? _emailError;
  String? _passwordError;
  String? _confirmPasswordError;
  bool _isFormValid = false;
  bool _isSubmitting = false;
  XFile? _selectedImage;

  bool get _allFieldsFilled =>
      _nameController.text.isNotEmpty &&
      _lastNameController.text.isNotEmpty &&
      _emailController.text.isNotEmpty &&
      _idController.text.isNotEmpty &&
      _passwordController.text.isNotEmpty &&
      _confirmPasswordController.text.isNotEmpty;

  @override
  void dispose() {
    _nameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _idController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 34, vertical: 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 24),
                Center(
                  child: Text(
                    'Create Account',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                const Center(
                  child: Text(
                    'All fields are required',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                _InputField(
                  controller: _nameController,
                  label: 'Name',
                  hintText: 'Name',
                  prefixIcon: Icons.person_outline,
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 16),
                _InputField(
                  controller: _lastNameController,
                  label: 'Last name',
                  hintText: 'Last name',
                  prefixIcon: Icons.person_outline,
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 16),
                _InputField(
                  controller: _emailController,
                  label: 'Email address',
                  hintText: 'Email address',
                  prefixIcon: Icons.mail_outline,
                  keyboardType: TextInputType.emailAddress,
                  onChanged: (_) => _revalidate(),
                  errorText: _emailError,
                ),
                const SizedBox(height: 16),
                Text(
                  'Contact image',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                _ImagePickerRow(
                  selectedImage: _selectedImage,
                  onImageSelected: (XFile? image) {
                    setState(() {
                      _selectedImage = image;
                    });
                  },
                ),
                const SizedBox(height: 16),
                _InputField(
                  controller: _idController,
                  label: 'ID number',
                  hintText: 'ID number',
                  prefixIcon: Icons.badge_outlined,
                  keyboardType: TextInputType.number,
                  onChanged: (_) => _revalidate(),
                ),
                const SizedBox(height: 16),
                _InputField(
                  controller: _passwordController,
                  label: 'Password',
                  hintText: 'Password',
                  prefixIcon: Icons.lock_outline,
                  obscureText: obscurePassword,
                  onChanged: (_) => _revalidate(),
                  errorText: _passwordError,
                  suffixIcon: IconButton(
                    onPressed: () {
                      setState(() {
                        obscurePassword = !obscurePassword;
                      });
                    },
                    icon: Icon(
                      obscurePassword ? Icons.visibility_off : Icons.visibility,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                _InputField(
                  controller: _confirmPasswordController,
                  label: 'Confirm Password',
                  hintText: 'Confirm Password',
                  prefixIcon: Icons.lock_outline,
                  obscureText: obscureConfirmPassword,
                  onChanged: (_) => _revalidate(),
                  errorText: _confirmPasswordError,
                  suffixIcon: IconButton(
                    onPressed: () {
                      setState(() {
                        obscureConfirmPassword = !obscureConfirmPassword;
                      });
                    },
                    icon: Icon(
                      obscureConfirmPassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3BB273),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  onPressed:
                      _isFormValid && !_isSubmitting ? _submitForm : null,
                  child:
                      _isSubmitting
                          ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation(Colors.white),
                            ),
                          )
                          : const Text(
                            'Create Account',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Already have an account?',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: const Text('Sign In here'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submitForm() async {
    setState(() {
      _emailError = null;
      _passwordError = null;
      _confirmPasswordError = null;
    });

    if (!_validateForm()) {
      setState(() {
        _isFormValid = false;
      });
      return;
    }

    // Validar que hay imagen seleccionada
    if (_selectedImage == null) {
      _showErrorToast('Por favor, selecciona una imagen de perfil.');
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    try {
      // Comprimir la imagen
      XFile compressedImage;
      try {
        final File imageFile = File(_selectedImage!.path);
        compressedImage = await ImageUtils.compressImage(
          imageFile: imageFile,
          quality: 30,
        );
      } catch (e) {
        if (!mounted) return;
        setState(() {
          _isSubmitting = false;
        });
        _showErrorToast(
          'Error al procesar la imagen. Por favor, selecciona una imagen diferente.',
        );
        return;
      }

      // Crear usuario en Firebase Auth
      final credential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);

      final uid = credential.user?.uid;
      if (uid == null) {
        if (!mounted) return;
        setState(() {
          _isSubmitting = false;
        });
        _showErrorToast(
          'Error al crear la cuenta. Por favor, intenta de nuevo.',
        );
        return;
      }

      // Subir imagen a Firebase Storage
      String imageUrl;
      try {
        imageUrl = await StorageService.uploadUserProfileImage(
          uid: uid,
          imageFile: compressedImage,
        );
      } catch (e) {
        // Si falla la subida, eliminar el usuario creado
        await credential.user?.delete();
        if (!mounted) return;
        setState(() {
          _isSubmitting = false;
        });
        _showErrorToast(
          'Error al procesar la imagen. Por favor, selecciona una imagen diferente.',
        );
        return;
      }

      // Guardar información en Firestore
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'name': _nameController.text.trim(),
        'lastName': _lastNameController.text.trim(),
        'email': email,
        'idNumber': _idController.text.trim(),
        'imageUrl': imageUrl,
      });

      await RealtimeDatabaseService.initializeUserDocument();

      if (!mounted) return;
      Navigator.pushReplacementNamed(context, Routes.login);
    } on FirebaseAuthException catch (e) {
      String message = 'An unknown error occurred.';
      if (e.code == 'weak-password') {
        message = 'The password provided is too weak.';
      } else if (e.code == 'email-already-in-use') {
        message = 'The account already exists for that email.';
      } else if (e.code == 'invalid-email') {
        message = 'The email address is badly formatted.';
      }
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
        _showErrorDialog(message);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
        _showErrorToast(
          'Error al procesar la imagen. Por favor, selecciona una imagen diferente.',
        );
      }
    }
  }

  void _showErrorToast(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 5),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _revalidate() {
    setState(() {
      _emailError = null;
      _passwordError = null;
      _confirmPasswordError = null;
      _isFormValid = _validateForm();
    });
  }

  bool _validateForm() {
    if (!_allFieldsFilled) return false;

    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!emailRegex.hasMatch(email)) {
      _emailError = 'Enter a valid email address';
    }

    if (password.length < 6) {
      _passwordError = 'Password must be at least 6 characters';
    }

    if (password != confirmPassword) {
      _confirmPasswordError = 'Passwords do not match';
    }

    return _emailError == null &&
        _passwordError == null &&
        _confirmPasswordError == null;
  }

  void _showErrorDialog(String message) {
    if (!mounted) return;
    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Registration Error'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }
}

class _InputField extends StatelessWidget {
  const _InputField({
    required this.controller,
    required this.label,
    required this.hintText,
    required this.prefixIcon,
    required this.onChanged,
    this.suffixIcon,
    this.obscureText = false,
    this.keyboardType,
    this.errorText,
  });

  final TextEditingController controller;
  final String label;
  final String hintText;
  final IconData prefixIcon;
  final Widget? suffixIcon;
  final bool obscureText;
  final TextInputType? keyboardType;
  final String? errorText;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: obscureText,
          onChanged: onChanged,
          decoration: InputDecoration(
            prefixIcon: Icon(prefixIcon, color: AppColors.textSecondary),
            suffixIcon: suffixIcon,
            hintText: hintText,
            errorText: errorText,
            filled: true,
            fillColor: AppColors.surface,
            contentPadding: const EdgeInsets.symmetric(vertical: 16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(24),
              borderSide: BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(24),
              borderSide: BorderSide(color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(24),
              borderSide: const BorderSide(
                color: AppColors.primary,
                width: 1.5,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ImagePickerRow extends StatefulWidget {
  const _ImagePickerRow({
    required this.selectedImage,
    required this.onImageSelected,
  });

  final XFile? selectedImage;
  final ValueChanged<XFile?> onImageSelected;

  @override
  State<_ImagePickerRow> createState() => _ImagePickerRowState();
}

enum _CameraPermissionUiState { none, showRationale, denied }

class _ImagePickerRowState extends State<_ImagePickerRow> {
  final ImagePicker _picker = ImagePicker();

  _CameraPermissionUiState _cameraUiState = _CameraPermissionUiState.none;

  Future<void> _handleCameraTap() async {
    if (!Platform.isAndroid) {
      await _openCamera();
      return;
    }

    final status = await Permission.camera.status;

    // Ya concedido -> abrir cámara directamente.
    if (status.isGranted) {
      setState(() {
        _cameraUiState = _CameraPermissionUiState.none;
      });
      await _openCamera();
      return;
    }

    // Permanente denegado -> mostrar mensaje de ir a configuración.
    if (status.isPermanentlyDenied) {
      setState(() {
        _cameraUiState = _CameraPermissionUiState.denied;
      });
      return;
    }

    // Estado inicial o denegado normal -> pedir permiso.
    final result = await Permission.camera.request();

    if (result.isGranted) {
      setState(() {
        _cameraUiState = _CameraPermissionUiState.none;
      });
      await _openCamera();
    } else if (result.isPermanentlyDenied) {
      setState(() {
        _cameraUiState = _CameraPermissionUiState.denied;
      });
    } else {
      // Denegado pero no permanente -> mostrar texto tipo rationale.
      setState(() {
        _cameraUiState = _CameraPermissionUiState.showRationale;
      });
    }
  }

  Future<void> _openCamera() async {
    final XFile? photo = await _picker.pickImage(source: ImageSource.camera);
    if (photo == null) return;

    try {
      // Comprimir la imagen con quality: 30
      final File imageFile = File(photo.path);
      final XFile compressedImage = await ImageUtils.compressImage(
        imageFile: imageFile,
        quality: 30,
      );
      widget.onImageSelected(compressedImage);
    } catch (e) {
      // Si falla la compresión, no cargar ninguna imagen y mostrar error
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al cargar la imagen: ${e.toString()}'),
          duration: const Duration(seconds: 4),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _handleGalleryTap() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image == null) return;

    try {
      // Comprimir la imagen con quality: 30
      final File imageFile = File(image.path);
      final XFile compressedImage = await ImageUtils.compressImage(
        imageFile: imageFile,
        quality: 30,
      );
      widget.onImageSelected(compressedImage);
    } catch (e) {
      // Si falla la compresión, no cargar ninguna imagen y mostrar error
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al cargar la imagen: ${e.toString()}'),
          duration: const Duration(seconds: 4),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _repeatImage() async {
    await _handleCameraTap();
  }

  Future<void> _pickAnotherFromGallery() async {
    await _handleGalleryTap();
  }

  @override
  Widget build(BuildContext context) {
    String? cameraMessage;
    switch (_cameraUiState) {
      case _CameraPermissionUiState.showRationale:
        cameraMessage =
            'Es importante dar permisos para acceder a la cámara, ya que el usuario necesita tomarse una foto para poder identificarlo.';
        break;
      case _CameraPermissionUiState.denied:
        cameraMessage =
            'Debe dirigirse a las configuraciones de la aplicación para habilitar la cámara, en caso de querer usarla.';
        break;
      case _CameraPermissionUiState.none:
        cameraMessage = null;
        break;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.selectedImage == null)
          Row(
            children: [
              Expanded(
                child: _PickerButton(
                  icon: Icons.photo_library_outlined,
                  label: 'Gallery',
                  onTap: _handleGalleryTap,
                ),
              ),
              Container(
                width: 1,
                height: 56,
                margin: const EdgeInsets.symmetric(horizontal: 12),
                color: AppColors.border,
              ),
              Expanded(
                child: _PickerButton(
                  icon: Icons.photo_camera_outlined,
                  label: 'Camera',
                  onTap: _handleCameraTap,
                ),
              ),
            ],
          ),
        if (cameraMessage != null) ...[
          const SizedBox(height: 8),
          Text(
            cameraMessage,
            style: const TextStyle(color: Colors.red, fontSize: 13),
          ),
        ],
        if (widget.selectedImage != null) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(
                    File(widget.selectedImage!.path),
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: double.infinity,
                        child: TextButton(
                          onPressed: _repeatImage,
                          child: const Text('Repetir imagen'),
                        ),
                      ),
                      SizedBox(
                        width: double.infinity,
                        child: TextButton(
                          onPressed: _pickAnotherFromGallery,
                          child: const Text('Escoger otra foto'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _PickerButton extends StatelessWidget {
  const _PickerButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: AppColors.textSecondary),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
