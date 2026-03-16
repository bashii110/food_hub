// lib/home/admin/admin_product_screen.dart
//
// Replace BOTH:
//   lib/home/admin/admin_product_screen.dart
//   (and keep lib/admin_panel/admin_panel.dart ProductsPage pointing here
//    or replace admin_panel.dart's ProductsPage with AdminProductsScreen)
//
import 'dart:convert';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';

import '../../data/services/api_client.dart';

// ─────────────────────────────────────────────────────────────
// URL helper
// Converts "/storage/products/x.jpg" → "http://host:port/storage/products/x.jpg"
// Strips the /api path so images are served from the web root.
// ─────────────────────────────────────────────────────────────
String _fullUrl(String? raw) {
  if (raw == null || raw.isEmpty) return '';
  if (raw.startsWith('http://') || raw.startsWith('https://')) return raw;
  final u = Uri.parse(ApiClient.baseUrl);
  // u.host = "192.168.100.21", u.port = 8000
  // raw    = "/storage/products/abc.jpg"
  return '${u.scheme}://${u.host}:${u.port}$raw';
}

// ─────────────────────────────────────────────────────────────
// Sends a multipart POST to /products/{id}/update
//
// This is the CORRECT way to upload a file when editing a product.
// We do NOT use _method=PUT spoofing because Laravel 11's API
// middleware stack never processes that field — only the web stack does.
// A plain POST to the dedicated route is 100% reliable.
// ─────────────────────────────────────────────────────────────
Future<void> _uploadProductImage({
  required int productId,
  required File imageFile,
  required Map<String, String> fields, // name, price, etc.
}) async {
  final uri = Uri.parse('${ApiClient.baseUrl}/products/$productId/update');
  final token = await apiClient.getToken();
  final bytes = await imageFile.readAsBytes();

  final request = http.MultipartRequest('POST', uri)
    ..headers['Accept'] = 'application/json'
    ..headers['Authorization'] = 'Bearer $token'
    ..fields.addAll(fields)
    ..files.add(
      http.MultipartFile.fromBytes(
        'image',           // field name the backend expects
        bytes,
        filename: 'product_${DateTime.now().millisecondsSinceEpoch}.jpg',
        contentType: MediaType('image', 'jpeg'), // explicit MIME so mimes: validator passes
      ),
    );

  final streamed = await request.send();
  final response = await http.Response.fromStream(streamed);

  if (response.statusCode >= 400) {
    String msg = 'Upload failed (${response.statusCode})';
    try {
      final body = json.decode(response.body) as Map<String, dynamic>;
      msg = body['message'] as String? ?? msg;
      final errs = body['errors'] as Map<String, dynamic>?;
      if (errs != null) {
        msg += '\n' +
            errs.values.map((e) => (e as List).join(', ')).join('\n');
      }
    } catch (_) {}
    throw Exception(msg);
  }
}

// ═════════════════════════════════════════════════════════════
// SCREEN
// ═════════════════════════════════════════════════════════════
class AdminProductsScreen extends ConsumerStatefulWidget {
  const AdminProductsScreen({super.key});

  @override
  ConsumerState<AdminProductsScreen> createState() =>
      _AdminProductsScreenState();
}

class _AdminProductsScreenState extends ConsumerState<AdminProductsScreen> {
  List<Map<String, dynamic>> _products = [];
  List<Map<String, dynamic>> _categories = [];
  bool _loading = true;
  String _search = '';
  int? _filterCatId;
  int _page = 1, _lastPage = 1, _total = 0;
  final _searchCtrl = TextEditingController();

  // ── safe type coercions ───────────────────────────────────
  static int _i(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString()) ?? 0;
  }

  static double _d(dynamic v) {
    if (v == null) return 0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0;
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  // ── load list ─────────────────────────────────────────────
  Future<void> _load({int page = 1}) async {
    setState(() => _loading = true);
    try {
      if (_categories.isEmpty) {
        final cr = await apiClient.get('/categories');
        _categories =
            (cr['categories'] as List? ?? []).cast<Map<String, dynamic>>();
      }

      final q = StringBuffer('/products?all=true&per_page=15&page=$page');
      if (_search.isNotEmpty)
        q.write('&search=${Uri.encodeComponent(_search)}');
      if (_filterCatId != null) q.write('&category_id=$_filterCatId');

      final pr = await apiClient.get(q.toString());
      setState(() {
        _products =
            (pr['data'] as List? ?? []).cast<Map<String, dynamic>>();
        _total    = _i(pr['total'] ?? _products.length);
        _page     = _i(pr['current_page'] ?? 1);
        _lastPage = _i(pr['last_page'] ?? 1);
        _loading  = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      _snack('Failed to load: $e', error: true);
    }
  }

  void _snack(String msg, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: error ? Colors.red : Colors.green,
      behavior: SnackBarBehavior.floating,
    ));
  }

  Future<void> _delete(Map<String, dynamic> p) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Delete Product'),
        content: Text('Delete "${p['name']}"? This cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(c, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(c, true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Delete')),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await apiClient.delete('/products/${p['id']}');
      _load(page: _page);
    } catch (e) {
      _snack('Delete failed: $e', error: true);
    }
  }

  Future<void> _toggleAvail(Map<String, dynamic> p) async {
    final cur = p['is_available'] as bool? ?? true;
    try {
      await apiClient
          .put('/products/${p['id']}', body: {'is_available': !cur});
      _load(page: _page);
    } catch (e) {
      _snack('Update failed: $e', error: true);
    }
  }

  void _openForm(Map<String, dynamic>? existing) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _ProductForm(
        categories: _categories,
        existing: existing,
        onSaved: () => _load(page: _page),
      ),
    );
  }

  // ── build ─────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(null),
        icon: const Icon(Icons.add),
        label: const Text('Add Product'),
      ),
      body: Column(children: [
        // search + filter chips
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child:
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Search products…',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _search.isNotEmpty
                    ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _searchCtrl.clear();
                      setState(() => _search = '');
                      _load();
                    })
                    : null,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
              ),
              onChanged: (v) {
                setState(() => _search = v);
                Future.delayed(const Duration(milliseconds: 500), () {
                  if (_search == v) _load();
                });
              },
            ),
            if (_categories.isNotEmpty) ...[
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(children: [
                  FilterChip(
                      label: const Text('All'),
                      selected: _filterCatId == null,
                      onSelected: (_) {
                        setState(() => _filterCatId = null);
                        _load();
                      }),
                  const SizedBox(width: 6),
                  ..._categories.map((c) {
                    final id = _i(c['id']);
                    return Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: FilterChip(
                          label: Text(c['name'] as String? ?? ''),
                          selected: _filterCatId == id,
                          onSelected: (_) {
                            setState(() => _filterCatId =
                            _filterCatId == id ? null : id);
                            _load();
                          }),
                    );
                  }),
                ]),
              ),
            ],
          ]),
        ),

        const Divider(height: 1),

        // list
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _products.isEmpty
              ? _EmptyState(
              icon: Icons.restaurant_menu,
              message: _search.isNotEmpty
                  ? 'No products match "$_search"'
                  : 'No products yet.\nTap + to add one.')
              : RefreshIndicator(
            onRefresh: () => _load(page: _page),
            child: ListView.separated(
              padding: const EdgeInsets.only(bottom: 100),
              itemCount: _products.length,
              separatorBuilder: (_, __) =>
              const Divider(height: 1, indent: 80),
              itemBuilder: (_, idx) {
                final p = _products[idx];
                final avail = p['is_available'] as bool? ?? true;
                final popular = p['is_popular'] as bool? ?? false;
                final price = _d(p['price']);
                final cat =
                p['category'] as Map<String, dynamic>?;
                final catName = cat?['name'] as String? ?? '—';

                // ✅ Always build absolute URL
                final imgUrl =
                _fullUrl(p['image_url'] as String?);

                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 4),
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: SizedBox(
                      width: 56,
                      height: 56,
                      child: imgUrl.isNotEmpty
                          ? CachedNetworkImage(
                        imageUrl: imgUrl,
                        fit: BoxFit.cover,
                        placeholder: (_, __) =>
                        const _ImgPlaceholder(),
                        errorWidget: (_, __, ___) =>
                        const _ImgPlaceholder(),
                      )
                          : const _ImgPlaceholder(),
                    ),
                  ),
                  title: Row(children: [
                    Flexible(
                        child: Text(p['name'] as String? ?? '',
                            style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color:
                                avail ? null : Colors.grey),
                            overflow: TextOverflow.ellipsis)),
                    if (popular)
                      const Padding(
                        padding: EdgeInsets.only(left: 4),
                        child: Icon(Icons.star,
                            size: 14, color: Colors.amber),
                      ),
                  ]),
                  subtitle: Column(
                      crossAxisAlignment:
                      CrossAxisAlignment.start,
                      children: [
                        Text(
                            'Rs ${price.toStringAsFixed(0)}  •  $catName',
                            style: TextStyle(
                                fontSize: 12,
                                color: theme.colorScheme.primary)),
                        if (!avail)
                          const Text('Unavailable',
                              style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.red)),
                      ]),
                  trailing: PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert),
                    onSelected: (a) {
                      if (a == 'edit') _openForm(p);
                      if (a == 'toggle') _toggleAvail(p);
                      if (a == 'delete') _delete(p);
                    },
                    itemBuilder: (_) => [
                      const PopupMenuItem(
                          value: 'edit',
                          child: ListTile(
                              leading: Icon(Icons.edit),
                              title: Text('Edit'),
                              contentPadding: EdgeInsets.zero,
                              dense: true)),
                      PopupMenuItem(
                          value: 'toggle',
                          child: ListTile(
                              leading: Icon(avail
                                  ? Icons.visibility_off
                                  : Icons.visibility),
                              title: Text(avail
                                  ? 'Mark Unavailable'
                                  : 'Mark Available'),
                              contentPadding: EdgeInsets.zero,
                              dense: true)),
                      const PopupMenuDivider(),
                      const PopupMenuItem(
                          value: 'delete',
                          child: ListTile(
                              leading: Icon(Icons.delete,
                                  color: Colors.red),
                              title: Text('Delete',
                                  style: TextStyle(
                                      color: Colors.red)),
                              contentPadding: EdgeInsets.zero,
                              dense: true)),
                    ],
                  ),
                );
              },
            ),
          ),
        ),

        // pagination
        if (_lastPage > 1)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child:
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed:
                  _page > 1 ? () => _load(page: _page - 1) : null),
              Text('$_page / $_lastPage  ($_total)'),
              IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: _page < _lastPage
                      ? () => _load(page: _page + 1)
                      : null),
            ]),
          ),
      ]),
    );
  }
}

// ═════════════════════════════════════════════════════════════
// PRODUCT FORM  (bottom sheet — create & edit)
// ═════════════════════════════════════════════════════════════
class _ProductForm extends StatefulWidget {
  final List<Map<String, dynamic>> categories;
  final Map<String, dynamic>? existing;
  final VoidCallback onSaved;

  const _ProductForm(
      {required this.categories,
        required this.existing,
        required this.onSaved});

  @override
  State<_ProductForm> createState() => _ProductFormState();
}

class _ProductFormState extends State<_ProductForm> {
  final _key = GlobalKey<FormState>();
  late final TextEditingController _name, _price, _desc, _prep, _cal;
  int? _catId;
  bool _popular = false, _available = true, _saving = false;

  File? _pickedFile;       // new image the admin just selected from gallery
  String? _serverImgUrl;  // image already stored on server (full URL)

  static int _i(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString()) ?? 0;
  }

  static double _d(dynamic v) {
    if (v == null) return 0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0;
  }

  @override
  void initState() {
    super.initState();
    final p = widget.existing;
    _name  = TextEditingController(text: p?['name'] as String? ?? '');
    _price = TextEditingController(
        text: p != null ? _d(p['price']).toStringAsFixed(0) : '');
    _desc  = TextEditingController(text: p?['description'] as String? ?? '');
    _prep  = TextEditingController(
        text: p != null ? _i(p['preparation_time']).toString() : '20');
    _cal   = TextEditingController(
        text: p != null ? _i(p['calories']).toString() : '0');

    final cat = p?['category'] as Map<String, dynamic>?;
    _catId     = cat != null ? _i(cat['id']) : null;
    _popular   = p?['is_popular']   as bool? ?? false;
    _available = p?['is_available'] as bool? ?? true;

    final url = _fullUrl(p?['image_url'] as String?);
    _serverImgUrl = url.isNotEmpty ? url : null;
  }

  @override
  void dispose() {
    for (final c in [_name, _price, _desc, _prep, _cal]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pickFromGallery() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 1200,
      maxHeight: 1200,
      imageQuality: 85,
    );
    if (picked != null) setState(() => _pickedFile = File(picked.path));
  }

  // ── Save ─────────────────────────────────────────────────
  Future<void> _save() async {
    if (!_key.currentState!.validate()) return;
    if (_catId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Please select a category'),
          behavior: SnackBarBehavior.floating));
      return;
    }

    setState(() => _saving = true);

    try {
      final isEdit = widget.existing != null;

      if (_pickedFile != null) {
        // ── Path A: has new image → use multipart POST ────────
        //
        // For BOTH create and edit we use the same approach:
        //   • Create: POST /products  (multipart, image optional)
        //   • Edit:   POST /products/{id}/update  (dedicated endpoint)
        //
        // We do NOT use _method=PUT because Laravel 11 API routes
        // do not process form-method spoofing.
        //
        final fields = <String, String>{
          'name':             _name.text.trim(),
          'price':            _price.text.trim(),
          'description':      _desc.text.trim(),
          'category_id':      _catId.toString(),
          'preparation_time': (int.tryParse(_prep.text) ?? 20).toString(),
          'calories':         (int.tryParse(_cal.text)  ?? 0).toString(),
          'is_popular':       _popular   ? '1' : '0',
          'is_available':     _available ? '1' : '0',
        };

        if (isEdit) {
          // Edit with new image → POST /products/{id}/update
          await _uploadProductImage(
            productId: widget.existing!['id'] as int,
            imageFile: _pickedFile!,
            fields: fields,
          );
        } else {
          // Create with image → POST /products (multipart)
          final bytes = await _pickedFile!.readAsBytes();
          final uri   = Uri.parse('${ApiClient.baseUrl}/products');
          final token = await apiClient.getToken();

          final request = http.MultipartRequest('POST', uri)
            ..headers['Accept'] = 'application/json'
            ..headers['Authorization'] = 'Bearer $token'
            ..fields.addAll(fields)
            ..files.add(http.MultipartFile.fromBytes(
              'image',
              bytes,
              filename:
              'product_${DateTime.now().millisecondsSinceEpoch}.jpg',
              contentType: MediaType('image', 'jpeg'),
            ));

          final streamed  = await request.send();
          final response  = await http.Response.fromStream(streamed);

          if (response.statusCode >= 400) {
            String msg = 'Create failed (${response.statusCode})';
            try {
              final b = json.decode(response.body) as Map<String, dynamic>;
              msg = b['message'] as String? ?? msg;
              final errs = b['errors'] as Map<String, dynamic>?;
              if (errs != null) {
                msg += '\n' +
                    errs.values
                        .map((e) => (e as List).join(', '))
                        .join('\n');
              }
            } catch (_) {}
            throw Exception(msg);
          }
        }
      } else {
        // ── Path B: no new image → plain JSON ────────────────
        final body = <String, dynamic>{
          'name':             _name.text.trim(),
          'price':            double.tryParse(_price.text.trim()) ?? 0,
          'description':      _desc.text.trim(),
          'category_id':      _catId,
          'preparation_time': int.tryParse(_prep.text)  ?? 20,
          'calories':         int.tryParse(_cal.text)   ?? 0,
          'is_popular':       _popular,
          'is_available':     _available,
        };

        if (isEdit) {
          await apiClient.put('/products/${widget.existing!['id']}',
              body: body);
        } else {
          await apiClient.post('/products', body: body);
        }
      }

      if (mounted) Navigator.pop(context);
      widget.onSaved();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
              widget.existing != null ? 'Product updated ✓' : 'Product created ✓'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ));
      }
    } catch (e) {
      setState(() => _saving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ));
      }
    }
  }

  InputDecoration _dec(String hint, IconData icon) => InputDecoration(
    hintText: hint,
    prefixIcon: Icon(icon),
    border:
    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    contentPadding:
    const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
  );

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;
    return Padding(
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom),
      child: DraggableScrollableSheet(
        initialChildSize: 0.92,
        minChildSize: 0.5,
        maxChildSize: 0.97,
        expand: false,
        builder: (_, ctrl) => Form(
          key: _key,
          child: ListView(
            controller: ctrl,
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
            children: [
              // drag handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2)),
                ),
              ),

              Text(isEdit ? 'Edit Product' : 'Add Product',
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),

              // ── image picker box ────────────────────────
              GestureDetector(
                onTap: _pickFromGallery,
                child: Container(
                  height: 180,
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceVariant,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: Theme.of(context)
                            .colorScheme
                            .outline
                            .withOpacity(0.4)),
                  ),
                  child: _pickedFile != null
                  // ① freshly picked local file
                      ? Stack(fit: StackFit.expand, children: [
                    Image.file(_pickedFile!, fit: BoxFit.cover),
                    const Positioned(
                        bottom: 8,
                        right: 8,
                        child: _Badge('Change Photo')),
                  ])
                      : _serverImgUrl != null
                  // ② image already on server
                      ? Stack(fit: StackFit.expand, children: [
                    CachedNetworkImage(
                      imageUrl: _serverImgUrl!,
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) =>
                      const _NoImg(),
                    ),
                    const Positioned(
                        bottom: 8,
                        right: 8,
                        child: _Badge('Change Photo')),
                  ])
                  // ③ no image yet
                      : const _NoImg(),
                ),
              ),
              const SizedBox(height: 6),
              Center(
                child: Text(
                  'Tap to pick image from gallery  •  jpg / png  •  max 4 MB',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.outline),
                ),
              ),
              const SizedBox(height: 20),

              // ── text fields ─────────────────────────────
              TextFormField(
                controller: _name,
                decoration: _dec('Product Name', Icons.fastfood_outlined),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Name is required'
                    : null,
              ),
              const SizedBox(height: 14),

              TextFormField(
                controller: _price,
                keyboardType: TextInputType.number,
                decoration: _dec('Price (Rs)', Icons.attach_money),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Price required';
                  if (double.tryParse(v) == null) return 'Enter a valid number';
                  return null;
                },
              ),
              const SizedBox(height: 14),

              DropdownButtonFormField<int>(
                value: _catId,
                decoration: _dec('Category', Icons.category_outlined),
                items: widget.categories
                    .map((c) => DropdownMenuItem<int>(
                  value: _i(c['id']),
                  child: Text(c['name'] as String? ?? ''),
                ))
                    .toList(),
                onChanged: (v) => setState(() => _catId = v),
                validator: (v) =>
                v == null ? 'Please select a category' : null,
              ),
              const SizedBox(height: 14),

              TextFormField(
                controller: _desc,
                maxLines: 3,
                decoration:
                _dec('Description (optional)', Icons.notes_outlined),
              ),
              const SizedBox(height: 14),

              Row(children: [
                Expanded(
                    child: TextFormField(
                        controller: _prep,
                        keyboardType: TextInputType.number,
                        decoration: _dec(
                            'Prep Time (min)', Icons.timer_outlined))),
                const SizedBox(width: 12),
                Expanded(
                    child: TextFormField(
                        controller: _cal,
                        keyboardType: TextInputType.number,
                        decoration: _dec('Calories',
                            Icons.local_fire_department_outlined))),
              ]),
              const SizedBox(height: 4),

              SwitchListTile(
                title: const Text('Mark as Popular'),
                subtitle: const Text('Shows in Popular Dishes section'),
                value: _popular,
                onChanged: (v) => setState(() => _popular = v),
                contentPadding: EdgeInsets.zero,
              ),
              SwitchListTile(
                title: const Text('Available'),
                subtitle: const Text('Visible to customers'),
                value: _available,
                onChanged: (v) => setState(() => _available = v),
                contentPadding: EdgeInsets.zero,
              ),
              const SizedBox(height: 24),

              SizedBox(
                height: 52,
                child: FilledButton(
                  onPressed: _saving ? null : _save,
                  child: _saving
                      ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2.5))
                      : Text(
                      isEdit ? 'Update Product' : 'Create Product',
                      style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════
// TINY HELPER WIDGETS
// ═════════════════════════════════════════════════════════════

class _NoImg extends StatelessWidget {
  const _NoImg();
  @override
  Widget build(BuildContext context) => Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Icon(Icons.add_photo_alternate_outlined,
          size: 52, color: Theme.of(context).colorScheme.outline),
      const SizedBox(height: 10),
      Text('Tap to add product image',
          style: TextStyle(
              color: Theme.of(context).colorScheme.outline,
              fontSize: 13)),
    ],
  );
}

class _Badge extends StatelessWidget {
  final String label;
  const _Badge(this.label);
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(20)),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      const Icon(Icons.edit, size: 12, color: Colors.white),
      const SizedBox(width: 4),
      Text(label,
          style:
          const TextStyle(color: Colors.white, fontSize: 11)),
    ]),
  );
}

class _ImgPlaceholder extends StatelessWidget {
  const _ImgPlaceholder();
  @override
  Widget build(BuildContext context) => Container(
    color: Theme.of(context).colorScheme.surfaceVariant,
    child: Icon(Icons.restaurant,
        color: Theme.of(context).colorScheme.outline, size: 28),
  );
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  const _EmptyState({required this.icon, required this.message});
  @override
  Widget build(BuildContext context) => Center(
    child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(message,
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: Colors.grey.shade500, fontSize: 16)),
        ]),
  );
}