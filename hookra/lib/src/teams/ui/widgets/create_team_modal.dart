import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hookra/src/components/components.dart';
import 'package:hookra/src/teams/ui/blocs/teams_bloc/teams_bloc.dart';

class CreateTeamModal extends StatefulWidget {
  const CreateTeamModal({super.key});

  @override
  State<CreateTeamModal> createState() => _CreateTeamModalState();
}

class _CreateTeamModalState extends State<CreateTeamModal> {
  String _name = '';

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<TeamsBloc, TeamsState>(
      listenWhen: (prev, curr) =>
          prev.status != curr.status && curr.status == TeamsStatus.createSuccess,
      listener: (context, state) => Navigator.of(context).pop(),
      builder: (context, state) {
        final isCreating = state.status == TeamsStatus.creating;
        return Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'New Team',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              ThemedTextField(
                label: 'Client name',
                error: null,
                onChanged: (value) => setState(() => _name = value),
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed:
                        isCreating ? null : () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: isCreating || _name.trim().isEmpty
                        ? null
                        : () => context
                            .read<TeamsBloc>()
                            .add(CreateTeam(_name.trim())),
                    child: isCreating
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Create'),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
