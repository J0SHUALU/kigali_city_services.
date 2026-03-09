import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/service_model.dart';
import '../../providers/services_provider.dart';
import '../../providers/auth_provider.dart' as ap;
import '../../theme/app_theme.dart';

const List<String> kCategoryOptions = [
  'Cafés', 'Pharmacies', 'Hospitals', 'Restaurants',
  'Parks', 'Libraries', 'Police', 'Attractions',
];

class AddEditListingScreen extends StatefulWidget {
  final ServiceModel? service;
  const AddEditListingScreen({super.key, this.service});
  @override
  State<AddEditListingScreen> createState() => _AddEditListingScreenState();
}

class _AddEditListingScreenState extends State<AddEditListingScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _addressCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _descCtrl;
  late final TextEditingController _latCtrl;
  late final TextEditingController _lngCtrl;
  String _selectedCategory = kCategoryOptions.first;
  bool _isLoading = false;

  bool get _isEditing => widget.service != null;

  @override
  void initState() {
    super.initState();
    final s = widget.service;
    _nameCtrl = TextEditingController(text: s?.name ?? '');
    _addressCtrl = TextEditingController(text: s?.address ?? '');
    _phoneCtrl = TextEditingController(text: s?.phone ?? '');
    _descCtrl = TextEditingController(text: s?.description ?? '');
    _latCtrl = TextEditingController(text: s?.latitude.toString() ?? '');
    _lngCtrl = TextEditingController(text: s?.longitude.toString() ?? '');
    if (s != null) _selectedCategory = s.category;
  }

  @override
  void dispose() {
    _nameCtrl.dispose(); _addressCtrl.dispose(); _phoneCtrl.dispose();
    _descCtrl.dispose(); _latCtrl.dispose(); _lngCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    final provider = context.read<ServicesProvider>();
    final user = context.read<ap.AuthProvider>().user!;
    final service = ServiceModel(
      id: widget.service?.id ?? '',
      name: _nameCtrl.text.trim(),
      category: _selectedCategory,
      address: _addressCtrl.text.trim(),
      phone: _phoneCtrl.text.trim(),
      description: _descCtrl.text.trim(),
      latitude: double.tryParse(_latCtrl.text) ?? -1.9441,
      longitude: double.tryParse(_lngCtrl.text) ?? 30.0619,
      rating: widget.service?.rating ?? 0,
      reviewCount: widget.service?.reviewCount ?? 0,
      createdBy: user.uid,
      timestamp: widget.service?.timestamp ?? DateTime.now(),
    );
    if (_isEditing) {
      await provider.updateService(service);
    } else {
      await provider.createService(service);
    }
    setState(() => _isLoading = false);
    if (mounted) Navigator.pop(context);
  }

  Widget _field(TextEditingController ctrl, String label, IconData icon,
      {TextInputType keyboardType = TextInputType.text}) {
    return TextFormField(
      controller: ctrl,
      keyboardType: keyboardType,
      decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon, color: AppColors.muted)),
      validator: (v) => v == null || v.isEmpty ? 'Required' : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isEditing ? 'Edit Listing' : 'Add Listing')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _field(_nameCtrl, 'Place / Service Name', Icons.store),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _selectedCategory,
                dropdownColor: AppColors.surface,
                decoration: const InputDecoration(labelText: 'Category', prefixIcon: Icon(Icons.category_outlined, color: AppColors.muted)),
                items: kCategoryOptions.map((c) => DropdownMenuItem(value: c, child: Text(c, style: const TextStyle(color: AppColors.foreground)))).toList(),
                onChanged: (v) => setState(() => _selectedCategory = v!),
              ),
              const SizedBox(height: 12),
              _field(_addressCtrl, 'Address', Icons.location_on_outlined),
              const SizedBox(height: 12),
              _field(_phoneCtrl, 'Contact Number', Icons.phone_outlined, keyboardType: TextInputType.phone),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descCtrl,
                decoration: const InputDecoration(labelText: 'Description', prefixIcon: Icon(Icons.description_outlined, color: AppColors.muted), alignLabelWithHint: true),
                maxLines: 3,
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _field(_latCtrl, 'Latitude', Icons.explore,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true))),
                  const SizedBox(width: 12),
                  Expanded(child: _field(_lngCtrl, 'Longitude', Icons.explore,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true))),
                ],
              ),
              const SizedBox(height: 24),
              _isLoading
                  ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                  : ElevatedButton(onPressed: _submit, child: Text(_isEditing ? 'Save Changes' : 'Add Listing')),
            ],
          ),
        ),
      ),
    );
  }
}
