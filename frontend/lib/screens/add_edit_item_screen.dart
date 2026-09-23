import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../data/owner_listings_store.dart';
import '../models/owner_listing.dart';
import '../models/rental_item.dart';
import '../models/rental_pricing.dart';
import '../theme/app_theme.dart';
import '../state/auth_state.dart';

class AddEditItemScreen extends StatefulWidget {
  final OwnerListing? item;
  final String community;

  const AddEditItemScreen({super.key, this.item, required this.community});

  @override
  State<AddEditItemScreen> createState() => _AddEditItemScreenState();
}

class _AddEditItemScreenState extends State<AddEditItemScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _price;
  late final TextEditingController _description;
  late final TextEditingController _discount;
  bool _discountEnabled = false;
  final ImagePicker _imagePicker = ImagePicker();
  static const int _maxPhotos = 5;
  late List<String> _imagePaths;
  late List<String> _storagePaths;
  late ItemCategory _category;
  late String _condition;
  late AvailabilityStatus _availability;
  bool _saving = false;
  String? _saveError;

  bool get editing => widget.item != null;

  @override
  void initState() {
    super.initState();
    final item = widget.item;
    _name = TextEditingController(text: item?.name ?? '');
    _price = TextEditingController(text: item?.pricePerDay.toString() ?? '');
    _description = TextEditingController(text: item?.description ?? '');
    _discountEnabled = (item?.discountPercent ?? 0) > 0;
    _discount = TextEditingController(
      text: (item?.discountPercent ?? 0).toString(),
    );
    _imagePaths = item == null
        ? []
        : item.galleryUrls.isNotEmpty
        ? List.of(item.galleryUrls)
        : item.imageUrl.isEmpty
        ? []
        : [item.imageUrl];
    _storagePaths = List.of(item?.storagePaths ?? const []);
    _category = item?.category ?? ItemCategory.electronics;
    _condition = item?.condition ?? 'Good';
    _availability = item?.availability ?? AvailabilityStatus.available;
  }

  @override
  void dispose() {
    _name.dispose();
    _price.dispose();
    _description.dispose();
    _discount.dispose();
    super.dispose();
  }

  InputDecoration _decoration(String label, {String? hint}) => InputDecoration(
    labelText: label,
    hintText: hint,
    filled: true,
    fillColor: AppColors.surface,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.md),
      borderSide: const BorderSide(color: AppColors.border),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.md),
      borderSide: const BorderSide(color: AppColors.border),
    ),
  );

  Future<void> _pickPhotos() async {
    if (_imagePaths.length >= _maxPhotos) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You can add up to 5 photos.')),
      );
      return;
    }

    final picked = await _imagePicker.pickMultiImage(
      imageQuality: 85,
      maxWidth: 1600,
    );
    if (picked.isEmpty || !mounted) return;

    final availableSlots = _maxPhotos - _imagePaths.length;
    final newPaths = picked
        .map((image) => image.path)
        .where((path) => !_imagePaths.contains(path))
        .take(availableSlots);
    setState(() => _imagePaths.addAll(newPaths));

    if (picked.length > availableSlots && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Only the first 5 photos were added.')),
      );
    }
  }

  void _removePhoto(String path) {
    final index = _imagePaths.indexOf(path);
    if (index == -1) return;
    setState(() {
      _imagePaths.removeAt(index);
      if (index < _storagePaths.length) {
        _storagePaths.removeAt(index);
      }
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _saveError = null;
    });
    final auth = context.read<AuthState>();
    final item = OwnerListing(
      id:
          widget.item?.id ??
          'owner-local-${DateTime.now().millisecondsSinceEpoch}',
      name: _name.text.trim(),
      category: _category,
      pricePerDay: int.parse(_price.text.trim()),
      discountPercent: _discountEnabled ? int.parse(_discount.text.trim()) : 0,
      description: _description.text.trim(),
      condition: _condition,
      availability: _availability,
      imageUrl: _imagePaths.isEmpty ? '' : _imagePaths.first,
      galleryUrls: List.of(_imagePaths),
      storagePaths: List.of(_storagePaths),
      community: widget.community,
      ownerId: auth.currentUser?.id ?? 'user-owner-001',
      ownerName: auth.currentUser?.name ?? 'Sample Owner',
      moderationStatus:
          widget.item?.moderationStatus ?? ListingModerationStatus.active,
    );
    try {
      await OwnerListingsStore.instance.saveRemote(item, auth.accessToken);
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _saveError = error.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final categories = ItemCategory.values
        .where((c) => c != ItemCategory.all)
        .toList();
    return Scaffold(
      appBar: AppBar(title: Text(editing ? 'Edit Item' : 'List an Item')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              Text(
                editing
                    ? 'Update your rental listing.'
                    : 'Share an item with your community.',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: AppSpacing.lg),
              TextFormField(
                controller: _name,
                decoration: _decoration(
                  'Item name',
                  hint: 'e.g. Canon EOS Camera',
                ),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Item name is required.'
                    : null,
              ),
              const SizedBox(height: AppSpacing.md),
              DropdownButtonFormField<ItemCategory>(
                initialValue: _category,
                decoration: _decoration('Category'),
                items: categories
                    .map(
                      (c) => DropdownMenuItem(value: c, child: Text(c.label)),
                    )
                    .toList(),
                onChanged: (v) => setState(() => _category = v ?? _category),
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _price,
                keyboardType: TextInputType.number,
                decoration: _decoration('Price per day', hint: '500'),
                onChanged: (_) => setState(() {}),
                validator: (v) {
                  final value = int.tryParse(v ?? '');
                  if (value == null || value <= 0 || value > 1000000) {
                    return 'Enter a daily price from ₱1 to ₱1,000,000.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.md),
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                title: const Text('Offer a daily discount'),
                subtitle: const Text(
                  'Optional. You choose up to 20% off every rental day.',
                ),
                value: _discountEnabled,
                onChanged: _saving
                    ? null
                    : (enabled) => setState(() => _discountEnabled = enabled),
              ),
              if (_discountEnabled) ...[
                TextFormField(
                  controller: _discount,
                  keyboardType: TextInputType.number,
                  decoration: _decoration('Discount (%)', hint: '0–20'),
                  onChanged: (_) => setState(() {}),
                  validator: (value) {
                    final percent = int.tryParse(value?.trim() ?? '');
                    return percent == null || percent < 0 || percent > 20
                        ? 'Enter a whole percentage from 0 to 20.'
                        : null;
                  },
                ),
                const SizedBox(height: AppSpacing.sm),
                Builder(
                  builder: (context) {
                    final base = int.tryParse(_price.text.trim());
                    final percent = int.tryParse(_discount.text.trim());
                    if (base == null ||
                        base < 1 ||
                        percent == null ||
                        percent < 0 ||
                        percent > 20) {
                      return const SizedBox.shrink();
                    }
                    return Text(
                      'Renter pays ${formatPesos(discountedDailyCentavos(base, percent) / 100)} / day '
                      '(regular ${formatPesos(base)}).',
                      style: Theme.of(context).textTheme.bodyMedium,
                    );
                  },
                ),
              ],
              const SizedBox(height: AppSpacing.md),
              DropdownButtonFormField<String>(
                initialValue: _condition,
                decoration: _decoration('Condition'),
                items: const ['Excellent', 'Good', 'Fair']
                    .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                    .toList(),
                onChanged: (v) => setState(() => _condition = v ?? _condition),
              ),
              const SizedBox(height: AppSpacing.md),
              DropdownButtonFormField<AvailabilityStatus>(
                initialValue: _availability,
                decoration: _decoration('Availability'),
                items:
                    const [
                          AvailabilityStatus.available,
                          AvailabilityStatus.unavailable,
                        ]
                        .map(
                          (v) =>
                              DropdownMenuItem(value: v, child: Text(v.label)),
                        )
                        .toList(),
                onChanged: (v) =>
                    setState(() => _availability = v ?? _availability),
              ),
              const SizedBox(height: AppSpacing.md),
              _PhotoUploadField(
                imagePaths: _imagePaths,
                maxPhotos: _maxPhotos,
                onPick: _pickPhotos,
                onRemove: _removePhoto,
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _description,
                maxLines: 4,
                decoration: _decoration('Description'),
                validator: (v) => (v == null || v.trim().length < 10)
                    ? 'Enter at least 10 characters.'
                    : null,
              ),
              if (_saveError != null) ...[
                const SizedBox(height: AppSpacing.md),
                Text(
                  _saveError!,
                  style: const TextStyle(color: AppColors.error),
                ),
              ],
              const SizedBox(height: AppSpacing.xl),
              SizedBox(
                height: 52,
                child: FilledButton(
                  onPressed: _saving ? null : _save,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                  ),
                  child: _saving
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(editing ? 'SAVE CHANGES' : 'PUBLISH ITEM'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PhotoUploadField extends StatelessWidget {
  final List<String> imagePaths;
  final int maxPhotos;
  final VoidCallback onPick;
  final ValueChanged<String> onRemove;

  const _PhotoUploadField({
    required this.imagePaths,
    required this.maxPhotos,
    required this.onPick,
    required this.onRemove,
  });

  Widget _image(String path) {
    final isNetwork = path.startsWith('http://') || path.startsWith('https://');
    if (isNetwork) {
      return Image.network(
        path,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => const Icon(Icons.broken_image_outlined),
      );
    }
    return Image.file(
      File(path),
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => const Icon(Icons.broken_image_outlined),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Item photos',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            Text(
              '${imagePaths.length}/$maxPhotos',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        if (imagePaths.isEmpty)
          InkWell(
            onTap: onPick,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            child: Container(
              height: 160,
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.primarySofter,
                borderRadius: BorderRadius.circular(AppRadius.lg),
                border: Border.all(color: AppColors.border),
              ),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.add_photo_alternate_outlined,
                    size: 48,
                    color: AppColors.primary,
                  ),
                  SizedBox(height: 8),
                  Text('Select up to 5 photos'),
                ],
              ),
            ),
          )
        else
          SizedBox(
            height: 130,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: imagePaths.length,
              separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.sm),
              itemBuilder: (_, index) {
                final path = imagePaths[index];
                return Stack(
                  children: [
                    Container(
                      width: 130,
                      clipBehavior: Clip.antiAlias,
                      decoration: BoxDecoration(
                        color: AppColors.primarySofter,
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: _image(path),
                    ),
                    Positioned(
                      top: 4,
                      right: 4,
                      child: Material(
                        color: Colors.black54,
                        shape: const CircleBorder(),
                        child: InkWell(
                          onTap: () => onRemove(path),
                          customBorder: const CircleBorder(),
                          child: const Padding(
                            padding: EdgeInsets.all(6),
                            child: Icon(
                              Icons.close_rounded,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                        ),
                      ),
                    ),
                    if (index == 0)
                      Positioned(
                        left: 6,
                        bottom: 6,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(AppRadius.pill),
                          ),
                          child: const Text(
                            'COVER',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        if (imagePaths.length < maxPhotos) ...[
          const SizedBox(height: AppSpacing.sm),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onPick,
              icon: const Icon(Icons.add_photo_alternate_outlined),
              label: Text(
                imagePaths.isEmpty ? 'UPLOAD PHOTOS' : 'ADD MORE PHOTOS',
              ),
            ),
          ),
        ],
      ],
    );
  }
}
