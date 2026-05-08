import 'package:flutter/material.dart';
import 'package:hookra/src/config/config.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:hookra/features/organizations/domain/model/organization.dart';
import 'package:hookra/features/organizations/domain/model/organization_member.dart';
import 'package:hookra/features/organizations/domain/repo/organization_repository.dart';

class OrganizationDetailScreen extends StatefulWidget {
  final String organizationId;

  const OrganizationDetailScreen({
    super.key,
    required this.organizationId,
  });

  @override
  State<OrganizationDetailScreen> createState() => _OrganizationDetailScreenState();
}

class _OrganizationDetailScreenState extends State<OrganizationDetailScreen> {
  final OrganizationRepository _repository = sl<OrganizationRepository>();
  
  Organization? _organization;
  List<MemberWithProfile> _members = [];
  bool _isLoading = true;
  bool _isEditing = false;
  final TextEditingController _nameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final org = await _repository.getOrganizationById(widget.organizationId);
      final members = await _repository.getOrganizationMembers(widget.organizationId);
      
      if (mounted) {
        setState(() {
          _organization = org;
          _members = members;
          _nameController.text = org?.name ?? '';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _saveName() async {
    if (_nameController.text.trim().isEmpty) return;
    
    try {
      await _repository.updateOrganizationName(
        widget.organizationId,
        _nameController.text.trim(),
      );
      
      await _loadData();
      
      if (mounted) {
        setState(() => _isEditing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Organization name updated')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Organization')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_organization == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Organization')),
        body: const Center(child: Text('Organization not found')),
      );
    }

    final isOwner = _members.any((m) => m.profileId == currentUserId && m.role == OrganizationRole.owner);

    return Scaffold(
      appBar: AppBar(
        title: _isEditing
            ? TextField(
                controller: _nameController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  hintText: 'Organization name',
                  hintStyle: TextStyle(color: Colors.white70),
                ),
                autofocus: true,
              )
            : Text(_organization!.name),
        actions: [
          if (_isEditing)
            IconButton(
              icon: const Icon(Icons.check),
              onPressed: _saveName,
            )
          else if (isOwner)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => setState(() => _isEditing = true),
            ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_isEditing)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _saveName,
                      child: const Text('Save'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        _nameController.text = _organization!.name;
                        setState(() => _isEditing = false);
                      },
                      child: const Text('Cancel'),
                    ),
                  ),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Members (${_members.length})',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: _members.isEmpty
                ? const Center(child: Text('No members yet'))
                : ListView.builder(
                    itemCount: _members.length,
                    itemBuilder: (context, index) {
                      final member = _members[index];
                      final isCurrentUser = member.profileId == currentUserId;
                      
                      return ListTile(
                        leading: CircleAvatar(
                          child: Text(
                            member.firstName.isNotEmpty 
                                ? member.firstName[0].toUpperCase() 
                                : '?',
                          ),
                        ),
                        title: Text(
                          '${member.firstName} ${member.lastName}'.trim(),
                        ),
                        subtitle: Text(member.email),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (member.role == OrganizationRole.owner)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.green.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  'Owner',
                                  style: TextStyle(
                                    color: Colors.green,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            if (isCurrentUser)
                              const Padding(
                                padding: EdgeInsets.only(left: 8),
                                child: Text(
                                  '(You)',
                                  style: TextStyle(color: Colors.grey),
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}