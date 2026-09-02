import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:notey/features/notes/presentation/cubits/home_cubit.dart';
import 'package:notey/features/notes/presentation/cubits/home_state.dart';

import 'package:notey/features/notes/presentation/widgets/search_history_panel.dart';

/// The search-history panel. Visibility depends on the search field focus
/// ([ValueNotifier]) and the panel content on [HomeState.searchHistory], so
/// both are subscribed to in isolation — a focus change or a recorded term
/// never touches the rest of the page.
class HomeSearchHistory extends StatelessWidget {
  const HomeSearchHistory({
    super.key,
    required this.focused,
    required this.onSelected,
    required this.onRemove,
    required this.onClear,
  });

  final ValueListenable<bool> focused;
  final ValueChanged<String> onSelected;
  final ValueChanged<String> onRemove;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: focused,
      builder: (context, isFocused, _) {
        return BlocBuilder<HomeCubit, HomeState>(
          buildWhen: (prev, cur) =>
              prev.searchHistory != cur.searchHistory ||
              prev.query != cur.query,
          builder: (context, state) {
            if (!isFocused ||
                state.query.trim().isNotEmpty ||
                state.searchHistory.isEmpty) {
              return const SizedBox.shrink();
            }
            return Padding(
              padding: EdgeInsets.fromLTRB(20.w, 0.h, 20.w, 10.h),
              child: SearchHistoryPanel(
                history: state.searchHistory,
                onSelected: onSelected,
                onRemove: onRemove,
                onClear: onClear,
              ),
            );
          },
        );
      },
    );
  }
}
