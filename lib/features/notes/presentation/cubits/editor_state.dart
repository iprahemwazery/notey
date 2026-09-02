import 'package:equatable/equatable.dart';
import 'package:notey/features/notes/domain/entities/note.dart';


class EditorState extends Equatable {
  final String title;
  final String content;
  final List<String> attachments;
  final List<String> tags;
  final int colorIndex;
  final DateTime? reminderAt;
  final String folder;
  final bool saving;
  final bool allowPop;
  final bool isEditing;
  final Note? note;
  final String? errorMessage;
  final bool canUndo;
  final bool canRedo;

  const EditorState({
    this.title = '',
    this.content = '',
    this.attachments = const [],
    this.tags = const [],
    this.colorIndex = 0,
    this.reminderAt,
    this.folder = '',
    this.saving = false,
    this.allowPop = false,
    this.isEditing = false,
    this.note,
    this.errorMessage,
    this.canUndo = false,
    this.canRedo = false,
  });

  bool get hasChanges => title.isNotEmpty || content.isNotEmpty || attachments.isNotEmpty;

  EditorState copyWith({
    String? title,
    String? content,
    List<String>? attachments,
    List<String>? tags,
    int? colorIndex,
    DateTime? Function()? reminderAt,
    String? folder,
    bool? saving,
    bool? allowPop,
    bool? isEditing,
    Note? note,
    String? Function()? errorMessage,
    bool? canUndo,
    bool? canRedo,
  }) {
    return EditorState(
      title: title ?? this.title,
      content: content ?? this.content,
      attachments: attachments ?? this.attachments,
      tags: tags ?? this.tags,
      colorIndex: colorIndex ?? this.colorIndex,
      reminderAt: reminderAt != null ? reminderAt() : this.reminderAt,
      folder: folder ?? this.folder,
      saving: saving ?? this.saving,
      allowPop: allowPop ?? this.allowPop,
      isEditing: isEditing ?? this.isEditing,
      note: note ?? this.note,
      errorMessage: errorMessage != null ? errorMessage() : this.errorMessage,
      canUndo: canUndo ?? this.canUndo,
      canRedo: canRedo ?? this.canRedo,
    );
  }

  @override
  List<Object?> get props => [title, content, attachments, tags, colorIndex, reminderAt, folder, saving, allowPop, isEditing, note, errorMessage, canUndo, canRedo];
}
