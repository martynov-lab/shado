import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../storage/token_storage.dart';
import 'api_client.dart';

/// Токены живут столько же, сколько приложение: access — в памяти этого
/// объекта, refresh — в защищённом хранилище платформы.
final tokenStorageProvider = Provider<TokenStorage>(
  (ref) => SecureTokenStorage(),
);

/// Один клиент на всё приложение: у него общий `Dio`, а значит и общий
/// интерсептор, который следит, чтобы refresh шёл в один поток.
final apiClientProvider = Provider<ApiClient>(
  (ref) => ApiClient(tokens: ref.watch(tokenStorageProvider)),
);
