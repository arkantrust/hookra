// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'report.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Report _$ReportFromJson(Map<String, dynamic> json) => _Report(
  id: json['id'] as String,
  title: json['title'] as String,
  content: json['content'] as String,
  latitude: (json['latitude'] as num).toDouble(),
  longitude: (json['longitude'] as num).toDouble(),
  reporterId: json['reporter_id'] as String?,
  risk: $enumDecode(_$RiskEnumMap, json['risk']),
);

Map<String, dynamic> _$ReportToJson(_Report instance) => <String, dynamic>{
  'id': instance.id,
  'title': instance.title,
  'content': instance.content,
  'latitude': instance.latitude,
  'longitude': instance.longitude,
  'reporter_id': instance.reporterId,
  'risk': _$RiskEnumMap[instance.risk]!,
};

const _$RiskEnumMap = {Risk.low: 'low', Risk.mid: 'mid', Risk.high: 'high'};
