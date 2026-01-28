class ProfileState {
  final String name;
  final String email;
  final int totalSessions;
  final int usedSessions;
  final bool isLoading;
  final String? error;

  ProfileState({
    required this.name,
    required this.email,
    required this.totalSessions,
    required this.usedSessions,
    this.isLoading = false,
    this.error,
  });

  int get remainingSessions => totalSessions - usedSessions;
  double get progress => totalSessions == 0 ? 0 : usedSessions / totalSessions;

  ProfileState copyWith({
    String? name,
    String? email,
    int? totalSessions,
    int? usedSessions,
    bool? isLoading,
    String? error,
  }) {
    return ProfileState(
      name: name ?? this.name,
      email: email ?? this.email,
      totalSessions: totalSessions ?? this.totalSessions,
      usedSessions: usedSessions ?? this.usedSessions,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}
