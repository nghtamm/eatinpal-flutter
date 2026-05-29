import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:eatinpal/app/router/route_names.dart';
import 'package:eatinpal/core/helpers/jwt.dart';
import 'package:eatinpal/core/local/local_storage.dart';
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

class DeepLinkService {
  final GlobalKey<NavigatorState> _navigatorKey;
  final AppLinks _applinks;
  final LocalStorage _storage;
  StreamSubscription<Uri>? _sub;

  DeepLinkService(this._navigatorKey, this._applinks, this._storage);

  Future<void> init() async {
    _sub = _applinks.uriLinkStream.listen(_handle);
  }

  Future<void> dispose() async {
    await _sub?.cancel();
    _sub = null;
  }

  Future<void> _handle(Uri uri) async {
    if (!uri.path.endsWith('/auth/verify')) return;

    final token = uri.queryParameters['token'];
    if (token == null || token.isEmpty) return;

    final signed = await _storage.signed;
    if (signed) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = _navigatorKey.currentContext;
      if (ctx == null) return;
      if (isJWTExpired(token)) return;
      ctx.go(RoutePaths.VERIFICATION_SUCCESS, extra: token);
    });
  }
}
