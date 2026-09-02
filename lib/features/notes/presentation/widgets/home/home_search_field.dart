import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:notey/features/notes/presentation/cubits/home_cubit.dart';
import 'package:notey/features/notes/presentation/cubits/home_state.dart';

import 'package:notey/l10n/generated/app_localizations.dart';

/// The home search field. Rebuilds only when [HomeState.query] changes so the
/// page shell is not rebuilt on every keystroke.
class HomeSearchField extends StatelessWidget {
  const HomeSearchField({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    required this.onSubmitted,
    required this.onClear,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onSubmitted;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      focusNode: focusNode,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      textInputAction: TextInputAction.search,
      onTapOutside: (_) => focusNode.unfocus(),
      decoration: InputDecoration(
        hintText: AppLocalizations.of(context).homeSearchHint,
        prefixIcon: const Icon(Icons.search_rounded),
        suffixIcon: _SearchClearButton(onPressed: onClear),
        suffixIconConstraints: const BoxConstraints(
          minWidth: 0,
          minHeight: 0,
        ),
      ),
    );
  }
}

/// The suffix "clear search" button. Watches only the [HomeState.query] field.
class _SearchClearButton extends StatelessWidget {
  const _SearchClearButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HomeCubit, HomeState>(
      buildWhen: (prev, cur) => prev.query != cur.query,
      builder: (context, state) {
        if (state.query.isEmpty) return const SizedBox.shrink();
        return IconButton(
          tooltip: AppLocalizations.of(context).homeClearSearch,
          icon: const Icon(Icons.close_rounded),
          onPressed: onPressed,
        );
      },
    );
  }
}
