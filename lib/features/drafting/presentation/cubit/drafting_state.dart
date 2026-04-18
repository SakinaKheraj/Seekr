class DraftingState {
  final bool isLoading;
  final String? draftResult;
  final String? error;

  const DraftingState({
    this.isLoading = false,
    this.draftResult,
    this.error,
  });

  DraftingState copyWith({
    bool? isLoading,
    String? draftResult,
    String? error,
  }) {
    return DraftingState(
      isLoading: isLoading ?? this.isLoading,
      draftResult: draftResult ?? this.draftResult,
      error: error,
    );
  }
}
