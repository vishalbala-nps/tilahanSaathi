import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Typed access to environment variables loaded from `.env` (see `.env.example`).
abstract final class Env {
  static String get apiUrl => dotenv.env['API_URL'] ?? '';
}
