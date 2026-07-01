import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/api_order.dart';
import '../models/api_product.dart';
import '../models/api_result.dart';
import '../models/api_shop.dart';
import '../models/influencer_ad.dart';
import '../models/notification_item.dart';

class ApiService {
  static const Duration _timeout = Duration(seconds: 8);

  static List<String> _getBaseUrls() {
    final port = ApiConfig.port;
    final lan = ApiConfig.lanHost;
    final urls = <String>[];

    // Custom host via: flutter run --dart-define=API_HOST=192.168.x.x
    const defineHost = String.fromEnvironment('API_HOST');
    if (defineHost.isNotEmpty) {
      urls.add('http://$defineHost:$port/api');
    }

    urls.add('http://$lan:$port/api');

    if (kIsWeb) {
      urls.add('http://127.0.0.1:$port/api');
    } else if (Platform.isAndroid) {
      urls.add(
        'http://10.0.2.2:$port/api',
      ); // Android emulator to computer localhost
      urls.add('http://10.0.3.2:$port/api'); // Genymotion
    } else {
      urls.add('http://127.0.0.1:$port/api');
    }

    // Remove duplicates while preserving order.
    return urls.toSet().toList();
  }

  Future<http.Response> _post(String path, Map<String, dynamic> body) async {
    for (final baseUrl in _getBaseUrls()) {
      final uri = Uri.parse('$baseUrl$path');
      if (kDebugMode) {
        debugPrint('Trying API host: $uri');
      }
      try {
        final response = await http
            .post(
              uri,
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode(body),
            )
            .timeout(_timeout);

        if (kDebugMode) {
          debugPrint('POST $uri -> ${response.statusCode}');
        }

        if (response.statusCode < 500) {
          return response;
        }

        debugPrint('Server error on $uri, trying next host...');
      } on SocketException {
        debugPrint('SocketException while connecting to $uri');
        continue;
      } on TimeoutException {
        debugPrint('Timeout while connecting to $uri');
        continue;
      } catch (e) {
        debugPrint('Unexpected error while connecting to $uri: $e');
        continue;
      }
    }

    throw SocketException(
      'Unable to reach API. Tried: ${_getBaseUrls().join(', ')}. '
      'Start Django with: python manage.py runserver 0.0.0.0:${ApiConfig.port}',
    );
  }

  Future<http.Response> _request(
    String method,
    String path,
    String accessToken, {
    Map<String, dynamic>? body,
  }) async {
    for (final baseUrl in _getBaseUrls()) {
      final uri = Uri.parse('$baseUrl$path');
      try {
        late http.Response response;
        final headers = {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        };
        switch (method) {
          case 'GET':
            response = await http.get(uri, headers: headers).timeout(_timeout);
            break;
          case 'POST':
            response = await http
                .post(uri, headers: headers, body: jsonEncode(body ?? {}))
                .timeout(_timeout);
            break;
          case 'PATCH':
            response = await http
                .patch(uri, headers: headers, body: jsonEncode(body ?? {}))
                .timeout(_timeout);
            break;
          case 'DELETE':
            response = await http
                .delete(uri, headers: headers)
                .timeout(_timeout);
            break;
          default:
            throw UnsupportedError(method);
        }
        if (response.statusCode < 500) return response;
      } on SocketException {
        continue;
      } on TimeoutException {
        continue;
      }
    }
    throw SocketException('Unable to reach API');
  }

  Future<http.Response> _get(String path, String accessToken) =>
      _request('GET', path, accessToken);

  Future<http.Response> _postAuth(
    String path,
    String accessToken,
    Map<String, dynamic> body,
  ) => _request('POST', path, accessToken, body: body);

  Future<http.Response> _patchAuth(
    String path,
    String accessToken,
    Map<String, dynamic> body,
  ) => _request('PATCH', path, accessToken, body: body);

  /// Multipart request — sends text fields + optional files without authentication
  Future<http.Response> _multipartNoAuth(
    String method,
    String path, {
    required Map<String, String> fields,
    Map<String, String>? filePaths,
  }) async {
    for (final baseUrl in _getBaseUrls()) {
      final uri = Uri.parse('$baseUrl$path');
      try {
        final request = http.MultipartRequest(method, uri)
          ..fields.addAll(fields);
        if (filePaths != null) {
          for (final entry in filePaths.entries) {
            request.files.add(
              await http.MultipartFile.fromPath(entry.key, entry.value),
            );
          }
        }
        final streamed = await request.send().timeout(_timeout);
        final response = await http.Response.fromStream(streamed);
        if (response.statusCode < 500) return response;
      } on SocketException {
        continue;
      } on TimeoutException {
        continue;
      }
    }
    throw SocketException('Unable to reach API');
  }

  /// Multipart request — sends text fields + optional files
  /// [filePath] + [fieldName]: single primary file (legacy param)
  /// [extraFilePaths]: map of fieldName → filePath for additional files
  Future<http.Response> _multipart(
    String method,
    String path,
    String accessToken, {
    required Map<String, String> fields,
    String? filePath,
    String fieldName = 'image',
    Map<String, String>? extraFilePaths,
  }) async {
    for (final baseUrl in _getBaseUrls()) {
      final uri = Uri.parse('$baseUrl$path');
      try {
        final request = http.MultipartRequest(method, uri)
          ..headers['Authorization'] = 'Bearer $accessToken'
          ..fields.addAll(fields);
        if (filePath != null) {
          request.files.add(
            await http.MultipartFile.fromPath(fieldName, filePath),
          );
        }
        if (extraFilePaths != null) {
          for (final e in extraFilePaths.entries) {
            request.files.add(
              await http.MultipartFile.fromPath(e.key, e.value),
            );
          }
        }
        final streamed = await request.send().timeout(_timeout);
        final response = await http.Response.fromStream(streamed);
        if (response.statusCode < 500) return response;
      } on SocketException {
        continue;
      } on TimeoutException {
        continue;
      }
    }
    throw SocketException('Unable to reach API');
  }

  List<dynamic> _decodeList(String body) {
    final data = jsonDecode(body);
    if (data is List) return data;
    if (data is Map && data['results'] is List) return data['results'] as List;
    return [];
  }

  Future<ApiResult<List<ApiProduct>>> fetchProducts(String token) async {
    try {
      final response = await _get('/products/', token);
      if (response.statusCode == 200) {
        final list = _decodeList(
          response.body,
        ).map((e) => ApiProduct.fromJson(e as Map<String, dynamic>)).toList();
        return ApiResult.success(list);
      }
      return ApiResult.failure('${response.statusCode}: ${response.body}');
    } catch (e) {
      return ApiResult.failure(e.toString());
    }
  }

  Future<ApiResult<List<ApiProduct>>> searchProductsByImage(
    String token,
    String imagePath,
  ) async {
    try {
      final response = await _multipart(
        'POST',
        '/products/search_by_image/',
        token,
        fields: {},
        filePath: imagePath,
        fieldName: 'image',
      );
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        final results = (body['results'] as List? ?? [])
            .map((e) => ApiProduct.fromJson(e as Map<String, dynamic>))
            .toList();
        return ApiResult.success(results);
      }
      return ApiResult.failure('${response.statusCode}: ${response.body}');
    } catch (e) {
      return ApiResult.failure(e.toString());
    }
  }

  Future<ApiResult<List<ApiShop>>> fetchShops(String token) async {
    try {
      final response = await _get('/shops/', token);
      if (response.statusCode == 200) {
        final list = _decodeList(
          response.body,
        ).map((e) => ApiShop.fromJson(e as Map<String, dynamic>)).toList();
        return ApiResult.success(list);
      }
      return ApiResult.failure('${response.statusCode}: ${response.body}');
    } catch (e) {
      return ApiResult.failure(e.toString());
    }
  }

  Future<ApiResult<List<InfluencerAd>>> fetchInfluencerAds(
    String token, {
    int? influencerId,
  }) async {
    for (final baseUrl in _getBaseUrls()) {
      try {
        final uri = Uri.parse('$baseUrl/influencer-ads/').replace(
          queryParameters: influencerId != null
              ? {'influencer_id': '$influencerId'}
              : null,
        );
        final response = await http
            .get(
              uri,
              headers: {
                'Authorization': 'Bearer $token',
                'Content-Type': 'application/json',
              },
            )
            .timeout(_timeout);
        debugPrint(
          'fetchInfluencerAds → $uri → ${response.statusCode}: ${response.body}',
        );
        if (response.statusCode == 200) {
          final list = _decodeList(response.body)
              .map((e) => InfluencerAd.fromJson(e as Map<String, dynamic>))
              .toList();
          return ApiResult.success(list);
        }
        return ApiResult.failure('${response.statusCode}: ${response.body}');
      } on SocketException {
        continue;
      } on TimeoutException {
        continue;
      } catch (e) {
        return ApiResult.failure(e.toString());
      }
    }
    return ApiResult.failure('Unable to reach API');
  }

  Future<ApiResult<InfluencerAd>> createInfluencerAd(
    String token, {
    required String description,
    required int price,
    String? imagePath,
  }) async {
    try {
      final response = await _multipart(
        'POST',
        '/influencer-ads/',
        token,
        fields: {'description': description, 'price': price.toString()},
        filePath: imagePath,
        fieldName: 'image',
      );
      if (response.statusCode == 201) {
        return ApiResult.success(
          InfluencerAd.fromJson(
            jsonDecode(response.body) as Map<String, dynamic>,
          ),
        );
      }
      return ApiResult.failure('${response.statusCode}: ${response.body}');
    } catch (e) {
      return ApiResult.failure(e.toString());
    }
  }

  Future<ApiResult<void>> deleteInfluencerAd(String token, int id) async {
    try {
      final response = await _request('DELETE', '/influencer-ads/$id/', token);
      if (response.statusCode == 204 || response.statusCode == 200) {
        return ApiResult.success(null);
      }
      return ApiResult.failure('${response.statusCode}: ${response.body}');
    } catch (e) {
      return ApiResult.failure(e.toString());
    }
  }

  Future<ApiResult<List<NotificationItem>>> fetchNotifications(String token) async {
    try {
      final response = await _get('/notifications/', token);
      if (response.statusCode == 200) {
        final list = _decodeList(response.body)
            .map((e) => NotificationItem.fromJson(e as Map<String, dynamic>))
            .toList();
        return ApiResult.success(list);
      }
      return ApiResult.failure('${response.statusCode}: ${response.body}');
    } catch (e) {
      return ApiResult.failure(e.toString());
    }
  }

  Future<int> fetchUnreadNotifCount(String token) async {
    try {
      final response = await _get('/notifications/unread_count/', token);
      if (response.statusCode == 200) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        return (body['count'] as int?) ?? 0;
      }
    } catch (_) {}
    return 0;
  }

  Future<void> markAllNotificationsRead(String token) async {
    try {
      await _postAuth('/notifications/mark_all_read/', token, {});
    } catch (_) {}
  }

  Future<ApiResult<void>> purchaseAd(String token, int adId) async {
    try {
      final response = await _postAuth('/ad-purchases/', token, {'ad': adId});
      if (response.statusCode == 201) return ApiResult.success(null);
      return ApiResult.failure('${response.statusCode}: ${response.body}');
    } catch (e) {
      return ApiResult.failure(e.toString());
    }
  }

  Future<ApiResult<ApiProduct>> createProduct(
    String token, {
    required String name,
    required String description,
    required int priceMru,
    int stock = 10,
    String? imagePath,
  }) async {
    try {
      final response = await _multipart(
        'POST',
        '/products/',
        token,
        fields: {
          'name': name,
          'description': description,
          'price': priceMru.toString(),
          'stock_quantity': stock.toString(),
        },
        filePath: imagePath,
        fieldName: 'image',
      );
      if (response.statusCode == 201) {
        return ApiResult.success(
          ApiProduct.fromJson(
            jsonDecode(response.body) as Map<String, dynamic>,
          ),
        );
      }
      return ApiResult.failure('${response.statusCode}: ${response.body}');
    } catch (e) {
      return ApiResult.failure(e.toString());
    }
  }

  Future<ApiResult<void>> deleteProduct(String token, int id) async {
    try {
      final response = await _request('DELETE', '/products/$id/', token);
      if (response.statusCode == 204 || response.statusCode == 200) {
        return const ApiResult.success(null);
      }
      return ApiResult.failure('${response.statusCode}: ${response.body}');
    } catch (e) {
      return ApiResult.failure(e.toString());
    }
  }

  Future<ApiResult<List<ApiOrder>>> fetchOrders(String token) async {
    try {
      final response = await _get('/orders/', token);
      if (response.statusCode == 200) {
        final list = _decodeList(
          response.body,
        ).map((e) => ApiOrder.fromJson(e as Map<String, dynamic>)).toList();
        return ApiResult.success(list);
      }
      return ApiResult.failure('${response.statusCode}: ${response.body}');
    } catch (e) {
      return ApiResult.failure(e.toString());
    }
  }

  Future<ApiResult<ApiOrder>> createOrderWithItems(
    String token,
    List<Map<String, dynamic>> items,
  ) async {
    try {
      final response = await _postAuth('/orders/create_with_items/', token, {
        'items': items,
      });
      if (response.statusCode == 201) {
        return ApiResult.success(
          ApiOrder.fromJson(jsonDecode(response.body) as Map<String, dynamic>),
        );
      }
      return ApiResult.failure('${response.statusCode}: ${response.body}');
    } catch (e) {
      return ApiResult.failure(e.toString());
    }
  }

  Future<ApiResult<ApiOrder>> confirmBankilyOrder(
    String token,
    int orderId,
  ) async {
    try {
      final response = await _postAuth(
        '/orders/$orderId/confirm_bankily/',
        token,
        {},
      );
      if (response.statusCode == 200) {
        return ApiResult.success(
          ApiOrder.fromJson(jsonDecode(response.body) as Map<String, dynamic>),
        );
      }
      return ApiResult.failure('${response.statusCode}: ${response.body}');
    } catch (e) {
      return ApiResult.failure(e.toString());
    }
  }

  Future<ApiResult<ApiOrder>> confirmDelivery(
    String token,
    int orderId,
    int rating,
  ) async {
    try {
      final response = await _postAuth(
        '/orders/$orderId/confirm_delivery/',
        token,
        {'driver_rating': rating},
      );
      if (response.statusCode == 200) {
        return ApiResult.success(
          ApiOrder.fromJson(jsonDecode(response.body) as Map<String, dynamic>),
        );
      }
      return ApiResult.failure('${response.statusCode}: ${response.body}');
    } catch (e) {
      return ApiResult.failure(e.toString());
    }
  }

  Future<ApiResult<List<Map<String, dynamic>>>> fetchDigitalServices(
    String token,
  ) async {
    try {
      final response = await _get('/services/', token);
      if (response.statusCode == 200) {
        final list = _decodeList(
          response.body,
        ).map((e) => e as Map<String, dynamic>).toList();
        return ApiResult.success(list);
      }
      return ApiResult.failure('${response.statusCode}: ${response.body}');
    } catch (e) {
      return ApiResult.failure(e.toString());
    }
  }

  Future<ApiResult<ApiOrder>> acceptDelivery(String token, int orderId) async {
    try {
      final response = await _postAuth(
        '/orders/$orderId/accept_delivery/',
        token,
        {},
      );
      if (response.statusCode == 200) {
        return ApiResult.success(
          ApiOrder.fromJson(jsonDecode(response.body) as Map<String, dynamic>),
        );
      }
      return ApiResult.failure('${response.statusCode}: ${response.body}');
    } catch (e) {
      return ApiResult.failure(e.toString());
    }
  }

  Future<ApiResult<ApiOrder>> releaseDelivery(String token, int orderId) async {
    try {
      final response = await _postAuth(
        '/orders/$orderId/release_delivery/',
        token,
        {},
      );
      if (response.statusCode == 200) {
        return ApiResult.success(
          ApiOrder.fromJson(jsonDecode(response.body) as Map<String, dynamic>),
        );
      }
      return ApiResult.failure('${response.statusCode}: ${response.body}');
    } catch (e) {
      return ApiResult.failure(e.toString());
    }
  }

  Future<ApiResult<ApiOrder>> updateOrderStatus(
    String token,
    int orderId,
    String status,
  ) async {
    try {
      final response = await _patchAuth(
        '/orders/$orderId/update_status/',
        token,
        {'status': status},
      );
      if (response.statusCode == 200) {
        return ApiResult.success(
          ApiOrder.fromJson(jsonDecode(response.body) as Map<String, dynamic>),
        );
      }
      return ApiResult.failure('${response.statusCode}: ${response.body}');
    } catch (e) {
      return ApiResult.failure(e.toString());
    }
  }

  Future<Map<String, dynamic>> login(String phone, String code) async {
    try {
      final response = await _post('/custom-login/', {
        'phone': phone,
        'code': code,
      });

      if (response.statusCode == 200) {
        debugPrint('✓ Connexion réussie');
        return {'success': true, 'body': jsonDecode(response.body)};
      }

      _logError('Login', response);
      final message = 'HTTP ${response.statusCode}: ${response.body}';
      debugPrint('Échec de connexion - $message');
      return {'success': false, 'error': message};
    } on SocketException catch (e) {
      final message = 'SocketException: ${e.message}';
      debugPrint('❌ Erreur: $message');
      return {'success': false, 'error': message};
    } on TimeoutException catch (e) {
      final message = 'TimeoutException: ${e.message}';
      debugPrint('❌ Échec de connexion: $message');
      return {'success': false, 'error': message};
    } catch (e) {
      final message = e.toString();
      debugPrint('❌ Échec de connexion: $message');
      return {'success': false, 'error': message};
    }
  }

  Future<Map<String, dynamic>> getCurrentUser(String accessToken) async {
    try {
      final response = await _get('/auth/users/me/', accessToken);

      if (response.statusCode == 200) {
        debugPrint('User data loaded successfully');
        return {'success': true, 'body': jsonDecode(response.body)};
      }

      _logError('GetCurrentUser', response);
      final message = 'HTTP ${response.statusCode}: ${response.body}';
      return {'success': false, 'error': message};
    } on SocketException catch (e) {
      final message = 'SocketException: ${e.message}';
      return {'success': false, 'error': message};
    } on TimeoutException catch (e) {
      final message = 'TimeoutException: ${e.message}';
      return {'success': false, 'error': message};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> updateCurrentUser(
    String accessToken,
    Map<String, dynamic> updates,
  ) async {
    try {
      final response = await _patchAuth(
        '/auth/users/me/',
        accessToken,
        updates,
      );

      if (response.statusCode == 200) {
        debugPrint('✓ Profil utilisateur mis à jour');
        return {'success': true, 'body': jsonDecode(response.body)};
      }

      _logError('UpdateCurrentUser', response);
      final message = 'HTTP ${response.statusCode}: ${response.body}';
      return {'success': false, 'error': message};
    } on SocketException catch (e) {
      final message = 'SocketException: ${e.message}';
      return {'success': false, 'error': message};
    } on TimeoutException catch (e) {
      final message = 'TimeoutException: ${e.message}';
      return {'success': false, 'error': message};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> updateCurrentUserWithImage(
    String accessToken,
    Map<String, dynamic> updates, {
    String? profileImagePath,
    String? vehicleImagePath,
    String? nationalIdPath,
    String? drivingLicensePath,
    String? storeLogoPath,
  }) async {
    try {
      final fields = updates.map((k, v) => MapEntry(k, v?.toString() ?? ''));
      final extra = <String, String>{
        if (vehicleImagePath != null) 'vehicle_image': vehicleImagePath,
        if (nationalIdPath != null) 'national_id': nationalIdPath,
        if (drivingLicensePath != null) 'driving_license': drivingLicensePath,
        if (storeLogoPath != null) 'store_logo': storeLogoPath,
      };
      final response = await _multipart(
        'PATCH',
        '/auth/users/me/',
        accessToken,
        fields: fields,
        filePath: profileImagePath,
        fieldName: 'profile_image',
        extraFilePaths: extra.isEmpty ? null : extra,
      );
      if (response.statusCode == 200) {
        return {'success': true, 'body': jsonDecode(response.body)};
      }
      return {
        'success': false,
        'error': 'HTTP ${response.statusCode}: ${response.body}',
      };
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> changePassword(
    String accessToken,
    String currentPassword,
    String newPassword,
  ) async {
    try {
      final response =
          await _postAuth('/auth/users/set_password/', accessToken, {
            'current_password': currentPassword,
            'new_password': newPassword,
            're_new_password': newPassword,
          });

      if (response.statusCode == 204 || response.statusCode == 200) {
        debugPrint('✓ Mot de passe mis à jour');
        return {'success': true};
      }

      _logError('ChangePassword', response);
      final message = 'HTTP ${response.statusCode}: ${response.body}';
      return {'success': false, 'error': message};
    } on SocketException catch (e) {
      final message = 'SocketException: ${e.message}';
      return {'success': false, 'error': message};
    } on TimeoutException catch (e) {
      final message = 'TimeoutException: ${e.message}';
      return {'success': false, 'error': message};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> register({
    required String username,
    required String email,
    required String password,
    required String role,
    Map<String, dynamic>? extraFields,
    Map<String, String>? filePaths,
  }) async {
    try {
      final body = {
        'username': username,
        'full_name': username,
        'email': email,
        'password': password,
        'role': role,
        if (extraFields != null) ...extraFields,
      };

      final response = filePaths != null && filePaths.isNotEmpty
          ? await _multipartNoAuth(
              'POST',
              '/register/',
              fields: body.map((key, value) => MapEntry(key, value.toString())),
              filePaths: filePaths,
            )
          : await _post('/register/', body);

      if (response.statusCode == 201) {
        debugPrint('Registration completed: ${response.body}');
        return {'success': true, 'body': jsonDecode(response.body)};
      }

      _logError('Register', response);
      final message = 'HTTP ${response.statusCode}: ${response.body}';
      debugPrint('Registration failed - $message');
      return {'success': false, 'error': message};
    } on SocketException catch (e) {
      final message = 'SocketException: ${e.message}';
      debugPrint('Connection error: $message');
      return {'success': false, 'error': message};
    } on TimeoutException catch (e) {
      final message = 'TimeoutException: ${e.message}';
      debugPrint('Unexpected registration error: $message');
      return {'success': false, 'error': message};
    } catch (e) {
      final message = e.toString();
      debugPrint('Unexpected registration error: $message');
      return {'success': false, 'error': message};
    }
  }

  // ── Users list (for vendor/influencer discovery) ──
  Future<ApiResult<List<Map<String, dynamic>>>> fetchUsers(String token) async {
    try {
      final response = await _get('/users/', token);
      if (response.statusCode == 200) {
        final list = _decodeList(
          response.body,
        ).map((e) => e as Map<String, dynamic>).toList();
        return ApiResult.success(list);
      }
      return ApiResult.failure('${response.statusCode}: ${response.body}');
    } catch (e) {
      return ApiResult.failure(e.toString());
    }
  }

  // ── Update product (PATCH) ──
  Future<ApiResult<ApiProduct>> updateProduct(
    String token,
    int productId,
    Map<String, dynamic> data, {
    String? imagePath,
  }) async {
    try {
      // Convert all values to strings for multipart
      final fields = data.map((k, v) => MapEntry(k, v.toString()));
      final response = await _multipart(
        'PATCH',
        '/products/$productId/update_product/',
        token,
        fields: fields,
        filePath: imagePath,
        fieldName: 'image',
      );
      if (response.statusCode == 200) {
        return ApiResult.success(
          ApiProduct.fromJson(
            jsonDecode(response.body) as Map<String, dynamic>,
          ),
        );
      }
      return ApiResult.failure('${response.statusCode}: ${response.body}');
    } catch (e) {
      return ApiResult.failure(e.toString());
    }
  }

  // ── Marketing Requests ──
  Future<ApiResult<List<Map<String, dynamic>>>> fetchMarketingRequests(
    String token,
  ) async {
    try {
      final response = await _get('/marketing-requests/', token);
      if (response.statusCode == 200) {
        final list = _decodeList(
          response.body,
        ).map((e) => e as Map<String, dynamic>).toList();
        return ApiResult.success(list);
      }
      return ApiResult.failure('${response.statusCode}: ${response.body}');
    } catch (e) {
      return ApiResult.failure(e.toString());
    }
  }

  Future<ApiResult<Map<String, dynamic>>> createMarketingRequest(
    String token,
    int productId,
  ) async {
    try {
      final response = await _postAuth('/marketing-requests/', token, {
        'product': productId,
      });
      if (response.statusCode == 201) {
        return ApiResult.success(
          jsonDecode(response.body) as Map<String, dynamic>,
        );
      }
      return ApiResult.failure('${response.statusCode}: ${response.body}');
    } catch (e) {
      return ApiResult.failure(e.toString());
    }
  }

  Future<ApiResult<Map<String, dynamic>>> acceptMarketingRequest(
    String token,
    int requestId,
  ) async {
    try {
      final response = await _postAuth(
        '/marketing-requests/$requestId/accept/',
        token,
        {},
      );
      if (response.statusCode == 200) {
        return ApiResult.success(
          jsonDecode(response.body) as Map<String, dynamic>,
        );
      }
      return ApiResult.failure('${response.statusCode}: ${response.body}');
    } catch (e) {
      return ApiResult.failure(e.toString());
    }
  }

  Future<ApiResult<Map<String, dynamic>>> rejectMarketingRequest(
    String token,
    int requestId,
  ) async {
    try {
      final response = await _postAuth(
        '/marketing-requests/$requestId/reject/',
        token,
        {},
      );
      if (response.statusCode == 200) {
        return ApiResult.success(
          jsonDecode(response.body) as Map<String, dynamic>,
        );
      }
      return ApiResult.failure('${response.statusCode}: ${response.body}');
    } catch (e) {
      return ApiResult.failure(e.toString());
    }
  }

  Future<ApiResult<List<Map<String, dynamic>>>> fetchAcceptedProducts(
    String token,
  ) async {
    try {
      final response = await _get(
        '/marketing-requests/accepted_products/',
        token,
      );
      if (response.statusCode == 200) {
        final list = _decodeList(
          response.body,
        ).map((e) => e as Map<String, dynamic>).toList();
        return ApiResult.success(list);
      }
      return ApiResult.failure('${response.statusCode}: ${response.body}');
    } catch (e) {
      return ApiResult.failure(e.toString());
    }
  }

  Future<ApiResult<List<Map<String, dynamic>>>> fetchInfluencerProducts(
    String token,
    int influencerId,
  ) async {
    try {
      final response = await _get(
        '/marketing-requests/influencer_products/?influencer_id=$influencerId',
        token,
      );
      if (response.statusCode == 200) {
        final list = _decodeList(
          response.body,
        ).map((e) => e as Map<String, dynamic>).toList();
        return ApiResult.success(list);
      }
      return ApiResult.failure('${response.statusCode}: ${response.body}');
    } catch (e) {
      return ApiResult.failure(e.toString());
    }
  }

  // ── Admin-specific endpoints ──────────────────────────────────

  Future<Map<String, dynamic>> fetchDashboardStats(String token) async {
    try {
      final response = await _get('/users/dashboard_stats/', token);
      if (response.statusCode == 200) {
        return {'success': true, 'body': jsonDecode(response.body)};
      }
      return {'success': false, 'error': 'HTTP ${response.statusCode}'};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<ApiResult<List<Map<String, dynamic>>>> fetchOrdersAdmin(
    String token,
  ) async {
    try {
      final response = await _get('/orders/', token);
      if (response.statusCode == 200) {
        return ApiResult.success(
          _decodeList(response.body).cast<Map<String, dynamic>>(),
        );
      }
      return ApiResult.failure('${response.statusCode}: ${response.body}');
    } catch (e) {
      return ApiResult.failure(e.toString());
    }
  }

  Future<ApiResult<List<Map<String, dynamic>>>> fetchFinance(
    String token,
  ) async {
    try {
      final response = await _get('/finance/', token);
      if (response.statusCode == 200) {
        return ApiResult.success(
          _decodeList(response.body).cast<Map<String, dynamic>>(),
        );
      }
      return ApiResult.failure('${response.statusCode}: ${response.body}');
    } catch (e) {
      return ApiResult.failure(e.toString());
    }
  }

  Future<Map<String, dynamic>> fetchUserById(String token, int userId) async {
    try {
      final response = await _get('/users/$userId/', token);
      if (response.statusCode == 200) {
        return {'success': true, 'body': jsonDecode(response.body)};
      }
      return {'success': false, 'error': 'HTTP ${response.statusCode}'};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> approveUser(String token, int userId) async {
    try {
      final response = await _postAuth('/users/$userId/approve/', token, {});
      if (response.statusCode == 200 || response.statusCode == 201) {
        return {'success': true};
      }
      return {
        'success': false,
        'error': 'HTTP ${response.statusCode}: ${response.body}',
      };
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> rejectUser(String token, int userId) async {
    try {
      final response = await _postAuth('/users/$userId/reject/', token, {});
      if (response.statusCode == 200 || response.statusCode == 204) {
        return {'success': true};
      }
      return {
        'success': false,
        'error': 'HTTP ${response.statusCode}: ${response.body}',
      };
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<ApiResult<List<Map<String, dynamic>>>> fetchProductsAdmin(
    String token,
  ) async {
    try {
      final response = await _get('/products/', token);
      if (response.statusCode == 200) {
        return ApiResult.success(
          _decodeList(response.body).cast<Map<String, dynamic>>(),
        );
      }
      return ApiResult.failure('${response.statusCode}: ${response.body}');
    } catch (e) {
      return ApiResult.failure(e.toString());
    }
  }

  Future<Map<String, dynamic>> approveProductAdmin(
    String token,
    int productId,
  ) async {
    try {
      final response = await _patchAuth('/products/$productId/', token, {
        'is_approved': true,
      });
      if (response.statusCode == 200) {
        return {'success': true, 'body': jsonDecode(response.body)};
      }
      return {
        'success': false,
        'error': 'HTTP ${response.statusCode}: ${response.body}',
      };
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> deleteProductAdmin(
    String token,
    int productId,
  ) async {
    try {
      final response = await _request('DELETE', '/products/$productId/', token);
      if (response.statusCode == 204 || response.statusCode == 200) {
        return {'success': true};
      }
      return {'success': false, 'error': 'HTTP ${response.statusCode}'};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<ApiResult<List<Map<String, dynamic>>>> fetchServices(
    String token,
  ) async {
    try {
      final response = await _get('/services/', token);
      if (response.statusCode == 200) {
        return ApiResult.success(
          _decodeList(response.body).cast<Map<String, dynamic>>(),
        );
      }
      return ApiResult.failure('${response.statusCode}: ${response.body}');
    } catch (e) {
      return ApiResult.failure(e.toString());
    }
  }

  Future<ApiResult<List<Map<String, dynamic>>>> fetchTopupRequests(
    String token,
  ) async {
    try {
      final response = await _get('/services/topup_requests/', token);
      if (response.statusCode == 200) {
        return ApiResult.success(
          _decodeList(response.body).cast<Map<String, dynamic>>(),
        );
      }
      return ApiResult.failure('${response.statusCode}: ${response.body}');
    } catch (e) {
      return ApiResult.failure(e.toString());
    }
  }

  Future<Map<String, dynamic>> completeTopupOrder(
    String token,
    int orderId,
  ) async {
    try {
      final response = await _postAuth(
        '/orders/$orderId/complete_topup/',
        token,
        {},
      );
      if (response.statusCode == 200) return {'success': true};
      return {
        'success': false,
        'error': 'HTTP ${response.statusCode}: ${response.body}',
      };
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> createServiceAdmin(
    String token,
    Map<String, String> fields, {
    String? imagePath,
  }) async {
    try {
      final response = await _multipart(
        'POST',
        '/services/',
        token,
        fields: fields,
        filePath: imagePath,
        fieldName: 'image',
      );
      if (response.statusCode == 201) {
        return {'success': true, 'body': jsonDecode(response.body)};
      }
      return {
        'success': false,
        'error': 'HTTP ${response.statusCode}: ${response.body}',
      };
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> updateServiceAdmin(
    String token,
    int id,
    Map<String, String> fields, {
    String? imagePath,
  }) async {
    try {
      final response = await _multipart(
        'PATCH',
        '/services/$id/',
        token,
        fields: fields,
        filePath: imagePath,
        fieldName: 'image',
      );
      if (response.statusCode == 200) {
        return {'success': true, 'body': jsonDecode(response.body)};
      }
      return {
        'success': false,
        'error': 'HTTP ${response.statusCode}: ${response.body}',
      };
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> deleteServiceAdmin(String token, int id) async {
    try {
      final response = await _request('DELETE', '/services/$id/', token);
      if (response.statusCode == 204 || response.statusCode == 200) {
        return {'success': true};
      }
      return {'success': false, 'error': 'HTTP ${response.statusCode}'};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> updateOrderStatusAdmin(
    String token,
    int orderId,
    String status,
  ) async {
    try {
      final response = await _postAuth(
        '/orders/$orderId/update_status/',
        token,
        {'status': status},
      );
      if (response.statusCode == 200) return {'success': true};
      return {
        'success': false,
        'error': 'HTTP ${response.statusCode}: ${response.body}',
      };
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> confirmBankilyAdmin(
    String token,
    int orderId,
  ) async {
    try {
      final response = await _postAuth(
        '/orders/$orderId/confirm_bankily/',
        token,
        {},
      );
      if (response.statusCode == 200) return {'success': true};
      return {
        'success': false,
        'error': 'HTTP ${response.statusCode}: ${response.body}',
      };
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<ApiResult<List<Map<String, dynamic>>>> fetchShopsAdmin(
    String token,
  ) async {
    try {
      final response = await _get('/shops/', token);
      if (response.statusCode == 200) {
        return ApiResult.success(
          _decodeList(response.body).cast<Map<String, dynamic>>(),
        );
      }
      return ApiResult.failure('${response.statusCode}: ${response.body}');
    } catch (e) {
      return ApiResult.failure(e.toString());
    }
  }

  Future<Map<String, dynamic>> deleteShopAdmin(String token, int shopId) async {
    try {
      final response = await _request('DELETE', '/shops/$shopId/', token);
      if (response.statusCode == 204 || response.statusCode == 200) {
        return {'success': true};
      }
      return {'success': false, 'error': 'HTTP ${response.statusCode}'};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  // Keep diagnostic details in debug logs only.
  void _logError(String action, http.Response response) {
    if (kDebugMode) {
      debugPrint("--- Error in $action ---");
      debugPrint("Status Code: ${response.statusCode}");
      debugPrint("Response Body: ${response.body}");
      debugPrint("-------------------------");
    }
  }
}
