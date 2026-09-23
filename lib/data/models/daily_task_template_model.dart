import 'package:hive/hive.dart';
import '../../domain/entities/daily_task.dart';

/// Hive-persisted view of [DailyTaskTemplate].
///
/// typeId 5 — a fresh number. Never reuse or renumber after the app ships.
class DailyTaskTemplateModel {
  String id;
  String title;
  String? description;
  String? subjectId;
  bool active;
  int sortOrder;
  DateTime createdAt;
  DateTime? archivedAt;

  DailyTaskTemplateModel({
    required this.id,
    required this.title,
    this.description,
    this.subjectId,
    required this.active,
    required this.sortOrder,
    required this.createdAt,
    this.archivedAt,
  });

  DailyTaskTemplate toEntity() => DailyTaskTemplate(
        id: id,
        title: title,
        description: description,
        subjectId: subjectId,
        active: active,
        sortOrder: sortOrder,
        createdAt: createdAt,
        archivedAt: archivedAt,
      );

  factory DailyTaskTemplateModel.fromEntity(DailyTaskTemplate e) =>
      DailyTaskTemplateModel(
        id: e.id,
        title: e.title,
        description: e.description,
        subjectId: e.subjectId,
        active: e.active,
        sortOrder: e.sortOrder,
        createdAt: e.createdAt,
        archivedAt: e.archivedAt,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'subjectId': subjectId,
        'active': active,
        'sortOrder': sortOrder,
        'createdAt': createdAt.toIso8601String(),
        'archivedAt': archivedAt?.toIso8601String(),
      };

  factory DailyTaskTemplateModel.fromJson(Map<String, dynamic> j) =>
      DailyTaskTemplateModel(
        id: j['id'] as String,
        title: j['title'] as String,
        description: j['description'] as String?,
        subjectId: j['subjectId'] as String?,
        active: (j['active'] as bool?) ?? true,
        sortOrder: (j['sortOrder'] as int?) ?? 0,
        createdAt: DateTime.parse(j['createdAt'] as String),
        archivedAt: j['archivedAt'] != null
            ? DateTime.parse(j['archivedAt'] as String)
            : null,
      );
}

/// Hand-written TypeAdapter — build_runner is not run locally.
class DailyTaskTemplateModelAdapter
    extends TypeAdapter<DailyTaskTemplateModel> {
  @override
  final int typeId = 5;

  @override
  DailyTaskTemplateModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return DailyTaskTemplateModel(
      id: fields[0] as String,
      title: fields[1] as String,
      description: fields[2] as String?,
      subjectId: fields[3] as String?,
      active: (fields[4] as bool?) ?? true,
      sortOrder: (fields[5] as int?) ?? 0,
      createdAt: fields[6] as DateTime,
      archivedAt: fields[7] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, DailyTaskTemplateModel obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.description)
      ..writeByte(3)
      ..write(obj.subjectId)
      ..writeByte(4)
      ..write(obj.active)
      ..writeByte(5)
      ..write(obj.sortOrder)
      ..writeByte(6)
      ..write(obj.createdAt)
      ..writeByte(7)
      ..write(obj.archivedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DailyTaskTemplateModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
