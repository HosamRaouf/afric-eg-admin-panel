import 'package:afric_eg_admin_panel/core/di/injection_container.dart';
import 'package:afric_eg_admin_panel/core/theme/colors.dart';
import 'package:afric_eg_admin_panel/core/utils/ids.dart';
import 'package:afric_eg_admin_panel/core/widgets/admin_widgets.dart';
import 'package:afric_eg_admin_panel/features/committee/domain/entities/committee_member.dart';
import 'package:afric_eg_admin_panel/features/committee/domain/entities/committee_category.dart';
import 'package:afric_eg_admin_panel/features/committee/presentation/bloc/committee_bloc.dart';
import 'package:afric_eg_admin_panel/features/committee/presentation/bloc/committee_event.dart';
import 'package:afric_eg_admin_panel/features/committee/presentation/bloc/committee_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class CommitteePage extends StatelessWidget {
  const CommitteePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: sl<CommitteeBloc>(),
      child: const _CommitteeView(),
    );
  }
}

class _CommitteeView extends StatelessWidget {
  const _CommitteeView();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CommitteeBloc, CommitteeState>(
      builder: (context, state) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              PageHeader(
                title: 'Committee',
                subtitle: 'Organizing committee members and categories',
                trailing: GlassButton(
                  label: 'New Member',
                  icon: Icons.add,
                  onPressed: () => _openMemberEditor(context),
                ),
              ),
              const SizedBox(height: 24),
              if (state.isLoading && state.members.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(40),
                    child: CircularProgressIndicator(color: AppColors.accent),
                  ),
                )
              else if (state.members.isEmpty)
                const EmptyState(message: 'No committee members yet.')
              else
                Wrap(
                  spacing: 14,
                  runSpacing: 14,
                  children: state.members
                      .map(
                        (m) => _MemberCard(
                          member: m,
                          categories: state.categories,
                          onEdit: () => _openMemberEditor(context, member: m),
                          onDelete: () => _confirmDeleteMember(context, m),
                        ),
                      )
                      .toList(),
                ),
              if (state.categories.isNotEmpty) ...[
                const SizedBox(height: 32),
                Row(
                  children: [
                    const Text(
                      'Categories',
                      style: TextStyle(
                        fontFamily: 'SpaceGrotesk',
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textWhite,
                      ),
                    ),
                    const Spacer(),
                    GlassButton(
                      label: 'New Category',
                      icon: Icons.add,
                      onPressed: () => _openCategoryEditor(context),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 14,
                  runSpacing: 14,
                  children: state.categories
                      .map(
                        (c) => _CategoryCard(
                          category: c,
                          onEdit: () => _openCategoryEditor(context, category: c),
                          onDelete: () => _confirmDeleteCategory(context, c),
                        ),
                      )
                      .toList(),
                ),
              ],
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

  void _openMemberEditor(BuildContext context, {CommitteeMember? member}) {
    final bloc = context.read<CommitteeBloc>();
    showDialog(
      context: context,
      builder: (_) => BlocProvider.value(
        value: bloc,
        child: _MemberDialog(member: member),
      ),
    );
  }

  void _openCategoryEditor(BuildContext context, {CommitteeCategory? category}) {
    final bloc = context.read<CommitteeBloc>();
    showDialog(
      context: context,
      builder: (_) => BlocProvider.value(
        value: bloc,
        child: _CategoryDialog(category: category),
      ),
    );
  }

  void _confirmDeleteMember(BuildContext context, CommitteeMember m) {
    final bloc = context.read<CommitteeBloc>();
    showDialog(
      context: context,
      builder: (dialogContext) => BlocProvider.value(
        value: bloc,
        child: AlertDialog(
          backgroundColor: const Color(0xFF2a0f10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: AppColors.glassBorder),
          ),
          title: const Text(
            'Delete member?',
            style: TextStyle(fontFamily: 'Inter', fontSize: 16),
          ),
          content: Text(
            m.name,
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
            TextButton(
              onPressed: () {
                bloc.add(DeleteCommitteeMemberEvent(m.id));
                Navigator.pop(dialogContext);
              },
              child: const Text(
                'Delete',
                style: TextStyle(color: AppColors.liveRed),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteCategory(BuildContext context, CommitteeCategory c) {
    final bloc = context.read<CommitteeBloc>();
    showDialog(
      context: context,
      builder: (dialogContext) => BlocProvider.value(
        value: bloc,
        child: AlertDialog(
          backgroundColor: const Color(0xFF2a0f10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: AppColors.glassBorder),
          ),
          title: const Text(
            'Delete category?',
            style: TextStyle(fontFamily: 'Inter', fontSize: 16),
          ),
          content: Text(
            c.name,
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
            TextButton(
              onPressed: () {
                bloc.add(DeleteCommitteeCategoryEvent(c.id));
                Navigator.pop(dialogContext);
              },
              child: const Text(
                'Delete',
                style: TextStyle(color: AppColors.liveRed),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MemberCard extends StatelessWidget {
  final CommitteeMember member;
  final List<CommitteeCategory> categories;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _MemberCard({
    required this.member,
    required this.categories,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final categoryName = categories
        .where((c) => c.id == member.categoryId)
        .map((c) => c.name)
        .firstOrNull;

    return GlassCard(
      padding: const EdgeInsets.all(16),
      radius: 16,
      child: SizedBox(
        width: 280,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.25),
                  backgroundImage: member.image.isNotEmpty
                      ? NetworkImage(member.image)
                      : null,
                  child: member.image.isEmpty
                      ? const Icon(Icons.person, size: 20, color: AppColors.accent)
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        member.name,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textWhite,
                        ),
                      ),
                      Text(
                        member.role,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 11,
                          color: AppColors.textTertiary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (categoryName != null) ...[
              const SizedBox(height: 10),
              StatusBadge(label: categoryName.toUpperCase(), color: AppColors.accent),
            ],
            if (member.description.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                member.description,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                const Spacer(),
                GhostIconButton(icon: Icons.edit_outlined, onPressed: onEdit),
                const SizedBox(width: 8),
                GhostIconButton(
                  icon: Icons.delete_outline,
                  color: AppColors.liveRedLight,
                  onPressed: onDelete,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final CommitteeCategory category;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _CategoryCard({
    required this.category,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(14),
      radius: 12,
      child: SizedBox(
        width: 200,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              category.name,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textWhite,
              ),
            ),
            Text(
              'Order: ${category.order}',
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 11,
                color: AppColors.textTertiary,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Spacer(),
                GhostIconButton(icon: Icons.edit_outlined, onPressed: onEdit),
                const SizedBox(width: 8),
                GhostIconButton(
                  icon: Icons.delete_outline,
                  color: AppColors.liveRedLight,
                  onPressed: onDelete,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MemberDialog extends StatefulWidget {
  final CommitteeMember? member;
  const _MemberDialog({this.member});

  @override
  State<_MemberDialog> createState() => _MemberDialogState();
}

class _MemberDialogState extends State<_MemberDialog> {
  late final TextEditingController _name;
  late final TextEditingController _role;
  late final TextEditingController _description;
  late final TextEditingController _image;
  late String _categoryId;

  @override
  void initState() {
    super.initState();
    final m = widget.member;
    _name = TextEditingController(text: m?.name ?? '');
    _role = TextEditingController(text: m?.role ?? '');
    _description = TextEditingController(text: m?.description ?? '');
    _image = TextEditingController(text: m?.image ?? '');
    _categoryId = m?.categoryId ?? '';
  }

  @override
  void dispose() {
    _name.dispose();
    _role.dispose();
    _description.dispose();
    _image.dispose();
    super.dispose();
  }

  void _save() {
    if (_name.text.trim().isEmpty) return;

    final isNew = widget.member == null;
    final member = CommitteeMember(
      id: widget.member?.id ?? Ids.generate(),
      name: _name.text.trim(),
      role: _role.text.trim(),
      description: _description.text.trim(),
      image: _image.text.trim(),
      categoryId: _categoryId,
    );
    context.read<CommitteeBloc>().add(
      SaveCommitteeMemberEvent(member, isNew: isNew),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<CommitteeBloc, CommitteeState>(
      listenWhen: (prev, curr) =>
          prev.isSaving && !curr.isSaving && curr.error == null,
      listener: (context, state) => Navigator.pop(context),
      builder: (context, state) {
        return AlertDialog(
          backgroundColor: const Color(0xFF2a0f10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: AppColors.glassBorder),
          ),
          title: Text(
            widget.member == null ? 'New Member' : 'Edit Member',
            style: const TextStyle(fontFamily: 'Inter', fontSize: 16),
          ),
          content: SingleChildScrollView(
            child: SizedBox(
              width: 420,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GlassTextField(
                    label: 'Name',
                    controller: _name,
                    hint: 'Dr. Ahmed Hassan',
                    enabled: !state.isSaving,
                  ),
                  const SizedBox(height: 14),
                  GlassTextField(
                    label: 'Role',
                    controller: _role,
                    hint: 'Conference Chair',
                    enabled: !state.isSaving,
                  ),
                  const SizedBox(height: 14),
                  GlassTextField(
                    label: 'Description',
                    controller: _description,
                    maxLines: 3,
                    enabled: !state.isSaving,
                  ),
                  const SizedBox(height: 14),
                  GlassTextField(
                    label: 'Image URL',
                    controller: _image,
                    enabled: !state.isSaving,
                  ),
                  const SizedBox(height: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Category',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
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
                          child: DropdownButton<String>(
                            value: _categoryId.isEmpty ? null : _categoryId,
                            isExpanded: true,
                            dropdownColor: const Color(0xFF2a0f10),
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 13,
                              color: AppColors.textWhite,
                            ),
                            hint: const Text(
                              'Select category',
                              style: TextStyle(color: AppColors.textDisabled),
                            ),
                            items: state.categories
                                .map((c) => DropdownMenuItem(
                                      value: c.id,
                                      child: Text(c.name),
                                    ))
                                .toList(),
                            onChanged: state.isSaving
                                ? null
                                : (v) => setState(() => _categoryId = v ?? ''),
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (state.error != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: Text(
                        state.error!,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12,
                          color: AppColors.liveRed,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: state.isSaving ? null : () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            state.isSaving
                ? const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.accent,
                      ),
                    ),
                  )
                : GlassButton(
                    label: 'Save',
                    icon: Icons.save_outlined,
                    onPressed: _save,
                  ),
          ],
        );
      },
    );
  }
}

class _CategoryDialog extends StatefulWidget {
  final CommitteeCategory? category;
  const _CategoryDialog({this.category});

  @override
  State<_CategoryDialog> createState() => _CategoryDialogState();
}

class _CategoryDialogState extends State<_CategoryDialog> {
  late final TextEditingController _name;
  late final TextEditingController _order;

  @override
  void initState() {
    super.initState();
    final c = widget.category;
    _name = TextEditingController(text: c?.name ?? '');
    _order = TextEditingController(text: c?.order.toString() ?? '0');
  }

  @override
  void dispose() {
    _name.dispose();
    _order.dispose();
    super.dispose();
  }

  void _save() {
    if (_name.text.trim().isEmpty) return;

    final isNew = widget.category == null;
    final category = CommitteeCategory(
      id: widget.category?.id ?? Ids.generate(),
      name: _name.text.trim(),
      order: int.tryParse(_order.text) ?? 0,
    );
    context.read<CommitteeBloc>().add(
      SaveCommitteeCategoryEvent(category, isNew: isNew),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<CommitteeBloc, CommitteeState>(
      listenWhen: (prev, curr) =>
          prev.isSaving && !curr.isSaving && curr.error == null,
      listener: (context, state) => Navigator.pop(context),
      builder: (context, state) {
        return AlertDialog(
          backgroundColor: const Color(0xFF2a0f10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: AppColors.glassBorder),
          ),
          title: Text(
            widget.category == null ? 'New Category' : 'Edit Category',
            style: const TextStyle(fontFamily: 'Inter', fontSize: 16),
          ),
          content: SingleChildScrollView(
            child: SizedBox(
              width: 360,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GlassTextField(
                    label: 'Name',
                    controller: _name,
                    hint: 'Steering Committee',
                    enabled: !state.isSaving,
                  ),
                  const SizedBox(height: 14),
                  GlassTextField(
                    label: 'Order',
                    controller: _order,
                    keyboardType: TextInputType.number,
                    enabled: !state.isSaving,
                  ),
                  if (state.error != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: Text(
                        state.error!,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12,
                          color: AppColors.liveRed,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: state.isSaving ? null : () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            state.isSaving
                ? const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.accent,
                      ),
                    ),
                  )
                : GlassButton(
                    label: 'Save',
                    icon: Icons.save_outlined,
                    onPressed: _save,
                  ),
          ],
        );
      },
    );
  }
}
