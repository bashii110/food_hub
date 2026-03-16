import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/services/api_client.dart';
import '../../presentation/providers/paymentsettingsprovider.dart'; // ← fixed

class AdminPaymentSettingsScreen extends ConsumerStatefulWidget {
  const AdminPaymentSettingsScreen({super.key});

  @override
  ConsumerState<AdminPaymentSettingsScreen> createState() =>
      _AdminPaymentSettingsScreenState();
}

class _AdminPaymentSettingsScreenState
    extends ConsumerState<AdminPaymentSettingsScreen> {

  final Map<int, Map<String, TextEditingController>> _controllers = {};
  final Map<int, bool> _saving = {};

  @override
  void dispose() {
    for (final row in _controllers.values) {
      for (final c in row.values) { c.dispose(); }
    }
    super.dispose();
  }

  void _initControllers(Map<String, dynamic> setting) {
    final id = setting['id'] as int;
    if (_controllers.containsKey(id)) return;
    _controllers[id] = {
      'account_number': TextEditingController(
          text: setting['account_number'] as String? ?? ''),
      'account_name': TextEditingController(
          text: setting['account_name'] as String? ?? ''),
      'instructions': TextEditingController(
          text: setting['instructions'] as String? ?? ''),
    };
  }

  Future<void> _save(int id) async {
    final ctrl = _controllers[id]!;
    setState(() => _saving[id] = true);
    try {
      await apiClient.put('/admin/payment-settings/$id', body: {
        'account_number': ctrl['account_number']!.text.trim(),
        'account_name':   ctrl['account_name']!.text.trim(),
        'instructions':   ctrl['instructions']!.text.trim(),
      });
      ref.invalidate(adminPaymentSettingsProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content:         Text('Saved successfully'),
          backgroundColor: Colors.green,
          behavior:        SnackBarBehavior.floating,
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content:         Text('Failed to save: $e'),
          backgroundColor: Colors.red,
          behavior:        SnackBarBehavior.floating,
        ));
      }
    } finally {
      if (mounted) setState(() => _saving[id] = false);
    }
  }

  Future<void> _toggleActive(int id, bool current) async {
    try {
      await apiClient.put('/admin/payment-settings/$id', body: {
        'is_active': !current,
      });
      ref.invalidate(adminPaymentSettingsProvider);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Failed: $e'),
          behavior: SnackBarBehavior.floating,
        ));
      }
    }
  }

  Color _color(String method) {
    switch (method) {
      case 'jazzcash':      return Colors.red.shade700;
      case 'easypaisa':     return Colors.green.shade700;
      case 'bank_transfer': return Colors.blue.shade700;
      default:              return Colors.grey;
    }
  }

  String _label(String method) {
    switch (method) {
      case 'jazzcash':      return 'JazzCash';
      case 'easypaisa':     return 'Easypaisa';
      case 'bank_transfer': return 'Bank Transfer';
      default:              return method;
    }
  }

  IconData _icon(String method) {
    switch (method) {
      case 'jazzcash':      return Icons.phone_android;
      case 'easypaisa':     return Icons.account_balance_wallet;
      case 'bank_transfer': return Icons.account_balance;
      default:              return Icons.payment;
    }
  }

  @override
  Widget build(BuildContext context) {
    final settingsAsync = ref.watch(adminPaymentSettingsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment Account Settings'),
        actions: [
          IconButton(
            icon:      const Icon(Icons.refresh),
            tooltip:   'Refresh',
            onPressed: () => ref.invalidate(adminPaymentSettingsProvider),
          ),
        ],
      ),
      body: settingsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 12),
              Text('Failed to load: $e'),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => ref.invalidate(adminPaymentSettingsProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (settings) {
          if (settings.isEmpty) {
            return const Center(
                child: Text('No payment settings found.\nRun the seeder.'));
          }

          return ListView.separated(
            padding:          const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            itemCount:        settings.length,
            separatorBuilder: (_, __) => const SizedBox(height: 16),
            itemBuilder: (_, i) {
              final s      = settings[i];
              final id     = s['id'] as int;
              final method = s['method'] as String;
              final active = s['is_active'] as bool? ?? true;
              final color  = _color(method);

              _initControllers(s);
              final ctrl = _controllers[id]!;

              return Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: color.withOpacity(0.3)),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      // ── Header ───────────────────────────────
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          CircleAvatar(
                            backgroundColor: color.withOpacity(0.12),
                            child: Icon(_icon(method), color: color, size: 25),
                          ),
                          const SizedBox(width: 3),
                          Text(_label(method),
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: color)),
                          const Spacer(),
                          Row(children: [
                            Text(active ? 'Active' : 'Inactive',
                                style: TextStyle(
                                    fontSize: 12,
                                    color: active ? Colors.green : Colors.grey)),
                            const SizedBox(width: 2),
                            Switch(
                              value:       active,
                              onChanged:   (_) => _toggleActive(id, active),
                              activeColor: Colors.green,
                            ),
                          ]),
                        ],
                      ),

                      const Divider(height: 24),

                      // ── Account Number ────────────────────────
                      TextField(
                        controller: ctrl['account_number'],
                        decoration: InputDecoration(
                          labelText:  'Account Number',
                          prefixIcon: const Icon(Icons.tag),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // ── Account Name ──────────────────────────
                      TextField(
                        controller: ctrl['account_name'],
                        decoration: InputDecoration(
                          labelText:  'Account Name',
                          prefixIcon: const Icon(Icons.person_outline),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // ── Instructions ──────────────────────────
                      TextField(
                        controller: ctrl['instructions'],
                        maxLines: 2,
                        decoration: InputDecoration(
                          labelText:  'Instructions (optional)',
                          prefixIcon: const Icon(Icons.info_outline),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // ── Save Button ───────────────────────────
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _saving[id] == true
                              ? null
                              : () => _save(id),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: color,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                          ),
                          icon: _saving[id] == true
                              ? const SizedBox(
                              width: 16, height: 16,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2))
                              : const Icon(Icons.save_outlined, size: 18),
                          label: Text(_saving[id] == true
                              ? 'Saving...'
                              : 'Save ${_label(method)}'),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}