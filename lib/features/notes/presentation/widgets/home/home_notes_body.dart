import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:notey/features/notes/presentation/cubits/home_cubit.dart';
import 'package:notey/features/notes/presentation/cubits/home_state.dart';
import 'package:notey/features/notes/domain/entities/note.dart';
import 'package:notey/features/notes/domain/entities/note_search_result.dart';

import 'package:notey/features/notes/presentation/widgets/folder_filter_row.dart';
import 'package:notey/features/notes/presentation/widgets/search_results_list.dart';
import 'package:notey/features/notes/presentation/widgets/tag_filter_row.dart';

import 'package:notey/l10n/generated/app_localizations.dart';
import 'package:notey/widgets/empty_state.dart';

/// The scrollable body of the home screen: advanced-search results, loading,
/// empty state, or the folder/tag filters plus the notes grid/list.
class HomeNotesBody extends StatelessWidget {
  const HomeNotesBody({
    super.key,
    required this.isSearching,
    required this.viewState,
    required this.notes,
    required this.query,
    required this.onOpenSearchResult,
    required this.onGridEntries,
    required this.onListEntries,
  });

  final bool isSearching;
  final ViewState viewState;
  final List<Note> notes;
  final String query;
  final ValueChanged<NoteSearchMatch> onOpenSearchResult;

  /// Builds the themed grid view for the given notes.
  final Widget Function(BuildContext, List<Note>) onGridEntries;

  /// Builds the themed list view for the given notes.
  final Widget Function(BuildContext, List<Note>) onListEntries;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: isSearching
          ? _SearchResultsArea(
              onTap: onOpenSearchResult,
            )
          : viewState == ViewState.loading && notes.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : notes.isEmpty
          ? EmptyState(isSearching: query.trim().isNotEmpty)
          : _buildFiltersGrid(
              context,
              onGridEntries,
              onListEntries,
            ),
    );
  }

  Widget _buildFiltersGrid(
    BuildContext context,
    Widget Function(BuildContext, List<Note>) gridBuilder,
    Widget Function(BuildContext, List<Note>) listBuilder,
  ) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      children: <Widget>[
        TagFilterRow(
          tags: context.select<HomeCubit, List<String>>(
            (c) => c.state.allTags,
          ),
          activeTag: context.select<HomeCubit, String?>(
            (c) => c.state.activeTag,
          ),
          onSelected: (tag) =>
              context.read<HomeCubit>().setActiveTag(tag),
        ),
        FolderFilterRow(
          folders: context.select<HomeCubit, List<String>>(
            (c) => c.state.folders,
          ),
          activeFolder: context.select<HomeCubit, String?>(
            (c) => c.state.activeFolder,
          ),
          onSelected: (folder) =>
              context.read<HomeCubit>().setActiveFolder(folder),
        ),
        SizedBox(height: 8.h),
        Expanded(
          child: _buildEntriesGrid(context, scheme, gridBuilder, listBuilder),
        ),
      ],
    );
  }

  Widget _buildEntriesGrid(
    BuildContext context,
    ColorScheme scheme,
    Widget Function(BuildContext, List<Note>) gridBuilder,
    Widget Function(BuildContext, List<Note>) listBuilder,
  ) {
    final l10n = AppLocalizations.of(context);
    final activeTag = context.select<HomeCubit, String?>(
      (c) => c.state.activeTag,
    );
    final gridLayout = context.select<HomeCubit, bool>((c) => c.state.gridLayout);

    if (notes.isEmpty && activeTag != null) {
      return Center(
        child: Text(
          l10n.noNotesWithTag,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
      );
    }
    return gridLayout
        ? gridBuilder(context, notes)
        : listBuilder(context, notes);
  }
}

/// The advanced-search results. Rebuilds only when the query or its results
/// change, keeping header/filters/grid untouched while typing.
class _SearchResultsArea extends StatelessWidget {
  const _SearchResultsArea({required this.onTap});

  final ValueChanged<NoteSearchMatch> onTap;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HomeCubit, HomeState>(
      buildWhen: (prev, cur) =>
          prev.query != cur.query ||
          prev.searchResults != cur.searchResults ||
          prev.viewState != cur.viewState,
      builder: (context, state) {
        if (state.viewState == ViewState.loading &&
            state.searchResults.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        if (state.searchResults.isEmpty) {
          return EmptyState(isSearching: true);
        }
        return SearchResultsList(
          results: state.searchResults,
          query: state.query.trim(),
          onTap: onTap,
        );
      },
    );
  }
}
