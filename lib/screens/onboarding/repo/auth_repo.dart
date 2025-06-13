import 'dart:convert';
import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart';
import 'package:http/http.dart' as http;
import 'package:zineapp2023/backend_properties.dart';
import 'package:zineapp2023/database/database.dart';
import 'package:zineapp2023/models/newUser.dart';
import 'package:zineapp2023/screens/chat/chat_screen/repo/chat_repo.dart';
import '/common/data_store.dart';
import '../../../models/user.dart';
Future<bool> isServerUp() async {
  try {
    // Try a simple GET request to your server
    final response = await http.get(
      BackendProperties.loginUri, // or any lightweight endpoint
      headers: BackendProperties.getHeaders(),
    ).timeout(Duration(seconds: 5));

    // Server is up if we get any response (even errors like 404)
    return response.statusCode < 500;
  } catch (e) {
    print("Server check failed: $e");
    return false;
  }
}
class AuthRepo {
  AppDb db;
  late DataStore store;

  AuthRepo({required this.store, required this.db});

  Future<bool> sendResetEmail(String email) async {
    Response res = await http.post(
        BackendProperties.resetUri
            .replace(queryParameters: {'email': email.toString()}),
        headers: BackendProperties.getHeaders());
    print("res:${res.statusCode}");
    if (res.statusCode == 200) {
      return true;
    } else {
      return false;
    }
  }

  Future<UserModel?> signInWithEmailAndPassword(
      {String? email, String? password, String? pushToken}) async {
    Response res;
    Map<String, dynamic> resBody = {};
    try {
      res = await http.post(BackendProperties.loginUri,
          body: jsonEncode(
              {"email": email, "password": password, "pushToken": pushToken}),
          headers: {
            "Content-Type": "application/json",
            ...BackendProperties.getHeaders()
          });
      resBody = jsonDecode(res.body);
      logger.i(resBody);
      if (kDebugMode) {
        print("Response Code ${resBody['failureReason']}");
      }

      String userToken = "";
      switch (res.statusCode) {
        case 200:
          if (!resBody.containsKey('jwt')) {
            throw AuthException(code: 'backend-not-responding');
          } else {
            userToken = (resBody['jwt'] as String);
            print("userToken:${userToken}");
            return getUserbyId(userToken);
          }
          break;

        default:
          print("${resBody['failureReason']}");
          throw AuthException(code: resBody['failureReason']);
      }
    } on SocketException {
      if (kDebugMode) print('no-connect');
      throw AuthException(code: 'no-connect');
    } catch (e) {
      print("Error in SignInWithEmailAndPassword: $e");
      throw AuthException(code: resBody['failureReason'] ?? 'unknown-error');
    }
  }

  Future<bool> isUserReg(String email) async {
    //FIXME : Implement This
    return true;
  }

  Future<UserModel> getUserbyId(String uid) async {
    try {
      Response res = await http.get(BackendProperties.userInfoUri, headers: {
        'Authorization': 'Bearer $uid',
        ...BackendProperties.getHeaders()
      });

      if (res.statusCode != 200 || res.body.isEmpty) throw Exception();
      print('User Body ${res.body}');
      Map<String, dynamic> user = jsonDecode(res.body);
      NewUserModel userData = NewUserModel.fromJson(user);
      await db.upsertUserDB(userData);

      UserModel userMod = UserModel(
          uid: uid,
          id: user['id'],
          email: user['email'],
          name: user['name'],
          dp: user['dpUrl'] ?? "1",
          type: user['type'],
          registered: user['registered']! ?? false,
          tasks: [],
          lastSeen: user['lastSeen'] ?? {});

      return userMod;
    } on TimeoutException {
      throw AuthException(code: 'no-connect');
    } catch (e) {
      if (kDebugMode) print("Non TimeoutException Error in GetUserByID: $e");
      throw AuthException(code: 'unknown');
    }
  }

  Future<void> createUserWithEmailAndPassword({
    String? name = 'New Recruit',
    String? email = 'a@gmail.com',
    String? password = 'password',
  }) async {
    Map<String, dynamic> resBody = {};
    String errorMessage = 'Unknown registration error';

    try {
      print("DEBUG: Starting registration for email: $email");
      print("DEBUG: Request body: ${jsonEncode({
        "name": name,
        "email": email,
        "password": password,
      })}");

      // Add timeout to the request
      Response res = await http.post(
        BackendProperties.registerUri,
        body: jsonEncode({
          "name": name,
          "email": email,
          "password": password,
        }),
        headers: {
          "Content-Type": "application/json",
          ...BackendProperties.getHeaders()
        },
      ).timeout(Duration(seconds: 300));

      print("DEBUG: Response status code: ${res.statusCode}");
      print("DEBUG: Response body: ${res.body}");
      print("DEBUG: Response headers: ${res.headers}");

      //i hate flutter
      if (res.body.isEmpty) {
        throw AuthException(code: 'empty-response-from-server');
      }

      // Try to parse JSON response
      try {
        resBody = jsonDecode(res.body);
        print("DEBUG: Parsed response body: $resBody");
      } catch (jsonError) {
        print("DEBUG: JSON parsing error: $jsonError");
        print("DEBUG: Raw response body: ${res.body}");
        throw AuthException(code: 'invalid-json-response');
      }

      logger.i(resBody);

      // Extract error message more safely
      if (resBody.containsKey('message') && resBody['message'] != null) {
        errorMessage = resBody['message'].toString();
      } else if (resBody.containsKey('error') && resBody['error'] != null) {
        errorMessage = resBody['error'].toString();
      } else if (resBody.containsKey('failureReason') && resBody['failureReason'] != null) {
        errorMessage = resBody['failureReason'].toString();
      } else {
        errorMessage = 'Server error without specific message (Status: ${res.statusCode})';
      }
      // bool serverReachable = await testServerConnectivity();
      // if (!serverReachable) {
      //   throw AuthException(code: 'server-unreachable');
      // }
      switch (res.statusCode) {
      // Test server connectivity first

        case 200:
        case 201: // Also accept 201 Created as success
          logger.i("Registration successful: $resBody");
          return; // Success - exit the function

        case 400:
          print("DEBUG: Bad request - check input validation");
          throw AuthException(code: errorMessage);

        case 409:
          print("DEBUG: Conflict - user might already exist");
          throw AuthException(code: errorMessage);

        case 422:
          print("DEBUG: Unprocessable entity - validation failed");
          throw AuthException(code: errorMessage);

        case 500:
          print("DEBUG: Internal server error");
          throw AuthException(code: 'server-error: $errorMessage');

        default:
          print("DEBUG: Unexpected status code: ${res.statusCode}");
          throw AuthException(code: 'http-error-${res.statusCode}: $errorMessage');
      }

    } on TimeoutException {
      print("DEBUG: Request timeout");
      throw AuthException(code: 'request-timeout');

    } on SocketException catch (e) {
      print("DEBUG: Network exception: $e");
      throw AuthException(code: 'no-connect');

    } on FormatException catch (e) {
      print("DEBUG: Format exception (likely JSON): $e");
      throw AuthException(code: 'invalid-response-format');

    } on AuthException {
      // Re-throw AuthExceptions as-is
      rethrow;

    } catch (e) {
      print("DEBUG: Unexpected exception in createUserWithEmailAndPassword: $e");
      print("DEBUG: Exception type: ${e.runtimeType}");
      // For any other exception, provide detailed error info
      throw AuthException(code: 'unexpected-error: ${e.toString()}');
    }
  }

  Future<void> signOut() async {
    store.delete(key: 'uid');
    store.setString('loggedIn', 'false'); // Fixed: should be 'false' when signing out
  }
}

class AuthException implements Exception {
  String code;

  AuthException({required this.code});

  @override
  String toString() => 'AuthException: $code';
}