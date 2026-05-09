import 'package:supabase_flutter/supabase_flutter.dart' hide User;
import 'package:hookra/src/organizations/domain/model/organization.dart';
import 'package:hookra/src/organizations/domain/model/organization_member.dart';
import 'package:hookra/src/organizations/domain/model/role.dart';
import 'package:hookra/src/profile/domain/entities/user.dart';

class OrganizationDataSource {
  final SupabaseClient _client = Supabase.instance.client;

  void _log(String msg) => print('DEBUG: $msg');

  Future<List<OrganizationMember>> getMembers(String organizationId) async {
    print('DEBUG: getMembers for org: $organizationId');
    
    final response = await _client
        .from('organization_members')
        .select('''
          id,
          organization_id,
          profile_id,
          role,
          invited_by,
          joined_at
        ''')
        .eq('organization_id', organizationId)
        .order('joined_at', ascending: true);

    print('DEBUG: raw members response: $response');

    final List<OrganizationMember> members = [];
    
    for (final memberJson in response) {
      final profileId = memberJson['profile_id'] as String;
      
      final profileResponse = await _client
          .from('profiles')
          .select()
          .eq('id', profileId)
          .maybeSingle();
      
      print('DEBUG: profile for $profileId: $profileResponse');
      
      User? profile;
      if (profileResponse != null) {
        profile = User(
          id: profileResponse['id'] as String,
          firstName: profileResponse['first_name'] as String,
          lastName: profileResponse['last_name'] as String,
          email: profileResponse['email'] as String,
        );
      }
      
      final member = OrganizationMember.fromJson(memberJson).copyWith(
        profile: profile,
      );
      members.add(member);
    }

    return members;
  }

  Future<Organization?> getOrganization(String organizationId) async {
    final response = await _client
        .from('organizations')
        .select()
        .eq('id', organizationId)
        .maybeSingle();

    if (response == null) return null;
    return Organization.fromJson(response);
  }

  Future<OrganizationMember?> getMemberRole(
      String organizationId, String profileId) async {
    final response = await _client
        .from('organization_members')
        .select('''
          id,
          organization_id,
          profile_id,
          role,
          invited_by,
          joined_at
        ''')
        .eq('organization_id', organizationId)
        .eq('profile_id', profileId)
        .maybeSingle();

    if (response == null) return null;
    return OrganizationMember.fromJson(response);
  }

  Future<void> updateMemberRole(String memberId, OrgRole newRole) async {
    print('DEBUG: updateMemberRole called - memberId: $memberId, newRole: ${newRole.value}');
    await _client
        .from('organization_members')
        .update({'role': newRole.value})
        .eq('id', memberId);
    print('DEBUG: updateMemberRole completed');
  }

  Future<Organization?> getUserOrganization(String profileId) async {
    _log('getUserOrganization: profileId=$profileId');
    
    final memberResponse = await _client
        .from('organization_members')
        .select('organization_id')
        .eq('profile_id', profileId)
        .limit(1)
        .maybeSingle();

    _log('memberResponse: $memberResponse');

    if (memberResponse == null) return null;

    final orgId = memberResponse['organization_id'];
    _log('orgId: $orgId');

    final orgResponse = await _client
        .from('organizations')
        .select()
        .eq('id', orgId)
        .maybeSingle();

    _log('orgResponse: $orgResponse');

    if (orgResponse == null) return null;
    return Organization.fromJson(orgResponse);
  }

  Future<List<Organization>> getUserOrganizations(String profileId) async {
    _log('getUserOrganizations: profileId=$profileId');
    
    final memberResponse = await _client
        .from('organization_members')
        .select('organization_id')
        .eq('profile_id', profileId);

    _log('memberResponse: $memberResponse (length: ${memberResponse.length})');

    if (memberResponse.isEmpty) return [];

    final orgIds = memberResponse.map((m) => m['organization_id'] as String).toList();
    _log('orgIds: $orgIds');

    final List<Organization> organizations = [];
    
    for (final orgId in orgIds) {
      _log('Fetching org: $orgId');
      final orgResponse = await _client
          .from('organizations')
          .select()
          .eq('id', orgId)
          .maybeSingle();
      
      _log('orgResponse for $orgId: $orgResponse');
      
      if (orgResponse != null) {
        organizations.add(Organization.fromJson(orgResponse));
      }
    }

    _log('Returning organizations: ${organizations.length}');
    return organizations;
  }
}