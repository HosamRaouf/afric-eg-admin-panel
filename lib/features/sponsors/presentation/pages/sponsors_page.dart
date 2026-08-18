import 'package:afric_eg_admin_panel/core/di/injection_container.dart';
import 'package:afric_eg_admin_panel/core/theme/colors.dart';
import 'package:afric_eg_admin_panel/core/utils/ids.dart';
import 'package:afric_eg_admin_panel/core/widgets/admin_widgets.dart';
import 'package:afric_eg_admin_panel/features/sponsors/domain/entities/sponsor.dart';
import 'package:afric_eg_admin_panel/features/sponsors/presentation/bloc/sponsor_bloc.dart';
import 'package:afric_eg_admin_panel/features/sponsors/presentation/bloc/sponsor_event.dart';
import 'package:afric_eg_admin_panel/features/sponsors/presentation/bloc/sponsor_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SponsorsPage extends StatelessWidget {
  const SponsorsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: sl<SponsorBloc>(),
      child: const _SponsorsView(),
    );
  }
}

class _SponsorsView extends StatelessWidget {
  const _SponsorsView();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SponsorBloc, SponsorState>(
      builder: (context, state) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              PageHeader(
                title: 'Sponsors',
                subtitle: 'Sponsor logos and links shown on the home screen',
                trailing: GlassButton(
                  label: 'New Sponsor',
                  icon: Icons.add,
                  onPressed: () => _openEditor(context),
                ),
              ),
              const SizedBox(height: 24),
              if (state.isLoading && state.sponsors.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(40),
                    child: CircularProgressIndicator(color: AppColors.accent),
                  ),
                )
              else if (state.sponsors.isEmpty)
                const EmptyState(message: 'No sponsors yet.')
              else
                Wrap(
                  spacing: 14,
                  runSpacing: 14,
                  children: state.sponsors
                      .map(
                        (s) => _SponsorCard(
                          sponsor: s,
                          onEdit: () => _openEditor(context, sponsor: s),
                          onDelete: () => _confirmDelete(context, s),
                        ),
                      )
                      .toList(),
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

  void _openEditor(BuildContext context, {Sponsor? sponsor}) {
    final bloc = context.read<SponsorBloc>();
    showDialog(
      context: context,
      builder: (_) => BlocProvider.value(
        value: bloc,
        child: _SponsorDialog(sponsor: sponsor),
      ),
    );
  }

  void _confirmDelete(BuildContext context, Sponsor s) {
    final bloc = context.read<SponsorBloc>();
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
            'Delete sponsor?',
            style: TextStyle(fontFamily: 'Inter', fontSize: 16),
          ),
          content: Text(
            s.name,
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
                bloc.add(DeleteSponsorEvent(s.id));
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

class _SponsorCard extends StatelessWidget {
  final Sponsor sponsor;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _SponsorCard({
    required this.sponsor,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      radius: 16,
      child: SizedBox(
        width: 260,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.glassBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.glassBorder),
                  ),
                  child: sponsor.image.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            sponsor.image,
                            fit: BoxFit.contain,
                            errorBuilder: (_, e, s) => const Icon(
                              Icons.business,
                              size: 24,
                              color: AppColors.accent,
                            ),
                          ),
                        )
                      : const Icon(Icons.business, size: 24, color: AppColors.accent),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    sponsor.name,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textWhite,
                    ),
                  ),
                ),
              ],
            ),
            if (sponsor.url.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                sponsor.url,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 10,
                  color: AppColors.accent,
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

class _SponsorDialog extends StatefulWidget {
  final Sponsor? sponsor;
  const _SponsorDialog({this.sponsor});

  @override
  State<_SponsorDialog> createState() => _SponsorDialogState();
}

class _SponsorDialogState extends State<_SponsorDialog> {
  late final TextEditingController _name;
  late final TextEditingController _image;
  late final TextEditingController _url;

  @override
  void initState() {
    super.initState();
    final s = widget.sponsor;
    _name = TextEditingController(text: s?.name ?? '');
    _image = TextEditingController(text: s?.image ?? '');
    _url = TextEditingController(text: s?.url ?? '');
  }

  @override
  void dispose() {
    _name.dispose();
    _image.dispose();
    _url.dispose();
    super.dispose();
  }

  void _save() {
    if (_name.text.trim().isEmpty) return;

    final isNew = widget.sponsor == null;
    final sponsor = Sponsor(
      id: widget.sponsor?.id ?? Ids.generate(),
      name: _name.text.trim(),
      image: _image.text.trim(),
      url: _url.text.trim(),
    );
    context.read<SponsorBloc>().add(
      SaveSponsorEvent(sponsor, isNew: isNew),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<SponsorBloc, SponsorState>(
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
            widget.sponsor == null ? 'New Sponsor' : 'Edit Sponsor',
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
                    hint: 'Sponsor Co.',
                    enabled: !state.isSaving,
                  ),
                  const SizedBox(height: 14),
                  GlassTextField(
                    label: 'Logo URL',
                    controller: _image,
                    hint: 'https://...',
                    enabled: !state.isSaving,
                  ),
                  const SizedBox(height: 14),
                  GlassTextField(
                    label: 'Website URL',
                    controller: _url,
                    hint: 'https://...',
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
