// Web-only admin panel: native drag & drop requires dart:html.
// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:async';
import 'dart:html' as html;
import 'dart:math' as math;

import 'package:afric_eg_admin_panel/core/di/injection_container.dart';
import 'package:afric_eg_admin_panel/core/services/auth_service.dart';
import 'package:afric_eg_admin_panel/core/theme/colors.dart';
import 'package:afric_eg_admin_panel/core/widgets/admin_widgets.dart';
import 'package:afric_eg_admin_panel/features/push/domain/repositories/push_repository.dart';
import 'package:afric_eg_admin_panel/features/users/domain/entities/panel_user.dart';
import 'package:afric_eg_admin_panel/features/users/presentation/bloc/users_bloc.dart';
import 'package:afric_eg_admin_panel/features/users/presentation/bloc/users_event.dart';
import 'package:afric_eg_admin_panel/features/users/presentation/bloc/users_state.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class UsersPage extends StatelessWidget {
  const UsersPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => UsersBloc(repository: sl())..add(const LoadUsersEvent()),
      child: const _UsersView(),
    );
  }
}

class _UsersView extends StatefulWidget {
  const _UsersView();

  @override
  State<_UsersView> createState() => _UsersViewState();
}

class _UsersViewState extends State<_UsersView> {
  VerificationCodeResult? _shownCode;
  String _roleFilter = 'all';
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<PanelUser> _filtered(List<PanelUser> users) {
    final q = _query;
    return users.where((u) {
      if (_roleFilter != 'all' && u.role != _roleFilter) return false;
      if (q.isEmpty) return true;
      return u.displayName.toLowerCase().contains(q) ||
          u.email.toLowerCase().contains(q) ||
          u.title.toLowerCase().contains(q) ||
          u.role.toLowerCase().contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final currentUid = sl<AuthService>().currentUid;

    return BlocConsumer<UsersBloc, UsersState>(
      listener: (context, state) {
        final code = state.verificationCode;
        if (code != null && !identical(code, _shownCode)) {
          _shownCode = code;
          _showCodeDialog(context, code, state.codeAction);
        }
      },
      builder: (context, state) {
        final visible = _filtered(state.users);
        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              PageHeader(
                title: 'Users',
                subtitle:
                    'Everyone with a Firebase account — attendees, speakers, '
                    'faculty, sponsors and admins',
                trailing: GlassButton(
                  label: 'New User',
                  icon: Icons.person_add_alt,
                  onPressed: state.isSaving
                      ? null
                      : () => _openNewUser(context),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      onChanged: (v) =>
                          setState(() => _query = v.trim().toLowerCase()),
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13,
                        color: AppColors.textWhite,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Search by name, email, title…',
                        hintStyle: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 13,
                          color: AppColors.textDisabled,
                        ),
                        prefixIcon: const Icon(
                          Icons.search,
                          size: 18,
                          color: AppColors.textTertiary,
                        ),
                        filled: true,
                        fillColor: AppColors.glassBg,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: AppColors.glassBorder,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.accent),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  SizedBox(
                    width: 220,
                    child: _GlassDropdown<String>(
                      label: 'Role filter',
                      value: _roleFilter,
                      items: const [
                        DropdownMenuItem(
                          value: 'all',
                          child: Text('All roles'),
                        ),
                        DropdownMenuItem(
                          value: 'attendee',
                          child: Text('Attendees'),
                        ),
                        DropdownMenuItem(
                          value: 'speaker',
                          child: Text('Speakers'),
                        ),
                        DropdownMenuItem(
                          value: 'faculty',
                          child: Text('Faculty'),
                        ),
                        DropdownMenuItem(
                          value: 'sponsor',
                          child: Text('Sponsors'),
                        ),
                        DropdownMenuItem(value: 'admin', child: Text('Admins')),
                      ],
                      onChanged: (v) =>
                          setState(() => _roleFilter = v ?? 'all'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Text(
                      '${visible.length} of ${state.users.length} users',
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11,
                        color: AppColors.textTertiary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              if (state.isLoading && state.users.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(40),
                    child: CircularProgressIndicator(color: AppColors.accent),
                  ),
                )
              else if (state.users.isEmpty)
                const EmptyState(message: 'No users found.')
              else if (visible.isEmpty)
                const EmptyState(message: 'No users match this filter.')
              else
                _UsersTable(
                  users: visible,
                  currentUid: currentUid,
                  onSendCode: state.isSaving
                      ? null
                      : (u) => _confirmSendCode(context, u),
                  onEdit: state.isSaving ? null : (u) => _openEdit(context, u),
                  onDelete: state.isSaving
                      ? null
                      : (u) => _confirmDelete(context, u),
                  onNotify: state.isSaving
                      ? null
                      : (u) => _openNotify(context, u),
                ),
              if (state.error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Text(
                    state.error!,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 11,
                      color: AppColors.liveRed,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  void _openNewUser(BuildContext context) {
    final bloc = context.read<UsersBloc>();
    showDialog(
      context: context,
      builder: (_) =>
          BlocProvider.value(value: bloc, child: const _NewUserDialog()),
    );
  }

  void _openEdit(BuildContext context, PanelUser user) {
    final bloc = context.read<UsersBloc>();
    final isSelf = user.uid == sl<AuthService>().currentUid;
    showDialog(
      context: context,
      builder: (_) => BlocProvider.value(
        value: bloc,
        child: _EditUserDialog(user: user, isSelf: isSelf),
      ),
    );
  }

  void _confirmSendCode(BuildContext context, PanelUser user) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF2a0f10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.glassBorder),
        ),
        title: const Text(
          'Send new verification code?',
          style: TextStyle(fontFamily: 'Inter', fontSize: 16),
        ),
        content: Text(
          'A new one-time code will be issued for ${user.email}. '
          'Their current password stops working and a fresh code is emailed '
          'to them.',
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          GlassButton(
            label: 'Send Code',
            icon: Icons.qr_code_2,
            onPressed: () {
              Navigator.pop(dialogContext);
              context.read<UsersBloc>().add(
                SendVerificationCodeEvent(user.uid),
              );
            },
          ),
        ],
      ),
    );
  }

  void _openNotify(BuildContext context, PanelUser user) {
    showDialog(
      context: context,
      builder: (_) => _NotifyUserDialog(user: user),
    );
  }

  void _confirmDelete(BuildContext context, PanelUser user) {
    final isSelf = user.uid == sl<AuthService>().currentUid;
    if (isSelf) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You cannot delete your own account.')),
      );
      return;
    }
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF2a0f10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.glassBorder),
        ),
        title: const Text(
          'Delete user?',
          style: TextStyle(fontFamily: 'Inter', fontSize: 16),
        ),
        content: Text(
          '${user.displayName.isNotEmpty ? '${user.displayName} — ' : ''}'
          '${user.email} will be permanently removed: Firebase Auth account, '
          'app profile, and admin access (if any). This cannot be undone.',
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          GlassButton(
            label: 'Delete',
            icon: Icons.person_remove_outlined,
            destructive: true,
            onPressed: () {
              Navigator.pop(dialogContext);
              context.read<UsersBloc>().add(DeleteUserEvent(user.uid));
            },
          ),
        ],
      ),
    );
  }

  void _showCodeDialog(
    BuildContext context,
    VerificationCodeResult code,
    String? action,
  ) {
    showDialog(
      context: context,
      builder: (_) => _VerificationCodeDialog(
        code: code,
        isNewUser: action == 'create',
        onClose: () {
          context.read<UsersBloc>().add(const ClearVerificationCodeEvent());
        },
      ),
    );
  }
}

// ─────────────────────────── Table ─────────────────────────────────────────

const double _noColW = 36;
const double _avatarColW = 44;
const double _nameColW = 220;
const double _emailColW = 280;
const double _roleColW = 130;
const double _actionsColW = 200;
const double _colGap = 20;
const double _tableMinW =
    _noColW +
    _avatarColW +
    _nameColW +
    _emailColW +
    _roleColW +
    _actionsColW +
    _colGap * 5 +
    32;

class _UsersTable extends StatelessWidget {
  final List<PanelUser> users;
  final String? currentUid;
  final void Function(PanelUser)? onSendCode;
  final void Function(PanelUser)? onEdit;
  final void Function(PanelUser)? onDelete;
  final void Function(PanelUser)? onNotify;

  const _UsersTable({
    required this.users,
    required this.currentUid,
    this.onSendCode,
    this.onEdit,
    this.onDelete,
    this.onNotify,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.glassBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.glassBorder),
      ),
      clipBehavior: Clip.antiAlias,
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Fill the available width (min _tableMinW so narrow windows still
          // scroll horizontally instead of crushing the fixed columns).
          final tableWidth = math.max(_tableMinW, constraints.maxWidth);
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: tableWidth,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const _HeaderRow(),
                  ...users.asMap().entries.map(
                    (e) => _UserRow(
                      no: e.key + 1,
                      user: e.value,
                      isSelf: e.value.uid == currentUid,
                      onSendCode: onSendCode,
                      onEdit: onEdit,
                      onDelete: onDelete,
                      onNotify: onNotify,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _HeaderRow extends StatelessWidget {
  const _HeaderRow();

  @override
  Widget build(BuildContext context) {
    const label = TextStyle(
      fontFamily: 'Inter',
      fontSize: 10,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.08,
      color: AppColors.textTertiary,
    );
    return Container(
      color: AppColors.primary.withValues(alpha: 0.2),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: const Row(
        children: [
          SizedBox(
            width: _noColW,
            child: Text('NO.', style: label),
          ),
          SizedBox(width: _colGap),
          SizedBox(width: _avatarColW),
          SizedBox(width: _colGap),
          Expanded(child: Text('NAME', style: label)),
          SizedBox(width: _colGap),
          Expanded(flex: 2, child: Text('EMAIL', style: label)),
          SizedBox(width: _colGap),
          SizedBox(
            width: _roleColW,
            child: Text('ROLE', style: label),
          ),
          SizedBox(width: _colGap),
          SizedBox(
            width: _actionsColW,
            child: Text('ACTIONS', textAlign: TextAlign.right, style: label),
          ),
        ],
      ),
    );
  }
}

class _UserRow extends StatefulWidget {
  final int no;
  final PanelUser user;
  final bool isSelf;
  final void Function(PanelUser)? onSendCode;
  final void Function(PanelUser)? onEdit;
  final void Function(PanelUser)? onDelete;
  final void Function(PanelUser)? onNotify;

  const _UserRow({
    required this.no,
    required this.user,
    required this.isSelf,
    this.onSendCode,
    this.onEdit,
    this.onDelete,
    this.onNotify,
  });

  @override
  State<_UserRow> createState() => _UserRowState();
}

class _UserRowState extends State<_UserRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final user = widget.user;
    final canSend = user.isProfessional;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Container(
        decoration: BoxDecoration(
          color: _hovered
              ? AppColors.primary.withValues(alpha: 0.16)
              : Colors.transparent,
          border: const Border(
            bottom: BorderSide(color: AppColors.glassBorder),
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            SizedBox(
              width: _noColW,
              child: Text(
                '${widget.no}',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11,
                  color: AppColors.textTertiary,
                ),
              ),
            ),
            const SizedBox(width: _colGap),
            SizedBox(
              width: _avatarColW,
              child: _UserAvatar(user: user),
            ),
            const SizedBox(width: _colGap),
            Expanded(child: _name(user)),
            const SizedBox(width: _colGap),
            Expanded(
              flex: 2,
              child: Text(
                user.email,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            const SizedBox(width: _colGap),
            SizedBox(
              width: _roleColW,
              child: _RoleBadge(role: user.role),
            ),
            const SizedBox(width: _colGap),
            SizedBox(
              width: _actionsColW,
              child: Align(
                alignment: Alignment.centerRight,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Tooltip(
                      message: canSend
                          ? 'Send verification code (email + QR)'
                          : 'Verification codes are for professional roles',
                      child: _ActionButton(
                        icon: Icons.qr_code_2,
                        color: canSend
                            ? AppColors.pointsGreen
                            : AppColors.textDisabled,
                        onPressed: canSend
                            ? () => widget.onSendCode?.call(user)
                            : null,
                      ),
                    ),
                    const SizedBox(width: 8),
                    _ActionButton(
                      icon: Icons.edit_outlined,
                      color: AppColors.accent,
                      onPressed: () => widget.onEdit?.call(user),
                      tooltip: 'Edit user',
                    ),
                    const SizedBox(width: 8),
                    _ActionButton(
                      icon: Icons.notifications_active_outlined,
                      color: AppColors.goldLight,
                      onPressed: () => widget.onNotify?.call(user),
                      tooltip: 'Send notification to this user',
                    ),
                    const SizedBox(width: 8),
                    _ActionButton(
                      icon: Icons.person_remove_outlined,
                      color: widget.isSelf
                          ? AppColors.textDisabled
                          : AppColors.liveRedLight,
                      onPressed: widget.isSelf
                          ? null
                          : () => widget.onDelete?.call(user),
                      tooltip: widget.isSelf
                          ? 'You cannot delete yourself'
                          : 'Delete user',
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _name(PanelUser user) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Flexible(
              child: Text(
                user.displayName.isNotEmpty ? user.displayName : '—',
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textWhite,
                ),
              ),
            ),
            if (widget.isSelf) ...[
              const SizedBox(width: 8),
              const StatusBadge(label: 'YOU', color: AppColors.goldLight),
            ],
            if (user.disabled) ...[
              const SizedBox(width: 8),
              const StatusBadge(
                label: 'DISABLED',
                color: AppColors.liveRedLight,
              ),
            ],
          ],
        ),
        if (user.title.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              user.title,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 10,
                color: AppColors.textTertiary,
              ),
            ),
          ),
      ],
    );
  }
}

class _UserAvatar extends StatelessWidget {
  final PanelUser user;
  final double size;

  const _UserAvatar({required this.user, this.size = 40});

  @override
  Widget build(BuildContext context) {
    if (user.photoUrl.isNotEmpty) {
      return ClipOval(
        child: Image.network(
          user.photoUrl,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => _InitialAvatar(user: user, size: size),
        ),
      );
    }
    return _InitialAvatar(user: user, size: size);
  }
}

class _InitialAvatar extends StatelessWidget {
  final PanelUser user;
  final double size;

  const _InitialAvatar({required this.user, this.size = 40});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.3),
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: Text(
        user.initials,
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: size * 0.32,
          fontWeight: FontWeight.w700,
          color: AppColors.highlight,
        ),
      ),
    );
  }
}

class _RoleBadge extends StatelessWidget {
  final String role;
  const _RoleBadge({required this.role});

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (role) {
      'admin' => ('Admin', AppColors.liveRedLight),
      'speaker' => ('Speaker', AppColors.accent),
      'faculty' => ('Faculty', AppColors.pointsGreen),
      'sponsor' => ('Sponsor', AppColors.goldLight),
      _ => ('Attendee', AppColors.textSecondary),
    };
    return StatusBadge(label: label, color: color);
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback? onPressed;
  final String? tooltip;

  const _ActionButton({
    required this.icon,
    required this.color,
    this.onPressed,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    final button = InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.glassBg,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.glassBorder),
        ),
        child: Icon(icon, size: 16, color: color),
      ),
    );
    return tooltip == null ? button : Tooltip(message: tooltip, child: button);
  }
}

// ─────────────────────────── Dialogs ───────────────────────────────────────

class _NotifyUserDialog extends StatefulWidget {
  final PanelUser user;
  const _NotifyUserDialog({required this.user});

  @override
  State<_NotifyUserDialog> createState() => _NotifyUserDialogState();
}

class _NotifyUserDialogState extends State<_NotifyUserDialog> {
  final _titleController = TextEditingController();
  final _messageController = TextEditingController();
  bool _sending = false;
  String? _error;
  String? _success;

  @override
  void dispose() {
    _titleController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final title = _titleController.text.trim();
    final message = _messageController.text.trim();
    if (title.isEmpty) {
      setState(() => _error = 'A title is required.');
      return;
    }
    setState(() {
      _sending = true;
      _error = null;
      _success = null;
    });
    final result = await sl<PushRepository>().sendToUser(
      uid: widget.user.uid,
      title: title,
      message: message,
    );
    if (!mounted) return;
    result.fold(
      (failure) => setState(() {
        _sending = false;
        _error = failure.message;
      }),
      (r) => setState(() {
        _sending = false;
        _success =
            'Notification sent — ${r.success} of ${r.total} devices delivered.';
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.user;
    return AlertDialog(
      backgroundColor: const Color(0xFF2a0f10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.glassBorder),
      ),
      title: const Text(
        'Send Notification',
        style: TextStyle(fontFamily: 'Inter', fontSize: 16),
      ),
      content: SingleChildScrollView(
        child: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'To: ${user.displayName.isNotEmpty ? user.displayName : user.email} '
                '(${user.email})',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11,
                  color: AppColors.textTertiary,
                ),
              ),
              const SizedBox(height: 16),
              GlassTextField(
                label: 'Title',
                controller: _titleController,
                hint: 'e.g. Session reminder',
              ),
              const SizedBox(height: 14),
              GlassTextField(
                label: 'Message',
                controller: _messageController,
                hint: 'Notification body',
                maxLines: 4,
              ),
              const SizedBox(height: 18),
              if (_error != null) ...[
                Text(
                  _error!,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    color: AppColors.liveRed,
                  ),
                ),
                const SizedBox(height: 10),
              ],
              if (_success != null) ...[
                Text(
                  _success!,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    color: AppColors.pointsGreen,
                  ),
                ),
                const SizedBox(height: 10),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _sending ? null : () => Navigator.pop(context),
          child: const Text('Close'),
        ),
        GlassButton(
          label: 'Send',
          icon: Icons.send_outlined,
          loading: _sending,
          onPressed: _sending ? null : _send,
        ),
      ],
    );
  }
}

class _NewUserDialog extends StatefulWidget {
  const _NewUserDialog();

  @override
  State<_NewUserDialog> createState() => _NewUserDialogState();
}

class _NewUserDialogState extends State<_NewUserDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _titleController = TextEditingController();
  final _photoController = TextEditingController();
  String _role = 'speaker';

  static bool _isProfessional(String role) =>
      role == 'speaker' || role == 'faculty' || role == 'sponsor';

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _titleController.dispose();
    _photoController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState?.validate() ?? false) {
      context.read<UsersBloc>().add(
        CreateUserEvent(
          email: _emailController.text.trim(),
          displayName: _nameController.text.trim(),
          role: _role,
          title: _titleController.text.trim(),
          photoUrl: _photoController.text.trim(),
        ),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF2a0f10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.glassBorder),
      ),
      title: const Text(
        'New User',
        style: TextStyle(fontFamily: 'Inter', fontSize: 16),
      ),
      content: SingleChildScrollView(
        child: SizedBox(
          width: 420,
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GlassTextField(
                  label: 'Display name',
                  controller: _nameController,
                  hint: 'e.g. Dr. Sara Hassan',
                ),
                const SizedBox(height: 14),
                GlassTextField(
                  label: 'Email address',
                  controller: _emailController,
                  hint: 'name@afric-eg.com',
                  keyboardType: TextInputType.emailAddress,
                  onChanged: (_) {},
                ),
                const SizedBox(height: 14),
                _GlassDropdown<String>(
                  label: 'Role',
                  value: _role,
                  items: const [
                    DropdownMenuItem(value: 'speaker', child: Text('Speaker')),
                    DropdownMenuItem(value: 'faculty', child: Text('Faculty')),
                    DropdownMenuItem(value: 'sponsor', child: Text('Sponsor')),
                    DropdownMenuItem(value: 'admin', child: Text('Admin')),
                  ],
                  onChanged: (v) => setState(() => _role = v ?? 'speaker'),
                ),
                if (_isProfessional(_role)) ...[
                  const SizedBox(height: 14),
                  GlassTextField(
                    label: 'Role / job title',
                    controller: _titleController,
                    hint: 'e.g. Professor of OB/GYN',
                  ),
                ],
                const SizedBox(height: 12),
                Text(
                  _role == 'admin'
                      ? 'Admin accounts can sign in to this admin panel.'
                      : 'An initial verification code is generated, emailed and '
                            'shown as a QR — the user uses it for their first '
                            'sign-in, then sets their own password.',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    color: AppColors.textTertiary,
                  ),
                ),
                const SizedBox(height: 14),
                _UserImageUploadField(
                  urlController: _photoController,
                  storagePath:
                      'users/avatar_${DateTime.now().microsecondsSinceEpoch}.jpg',
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        GlassButton(label: 'Create User', icon: Icons.add, onPressed: _submit),
      ],
    );
  }
}

class _EditUserDialog extends StatefulWidget {
  final PanelUser user;
  final bool isSelf;

  const _EditUserDialog({required this.user, required this.isSelf});

  @override
  State<_EditUserDialog> createState() => _EditUserDialogState();
}

class _EditUserDialogState extends State<_EditUserDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late final TextEditingController _titleController;
  late final TextEditingController _photoController;
  late String _role;
  bool _resending = false;

  static bool isProfessional(String role) =>
      role == 'speaker' || role == 'faculty' || role == 'sponsor';

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.user.displayName);
    _emailController = TextEditingController(text: widget.user.email);
    _titleController = TextEditingController(text: widget.user.title);
    _photoController = TextEditingController(text: widget.user.photoUrl);
    _role = widget.user.role == 'attendee' ? 'attendee' : widget.user.role;
    _photoController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _titleController.dispose();
    _photoController.dispose();
    super.dispose();
  }

  void _submit() {
    context.read<UsersBloc>().add(
      UpdateUserEvent(
        uid: widget.user.uid,
        email: _emailController.text.trim(),
        displayName: _nameController.text.trim(),
        title: _titleController.text.trim(),
        photoUrl: _photoController.text.trim(),
        role: _role,
      ),
    );
    Navigator.pop(context);
  }

  Future<void> _resendCode() async {
    setState(() => _resending = true);
    context.read<UsersBloc>().add(SendVerificationCodeEvent(widget.user.uid));
    await Future.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;
    Navigator.pop(context);
  }

  PanelUser get _previewUser => PanelUser(
    uid: widget.user.uid,
    email: widget.user.email,
    displayName: _nameController.text.trim().isEmpty
        ? widget.user.displayName
        : _nameController.text.trim(),
    photoUrl: _photoController.text.trim(),
  );

  @override
  Widget build(BuildContext context) {
    final demotingAdmin = widget.user.isAdmin && _role != 'admin';
    final canResend = widget.user.isProfessional;
    return AlertDialog(
      backgroundColor: const Color(0xFF2a0f10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.glassBorder),
      ),
      title: const Text(
        'Edit User',
        style: TextStyle(fontFamily: 'Inter', fontSize: 16),
      ),
      content: SingleChildScrollView(
        child: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _UserAvatar(user: _previewUser, size: 56),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.user.email,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Change the photo by uploading a new image below.',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 10,
                            color: AppColors.textTertiary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              GlassTextField(
                label: 'Display name',
                controller: _nameController,
              ),
              const SizedBox(height: 14),
              GlassTextField(
                label: 'Email address',
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 14),
              _GlassDropdown<String>(
                label: 'Role',
                value: _role,
                items: const [
                  DropdownMenuItem(value: 'attendee', child: Text('Attendee')),
                  DropdownMenuItem(value: 'speaker', child: Text('Speaker')),
                  DropdownMenuItem(value: 'faculty', child: Text('Faculty')),
                  DropdownMenuItem(value: 'sponsor', child: Text('Sponsor')),
                  DropdownMenuItem(value: 'admin', child: Text('Admin')),
                ],
                onChanged: (v) => setState(() => _role = v ?? 'attendee'),
              ),
              if (_EditUserDialogState.isProfessional(_role)) ...[
                const SizedBox(height: 14),
                GlassTextField(
                  label: 'Role / job title',
                  controller: _titleController,
                  hint: 'e.g. Professor of OB/GYN',
                ),
              ],
              if (demotingAdmin) ...[
                const SizedBox(height: 12),
                Text(
                  widget.isSelf
                      ? 'You cannot remove your own admin access.'
                      : 'This removes their access to the admin panel.',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    color: AppColors.liveRedLight,
                  ),
                ),
              ],
              const SizedBox(height: 14),
              _UserImageUploadField(
                urlController: _photoController,
                storagePath: 'users/${widget.user.uid}.jpg',
              ),
            ],
          ),
        ),
      ),
      actions: [
        if (canResend)
          TextButton.icon(
            onPressed: _resending ? null : _resendCode,
            icon: _resending
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.highlight,
                    ),
                  )
                : const Icon(Icons.mail_outline, size: 16),
            label: const Text('Resend Code'),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.highlight,
              textStyle: const TextStyle(fontFamily: 'Inter', fontSize: 12),
            ),
          ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        GlassButton(label: 'Save', icon: Icons.check, onPressed: _submit),
      ],
    );
  }
}

class _VerificationCodeDialog extends StatefulWidget {
  final VerificationCodeResult code;
  final bool isNewUser;
  final VoidCallback onClose;

  const _VerificationCodeDialog({
    required this.code,
    required this.isNewUser,
    required this.onClose,
  });

  @override
  State<_VerificationCodeDialog> createState() =>
      _VerificationCodeDialogState();
}

class _VerificationCodeDialogState extends State<_VerificationCodeDialog> {
  bool _copied = false;

  Future<void> _copyCode() async {
    await Clipboard.setData(ClipboardData(text: widget.code.code));
    if (!mounted) return;
    setState(() => _copied = true);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _copied = false);
    });
  }

  Future<void> _composeEmail() async {
    const subject = 'AFRIC 2026 — Professional Access';
    final body =
        'Hello,\n\n'
        'Your AFRIC 2026 professional access details:\n\n'
        'Email: ${widget.code.email}\n'
        'Verification code: ${widget.code.code}\n\n'
        'How to sign in:\n'
        '1. Open the AFRIC 2026 app and tap "Professional Portal".\n'
        '2. Enter your email and the verification code above, or scan the QR '
        'code shown in the panel.\n'
        '3. Create your personal password when prompted.\n\n'
        'AFRIC 2026 — The Queens Edition';
    final uri = Uri(
      scheme: 'mailto',
      path: widget.code.email,
      queryParameters: {'subject': subject, 'body': body},
    );
    final ok = await launchUrl(uri);
    if (!mounted) return;
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open your email app.')),
      );
    }
  }

  void _close() {
    Navigator.pop(context);
    widget.onClose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF2a0f10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.glassBorder),
      ),
      title: Text(
        widget.isNewUser
            ? 'User created — share access'
            : 'New verification code',
        style: const TextStyle(fontFamily: 'Inter', fontSize: 16),
      ),
      content: SingleChildScrollView(
        child: SizedBox(
          width: 380,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.code.email,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: QrImageView(
                  data: widget.code.qrPayload,
                  version: QrVersions.auto,
                  size: 200,
                  backgroundColor: Colors.white,
                  eyeStyle: const QrEyeStyle(
                    eyeShape: QrEyeShape.square,
                    color: Color(0xFF111111),
                  ),
                  dataModuleStyle: const QrDataModuleStyle(
                    dataModuleShape: QrDataModuleShape.square,
                    color: Color(0xFF111111),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Scan with the app (Professional Portal → scan)',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 10,
                  color: AppColors.textTertiary,
                ),
              ),
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.gold.withValues(alpha: 0.35),
                  ),
                ),
                child: Text(
                  widget.code.code,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: 'SpaceGrotesk',
                    fontSize: 30,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 8,
                    color: AppColors.textWhite,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              if (widget.code.emailed)
                const StatusBadge(
                  label: 'EMAILED',
                  color: AppColors.answeredGreen,
                )
              else
                Column(
                  children: [
                    const StatusBadge(
                      label: 'EMAIL FAILED — SHARE MANUALLY',
                      color: AppColors.liveRedLight,
                    ),
                    if (widget.code.emailError.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        widget.code.emailError,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 9,
                          color: AppColors.textTertiary,
                        ),
                      ),
                    ],
                  ],
                ),
              const SizedBox(height: 12),
              const Text(
                'Works once for first sign-in, then they create their own '
                'password.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 10,
                  color: AppColors.textTertiary,
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: _close, child: const Text('Done')),
        TextButton.icon(
          onPressed: _composeEmail,
          icon: const Icon(Icons.mail_outline, size: 16),
          label: const Text('Compose Email'),
          style: TextButton.styleFrom(foregroundColor: AppColors.highlight),
        ),
        GlassButton(
          label: _copied ? 'Copied!' : 'Copy Code',
          icon: _copied ? Icons.check : Icons.content_copy,
          onPressed: _copyCode,
        ),
      ],
    );
  }
}

// ─────────────────────────── Shared widgets ────────────────────────────────

class _GlassDropdown<T> extends StatelessWidget {
  final String label;
  final T value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?>? onChanged;

  const _GlassDropdown({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.04,
            color: AppColors.textTertiary,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: AppColors.glassBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.glassBorder),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<T>(
              value: value,
              isExpanded: true,
              dropdownColor: const Color(0xFF2a0f10),
              icon: const Icon(
                Icons.keyboard_arrow_down,
                color: AppColors.textSecondary,
                size: 18,
              ),
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                color: AppColors.textWhite,
              ),
              items: items,
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }
}

/// Drag-and-drop / click-to-browse image uploader for user photos, mirroring
/// the workshop cover uploader. Writes the resulting download URL into
/// [urlController] so it is persisted with the user record.
class _UserImageUploadField extends StatefulWidget {
  final TextEditingController urlController;
  final String storagePath;

  const _UserImageUploadField({
    required this.urlController,
    required this.storagePath,
  });

  @override
  State<_UserImageUploadField> createState() => _UserImageUploadFieldState();
}

class _UserImageUploadFieldState extends State<_UserImageUploadField> {
  bool _dragging = false;
  bool _uploading = false;
  double? _progress;
  String? _error;

  @override
  void initState() {
    super.initState();
    final win = html.window;
    win.addEventListener('dragover', _onDragOver);
    win.addEventListener('dragleave', _onDragLeave);
    win.addEventListener('drop', _onDrop);
  }

  @override
  void dispose() {
    final win = html.window;
    win.removeEventListener('dragover', _onDragOver);
    win.removeEventListener('dragleave', _onDragLeave);
    win.removeEventListener('drop', _onDrop);
    super.dispose();
  }

  void _onDragOver(html.Event e) {
    if (!mounted) return;
    e.preventDefault();
    e.stopPropagation();
    if (!_dragging) setState(() => _dragging = true);
  }

  void _onDragLeave(html.Event e) {
    if (!mounted) return;
    e.preventDefault();
    if (_dragging) setState(() => _dragging = false);
  }

  void _onDrop(html.Event e) {
    if (!mounted) return;
    e.preventDefault();
    e.stopPropagation();
    if (_dragging) setState(() => _dragging = false);
    final data = (e as dynamic).dataTransfer as html.DataTransfer?;
    final dropped = data?.files;
    final file = (dropped == null || dropped.isEmpty) ? null : dropped.first;
    if (file != null) _readAndUpload(file);
  }

  void _browse() {
    final input = html.FileUploadInputElement()
      ..accept = 'image/*'
      ..multiple = false;
    void cleanup() => input.remove();
    input.onChange.first.then((_) {
      cleanup();
      final files = input.files;
      final file = (files == null || files.isEmpty) ? null : files.first;
      if (file != null) _readAndUpload(file);
    }, onError: (_) => cleanup());
    input.on['cancel'].first.then((_) => cleanup());
    html.document.body?.append(input);
    input.click();
  }

  void _readAndUpload(html.File file) {
    final reader = html.FileReader();
    reader.onLoad.listen((_) {
      final bytes = reader.result;
      if (bytes is Uint8List) {
        _uploadBytes(bytes, file.name.isEmpty ? 'image.jpg' : file.name);
      }
    });
    reader.onError.listen((_) {
      if (mounted) setState(() => _error = 'Could not read the dropped file.');
    });
    reader.readAsArrayBuffer(file);
  }

  String _contentType(String name) {
    final lower = name.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.gif')) return 'image/gif';
    if (lower.endsWith('.webp')) return 'image/webp';
    return 'image/jpeg';
  }

  Future<void> _uploadBytes(Uint8List bytes, String name) async {
    if (!mounted) return;
    setState(() {
      _uploading = true;
      _progress = 0;
      _error = null;
    });
    final ref = FirebaseStorage.instance.ref(widget.storagePath);
    final task = ref.putData(
      bytes,
      SettableMetadata(
        contentType: _contentType(name),
        cacheControl: 'public,max-age=86400',
      ),
    );
    String? failure;
    final done = Completer<void>();
    final sub = task.snapshotEvents.listen((snap) {
      if (!mounted) return;
      if (snap.totalBytes > 0) {
        setState(
          () =>
              _progress = (snap.bytesTransferred / snap.totalBytes).clamp(0, 1),
        );
      }
      if (done.isCompleted) return;
      switch (snap.state) {
        case TaskState.success:
          done.complete();
          break;
        case TaskState.error:
          failure ??= 'Upload failed.';
          done.complete();
          break;
        case TaskState.canceled:
          failure ??= 'Upload canceled.';
          done.complete();
          break;
        case TaskState.paused:
        case TaskState.running:
          // On web the SDK can stall without emitting a success state after
          // the payload has fully transferred; treat full transfer as done.
          if (snap.totalBytes > 0 && snap.bytesTransferred >= snap.totalBytes) {
            done.complete();
          }
          break;
      }
    });
    try {
      await done.future.timeout(const Duration(seconds: 90));
      if (failure != null) throw failure!;
      final url = await _waitForDownloadUrl(ref);
      if (!mounted) return;
      widget.urlController.text = url;
      setState(() {
        _uploading = false;
        _progress = 1;
        _error = null;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _uploading = false;
          _error = 'Upload failed: $e';
        });
      }
    } finally {
      sub.cancel();
    }
  }

  /// On web the upload can be finalized a moment after the transfer reports
  /// complete, so a premature getDownloadURL returns 404 ('no object exists').
  /// Retry briefly before surfacing a failure.
  Future<String> _waitForDownloadUrl(Reference ref) async {
    for (var attempt = 0; attempt < 15; attempt++) {
      try {
        return await ref.getDownloadURL();
      } catch (_) {
        final delay = 500 * (attempt + 1);
        await Future.delayed(Duration(milliseconds: delay));
      }
    }
    throw 'Upload finished but the file is not reachable yet. Please try again.';
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: widget.urlController,
      builder: (context, value, _) {
        final url = value.text;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (url.isNotEmpty) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  height: 140,
                  child: Image.network(
                    url,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: AppColors.darkBase,
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.broken_image_outlined,
                        size: 30,
                        color: AppColors.textTertiary,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
            ],
            InkWell(
              onTap: _uploading ? null : _browse,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                height: 96,
                decoration: BoxDecoration(
                  color: _dragging
                      ? AppColors.primary.withValues(alpha: 0.2)
                      : AppColors.glassBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _dragging ? AppColors.gold : AppColors.glassBorder,
                    width: _dragging ? 2 : 1,
                  ),
                ),
                child: _uploading
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 180,
                            child: LinearProgressIndicator(
                              value: _progress,
                              minHeight: 4,
                              color: AppColors.gold,
                              backgroundColor: AppColors.glassBorder,
                            ),
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            'Uploading…',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 11,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      )
                    : const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.cloud_upload_outlined,
                            size: 26,
                            color: AppColors.accent,
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Drag & drop an image here\nor click to browse',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 11,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  _error!,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 11,
                    color: AppColors.liveRedLight,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
