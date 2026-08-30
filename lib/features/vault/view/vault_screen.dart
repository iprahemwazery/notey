import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:notey/core/services/haptics.dart';

import 'package:notey/data/repositories/secure_vault_repository.dart';

import 'package:notey/l10n/generated/app_localizations.dart';
import 'package:notey/features/vault/model/vault_entry.dart';

import 'package:notey/features/vault/cubit/vault_cubit.dart';

import 'package:notey/features/vault/cubit/vault_state.dart';

import 'package:notey/features/vault/view/widgets/vault_meta.dart';

import 'vault_entry_detail_screen.dart';
import 'vault_entry_editor_screen.dart';

/// The encrypted digital vault: passwords, bank info and secure notes,
/// browsable through the category chips `[All | Passwords | Banking |
/// Documents | Audio | Canvas]`.
class VaultScreen extends StatefulWidget {
  const VaultScreen({super.key, this.repository});

  final SecureVaultRepository? repository;

  @override
  State<VaultScreen> createState() => _VaultScreenState();
}

class _VaultScreenState extends State<VaultScreen> {
  late final SecureVaultRepository _repository =
      widget.repository ?? SecureVaultRepository();

  @override
  Widget build(BuildContext context) {
    return BlocProvider<VaultCubit>(
      create: (_) => VaultCubit(_repository)..load(),
      child: BlocBuilder<VaultCubit, VaultState>(
        builder: (context, state) => _VaultView(
          state: state,
          onFilter: context.read<VaultCubit>().setFilter,
        ),
      ),
    );
  }
}

class _VaultView extends StatelessWidget {
  const _VaultView({required this.state, required this.onFilter});

  final VaultState state;
  final ValueChanged<VaultFilter> onFilter;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: <Widget>[
            Icon(Icons.shield_rounded, color: scheme.primary, size: 22.w),
            SizedBox(width: 8.w),
            Text(l10n.vaultTitle),
          ],
        ),
        actions: <Widget>[
          if (state.phase == VaultPhase.loading)
            Padding(
              padding: EdgeInsets.only(left: 16.w),
              child: Center(
                child: SizedBox(
                  width: 20.w,
                  height: 20.h,
                  child: const CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
          IconButton(
            tooltip: l10n.vaultScreenProtected,
            onPressed: () {
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(
                  SnackBar(content: Text(l10n.vaultScreenProtected)),
                );
            },
            icon: Icon(Icons.remove_red_eye_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: CustomScrollView(
          slivers: <Widget>[
            SliverPadding(
              padding: EdgeInsets.fromLTRB(16.w, 10.h, 16.w, 6.h),
              sliver: SliverToBoxAdapter(
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.fromLTRB(16.w, 14.h, 12.w, 14.h),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(22.r),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: <Color>[
                        scheme.primary.withValues(alpha: 0.10),
                        scheme.tertiary.withValues(alpha: 0.12),
                        scheme.surfaceContainerHighest.withValues(alpha: 0.70),
                      ],
                    ),
                    border: Border.all(
                      color: scheme.outlineVariant.withValues(alpha: 0.7),
                      width: 1,
                    ),
                    boxShadow: <BoxShadow>[
                      BoxShadow(
                        color: scheme.shadow.withValues(alpha: 0.07),
                        blurRadius: 12.r,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Row(
                    children: <Widget>[
                      Container(
                        width: 52.w,
                        height: 52.h,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: <Color>[
                              scheme.primary,
                              scheme.primary.withValues(alpha: 0.72),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(16.r),
                          boxShadow: <BoxShadow>[
                            BoxShadow(
                              color: scheme.primary.withValues(alpha: 0.20),
                              blurRadius: 12.r,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.shield_rounded,
                          color: Colors.white,
                          size: 28.w,
                        ),
                      ),
                      SizedBox(width: 14.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              l10n.vaultTitle,
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w800),
                            ),
                            SizedBox(height: 4.h),
                            Text(
                              'Private entries',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: scheme.onSurfaceVariant),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: 8.w),
                      IconButton.filledTonal(
                        onPressed: () => _pickAddCategory(context),
                        tooltip: l10n.vaultAdd,
                        style: IconButton.styleFrom(
                          backgroundColor: scheme.primary.withValues(
                            alpha: .12,
                          ),
                          foregroundColor: scheme.primary,
                        ),
                        icon: const Icon(Icons.add_rounded),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SliverPadding(
              padding: EdgeInsets.fromLTRB(16.w, 2.h, 16.w, 6.h),
              sliver: SliverToBoxAdapter(
                child: GridView(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 8.h,
                    crossAxisSpacing: 8.w,
                    mainAxisExtent: 122.h,
                  ),
                  children: <Widget>[
                    _QuickAddCard(
                      category: VaultCategory.login,
                      onTap: () => _openCategory(context, VaultCategory.login),
                    ),
                    _QuickAddCard(
                      category: VaultCategory.creditCard,
                      onTap: () =>
                          _openCategory(context, VaultCategory.creditCard),
                    ),
                    _QuickAddCard(
                      category: VaultCategory.bankAccount,
                      onTap: () =>
                          _openCategory(context, VaultCategory.bankAccount),
                    ),
                    _QuickAddCard(
                      category: VaultCategory.secureNote,
                      onTap: () =>
                          _openCategory(context, VaultCategory.secureNote),
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: _ChipsRow(filter: state.filter, onFilter: onFilter),
            ),
            ...switch (state.phase) {
              VaultPhase.ready => <Widget>[
                _ListReady(entries: state.filteredEntries),
              ],
              VaultPhase.error => <Widget>[
                _SliverCenter(
                  child: Text(
                    l10n.vaultErrorLoading,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ],
              _ => <Widget>[
                const _SliverCenter(child: CircularProgressIndicator()),
              ],
            },
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _pickAddCategory(context),
        icon: const Icon(Icons.add_rounded),
        label: Text(l10n.vaultAdd),
      ),
    );
  }

  Future<void> _openCategory(
    BuildContext context,
    VaultCategory category,
  ) async {
    await Haptics.tap();
    if (!context.mounted) return;
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => VaultEntryEditorScreen(category: category),
      ),
    );
    // Reload only when the editor actually saved something; cancel/back stays
    // untouched so the vault doesn't re-decrypt the whole set on every visit.
    if (changed == true && context.mounted) {
      context.read<VaultCubit>().load(silent: true);
    }
  }

  Future<void> _pickAddCategory(BuildContext context) async {
    await Haptics.tap();
    if (!context.mounted) return;
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final category = await showModalBottomSheet<VaultCategory>(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 24.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                l10n.vaultAdd,
                style: Theme.of(
                  sheetContext,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              SizedBox(height: 12.h),
              for (final option in VaultAddOption.all) ...<Widget>[
                ListTile(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14.r),
                  ),
                  leading: CircleAvatar(
                    backgroundColor: VaultMeta.colorFor(
                      option.category,
                      scheme,
                    ).withValues(alpha: .14),
                    child: Icon(
                      option.icon,
                      color: VaultMeta.colorFor(option.category, scheme),
                    ),
                  ),
                  title: Text(VaultMeta.labelFor(option.category, l10n)),
                  onTap: () => Navigator.pop(sheetContext, option.category),
                ),
                SizedBox(height: 4.h),
              ],
            ],
          ),
        ),
      ),
    );
    if (category == null || !context.mounted) return;
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => VaultEntryEditorScreen(category: category),
      ),
    );
    // Only the success path (a real add) needs a refresh; closing the sheet
    // with no change skips the decrypt work entirely.
    if (changed == true && context.mounted) {
      context.read<VaultCubit>().load(silent: true);
    }
  }
}

class _QuickAddCard extends StatelessWidget {
  const _QuickAddCard({required this.category, required this.onTap});

  final VaultCategory category;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    final color = VaultMeta.colorFor(category, scheme);
    final subtitle = switch (category) {
      VaultCategory.login => 'Email & password',
      VaultCategory.creditCard => 'Card details',
      VaultCategory.bankAccount => 'Bank account',
      VaultCategory.secureNote => 'Private note',
    };

    return Material(
      color: scheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(20.r),
      child: InkWell(
        borderRadius: BorderRadius.circular(20.r),
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.fromLTRB(12.w, 12.h, 12.w, 12.h),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20.r),
            border: Border.all(color: color.withValues(alpha: 0.18), width: 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Container(
                    width: 38.w,
                    height: 38.h,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Icon(VaultMeta.iconFor(category), color: color),
                  ),
                  const Spacer(),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 8.w,
                      vertical: 4.h,
                    ),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(999.r),
                    ),
                    child: Text(
                      'New',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: color,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 14.h),
              Text(
                VaultMeta.labelFor(category, l10n),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
              ),
              SizedBox(height: 4.h),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChipsRow extends StatelessWidget {
  const _ChipsRow({required this.filter, required this.onFilter});

  final VaultFilter filter;
  final ValueChanged<VaultFilter> onFilter;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SizedBox(
      height: 56.h,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
        itemCount: VaultMeta.filters.length,
        separatorBuilder: (_, _) => SizedBox(width: 8.w),
        itemBuilder: (context, index) {
          final f = VaultMeta.filters[index];
          return ChoiceChip(
            selected: f == filter,
            onSelected: (_) => onFilter(f),
            avatar: Icon(VaultMeta.iconForFilter(f), size: 18.w),
            label: Text(VaultMeta.labelForFilter(f, l10n)),
          );
        },
      ),
    );
  }
}

class _ListReady extends StatefulWidget {
  const _ListReady({required this.entries});

  final List<VaultEntry> entries;

  @override
  State<_ListReady> createState() => _ListReadyState();
}

class _ListReadyState extends State<_ListReady> {
  @override
  Widget build(BuildContext context) {
    if (widget.entries.isEmpty) {
      return _EmptyVault();
    }
    return SliverPadding(
      padding: EdgeInsets.fromLTRB(16.w, 4.h, 16.w, 96.h),
      sliver: SliverList.builder(
        itemCount: widget.entries.length,
        itemBuilder: (context, index) {
          final entry = widget.entries[index];
          return _VaultCard(
            entry: entry,
            onTap: () async {
              // Detail pops `true` only when the entry was deleted; any other
              // return (reopen, share, back) leaves the in-memory list alone so
              // we never re-decrypt the whole vault just for a peek.
              final closed = await Navigator.of(context).push<bool>(
                MaterialPageRoute<bool>(
                  builder: (_) => VaultEntryDetailScreen(entry: entry),
                ),
              );
              if (closed == true && context.mounted) {
                context.read<VaultCubit>().load(silent: true);
              }
            },
          );
        },
      ),
    );
  }
}

class _EmptyVault extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    return SliverFillRemaining(
      hasScrollBody: false,
      child: Center(
        child: Padding(
          padding: EdgeInsets.fromLTRB(32.w, 12.h, 32.w, 32.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(
                Icons.shield_outlined,
                size: 72.w,
                color: scheme.primary.withValues(alpha: .45),
              ),
              SizedBox(height: 16.h),
              Text(
                l10n.vaultEmptyTitle,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              SizedBox(height: 8.h),
              Text(
                l10n.vaultEmptyHint,
                textAlign: TextAlign.center,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SliverCenter extends StatelessWidget {
  const _SliverCenter({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SliverFillRemaining(
      hasScrollBody: false,
      child: Center(child: child),
    );
  }
}

class _VaultCard extends StatelessWidget {
  const _VaultCard({required this.entry, required this.onTap});

  final VaultEntry entry;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final color = VaultMeta.colorFor(entry.category, scheme);

    final String subtitle;
    if (entry.category == VaultCategory.secureNote) {
      subtitle = '';
    } else if (entry.fields.isEmpty) {
      subtitle = '';
    } else {
      final first = entry.fields.entries.first;
      subtitle = '${first.key}: ********';
    }

    return Padding(
      padding: EdgeInsets.only(bottom: 10.h),
      child: Material(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(18.r),
        child: InkWell(
          borderRadius: BorderRadius.circular(18.r),
          onTap: onTap,
          child: Padding(
            padding: EdgeInsets.fromLTRB(12.w, 12.h, 12.w, 12.h),
            child: Row(
              children: <Widget>[
                CircleAvatar(
                  backgroundColor: color.withValues(alpha: .14),
                  child: Icon(
                    VaultMeta.iconFor(entry.category),
                    color: color,
                    size: 22.w,
                  ),
                ),
                SizedBox(width: 14.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        entry.title.isEmpty ? l10n.untitled : entry.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (subtitle.isNotEmpty) ...<Widget>[
                        SizedBox(height: 4.h),
                        Text(
                          subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: scheme.onSurfaceVariant),
                        ),
                      ],
                    ],
                  ),
                ),
                SizedBox(width: 8.w),
                Icon(
                  entry.mediaType == VaultMediaType.none
                      ? Icons.chevron_left_rounded
                      : _mediaBadge(entry.mediaType),
                  size: 18.w,
                  color: scheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static IconData _mediaBadge(VaultMediaType type) {
    return switch (type) {
      VaultMediaType.document => Icons.description_outlined,
      VaultMediaType.audio => Icons.graphic_eq_rounded,
      VaultMediaType.drawing => Icons.brush_rounded,
      VaultMediaType.none => Icons.chevron_left_rounded,
    };
  }
}
