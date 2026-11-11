/// Where data shown on screen came from.
sealed class DataSource {
  const DataSource();
}

/// Fresh from the API.
final class FromNetwork extends DataSource {
  const FromNetwork();
}

/// From the on-device cache, because the API could not be reached.
final class FromCache extends DataSource {
  const FromCache(this.savedAt);

  /// When the cached copy was last refreshed from the API.
  final DateTime savedAt;
}
