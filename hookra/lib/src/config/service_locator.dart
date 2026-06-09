import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get_it/get_it.dart';
import 'package:hookra/src/ai_chat/ai_chat.dart';
import 'package:hookra/src/auth/auth.dart';
import 'package:hookra/src/config/config.dart';
import 'package:hookra/src/onboarding/onboarding.dart';
import 'package:hookra/src/organizations/data/repo/supabase_invite_repository.dart';
import 'package:hookra/src/organizations/organizations.dart';
import 'package:hookra/src/home/ui/cubit/home_activity_cubit.dart';
import 'package:hookra/src/preview/preview.dart';
import 'package:hookra/src/profile/profile.dart';
import 'package:hookra/src/selection/selection.dart';
import 'package:hookra/src/settings/settings.dart';
import 'package:hookra/src/teams/teams.dart';

GetIt sl = GetIt.instance;

void initServiceLocator() {
  // Repositories
  sl.registerSingleton<AuthRepository>(
    SupabaseAuthRepository(supabase: supabase),
  );
  sl.registerSingleton<UserRepository>(
    SupabaseUserRepository(supabase: supabase),
  );
  sl.registerSingleton<OrganizationRepository>(
    SupabaseOrganizationRepository(
      supabase: supabase,
      userRepository: sl<UserRepository>(),
    ),
  );
  sl.registerSingleton<InviteRepository>(
    SupabaseInviteRepository(supabase: supabase),
  );

  // Use cases
  sl.registerFactory<SignInUseCase>(() => SignInUseCase(sl<AuthRepository>()));
  sl.registerFactory<SignUpUseCase>(() => SignUpUseCase(sl<AuthRepository>()));
  sl.registerFactory<SignUpWithOrganizationUseCase>(
    () => SignUpWithOrganizationUseCase(
      sl<SignUpUseCase>(),
      sl<GetUserUseCase>(),
      sl<CreateOrganizationUseCase>(),
    ),
  );
  sl.registerFactory<SignOutUseCase>(
    () => SignOutUseCase(sl<AuthRepository>()),
  );
  sl.registerFactory<WatchAuthStatusUseCase>(
    () => WatchAuthStatusUseCase(sl<AuthRepository>()),
  );
  sl.registerFactory<GetUserUseCase>(
    () => GetUserUseCase(sl<UserRepository>()),
  );
  sl.registerFactory<GetOrganizationsUseCase>(
    () => GetOrganizationsUseCase(sl<OrganizationRepository>()),
  );
  sl.registerFactory<CreateOrganizationUseCase>(
    () => CreateOrganizationUseCase(sl<OrganizationRepository>()),
  );
  sl.registerFactory<UpdateProfileUseCase>(
    () => UpdateProfileUseCase(sl<UserRepository>()),
  );
  sl.registerFactory<GetOrganizationDetailsUseCase>(
    () => GetOrganizationDetailsUseCase(sl<OrganizationRepository>()),
  );
  sl.registerFactory<UpdateOrganizationNameUseCase>(
    () => UpdateOrganizationNameUseCase(sl<OrganizationRepository>()),
  );
  sl.registerFactory<UpdateMemberRoleUseCase>(
    () => UpdateMemberRoleUseCase(sl<OrganizationRepository>()),
  );
  sl.registerFactory<CreateInviteUseCase>(
    () => CreateInviteUseCase(sl<InviteRepository>()),
  );
  sl.registerFactory<GetInviteByTokenUseCase>(
    () => GetInviteByTokenUseCase(sl<InviteRepository>()),
  );
  sl.registerFactory<AcceptInviteUseCase>(
    () => AcceptInviteUseCase(sl<InviteRepository>()),
  );

  // BLoCs
  sl.registerSingleton<AuthBloc>(
    AuthBloc(
      watchStatus: sl<WatchAuthStatusUseCase>(),
      signOut: sl<SignOutUseCase>(),
      getUser: sl<GetUserUseCase>(),
    ),
  );
  sl.registerFactory<SignInBloc>(() => SignInBloc(signIn: sl<SignInUseCase>()));
  sl.registerFactory<SignUpBloc>(
    () => SignUpBloc(signUp: sl<SignUpWithOrganizationUseCase>()),
  );
  sl.registerFactory<EditProfileBloc>(
    () => EditProfileBloc(updateProfile: sl<UpdateProfileUseCase>()),
  );
  sl.registerFactory<OrganizationsBloc>(
    () => OrganizationsBloc(
      getOrganizations: sl<GetOrganizationsUseCase>(),
      createOrganization: sl<CreateOrganizationUseCase>(),
    ),
  );
  sl.registerFactory<OrganizationMembersBloc>(
    () => OrganizationMembersBloc(
      getDetails: sl<GetOrganizationDetailsUseCase>(),
      updateMemberRole: sl<UpdateMemberRoleUseCase>(),
      updateOrgName: sl<UpdateOrganizationNameUseCase>(),
    ),
  );

  sl.registerSingleton<TeamRepository>(
    SupabaseTeamRepository(supabase: supabase),
  );

  sl.registerFactory<GetTeamsUseCase>(
    () => GetTeamsUseCase(sl<TeamRepository>()),
  );
  sl.registerFactory<CreateTeamUseCase>(
    () => CreateTeamUseCase(sl<TeamRepository>()),
  );
  sl.registerFactory<JoinTeamUseCase>(
    () => JoinTeamUseCase(sl<TeamRepository>()),
  );
  sl.registerFactory<LeaveTeamUseCase>(
    () => LeaveTeamUseCase(sl<TeamRepository>()),
  );
  sl.registerFactory<DeleteTeamUseCase>(
    () => DeleteTeamUseCase(sl<TeamRepository>()),
  );
  sl.registerFactory<GetUserTeamIdsUseCase>(
    () => GetUserTeamIdsUseCase(sl<TeamRepository>()),
  );
  sl.registerFactory<GetTeamMembersUseCase>(
    () => GetTeamMembersUseCase(sl<TeamRepository>()),
  );

  sl.registerSingleton<SelectionCubit>(
    SelectionCubit(
      getOrganizations: sl<GetOrganizationsUseCase>(),
      getTeams: sl<GetTeamsUseCase>(),
    ),
  );

  sl.registerFactoryParam<TeamsBloc, String, String>(
    (organizationId, creatorId) => TeamsBloc(
      organizationId: organizationId,
      creatorId: creatorId,
      getTeams: sl<GetTeamsUseCase>(),
      createTeam: sl<CreateTeamUseCase>(),
      deleteTeam: sl<DeleteTeamUseCase>(),
      joinTeam: sl<JoinTeamUseCase>(),
      leaveTeam: sl<LeaveTeamUseCase>(),
      getUserTeamIds: sl<GetUserTeamIdsUseCase>(),
    ),
  );

  sl.registerFactory<InviteBloc>(
    () => InviteBloc(createInvite: sl<CreateInviteUseCase>()),
  );
  sl.registerFactory<AcceptInviteBloc>(
    () => AcceptInviteBloc(
      getInviteByToken: sl<GetInviteByTokenUseCase>(),
      acceptInvite: sl<AcceptInviteUseCase>(),
    ),
  );

  // AI Chat
  sl.registerSingleton<AgentChatRepository>(
    HookraAgentChatRepository(
      supabase: supabase,
      supabaseUrl: dotenv.get('SUPABASE_URL'),
    ),
  );
  sl.registerFactory<SendMessageUseCase>(
    () => SendMessageUseCase(sl<AgentChatRepository>()),
  );

   // Preview
   sl.registerSingleton<ContentRepository>(
     SupabaseContentRepository(supabase: supabase),
   );
   sl.registerFactory<GetLatestContentUseCase>(
     () => GetLatestContentUseCase(sl<ContentRepository>()),
   );
   sl.registerFactory<UpdateContentStatusUseCase>(
     () => UpdateContentStatusUseCase(sl<ContentRepository>()),
   );

   // Preview BLoC
   sl.registerFactory<PreviewBloc>(
     () => PreviewBloc(
       getLatestContent: sl<GetLatestContentUseCase>(),
       updateContentStatus: sl<UpdateContentStatusUseCase>(),
     ),
   );

   sl.registerSingleton<CommentRepository>(
     SupabaseCommentRepository(supabase: supabase),
   );
   sl.registerFactory<WatchCommentsUseCase>(
     () => WatchCommentsUseCase(sl<CommentRepository>()),
   );
   sl.registerFactory<AddCommentUseCase>(
     () => AddCommentUseCase(sl<CommentRepository>()),
   );
   sl.registerFactory<EditCommentUseCase>(
     () => EditCommentUseCase(sl<CommentRepository>()),
   );
   sl.registerFactory<DeleteCommentUseCase>(
     () => DeleteCommentUseCase(sl<CommentRepository>()),
   );
   sl.registerFactory<GetTeamCommentsUseCase>(
     () => GetTeamCommentsUseCase(sl<CommentRepository>()),
   );
   sl.registerFactory<ResolveCommentUseCase>(
     () => ResolveCommentUseCase(sl<CommentRepository>()),
   );
   sl.registerFactory<HomeActivityCubit>(
     () => HomeActivityCubit(sl<GetTeamCommentsUseCase>()),
   );
}
