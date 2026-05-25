import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/ui/responsive.dart';
import '../../auth/providers/auth_provider.dart';
import '../../auth/providers/auth_repository_provider.dart';
import '../../auth/data/models/user_profile_model.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _positionController;
  late TextEditingController _addressController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _phoneController = TextEditingController();
    _positionController = TextEditingController();
    _addressController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _positionController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(userProfileProvider);
    final role = ref.watch(userRoleProvider);
    final isAdmin = role == UserRole.admin || role == UserRole.superAdmin;

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      body: profile == null
          ? const Center(child: CircularProgressIndicator())
          : LayoutBuilder(
              builder: (context, constraints) {
                final r = R(Size(constraints.maxWidth, constraints.maxHeight));
                return SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                    horizontal: r.isDesktop ? 32 : 20,
                    vertical: r.isDesktop ? 28 : 20,
                  ),
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                          maxWidth: r.isDesktop ? 960 : 600),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header
                          Text(
                            'Profile',
                            style: Theme.of(context)
                                .textTheme
                                .headlineSmall
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 24),

                          // Hero card
                          _buildHeroCard(context, profile),
                          const SizedBox(height: 20),

                          // Main content
                          if (r.isDesktop)
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  flex: 3,
                                  child: Column(
                                    children: [
                                      _buildContactCard(context, profile),
                                      const SizedBox(height: 16),
                                      _buildQuickLinksCard(
                                          context, isAdmin),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 20),
                                Expanded(
                                  flex: 2,
                                  child: Column(
                                    children: [
                                      _buildAccountCard(context, profile),
                                      const SizedBox(height: 16),
                                      _buildAppInfoCard(context),
                                    ],
                                  ),
                                ),
                              ],
                            )
                          else ...[
                            _buildContactCard(context, profile),
                            const SizedBox(height: 16),
                            _buildQuickLinksCard(context, isAdmin),
                            const SizedBox(height: 16),
                            _buildAccountCard(context, profile),
                            const SizedBox(height: 16),
                            _buildAppInfoCard(context),
                          ],

                          const SizedBox(height: 32),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }

  // ── Hero Card ──

  Widget _buildHeroCard(BuildContext context, UserProfileModel profile) {
    final initials =
        (profile.fullName ?? 'U').substring(0, 1).toUpperCase();
    final roleBadgeColor = _getRoleColor(profile.role);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.sidebarBackground,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 36,
            backgroundColor: Colors.white.withValues(alpha: 0.15),
            backgroundImage: profile.avatarUrl != null
                ? NetworkImage(profile.avatarUrl!)
                : null,
            child: profile.avatarUrl == null
                ? Text(
                    initials,
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  profile.fullName ?? 'User',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                ),
                const SizedBox(height: 4),
                if (profile.email != null)
                  Text(
                    profile.email!,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 13,
                    ),
                  ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(
                        color: roleBadgeColor.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        profile.role.replaceAll('_', ' ').toUpperCase(),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    if (profile.createdAt != null) ...[
                      const SizedBox(width: 12),
                      Icon(Icons.calendar_today_outlined,
                          size: 12,
                          color: Colors.white.withValues(alpha: 0.5)),
                      const SizedBox(width: 4),
                      Text(
                        'Joined ${DateFormat('MMM yyyy').format(profile.createdAt!)}',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.white.withValues(alpha: 0.5),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          Material(
            color: Colors.white.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
            child: InkWell(
              onTap: () => _showEditSheet(context),
              borderRadius: BorderRadius.circular(10),
              child: const Padding(
                padding: EdgeInsets.all(10),
                child:
                    Icon(Icons.edit_outlined, size: 18, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Contact Card ──

  Widget _buildContactCard(BuildContext context, UserProfileModel profile) {
    return _SectionCard(
      title: 'Contact Information',
      icon: Icons.contact_mail_outlined,
      children: [
        _InfoTile(
          icon: Icons.mail_outline_rounded,
          label: 'Email',
          value: profile.email ?? 'Not set',
        ),
        const Divider(height: 24),
        _InfoTile(
          icon: Icons.phone_outlined,
          label: 'Phone',
          value: profile.phone ?? 'Not set',
          isEmpty: profile.phone == null || profile.phone!.isEmpty,
        ),
        const Divider(height: 24),
        _InfoTile(
          icon: Icons.work_outline_rounded,
          label: 'Position',
          value: profile.position ?? 'Not set',
          isEmpty:
              profile.position == null || profile.position!.isEmpty,
        ),
        const Divider(height: 24),
        _InfoTile(
          icon: Icons.location_on_outlined,
          label: 'Address',
          value: profile.address ?? 'Not set',
          isEmpty:
              profile.address == null || profile.address!.isEmpty,
        ),
      ],
    );
  }

  // ── Quick Links ──

  Widget _buildQuickLinksCard(BuildContext context, bool isAdmin) {
    return _SectionCard(
      title: 'Quick Links',
      icon: Icons.link_rounded,
      children: [
        _MenuTile(
          icon: Icons.folder_outlined,
          label: 'My Projects',
          onTap: () => context.go('/projects'),
        ),
        _MenuTile(
          icon: Icons.receipt_long_outlined,
          label: 'Bills',
          onTap: () => context.go('/bills'),
        ),
        if (isAdmin)
          _MenuTile(
            icon: Icons.bar_chart_rounded,
            label: 'Reports & Insights',
            onTap: () => context.go('/reports'),
          ),
        if (isAdmin)
          _MenuTile(
            icon: Icons.people_outline_rounded,
            label: 'Site Managers',
            onTap: () => context.push('/admin/site-managers'),
          ),
      ],
    );
  }

  // ── Account Card ──

  Widget _buildAccountCard(
      BuildContext context, UserProfileModel profile) {
    return _SectionCard(
      title: 'Account',
      icon: Icons.settings_outlined,
      children: [
        _MenuTile(
          icon: Icons.edit_outlined,
          label: 'Edit Profile',
          onTap: () => _showEditSheet(context),
        ),
        _MenuTile(
          icon: Icons.lock_outline_rounded,
          label: 'Change Password',
          subtitle: 'Reset via email',
          onTap: () => context.push('/forgot-password'),
        ),
        const Divider(height: 8),
        _MenuTile(
          icon: Icons.logout_rounded,
          label: 'Sign Out',
          color: AppColors.error,
          onTap: _logout,
        ),
      ],
    );
  }

  // ── App Info ──

  Widget _buildAppInfoCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border:
            Border.all(color: AppColors.borderDark.withValues(alpha: 0.5)),
      ),
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.asset(
              'assets/images/logo.png',
              width: 48,
              height: 48,
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Clivi Management',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            'Version 1.0.0',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textHint,
                ),
          ),
          const SizedBox(height: 12),
          Text(
            'Construction project management\nmade simple and efficient.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // ── Edit Sheet (unchanged logic) ──

  void _showEditSheet(BuildContext context) {
    final profile = ref.read(userProfileProvider);
    if (profile == null) return;

    _nameController.text = profile.fullName ?? '';
    _phoneController.text = profile.phone ?? '';
    _positionController.text = profile.position ?? '';
    _addressController.text = profile.address ?? '';

    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setStateSheet) {
          Future<void> submit() async {
            if (!_formKey.currentState!.validate()) return;
            setStateSheet(() => isSaving = true);

            final user = ref.read(currentUserProvider);
            if (user == null) {
              setStateSheet(() => isSaving = false);
              return;
            }

            try {
              final updates = {
                'full_name': _nameController.text.trim(),
                'phone': _phoneController.text.trim(),
                'position': _positionController.text.trim(),
                'address': _addressController.text.trim(),
                'updated_at': DateTime.now().toIso8601String(),
              };

              await ref
                  .read(authRepositoryProvider)
                  .updateUserProfile(userId: user.id, updates: updates);

              ref.invalidate(userProfileProvider);

              if (ctx.mounted) {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Profile updated successfully')),
                );
              }
            } catch (e) {
              if (ctx.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Failed to update: $e')),
                );
              }
              setStateSheet(() => isSaving = false);
            }
          }

          return Container(
            margin: EdgeInsets.only(
                top: MediaQuery.of(ctx).viewPadding.top + 40),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius:
                  BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                  24, 24, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Edit Profile',
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          const Spacer(),
                          IconButton(
                            onPressed: () => Navigator.pop(ctx),
                            icon: const Icon(Icons.close_rounded),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      _buildField(
                        controller: _nameController,
                        label: 'Full Name',
                        icon: Icons.person_outline,
                        validator: (v) =>
                            v == null || v.isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 16),
                      _buildField(
                        controller: _phoneController,
                        label: 'Phone',
                        icon: Icons.phone_outlined,
                        keyboardType: TextInputType.phone,
                      ),
                      const SizedBox(height: 16),
                      _buildField(
                        controller: _positionController,
                        label: 'Position',
                        icon: Icons.work_outline,
                      ),
                      const SizedBox(height: 16),
                      _buildField(
                        controller: _addressController,
                        label: 'Address',
                        icon: Icons.location_on_outlined,
                        maxLines: 2,
                      ),
                      const SizedBox(height: 28),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: isSaving ? null : submit,
                          style: ElevatedButton.styleFrom(
                            padding:
                                const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: isSaving
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text('Save Changes'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20),
      ),
    );
  }

  Color _getRoleColor(String role) {
    switch (role) {
      case 'super_admin':
        return AppColors.superAdmin;
      case 'admin':
        return AppColors.admin;
      case 'site_manager':
        return AppColors.siteManager;
      default:
        return AppColors.primary;
    }
  }

  Future<void> _logout() async {
    try {
      await ref.read(authProvider.notifier).signOut();
      if (mounted) context.go('/login');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Logout failed: $e')));
      }
    }
  }
}

// ── Section Card ──

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border:
            Border.all(color: AppColors.borderDark.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: AppColors.textSecondary),
              const SizedBox(width: 8),
              Text(
                title,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }
}

// ── Info Tile ──

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isEmpty;

  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
    this.isEmpty = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppColors.textSecondary, size: 18),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textHint,
                      fontSize: 11,
                    ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                      color: isEmpty
                          ? AppColors.textHint
                          : AppColors.textPrimary,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Menu Tile ──

class _MenuTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? subtitle;
  final VoidCallback onTap;
  final Color? color;

  const _MenuTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.subtitle,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final tileColor = color ?? AppColors.textPrimary;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 11),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: (color ?? AppColors.primary).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: tileColor, size: 18),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                          color: tileColor,
                        ),
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textHint,
                            fontSize: 11,
                          ),
                    ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded,
                size: 18, color: AppColors.textHint),
          ],
        ),
      ),
    );
  }
}
