import 'package:hookra/src/organizations/domain/model/organization.dart';

class OrganizationDto {
  static Organization fromJson(Map<String, dynamic> json) {
    return Organization(
      id: json['id'] as String,
      name: json['name'] as String,
      slug: json['slug'] as String,
      ownerId: json['owner_id'] as String,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
    );
  }
}
