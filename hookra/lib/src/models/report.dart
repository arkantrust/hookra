import 'package:flutter/foundation.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'report.freezed.dart';
part 'report.g.dart';

enum Risk { low, mid, high }

/// {@template report}
/// Report model
///
/// [Report.empty] represents an empty report.
/// {@endtemplate}
// dart run build_runner build -d
@freezed
abstract class Report with _$Report {
  @JsonSerializable(fieldRename: FieldRename.snake, explicitToJson: true)
  const factory Report({
    required String id,
    required String title,
    required String content,
    required double latitude,
    required double longitude,
    required String? reporterId,
    required Risk risk,
  }) = _Report;

  /// Empty report represents an empty report.
  static const empty = Report(
    id: '',
    title: '',
    content: '',
    reporterId: null,
    latitude: 0,
    longitude: 0,
    risk: Risk.low,
  );

  factory Report.fromJson(Map<String, Object?> json) => _$ReportFromJson(json);
}
