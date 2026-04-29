import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../config/app_config.dart';

// ── API endpoints ──────────────────────────────────────────────────────────
const String _geminiBaseUrl =
    'https://generativelanguage.googleapis.com/v1beta/models';
const String _openAiBaseUrl = 'https://api.openai.com/v1/chat/completions';

final _dio = Dio(
  BaseOptions(
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 30),
  ),
);

// ── Public API ─────────────────────────────────────────────────────────────

/// Returns true when at least one direct AI key is available at runtime.
bool get hasDirectAiKey =>
    AppConfig.geminiApiKey.isNotEmpty || AppConfig.openAiApiKey.isNotEmpty;

/// Sends a chat completion request.
/// Priority: Gemini → OpenAI fallback (even if Gemini key exists but fails).
/// Returns the assistant reply text, or throws on total failure.
Future<String> sendDirectChatCompletion(
  List<Map<String, dynamic>> messages,
) async {
  final geminiKey = AppConfig.geminiApiKey;
  final openAiKey = AppConfig.openAiApiKey;

  if (geminiKey.isNotEmpty) {
    try {
      return await _callGemini(messages, geminiKey);
    } catch (e) {
      // Gemini failed (quota / API error) — fall through to OpenAI
      debugPrint('[AI] Gemini failed: $e — trying OpenAI fallback');
      if (openAiKey.isNotEmpty) {
        return _callOpenAi(messages, openAiKey);
      }
      // Re-throw with a user-friendly message
      throw Exception('AI service unavailable. $e');
    }
  }

  if (openAiKey.isNotEmpty) {
    return _callOpenAi(messages, openAiKey);
  }

  throw Exception(
    'No AI key found. Add GEMINI_API_KEY or OPENAI_API_KEY to assets/env.json.',
  );
}

// ── Gemini ─────────────────────────────────────────────────────────────────

Future<String> _callGemini(
  List<Map<String, dynamic>> messages,
  String apiKey,
) async {
  final systemParts = messages
      .where((m) => m['role'] == 'system')
      .map((m) => {'text': m['content'] as String})
      .toList();

  final contents = messages
      .where((m) => m['role'] != 'system')
      .map((m) => {
            'role': m['role'] == 'assistant' ? 'model' : 'user',
            'parts': [
              {'text': m['content'] as String}
            ],
          })
      .toList();

  // Gemini requires at least one content entry
  if (contents.isEmpty) {
    throw Exception('No user messages to send.');
  }

  final body = <String, dynamic>{
    'contents': contents,
    'generationConfig': {
      'temperature': 0.7,
      'maxOutputTokens': 512,
    },
  };
  if (systemParts.isNotEmpty) {
    body['system_instruction'] = {'parts': systemParts};
  }

  // gemini-1.5-flash is stable and widely available
  const model = 'gemini-1.5-flash';
  final url = '$_geminiBaseUrl/$model:generateContent?key=$apiKey';

  try {
    final response = await _dio.post<Map<String, dynamic>>(
      url,
      data: body,
      options: Options(headers: {'Content-Type': 'application/json'}),
    );
    final candidates = response.data?['candidates'] as List?;
    if (candidates == null || candidates.isEmpty) {
      throw Exception('Gemini returned empty candidates.');
    }
    final text =
        candidates.first['content']?['parts']?.first?['text'] as String?;
    if (text == null || text.isEmpty) {
      throw Exception('Gemini returned empty text.');
    }
    return text.trim();
  } on DioException catch (e) {
    final errBody = e.response?.data?.toString() ?? e.message;
    debugPrint('[Gemini] HTTP ${e.response?.statusCode}: $errBody');
    throw Exception('Gemini: ${e.response?.statusCode} — $errBody');
  }
}

// ── OpenAI ─────────────────────────────────────────────────────────────────

Future<String> _callOpenAi(
  List<Map<String, dynamic>> messages,
  String apiKey,
) async {
  try {
    final response = await _dio.post<Map<String, dynamic>>(
      _openAiBaseUrl,
      data: {
        'model': 'gpt-4o-mini',
        'messages': messages,
        'max_tokens': 512,
        'temperature': 0.7,
      },
      options: Options(headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $apiKey',
      }),
    );
    final content =
        response.data?['choices']?[0]?['message']?['content'] as String?;
    if (content == null || content.isEmpty) {
      throw Exception('OpenAI returned empty content.');
    }
    return content.trim();
  } on DioException catch (e) {
    final errBody = e.response?.data?.toString() ?? e.message;
    debugPrint('[OpenAI] HTTP ${e.response?.statusCode}: $errBody');
    throw Exception('OpenAI: ${e.response?.statusCode} — $errBody');
  }
}
