import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
class UserApiService {
  static const String baseUrl = 'http://10.0.2.2:5208/api';
  // API ĐĂNG NHẬP
  static Future<Map<String, dynamic>?> register({
    required String name,
    required String email,
    required String password,
    String phone = '',
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/Auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': name,
          'email': email,
          'password': password,
          'phone': phone,
        }),
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      debugPrint('Lỗi đăng ký: $e');
    }
    return null;
  }
  static Future<Map<String, dynamic>?> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/Auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      debugPrint('Lỗi đăng nhập: $e');
    }
    return null;
  }
  static Future<bool> sendOtp({
    required String email,
    required String purpose,
  }) async {
    try {
      final response = await http.post(
        // SỬA: Bỏ /api thừa ở đây
        Uri.parse('$baseUrl/Security/send-otp'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'purpose': purpose,
        }),
      );
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Send OTP Error: $e');
      return false;
    }
  }
  static Future<bool> verifyOtp({
    required String email,
    required String otpCode,
  }) async {
    try {
      final response = await http.post(
        // SỬA: Bỏ /api thừa ở đây
        Uri.parse('$baseUrl/Security/verify-otp'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'otpCode': otpCode,
        }),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['success'] == true;
      }
      return false;
    } catch (e) {
      debugPrint('Verify OTP Error: $e');
      return false;
    }
  }
  static Future<Map<String, dynamic>?> getUserProfile(int userId) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/User/profile/$userId'));
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      debugPrint('Lỗi lấy profile: $e');
    }
    return null;
  }
  static Future<Map<String, dynamic>?> checkIn(int userId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/User/check-in'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'userId': userId}),
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      debugPrint('Lỗi điểm danh: $e');
    }
    return null;
  }
  static Future<Map<String, dynamic>?> updateUserProfile(int userId, Map<String, dynamic> userData) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/User/profile/$userId'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(userData),
      );

      debugPrint('Update Profile Status Code: ${response.statusCode}');
      debugPrint('Update Profile Response: ${response.body}');

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      debugPrint('Lỗi cập nhật profile: $e');
    }
    return null;
  }
  // 1. Lấy danh sách cấp độ CourseLevel từ C# Backend
  static Future<List<dynamic>> getCourseLevels() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/CourseLevel'));
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      debugPrint('Lỗi lấy danh sách cấp độ: $e');
    }
    return [];
  }
  // 2. Lấy danh mục bài học (CourseCategory) theo cấp độ và loại kỹ năng (VOCAB, SPEAKING, ...)
  static Future<List<dynamic>> getCategoriesByLevelAndSkill(String levelName, String skillType) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/CourseCategory?levelName=${Uri.encodeComponent(levelName)}&skillType=$skillType'),
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      debugPrint('Lỗi lấy danh mục bài học: $e');
    }
    return [];
  }
  // 3. Lấy danh sách từ vựng (VocabItem) theo TopicId
  static Future<List<dynamic>> getVocabItemsByTopic(int topicId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/VocabItem/topic/$topicId'),
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      debugPrint('Lỗi lấy danh sách từ vựng: $e');
    }
    return [];
  }
  static Future<List<dynamic>> getSpeakingItemsByTopic(int topicId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/SpeakingItem/topic/$topicId'),
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      debugPrint('Lỗi lấy danh sách bài luyện nói: $e');
    }
    return [];
  }
  static Future<List<dynamic>> getFlashcardsByTopicId(int topicId) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/FlashcardItem/topic/$topicId'));
      debugPrint('API Flashcard response status: ${response.statusCode}, body: ${response.body}');
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded is List) return decoded;
      }
    } catch (e) {
      debugPrint('Lỗi lấy flashcard: $e');
    }
    return [];
  }
  static Future<List<Map<String, dynamic>>> getQuizItemsByTopic(int topicId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/QuizItem/topic/$topicId'),
        headers: {'Content-Type': 'application/json'},
      );

      debugPrint('API QuizItem status: ${response.statusCode}, body: ${response.body}');

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded is List) {
          return decoded.map((item) => Map<String, dynamic>.from(item)).toList();
        }
      } else {
        debugPrint('Server trả về mã lỗi: ${response.statusCode}');
      }
    } catch (e, stackTrace) {
      debugPrint('Lỗi kết nối khi lấy danh sách câu hỏi trắc nghiệm: $e');
      debugPrint(stackTrace.toString());
    }
    return [];
  }
  static Future<Map<String, dynamic>> getQuizDetailByTopic(int topicId) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/QuizItem/topic-detail/$topicId'));
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      debugPrint('Lỗi tải quiz detail: $e');
    }
    return {'timeLimitSeconds': 20, 'items': []};
  }
  static Future<List<dynamic>> getListeningItemsByTopic(int topicId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/ListeningItem/topic/$topicId'),
      );
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded is List) return decoded;
      }
    } catch (e) {
      debugPrint('Lỗi lấy danh sách bài nghe: $e');
    }
    return [];
  }
  static Future<List<dynamic>> getBattleStages() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/battle/stages'));
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic> && decoded['data'] is List) {
          return decoded['data'];
        } else if (decoded is List) {
          return decoded;
        }
      }
    } catch (e) {
      debugPrint('Lỗi tải danh sách màn battle: $e');
    }
    return [];
  }
  // Thêm vào class UserApiService (trong api_service.dart tương ứng của bạn)
  static Future<List<dynamic>> getBattleQuestions(dynamic stageId) async {
    try {
      final url = Uri.parse('$baseUrl/battle/stages/$stageId/questions');
      debugPrint('Calling getBattleQuestions: $url');
      final response = await http.get(url);
      debugPrint('Response status: ${response.statusCode}, body: ${response.body}');

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic> && decoded['data'] is List) {
          return decoded['data'];
        } else if (decoded is List) {
          return decoded;
        }
      }
    } catch (e) {
      debugPrint('Lỗi tải câu hỏi battle của stage $stageId: $e');
    }
    return [];
  }
  static Future<List<dynamic>> getLeaderboard(String stageId) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/battle/stages/$stageId/leaderboard'));
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic> && decoded['data'] is List) {
          return decoded['data'];
        } else if (decoded is List) {
          return decoded;
        }
      }
    } catch (e) {
      debugPrint('Lỗi tải bảng xếp hạng của stage $stageId: $e');
    }
    return [];
  }
  static Future<bool> submitBattleResult(String stageId, int userId, int score, int timeSpentSeconds) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/battle/stages/$stageId/submit'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'userId': userId, // Truyền thẳng ID người dùng vừa đăng nhập vào đây
          'score': score,
          'timeSpentSeconds': timeSpentSeconds,
        }),
      );
      debugPrint('Submit result status: ${response.statusCode}, body: ${response.body}');
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      debugPrint('Lỗi nộp kết quả battle: $e');
      return false;
    }
  }
  static Future<bool> upgradePro(int userId, String planTitle) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/User/upgrade-pro'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "userId": userId,
          "planTitle": planTitle,
          "paymentMethod": "MoMo"
        }),
      );
      if (response.statusCode == 200) {
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Lỗi nâng cấp PRO: $e');
      return false;
    }

  }
  static Future<Map<String, dynamic>?> createMomoPayment(int userId, String planTitle) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/User/create-momo-payment'), // Giữ nguyên endpoint bên C#
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "userId": userId,
          "planTitle": planTitle,
        }),
      );

      debugPrint('PayOS API Response Status: ${response.statusCode}');
      debugPrint('PayOS API Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data;
      }
      return null;
    } catch (e) {
      debugPrint('Lỗi kết nối tạo thanh toán PayOS: $e');
      return null;
    }
  }

  // 3. [MỚI] Kiểm tra trạng thái PRO của user sau khi thanh toán xong
  static Future<bool> checkUserProStatus(int userId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/User/profile/$userId'),
        headers: {"Content-Type": "application/json"},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // Kiểm tra trường isPro từ server trả về
        return data['isPro'] == true;
      }
      return false;
    } catch (e) {
      debugPrint('Lỗi kiểm tra trạng thái Pro: $e');
      return false;
    }
  }
}