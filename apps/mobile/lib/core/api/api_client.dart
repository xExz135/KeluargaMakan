// Seam for the generated Dart API client (packages/contracts, T-015).
//
// The app talks only to the KeluargaMakan API, never to an AI provider or the
// AI service (ARCHITECTURE 3). The generated client is used as generated and
// never hand-edited. When it exists:
//   1. add it as a path dependency from packages/contracts,
//   2. build it in [apiClientProvider] from [ApiEnvironment] (and auth
//      interceptors from T-027),
//   3. feature code reads repositories, which read the generated client; no
//      widget calls the API directly.
// Until then, reading [apiClientProvider] throws, so nothing can quietly run
// against a fake backend. Tests override it.

import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Where the API lives. Set per build with
/// `--dart-define=KM_API_BASE_URL=https://...`; no secrets here.
final class ApiEnvironment {
  const ApiEnvironment(this.baseUrl);

  factory ApiEnvironment.fromBuild() =>
      ApiEnvironment(Uri.parse(const String.fromEnvironment(_key)));

  static const _key = 'KM_API_BASE_URL';

  /// Empty when no base URL was provided at build time.
  final Uri baseUrl;

  bool get isConfigured => baseUrl.hasScheme && baseUrl.host.isNotEmpty;
}

/// Placeholder for the generated client's entry point.
abstract interface class ApiClient {
  Uri get baseUrl;
}

final apiEnvironmentProvider = Provider<ApiEnvironment>(
  (ref) => ApiEnvironment.fromBuild(),
);

final apiClientProvider = Provider<ApiClient>(
  (ref) => throw UnimplementedError(
    'The generated API client (T-015) is not wired in yet.',
  ),
);
