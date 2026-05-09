import 'package:hookra/src/organizations/data/sources/organization_data_source.dart';
import 'package:hookra/src/organizations/domain/model/organization.dart';
import 'package:hookra/src/organizations/domain/model/organization_member.dart';
import 'package:hookra/src/organizations/domain/model/role.dart';
import 'package:hookra/src/organizations/domain/repo/organization_repository.dart';

class OrganizationRepositoryImpl implements OrganizationRepository {
  final OrganizationDataSource _dataSource;

  OrganizationRepositoryImpl(this._dataSource);

  @override
  Future<List<OrganizationMember>> getMembers(String organizationId) {
    return _dataSource.getMembers(organizationId);
  }

  @override
  Future<Organization?> getOrganization(String organizationId) {
    return _dataSource.getOrganization(organizationId);
  }

  @override
  Future<OrganizationMember?> getMemberRole(
      String organizationId, String profileId) {
    return _dataSource.getMemberRole(organizationId, profileId);
  }

  @override
  Future<void> updateMemberRole(String memberId, OrgRole newRole) {
    return _dataSource.updateMemberRole(memberId, newRole);
  }

  @override
  Future<Organization?> getUserOrganization(String profileId) {
    return _dataSource.getUserOrganization(profileId);
  }

  @override
  Future<List<Organization>> getUserOrganizations(String profileId) {
    return _dataSource.getUserOrganizations(profileId);
  }
}