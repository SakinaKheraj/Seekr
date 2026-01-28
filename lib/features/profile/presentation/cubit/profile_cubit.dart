import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:seekr/features/profile/data/profile_service.dart';
import 'profile_state.dart';

class ProfileCubit extends Cubit<ProfileState> {
  final ProfileService _profileService;

  ProfileCubit({required ProfileService profileService})
      : _profileService = profileService,
        super(
          ProfileState(
            name: '',
            email: '',
            totalSessions: 0,
            usedSessions: 0,
            isLoading: true,
          ),
        );

  Future<void> loadProfile() async {
    emit(state.copyWith(isLoading: true, error: null));
    try {
      final data = await _profileService.getStats();

      emit(
        state.copyWith(
          name: data['name'] as String? ?? '',
          email: data['email'] as String? ?? '',
          totalSessions: data['total_sessions'] as int? ?? 0,
          usedSessions: data['used_sessions'] as int? ?? 0,
          isLoading: false,
          error: null,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          isLoading: false,
          error: e.toString(),
        ),
      );
    }
  }
}