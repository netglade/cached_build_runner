import 'dart:async';

/// An interface for a database service used to cache generated code.
abstract class DatabaseService {
  /// Initializes the database service.
  Future<void> init();

  /// Checks if the mapping is available for the given digests in bulk.
  FutureOr<Map<String, bool>> isMappingAvailableForBulk(
    Iterable<String> digests,
  );

  /// Checks if the mapping is available for the given digest.
  FutureOr<bool> isMappingAvailable(String digest);

  /// Gets the cached file path for the given digests in bulk.
  FutureOr<Map<String, String>> getCachedFilePathForBulk(
    Iterable<String> digests,
  );

  /// Gets the cached file path for the given digest.
  FutureOr<String> getCachedFilePath(String digest);

  /// Creates entries for the given cached file paths in bulk.
  Future<void> createEntryForBulk(Map<String, String> cachedFilePaths);

  /// Creates an entry for the given digest and cached file path.
  Future<void> createEntry(String digest, String cachedFilePath);

  /// Creates custom [entry] under [key].
  Future<void> createCustomEntry(String key, String entry);

  /// Gets entry by key.
  Future<String?> getEntryByKey(String key);

  /// Delete all records except [keysToKeep].
  Future<void> prune({required List<String> keysToKeep});

  /// Flushes the database service. Flushing to disk, or closing network connections
  /// could be done here.
  Future<void> flush();
}
