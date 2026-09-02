import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../theme/app_theme.dart';
import '../../services/complaint_service.dart';
import '../../services/api_exception.dart';
import '../../models/order.dart';

const _reasons = [
  'Job not completed properly',
  'Baas did not show up',
  'Overcharged',
  'Unprofessional behaviour',
  'Other',
];

/// A complaint can only be filed for a Completed order (enforced
/// server-side too) - reason, details, and an optional photo.
/// Confirmed against the real backend: submitting notifies both this
/// customer and the Baas, and an Approved decision on a pay_now
/// order refunds the order total to this customer's wallet.
class ComplaintScreen extends StatefulWidget {
  final MybaasOrder order;

  const ComplaintScreen({super.key, required this.order});

  @override
  State<ComplaintScreen> createState() => _ComplaintScreenState();
}

class _ComplaintScreenState extends State<ComplaintScreen> {
  String? _reason;
  final _detailsController = TextEditingController();
  String? _photoBase64;
  bool _submitting = false;
  String? _error;

  final _picker = ImagePicker();

  @override
  void dispose() {
    _detailsController.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    try {
      final file = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 70, maxWidth: 1280);
      if (file == null) return;
      final bytes = await file.readAsBytes();
      setState(() => _photoBase64 = 'data:image/jpeg;base64,${base64Encode(bytes)}');
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to add photo. Please try again.')),
      );
    }
  }

  bool get _canSubmit => _reason != null && _detailsController.text.trim().isNotEmpty;

  Future<void> _submit() async {
    if (!_canSubmit) return;

    setState(() {
      _submitting = true;
      _error = null;
    });

    try {
      await ComplaintService.instance.submit(
        orderId: widget.order.orderId,
        reason: _reason!,
        details: _detailsController.text.trim(),
        photos: _photoBase64 != null ? [_photoBase64!] : const [],
      );

      if (!mounted) return;
      Navigator.of(context).pop(true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Complaint submitted. We will review it shortly.')),
      );
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } catch (e) {
      setState(() => _error = 'Unable to submit your complaint. Please try again.');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Report a Problem')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.order.service, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                  const SizedBox(height: 3),
                  Text(widget.order.orderId, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                ],
              ),
            ),
            const SizedBox(height: 20),

            Text('Reason', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _reasons.map((r) {
                final selected = _reason == r;
                return ChoiceChip(
                  label: Text(r),
                  selected: selected,
                  onSelected: (_) => setState(() => _reason = r),
                  selectedColor: AppColors.accentSoft,
                  labelStyle: TextStyle(
                    color: selected ? AppColors.accent : AppColors.textSecondary,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  ),
                  side: BorderSide(color: selected ? AppColors.accent : AppColors.border),
                  backgroundColor: AppColors.surface,
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            Text('Details', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            TextField(
              controller: _detailsController,
              maxLines: 4,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(hintText: 'Describe what happened'),
            ),
            const SizedBox(height: 20),

            Text('Photo (optional)', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            InkWell(
              onTap: _pickPhoto,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: _photoBase64 != null ? AppColors.successSoft : AppColors.surface,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  border: Border.all(color: _photoBase64 != null ? AppColors.success.withValues(alpha: 0.3) : AppColors.border),
                ),
                child: Row(
                  children: [
                    Icon(
                      _photoBase64 != null ? Icons.check_circle : Icons.add_a_photo_outlined,
                      color: _photoBase64 != null ? AppColors.success : AppColors.primary,
                    ),
                    const SizedBox(width: 12),
                    Text(_photoBase64 != null ? 'Photo added' : 'Add a photo'),
                  ],
                ),
              ),
            ),

            if (_error != null) ...[
              const SizedBox(height: 16),
              Text(_error!, style: const TextStyle(color: AppColors.danger, fontSize: 13)),
            ],

            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: (_canSubmit && !_submitting) ? _submit : null,
                child: _submitting
                    ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white))
                    : const Text('Submit Complaint'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
