import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../features/auth/data/models/user_profile_model.dart';

import '../../../features/auth/providers/auth_repository_provider.dart';
import 'site_manager_management_screen.dart';

/// Edit Site Manager Screen for Admins
class EditSiteManagerScreen extends ConsumerStatefulWidget {
  final UserProfileModel manager;

  const EditSiteManagerScreen({super.key, required this.manager});

  @override
  ConsumerState<EditSiteManagerScreen> createState() =>
      _EditSiteManagerScreenState();
}

class _EditSiteManagerScreenState extends ConsumerState<EditSiteManagerScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _positionController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;

  bool _isLoading = false;


  @override
  void initState() {
    super.initState();
    // Split full name into first and last name if possible
    String firstName = '';
    String lastName = '';

    if (widget.manager.fullName != null) {
      final names = widget.manager.fullName!.trim().split(' ');
      if (names.isNotEmpty) {
        firstName = names.first;
        if (names.length > 1) {
          lastName = names.sublist(1).join(' ');
        }
      }
    }

    _firstNameController = TextEditingController(text: firstName);
    _lastNameController = TextEditingController(text: lastName);
    _positionController = TextEditingController(text: widget.manager.position);
    _emailController = TextEditingController(text: widget.manager.email);
    _phoneController = TextEditingController(text: widget.manager.phone);
    _addressController = TextEditingController(text: widget.manager.address);
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _positionController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _handleUpdateSiteManager() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final firstName = _firstNameController.text.trim();
      final lastName = _lastNameController.text.trim();
      final fullName = [
        firstName,
        lastName,
      ].where((s) => s.isNotEmpty).join(' ');

      // Use a custom update method on auth repository to update another user
      // Since authProvider's updateProfile updates the CURRENT user
      // We need a way to update ANY user.
      // For now, let's assume we use a specialized provider method or repository call.
      // But looking at AuthRepository, we have updateUserProfile(userId, updates).

      // We need to access the repository directly or add a method to AuthNotifier
      // Let's go through the repository via provider for now as we haven't updated AuthNotifier for "update other user"
      // Wait, AuthRepository.updateUserProfile is public.

      final updates = <String, dynamic>{
        'full_name': fullName,
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (_phoneController.text.isNotEmpty) {
        updates['phone'] = _phoneController.text.trim();
      }

      if (_positionController.text.isNotEmpty) {
        updates['position'] = _positionController.text.trim();
      }

      if (_addressController.text.isNotEmpty) {
        updates['address'] = _addressController.text.trim();
      }

      // We need to use the auth repository directly here since the AuthProvider.updateProfile
      // is designed for the current user.
      await ref
          .read(authRepositoryProvider)
          .updateUserProfile(userId: widget.manager.id, updates: updates);

      if (!mounted) return;

      // Refresh the site managers list
      ref.invalidate(siteManagersProvider);

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Manager details updated successfully!'),
          backgroundColor: AppColors.success,
        ),
      );

      // Navigate back
      context.pop();
    } catch (e) {
      if (mounted) {
        final errorString = e.toString().toLowerCase();

        if (errorString.contains('socket') ||
            errorString.contains('network') ||
            errorString.contains('internet') ||
            errorString.contains('connection') ||
            errorString.contains('timeout')) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Row(
                children: [
                  Icon(Icons.wifi_off, color: AppColors.error),
                  SizedBox(width: 8),
                  Text('Connection Error'),
                ],
              ),
              content: const Text(
                'Unable to connect to the server. Please check your internet connection and try again.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Failed to update details: ${e.toString().replaceAll('Exception:', '').trim()}',
              ),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleDeleteSiteManager() async {
    // Show confirmation dialog
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'Delete Manager',
          style: TextStyle(color: Colors.red),
        ),
        content: const Text(
          'Are you sure you want to delete this manager? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await ref.read(authRepositoryProvider).deleteUser(widget.manager.id);

      if (!mounted) return;

      // Refresh the site managers list
      ref.invalidate(siteManagersProvider);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Manager deleted successfully!'),
          backgroundColor: AppColors.success,
        ),
      );

      // Navigate back
      context.pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete manager: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Edit Details',
          style: TextStyle(
            color: Color(0xFF1A1C1E),
            fontWeight: FontWeight.w700,
            fontSize: 20,
          ),
        ),
        leading: Container(
          margin: const EdgeInsets.only(left: 16),
          decoration: BoxDecoration(
            color: const Color(0xFFF6F7FB),
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            icon: const Icon(Icons.arrow_back, color: Color(0xFF1A1C1E)),
            onPressed: () => context.pop(),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            onPressed: _isLoading ? null : _handleDeleteSiteManager,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // First Name Field
                _buildLabel('First Name'),
                TextFormField(
                  controller: _firstNameController,
                  textCapitalization: TextCapitalization.words,
                  decoration: _inputDecoration('Rakesh'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter first name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Last Name Field
                _buildLabel('Last Name'),
                TextFormField(
                  controller: _lastNameController,
                  textCapitalization: TextCapitalization.words,
                  decoration: _inputDecoration('Kumar'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter last name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Position Field
                _buildLabel('Position'),
                TextFormField(
                  controller: _positionController,
                  textCapitalization: TextCapitalization.words,
                  decoration: _inputDecoration('Head Manager'),
                ),
                const SizedBox(height: 16),

                // Email Field (Read Only)
                _buildLabel('Email'),
                TextFormField(
                  controller: _emailController,
                  readOnly: true,
                  style: const TextStyle(color: Colors.grey),
                  decoration: _inputDecoration(
                    'rameshkumar@manager.com',
                  ).copyWith(fillColor: Colors.grey[100]),
                ),
                const SizedBox(height: 16),

                // Phone Field
                _buildLabel('Phone'),
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: _inputDecoration('+91 9874563210'),
                ),
                const SizedBox(height: 16),

                // Address Field
                _buildLabel('Address'),
                TextFormField(
                  controller: _addressController,
                  maxLines: 3,
                  decoration: _inputDecoration(
                    '4517 washington ave. manchester, kentucky 39495',
                  ),
                ),
                const SizedBox(height: 32),

                // Update Button
                SizedBox(
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleUpdateSiteManager,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            'Update Details',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          color: Color(0xFF1A1C1E),
          fontWeight: FontWeight.w700,
          fontSize: 14,
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(
        color: Color(0xFF1A1C1E),
        fontWeight: FontWeight.w700,
        fontSize: 14,
      ),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFF3F4F6)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFF3F4F6)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.error),
      ),
    );
  }
}
