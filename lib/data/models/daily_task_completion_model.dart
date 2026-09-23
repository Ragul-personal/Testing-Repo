import 'package:hive/hive.dart';
import '../../domain/entities/daily_task.dart';

/// Hive-persisted view of [DailyTaskCompletion].
///
/// typeId 6 — a fresh number. Never reuse or renumber after the app ships.
class DailyTaskCompletionModel {
  String id;
  String taskTemplateId;
  DateTime date;
  bool completed;
  DateTime? completedAt;

  DailyTaskCompletionModel({
    required this.id,
    required this.taskTemplateId,
    required this.date,
    required this.completed,
    this.completedAt,
  });

  DailyTaskCompletion toEntity() => DailyTaskCompletion(
        id: id,
        taskTemplateId: taskTemplateId,
        date: date,
        completed: completed,
        completedAt: completedAt,
      );

  factory DailyTaskCompletionModel.fromEntity(DailyTaskCompletion e) =>
      DailyTaskCompletionModel(
        id: e.id,
        taskTemplateId: e.taskTemplateId,
        date: DateTime(e.date.year, e.date.month, e.date.day),
        completed: e.completed,
        completedAt: e.completedAt,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'taskTemplateId': taskTemplateId,
        'date': date.toIso8601String(),
        'completed': completed,
        'completedAt': completedAt?.toIso8601String(),
      };

  factory DailyTaskCompletionModel.fromJson(Map<String, dynamic> j) =>
      DailyTaskCompletionModel(
        id: j['id'] as String,
        taskTemplateId: j['taskTemplateId'] as String,
        date: DateTime.parse(j['date'] as String),
        completed: (j['completed'] as bool?) ?? false,
        completedAt: j['completedAt'] != null
            ? DateTime.parse(j['completedAt'] as String)
            : null,
      );
}

/// Hand-written TypeAdapter — build_runner is not run locally.
class DailyTaskCompletionModelAdapter
    extends TypeAdapter<DailyTaskCompletionModel> {
  @override
  final int typeId = 6;

  @override
  DailyTaskCompletionModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return DailyTaskCompletionModel(
      id: fields[0] as String,
      taskTemplateId: fields[1] as String,
      date: fields[2] as DateTime,
      completed: (fields[3] as bool?) ?? false,
      completedAt: fields[4] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, DailyTaskCompletionModel obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.taskTemplateId)
      ..writeByte(2)
      ..write(obj.date)
      ..writeByte(3)
      ..write(obj.completed)
      ..writeByte(4)
      ..write(obj.completedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DailyTaskCompletionModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
