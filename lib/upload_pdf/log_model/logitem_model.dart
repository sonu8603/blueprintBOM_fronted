class LogItem {
  final String text;
  final bool isError;
  final bool isSuccess;

  LogItem(this.text, {this.isError = false, this.isSuccess = false});
}




// upload karte time ka state
class UploadExtractState {
  final bool isLoading;
  final List<LogItem> logs;

  UploadExtractState({
    this.isLoading = false,
    this.logs = const [],
  });

  UploadExtractState copyWith({
    bool? isLoading,
    List<LogItem>? logs,
  }) {
    return UploadExtractState(
      isLoading: isLoading ?? this.isLoading,
      logs: logs ?? this.logs,
    );
  }
}