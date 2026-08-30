import 'package:equatable/equatable.dart';
import 'package:notey/features/notes/model/note.dart';

import 'package:notey/features/notes/model/note_history.dart';


class ViewerState extends Equatable {
  final Note note;
  final Note? unlocked;
  final List<NoteHistory> history;
  final bool loadingHistory;
  final double fontScale;

  const ViewerState({
    required this.note,
    this.unlocked,
    this.history = const [],
    this.loadingHistory = false,
    this.fontScale = 1.0,
  });

  bool get isLocked => note.isLocked;
  bool get isUnlocked => unlocked != null;
  Note get displayNote => unlocked ?? note;

  ViewerState copyWith({
    Note? note,
    Note? Function()? unlocked,
    List<NoteHistory>? history,
    bool? loadingHistory,
    double? fontScale,
  }) {
    return ViewerState(
      note: note ?? this.note,
      unlocked: unlocked != null ? unlocked() : this.unlocked,
      history: history ?? this.history,
      loadingHistory: loadingHistory ?? this.loadingHistory,
      fontScale: fontScale ?? this.fontScale,
    );
  }

  @override
  List<Object?> get props => [note, unlocked, history, loadingHistory, fontScale];
}
