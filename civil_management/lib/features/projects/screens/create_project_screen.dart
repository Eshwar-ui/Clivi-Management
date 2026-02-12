import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/providers/auth_provider.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/ui/responsive.dart';
import '../../../core/ui/responsive_scaffold.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/error_widget.dart';
import '../data/models/project_model.dart';
import '../providers/project_provider.dart';
import '../widgets/site_manager_selection_sheet.dart';

/// Create/Edit Project Screen
class CreateProjectScreen extends ConsumerStatefulWidget {
  final String? projectId; // null for create, id for edit

  const CreateProjectScreen({super.key, this.projectId});

  bool get isEditing => projectId != null;

  @override
  ConsumerState<CreateProjectScreen> createState() =>
      _CreateProjectScreenState();
}

class _CreateProjectScreenState extends ConsumerState<CreateProjectScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _clientNameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _budgetController = TextEditingController();
  final _startDateController = TextEditingController();
  final _endDateController = TextEditingController();

  ProjectStatus _selectedStatus = ProjectStatus.planning;
  DateTime? _startDate = DateTime.now();
  DateTime? _endDate = DateTime.now().add(const Duration(days: 90));
  
  // Set of selected manager IDs
  Set<String> _selectedManagerIds = {};
  // List of selected manager models for display (fetched on load)
  List<SiteManagerModel> _displayManagers = [];

  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    if (_startDate != null) {
      _startDateController.text = DateFormat('dd-MM-yyyy').format(_startDate!);
    }
    if (_endDate != null) {
      _endDateController.text = DateFormat('dd-MM-yyyy').format(_endDate!);
    }
    if (widget.isEditing) {
      _loadProjectData();
    }
  }

  void _loadProjectData() {
    // Load existing project data for editing
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final state = ref.read(projectDetailProvider(widget.projectId!));
      final project = state.project;
      
      if (project != null) {
        _nameController.text = project.name;
        _clientNameController.text = project.clientName ?? '';
        _descriptionController.text = project.description ?? '';
        _locationController.text = project.location ?? '';
        _budgetController.text = project.budget?.toStringAsFixed(0) ?? '';
        
        // Initialize selected managers from project assignments
        if (project.assignments != null) {
           _selectedManagerIds = project.assignments!
              .map((a) => a.userId)
              .toSet();
           
           // We need to fetch the actual manager models to display names
           // This is a bit of a workaround since assignments have user profiles nested
           // but mapped to ProjectAssignmentModel. We can reconstruct display models.
           setState(() {
             _displayManagers = project.assignments!.map((a) => SiteManagerModel(
               id: a.userId,
               fullName: a.userName,
               phone: a.userPhone,
               isAssigned: true,
             )).toList();
           });
        }

        setState(() {
          _selectedStatus = project.status;
          _startDate = project.startDate;
          _endDate = project.endDate;
          if (_startDate != null) {
            _startDateController.text =
                DateFormat('dd-MM-yyyy').format(_startDate!);
          }
          if (_endDate != null) {
            _endDateController.text =
                DateFormat('dd-MM-yyyy').format(_endDate!);
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _clientNameController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _budgetController.dispose();
    _startDateController.dispose();
    _endDateController.dispose();
    super.dispose();
  }
  
  // Show bottom sheet to select managers
  Future<void> _showManagerSelection() async {
    final result = await showModalBottomSheet<Set<String>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => SiteManagerSelectionSheet(
        initialSelectedIds: _selectedManagerIds,
      ),
    );

    if (result != null) {
      setState(() {
        _selectedManagerIds = result;
      });
      _refreshDisplayManagers();
    }
  }

  // Refresh the display list of managers based on selected IDs
  Future<void> _refreshDisplayManagers() async {
    // If we have IDs but no display models (or mismatch), fetch all managers to get details
    // Only needed if we selected new ones that weren't already in _displayManagers
    final allManagers = await ref.read(projectRepositoryProvider).getSiteManagers();
    
    if (mounted) {
      setState(() {
         _displayManagers = allManagers
             .where((m) => _selectedManagerIds.contains(m.id))
             .toList();
      });
    }
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final project = ProjectModel(
        id: widget.projectId ?? '',
        name: _nameController.text.trim(),
        clientName: _clientNameController.text.trim().isEmpty 
            ? null 
            : _clientNameController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        location: _locationController.text.trim().isEmpty
            ? null
            : _locationController.text.trim(),
        status: _selectedStatus,
        startDate: _startDate,
        endDate: _endDate,
        budget: _budgetController.text.trim().isEmpty
            ? null
            : double.tryParse(_budgetController.text.trim()),
      );

      String? resultProjectId;
      
      if (widget.isEditing) {
        // Update existing project
        resultProjectId = widget.projectId;
        final success = await ref
            .read(projectDetailProvider(widget.projectId!).notifier)
            .updateProject(project.toJson());
            
        if (!success) throw Exception('Failed to update project details');
            
      } else {
        // Create new project
        final createdProject = await ref
            .read(createProjectProvider.notifier)
            .createProject(project);
            
         if (createdProject != null) {
           resultProjectId = createdProject.id;
         } else {
           throw Exception('Failed to create project');
         }
      }

      // Handle Manager Assignments
      // If we have a project ID (created/updated), update assignments
      if (resultProjectId != null) {
        final currentUser = ref.read(currentUserProvider);
        if (currentUser != null) {
            await ref.read(projectRepositoryProvider).updateAssignments(
              projectId: resultProjectId,
              assignedUserIds: _selectedManagerIds.toList(),
              assignedBy: currentUser.id,
            );
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.isEditing
                ? 'Project updated successfully!'
                : 'Project created successfully!'),
            backgroundColor: AppColors.success,
          ),
        );
        context.pop();
      }
      
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _selectStartDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (date != null) {
      setState(() {
        _startDate = date;
        _startDateController.text = DateFormat('dd-MM-yyyy').format(date);
        // Reset end date if it's before start date
        if (_endDate != null && _endDate!.isBefore(date)) {
          _endDate = null;
          _endDateController.clear();
        }
      });
    }
  }

  Future<void> _selectEndDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _endDate ?? _startDate ?? DateTime.now(),
      firstDate: _startDate ?? DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (date != null) {
      setState(() {
        _endDate = date;
        _endDateController.text = DateFormat('dd-MM-yyyy').format(date);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Watch for errors from provider
    final createState = ref.watch(createProjectProvider);
    if (createState.error != null && _errorMessage == null) {
      _errorMessage = createState.error;
    }

    return ResponsiveScaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(widget.isEditing ? 'Edit Project Details' : 'Add New Project'),
        centerTitle: true,
      ),
      builder: (context, r) {
        return Padding(
          padding: r.pad.copyWith(
            top: 20,
            bottom: 24 + MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_errorMessage != null) ...[
                      InlineErrorWidget(message: _errorMessage!),
                      const SizedBox(height: 16),
                    ],
                    
                    _buildLabel('Project Name'),
                    _buildTextField(
                      controller: _nameController,
                      hintText: 'Project name',
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Project name is required';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    _buildLabel('Client Name'),
                    _buildTextField(
                      controller: _clientNameController,
                      hintText: 'Mr.Narashima', // Example from design
                    ),
                    const SizedBox(height: 16),
                    
                    _buildLabel('Date'),
                    // Date field takes full width in design, usually start date
                    _buildDateField(_startDateController, _selectStartDate),
                     const SizedBox(height: 16),

                    _buildLabel('Site Place'),
                    _buildTextField(
                      controller: _locationController,
                      hintText: 'Hyd, Telangana',
                    ),
                    const SizedBox(height: 16),
                    
                    _buildLabel('Budget (optional)'),
                    _buildTextField(
                        controller: _budgetController,
                        hintText: 'Rs. 3,00,000',
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    ),
                    const SizedBox(height: 16),
                    
                    // Site Manager Section
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildLabel('Site Manager', padding: EdgeInsets.zero),
                        TextButton.icon(
                          onPressed: _showManagerSelection,
                          icon: const Icon(Icons.add, size: 16, color: AppColors.primary),
                          label: const Text(
                            'Add Manager',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    
                    if (_displayManagers.isEmpty)
                       Container(
                         padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                         decoration: BoxDecoration(
                           color: Colors.white,
                           borderRadius: BorderRadius.circular(12),
                           border: Border.all(color: Colors.grey.shade200),
                         ),
                         child: Text(
                           'No managers assigned', 
                           style: TextStyle(color: Colors.grey[400]),
                         ),
                       )
                    else 
                       ..._displayManagers.map((manager) => Padding(
                         padding: const EdgeInsets.only(bottom: 8.0),
                         child: _buildManagerTile(manager),
                       )),
                    
                    const SizedBox(height: 16),

                    _buildLabel('Description'),
                     TextFormField(
                       controller: _descriptionController,
                       decoration: InputDecoration(
                         hintText: 'Tell About the Project ...',
                         filled: true,
                         fillColor: Colors.white,
                         border: OutlineInputBorder(
                           borderRadius: BorderRadius.circular(12),
                           borderSide: BorderSide.none,
                         ),
                         enabledBorder: OutlineInputBorder(
                           borderRadius: BorderRadius.circular(12),
                           borderSide: BorderSide.none,
                         ),
                         focusedBorder: OutlineInputBorder(
                           borderRadius: BorderRadius.circular(12),
                           borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                         ),
                         contentPadding: const EdgeInsets.all(16),
                       ),
                       maxLines: 4,
                       textCapitalization: TextCapitalization.sentences,
                     ),
                    
                    const SizedBox(height: 32),
                    AppButton(
                      text: widget.isEditing ? 'Update Project Details' : 'Create Project',
                      onPressed: _handleSubmit,
                      isLoading: _isLoading,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLabel(String text, {EdgeInsets padding = const EdgeInsets.only(bottom: 8, left: 4)}) {
    return Padding(
      padding: padding,
      child: Text(
        text,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 14,
          color: Color(0xFF1E293B), // Dark Navy
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    String? Function(String?)? validator,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        hintText: hintText,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
           borderRadius: BorderRadius.circular(12),
           borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
           borderRadius: BorderRadius.circular(12),
           borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      validator: validator,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      textCapitalization: TextCapitalization.words,
    );
  }
  
  Widget _buildDateField(TextEditingController controller, VoidCallback onTap) {
      return GestureDetector(
        onTap: onTap,
        child: AbsorbPointer(
          child: TextFormField(
            controller: controller,
            decoration: InputDecoration(
              hintText: 'dd-MM-yyyy',
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                 borderRadius: BorderRadius.circular(12),
                 borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                 borderRadius: BorderRadius.circular(12),
                 borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
            readOnly: true,
          ),
        ),
      );
  }
  
  Widget _buildManagerTile(SiteManagerModel manager) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        // border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              manager.displayName,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 15,
                color: Color(0xFF1E293B),
              ),
            ),
          ),
          InkWell(
            onTap: () {
               setState(() {
                 _selectedManagerIds.remove(manager.id);
                 _displayManagers.removeWhere((m) => m.id == manager.id);
               });
            },
            child: const Padding(
              padding: EdgeInsets.all(4.0),
              child: Icon(
                Icons.delete_outline, 
                color: Colors.redAccent, 
                size: 20
              ),
            ),
          ),
        ],
      ),
    );
  }
}

