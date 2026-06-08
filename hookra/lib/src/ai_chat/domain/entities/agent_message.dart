import 'package:equatable/equatable.dart';

enum AgentMessageRole { user, agent }

class AgentMessage extends Equatable {
  const AgentMessage({required this.role, required this.text});

  final AgentMessageRole role;
  final String text;

  Map<String, Object?> toJson() => {'role': role.name, 'text': text};

  @override
  List<Object?> get props => [role, text];
}
