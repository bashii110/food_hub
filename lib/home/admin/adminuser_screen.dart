import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/services/api_client.dart';

class AdminUsersScreen extends ConsumerStatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  ConsumerState<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends ConsumerState<AdminUsersScreen> {
  List<Map<String, dynamic>> _users = [];
  bool _loading = true;
  String _search = '';
  int _total = 0;
  int _currentPage = 1;
  int _lastPage = 1;
  final _searchCtrl = TextEditingController();

  static int _toInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString()) ?? 0;
  }

  int get _activeCount =>
      _users.where((u) => u['is_active'] == true).length;
  int get _blockedCount =>
      _users.where((u) => u['is_active'] == false).length;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetch({int page = 1}) async {
    setState(() => _loading = true);
    try {
      final q = StringBuffer('/admin/users?page=$page');
      if (_search.isNotEmpty) q.write('&search=${Uri.encodeComponent(_search)}');

      final res = await apiClient.get(q.toString());
      final data = res['data'] as List? ?? [];
      setState(() {
        _users = data.cast<Map<String, dynamic>>();
        _total = _toInt(res['total'] ?? _users.length);
        _currentPage = _toInt(res['current_page'] ?? 1);
        _lastPage = _toInt(res['last_page'] ?? 1);
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) _showError('Failed to load users: $e');
    }
  }

  Future<void> _toggleBlock(Map<String, dynamic> user) async {
    final isActive = user['is_active'] as bool? ?? true;
    final name = user['name'] as String? ?? 'User';
    final action = isActive ? 'Block' : 'Unblock';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('$action User'),
        content: Text(
            '$action "$name"?\n\n'
                '${isActive ? 'They will not be able to log in.' : 'They will regain access.'}'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: isActive
                ? FilledButton.styleFrom(backgroundColor: Colors.red)
                : null,
            child: Text(action),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await apiClient.post('/admin/users/${user['id']}/toggle-block');
      _fetch(page: _currentPage);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
              'User ${isActive ? 'blocked' : 'unblocked'} successfully'),
          backgroundColor: isActive ? Colors.orange : Colors.green,
          behavior: SnackBarBehavior.floating,
        ));
      }
    } catch (e) {
      if (mounted) _showError('$e');
    }
  }

  void _showUserDetail(Map<String, dynamic> user) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _UserDetailSheet(
        user: user,
        onToggleBlock: () {
          Navigator.pop(context);
          _toggleBlock(user);
        },
      ),
    );
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: Colors.red,
      behavior: SnackBarBehavior.floating,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: Column(
        children: [
          // ── Header ─────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Text('Users',
                      style: theme.textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold)),
                  const Spacer(),
                  IconButton(
                      icon: const Icon(Icons.refresh),
                      tooltip: 'Refresh',
                      onPressed: () => _fetch(page: _currentPage)),
                ]),

                // Stats row
                if (!_loading) ...[
                  const SizedBox(height: 8),
                  Wrap(spacing: 8, children: [
                    _StatChip(
                        label: 'Total',
                        value: '$_total',
                        color: theme.colorScheme.primary),
                    _StatChip(
                        label: 'Active',
                        value: '$_activeCount',
                        color: Colors.green),
                    _StatChip(
                        label: 'Blocked',
                        value: '$_blockedCount',
                        color: Colors.red),
                  ]),
                ],

                const SizedBox(height: 12),

                // Search bar
                TextField(
                  controller: _searchCtrl,
                  decoration: InputDecoration(
                    hintText: 'Search by name or email…',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _search.isNotEmpty
                        ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchCtrl.clear();
                          setState(() => _search = '');
                          _fetch();
                        })
                        : null,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                    contentPadding:
                    const EdgeInsets.symmetric(vertical: 0),
                  ),
                  onChanged: (v) {
                    setState(() => _search = v);
                    Future.delayed(const Duration(milliseconds: 500), () {
                      if (_search == v) _fetch();
                    });
                  },
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // ── User List ──────────────────────────────────────
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _users.isEmpty
                ? _EmptyState(
                icon: Icons.person_search,
                message: _search.isNotEmpty
                    ? 'No users found for "$_search"'
                    : 'No users yet')
                : RefreshIndicator(
              onRefresh: () => _fetch(page: _currentPage),
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: _users.length,
                separatorBuilder: (_, __) =>
                const Divider(height: 1, indent: 72),
                itemBuilder: (_, i) {
                  final u = _users[i];
                  final active =
                      u['is_active'] as bool? ?? true;
                  final name =
                      u['name'] as String? ?? 'Unknown';
                  final email = u['email'] as String? ?? '';
                  final orders =
                  _toInt(u['orders_count'] ?? 0);
                  final role =
                      u['role'] as String? ?? 'user';

                  return ListTile(
                    onTap: () => _showUserDetail(u),
                    leading: CircleAvatar(
                      backgroundColor: active
                          ? theme.colorScheme.primaryContainer
                          : Colors.grey.shade200,
                      child: Text(
                        name.isNotEmpty
                            ? name[0].toUpperCase()
                            : '?',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: active
                              ? theme
                              .colorScheme.onPrimaryContainer
                              : Colors.grey,
                        ),
                      ),
                    ),
                    title: Row(children: [
                      Flexible(
                        child: Text(name,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontWeight: FontWeight.w600)),
                      ),
                      const SizedBox(width: 6),
                      if (role == 'admin')
                        _RoleBadge(
                            role: role, color: Colors.purple),
                      if (role == 'staff')
                        _RoleBadge(
                            role: role, color: Colors.blue),
                    ]),
                    subtitle: Text(
                      '$email  •  $orders order${orders == 1 ? '' : 's'}',
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12),
                    ),
                    // ✅ Single compact status badge — no overflow
                    trailing: _StatusBadge(
                        active: active,
                        onToggle: () => _toggleBlock(u)),
                  );
                },
              ),
            ),
          ),

          // ── Pagination ─────────────────────────────────────
          if (_lastPage > 1)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left),
                      onPressed: _currentPage > 1
                          ? () => _fetch(page: _currentPage - 1)
                          : null,
                    ),
                    Text('Page $_currentPage of $_lastPage'),
                    IconButton(
                      icon: const Icon(Icons.chevron_right),
                      onPressed: _currentPage < _lastPage
                          ? () => _fetch(page: _currentPage + 1)
                          : null,
                    ),
                  ]),
            ),
        ],
      ),
    );
  }
}

// ── Status badge with block button combined into a PopupMenu ──
// This replaces the overflowing Row(Chip + IconButton) pattern.
class _StatusBadge extends StatelessWidget {
  final bool active;
  final VoidCallback onToggle;
  const _StatusBadge({required this.active, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      tooltip: 'Actions',
      // Show a compact status chip as the button face
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: active ? Colors.green.shade50 : Colors.red.shade50,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: active
                  ? Colors.green.shade200
                  : Colors.red.shade200),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Text(
            active ? 'Active' : 'Blocked',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: active
                  ? Colors.green.shade700
                  : Colors.red.shade700,
            ),
          ),
          const SizedBox(width: 2),
          Icon(Icons.arrow_drop_down,
              size: 14,
              color: active
                  ? Colors.green.shade700
                  : Colors.red.shade700),
        ]),
      ),
      itemBuilder: (_) => [
        PopupMenuItem(
          onTap: onToggle,
          child: ListTile(
            leading: Icon(
              active ? Icons.block : Icons.check_circle,
              color: active ? Colors.red : Colors.green,
            ),
            title: Text(active ? 'Block User' : 'Unblock User'),
            contentPadding: EdgeInsets.zero,
            dense: true,
          ),
        ),
      ],
    );
  }
}

// ── User Detail Bottom Sheet ──────────────────────────────────
class _UserDetailSheet extends StatelessWidget {
  final Map<String, dynamic> user;
  final VoidCallback onToggleBlock;
  const _UserDetailSheet(
      {required this.user, required this.onToggleBlock});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final active = user['is_active'] as bool? ?? true;
    final name = user['name'] as String? ?? 'Unknown';
    final email = user['email'] as String? ?? '';
    final phone = user['phone'] as String?;
    final address = user['address'] as String?;
    final role = user['role'] as String? ?? 'user';
    final orders = (user['orders_count'] as num?)?.toInt() ?? 0;
    final createdAt = user['created_at'] as String? ?? '';

    return DraggableScrollableSheet(
      initialChildSize: 0.55,
      minChildSize: 0.4,
      maxChildSize: 0.85,
      expand: false,
      builder: (_, ctrl) => SingleChildScrollView(
        controller: ctrl,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40, height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2)),
                ),
              ),

              Row(children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: active
                      ? theme.colorScheme.primaryContainer
                      : Colors.grey.shade200,
                  child: Text(
                    name.isNotEmpty ? name[0].toUpperCase() : '?',
                    style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: active
                            ? theme.colorScheme.onPrimaryContainer
                            : Colors.grey),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(name,
                            style: theme.textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.bold)),
                        Text(email,
                            style: theme.textTheme.bodyMedium
                                ?.copyWith(color: Colors.grey),
                            overflow: TextOverflow.ellipsis),
                      ]),
                ),
                _RoleBadge(role: role, color: _roleColor(role)),
              ]),

              const SizedBox(height: 20),
              const Divider(),
              const SizedBox(height: 12),

              _InfoRow(icon: Icons.phone_outlined,
                  label: 'Phone', value: phone ?? 'Not provided'),
              _InfoRow(icon: Icons.location_on_outlined,
                  label: 'Address', value: address ?? 'Not provided'),
              _InfoRow(icon: Icons.shopping_bag_outlined,
                  label: 'Orders', value: '$orders'),
              _InfoRow(
                  icon: Icons.calendar_today_outlined,
                  label: 'Joined',
                  value: createdAt.length > 10
                      ? createdAt.substring(0, 10)
                      : createdAt),
              _InfoRow(
                  icon: active
                      ? Icons.check_circle_outline
                      : Icons.block,
                  label: 'Status',
                  value: active ? 'Active' : 'Blocked',
                  valueColor: active ? Colors.green : Colors.red),

              const SizedBox(height: 24),

              if (role != 'admin')
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: onToggleBlock,
                    icon: Icon(active ? Icons.block : Icons.check_circle),
                    label: Text(active ? 'Block User' : 'Unblock User'),
                    style: FilledButton.styleFrom(
                      backgroundColor:
                      active ? Colors.red : Colors.green,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Color _roleColor(String role) => switch (role) {
    'admin' => Colors.purple,
    'staff' => Colors.blue,
    _ => Colors.grey,
  };
}

// ── Shared small widgets ──────────────────────────────────────

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _StatChip(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Text(value,
            style: TextStyle(
                fontWeight: FontWeight.bold, color: color, fontSize: 13)),
        const SizedBox(width: 4),
        Text(label,
            style:
            TextStyle(color: color.withOpacity(0.8), fontSize: 11)),
      ]),
    );
  }
}

class _RoleBadge extends StatelessWidget {
  final String role;
  final Color color;
  const _RoleBadge({required this.role, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(role.toUpperCase(),
          style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: color)),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;
  const _InfoRow(
      {required this.icon,
        required this.label,
        required this.value,
        this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(children: [
        Icon(icon, size: 18, color: Colors.grey),
        const SizedBox(width: 12),
        Text('$label: ',
            style: const TextStyle(
                fontWeight: FontWeight.w500, color: Colors.grey)),
        Expanded(
          child: Text(value,
              style: TextStyle(
                  fontWeight: FontWeight.w600, color: valueColor),
              overflow: TextOverflow.ellipsis),
        ),
      ]),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  const _EmptyState({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(icon, size: 64, color: Colors.grey.shade300),
        const SizedBox(height: 16),
        Text(message,
            style:
            TextStyle(color: Colors.grey.shade500, fontSize: 16)),
      ]),
    );
  }
}