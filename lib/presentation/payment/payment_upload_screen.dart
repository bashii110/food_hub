import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show Uint8List, kIsWeb;
import 'package:image_picker/image_picker.dart';
import '../../data/services/order_service.dart';

class PaymentUploadScreen extends StatefulWidget {
  final int orderId;
  final double? amount;

  const PaymentUploadScreen({
    super.key,
    required this.orderId,
    this.amount,
  });

  @override
  State<PaymentUploadScreen> createState() => _PaymentUploadScreenState();
}

class _PaymentUploadScreenState extends State<PaymentUploadScreen> {
  final _referenceController = TextEditingController();
  File? _imageFile;
  List<int>? _imageBytes;
  bool _uploading = false;

  @override
  void dispose() {
    _referenceController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        if (kIsWeb) {
          final bytes = await pickedFile.readAsBytes();
          setState(() => _imageBytes = bytes);
        } else {
          setState(() => _imageFile = File(pickedFile.path));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error picking image: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _takePhoto() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        if (kIsWeb) {
          final bytes = await pickedFile.readAsBytes();
          setState(() => _imageBytes = bytes);
        } else {
          setState(() => _imageFile = File(pickedFile.path));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error taking photo: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _uploadProof() async {
    if (_imageFile == null && _imageBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a payment screenshot'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _uploading = true);

    try {
      List<int> bytes;
      if (kIsWeb) {
        bytes = _imageBytes!;
      } else {
        bytes = await _imageFile!.readAsBytes();
      }

      // ✅ Just await — if it throws, catch handles it
      await OrderService.uploadPaymentProof(
        orderId: widget.orderId,
        imageBytes: bytes,
        reference: _referenceController.text.trim().isEmpty
            ? null
            : _referenceController.text.trim(),
      );

      // ✅ If we reach here, upload succeeded
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Payment proof uploaded successfully!'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Upload failed: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasImage = _imageFile != null || _imageBytes != null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Upload Payment Proof'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Instructions
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Payment Instructions',
                        style: TextStyle(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (widget.amount != null)
                    Text(
                      'Amount to Pay: Rs ${widget.amount!.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  const SizedBox(height: 8),
                  const Text('1. Transfer money via JazzCash/Easypaisa'),
                  const Text('2. Take a screenshot of the transaction'),
                  const Text('3. Upload it below'),
                  const Text('4. Wait for admin verification'),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Image Preview or Upload Buttons
            if (hasImage)
              Column(
                children: [
                  Container(
                    height: 300,
                    decoration: BoxDecoration(
                      border: Border.all(color: theme.colorScheme.outline),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: kIsWeb
                          ? Image.memory(Uint8List.fromList(_imageBytes!), fit: BoxFit.contain)
                          : Image.file(_imageFile!, fit: BoxFit.contain),
                    ),

                  ),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: _pickImage,
                    icon: const Icon(Icons.change_circle),
                    label: const Text('Change Image'),
                  ),
                ],
              )
            else
              Column(
                children: [
                  ElevatedButton.icon(
                    onPressed: _pickImage,
                    icon: const Icon(Icons.photo_library),
                    label: const Text('Choose from Gallery'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(56),
                    ),
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: _takePhoto,
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('Take Photo'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(56),
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 32),

            // Transaction Reference (Optional)
            TextField(
              controller: _referenceController,
              decoration: InputDecoration(
                labelText: 'Transaction Reference (Optional)',
                hintText: 'e.g., TXN123456',
                prefixIcon: const Icon(Icons.receipt),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Upload Button
            SizedBox(
              height: 56,
              child: ElevatedButton(
                onPressed: _uploading ? null : _uploadProof,
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: Colors.white,
                ),
                child: _uploading
                    ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2.5,
                  ),
                )
                    : const Text(
                  'Submit Payment Proof',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}