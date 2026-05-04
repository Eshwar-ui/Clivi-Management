import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/file_upload_widget.dart';
import '../data/models/bill_model.dart';
import '../providers/bill_provider.dart';
import '../../projects/providers/project_provider.dart';
import '../../inventory/providers/inventory_provider.dart';

class CreateBillScreen extends ConsumerStatefulWidget {
  const CreateBillScreen({super.key});

  @override
  ConsumerState<CreateBillScreen> createState() => _CreateBillScreenState();
}

class _CreateBillScreenState extends ConsumerState<CreateBillScreen> {
  final _formKey = GlobalKey<FormState>();

  // Form State
  String? _selectedProjectId;
  String? _title;
  String? _description;
  double? _amount;
  String? _vendorName;
  DateTime _billDate = DateTime.now();
  BillType _type = BillType.expense;
  PaymentType _paymentType = PaymentType.cash;
  PaymentStatus _paymentStatus = PaymentStatus.needToPay;
  List<int>? _receiptBytes;
  String? _receiptName;

  bool _isSubmitting = false;
  String? _selectedFileName;
  String? _selectedFileSize;

  @override
  void initState() {
    super.initState();
    // Load projects to select from
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(projectListProvider.notifier).loadProjects();
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedProjectId == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select a project')));
      return;
    }

    _formKey.currentState!.save();

    setState(() => _isSubmitting = true);

    final success = await ref
        .read(billControllerProvider.notifier)
        .createBill(
          projectId: _selectedProjectId!,
          title: _title!,
          amount: _amount!,
          billType: _type.value,
          description: _description,
          vendorName: _vendorName,
          paymentType: _paymentType.value,
          paymentStatus: _paymentStatus.value,
          receiptBytes: _receiptBytes,
          receiptName: _receiptName,
          billDate: _billDate,
        );

    if (mounted) {
      setState(() => _isSubmitting = false);
      if (success) {
        context.pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bill created successfully')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final projectState = ref.watch(projectListProvider);
    final createBillState = ref.watch(billControllerProvider);
    final suppliersAsync = ref.watch(suppliersProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Bill Request')),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Project Dropdown
                    DropdownButtonFormField<String>(
                      initialValue: _selectedProjectId,
                      decoration: const InputDecoration(
                        labelText: 'Project',
                        prefixIcon: Icon(Icons.business),
                      ),
                      items: projectState.projects.map((p) {
                        return DropdownMenuItem(
                          value: p.id,
                          child: Text(p.name, overflow: TextOverflow.ellipsis),
                        );
                      }).toList(),
                      onChanged: (value) =>
                          setState(() => _selectedProjectId = value),
                      validator: (val) => val == null ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),

                    // Bill Type
                    DropdownButtonFormField<BillType>(
                      initialValue: _type,
                      decoration: const InputDecoration(
                        labelText: 'Type',
                        prefixIcon: Icon(Icons.category),
                      ),
                      items: BillType.values.map((type) {
                        return DropdownMenuItem(
                          value: type,
                          child: Text(type.label),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _type = val);
                      },
                    ),
                    const SizedBox(height: 16),

                    // Title
                    TextFormField(
                      decoration: const InputDecoration(
                        labelText: 'Title / Description',
                        hintText: 'e.g., Cement purchase',
                      ),
                      validator: (val) =>
                          val == null || val.isEmpty ? 'Required' : null,
                      onSaved: (val) => _title = val,
                    ),
                    const SizedBox(height: 16),

                    // Amount
                    TextFormField(
                      decoration: const InputDecoration(
                        labelText: 'Amount (₹)',
                        prefixIcon: Icon(Icons.currency_rupee),
                      ),
                      keyboardType: TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      validator: (val) {
                        if (val == null || val.isEmpty) return 'Required';
                        if (double.tryParse(val) == null) {
                          return 'Invalid number';
                        }
                        return null;
                      },
                      onSaved: (val) => _amount = double.parse(val!),
                    ),
                    const SizedBox(height: 16),

                    // Date Picker
                    InkWell(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _billDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now(),
                        );
                        if (picked != null) setState(() => _billDate = picked);
                      },
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Date',
                          prefixIcon: Icon(Icons.calendar_today),
                        ),
                        child: Text(
                          DateFormat('MMM d, yyyy').format(_billDate),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Vendor
                    suppliersAsync.when(
                      data: (suppliers) {
                        return DropdownButtonFormField<String>(
                          decoration: const InputDecoration(
                            labelText: 'Vendor Name (Optional)',
                            prefixIcon: Icon(Icons.store),
                          ),
                          items: [
                            const DropdownMenuItem<String>(
                              value: '',
                              child: Text('Select a Vendor'),
                            ),
                            ...suppliers.map((supplier) {
                              return DropdownMenuItem<String>(
                                value: supplier.name,
                                child: Text(supplier.name),
                              );
                            }),
                          ],
                          onChanged: (val) {
                            if (val != null) {
                              setState(() => _vendorName = val.isEmpty ? null : val);
                            }
                          },
                          onSaved: (val) => _vendorName = (val == null || val.isEmpty) ? null : val,
                        );
                      },
                      loading: () => const Center(
                        child: CircularProgressIndicator(),
                      ),
                      error: (err, stack) => Text('Failed to load vendors: $err'),
                    ),
                    const SizedBox(height: 16),

                    DropdownButtonFormField<PaymentStatus>(
                      initialValue: _paymentStatus,
                      decoration: const InputDecoration(
                        labelText: 'Status',
                        prefixIcon: Icon(Icons.pending_actions_outlined),
                      ),
                      items: PaymentStatus.values.map((status) {
                        return DropdownMenuItem(
                          value: status,
                          child: Text(status.label),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _paymentStatus = value);
                        }
                      },
                    ),
                    const SizedBox(height: 16),

                    DropdownButtonFormField<PaymentType>(
                      initialValue: _paymentType,
                      decoration: const InputDecoration(
                        labelText: 'Payment Type',
                        prefixIcon: Icon(Icons.account_balance_wallet_outlined),
                      ),
                      items: PaymentType.values.map((paymentType) {
                        return DropdownMenuItem(
                          value: paymentType,
                          child: Text(paymentType.label),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _paymentType = value);
                        }
                      },
                    ),
                    const SizedBox(height: 24),

                    // Receipt Upload
                    const Text(
                      'Receipt (PDF)',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    FileUploadWidget(
                      label: 'Upload PDF',
                      allowedExtensions: const ['pdf'],
                      onFileSelected: (fileName, bytes) => setState(() {
                        _receiptName = fileName;
                        _receiptBytes = bytes;
                        _selectedFileName = fileName;
                        _selectedFileSize =
                            '${(bytes.length / (1024 * 1024)).toStringAsFixed(2)} MB';
                      }),
                    ),
                    if (_selectedFileName != null) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.picture_as_pdf, color: Colors.red),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _selectedFileName!,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            _selectedFileSize ?? '',
                            style: TextStyle(color: AppColors.textSecondary),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () {
                              setState(() {
                                _receiptBytes = null;
                                _receiptName = null;
                                _selectedFileName = null;
                                _selectedFileSize = null;
                              });
                            },
                          ),
                        ],
                      ),
                    ],

                    const SizedBox(height: 32),

                    // Submit Button
                    ElevatedButton(
                      onPressed: (_isSubmitting || createBillState.isLoading)
                          ? null
                          : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: _isSubmitting || createBillState.isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text('ADD BILL'),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
