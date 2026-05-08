import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:hookra/features/organizations/domain/model/organization.dart';
import 'package:hookra/features/organizations/domain/model/organization_member.dart';
import 'package:hookra/features/organizations/domain/model/organization_with_role.dart';
import 'package:hookra/features/organizations/domain/repo/organization_repository.dart';
import 'package:hookra/features/organizations/data/sources/organization_data_source.dart';

class OrganizationRepositoryImpl extends OrganizationRepository {
  final OrganizationDataSource _dataSource = OrganizationDataSource();

  @override
  Future<List<OrganizationWithRole>> getOrganizationsForCurrentUser() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    final profileId = user.id;
    final results = await _dataSource.getOrganizationsForUser(profileId);

    return results.map((row) {
      final orgData = row['organization'] as Map<String, dynamic>;
      return OrganizationWithRole(
        organization: Organization.fromJson(orgData),
        role: row['role'] == 'owner' ? OrganizationRole.owner : OrganizationRole.member,
      );
    }).toList();
  }

  @override
  Future<Organization> createOrganization(String name, String ownerId) async {
    final slug = await generateUniqueSlug(name);
    return await _dataSource.createOrganization(
      name: name,
      slug: slug,
      ownerId: ownerId,
    );
  }

  @override
  Future<void> addMember(String organizationId, String profileId, String role) async {
    await _dataSource.addMember(
      organizationId: organizationId,
      profileId: profileId,
      role: role == 'owner' ? OrganizationRole.owner : OrganizationRole.member,
    );
  }

  @override
  Future<String> generateUniqueSlug(String baseName) async {
    final existingSlugs = await _dataSource.getExistingSlugs();
    
    String slug = baseName
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9\s-]'), '')
        .replaceAll(RegExp(r'\s+'), '-')
        .trim();
    
    if (slug.isEmpty) {
      slug = 'organization';
    }
    
    String finalSlug = slug;
    int counter = 1;
    
    while (existingSlugs.contains(finalSlug)) {
      finalSlug = '$slug-$counter';
      counter++;
    }
    
    return finalSlug;
  }

  @override
  Future<Organization?> getOrganizationById(String organizationId) async {
    final data = await _dataSource.getOrganizationById(organizationId);
    if (data == null) return null;
    return Organization.fromJson(data);
  }

  @override
  Future<void> updateOrganizationName(String organizationId, String name) async {
    await _dataSource.updateOrganizationName(organizationId, name);
  }

  @override
  Future<List<MemberWithProfile>> getOrganizationMembers(String organizationId) async {
    final results = await _dataSource.getOrganizationMembers(organizationId);
    
    return results.map((row) {
      final profile = row['profile'] as Map<String, dynamic>;
      return MemberWithProfile(
        profileId: profile['id'] as String,
        firstName: profile['first_name'] as String? ?? '',
        lastName: profile['last_name'] as String? ?? '',
        email: profile['email'] as String? ?? '',
        role: row['role'] == 'owner' ? OrganizationRole.owner : OrganizationRole.member,
      );
    }).toList();
  }
}