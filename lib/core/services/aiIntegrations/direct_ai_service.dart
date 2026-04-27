import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

// ── Keys read from --dart-define / env.json ───────────────────────────────
const String _geminiKey = String.fromEnvironment('GEMINI_API_KEY');
const String _openAiKey = String.fromEnvironment('OPENAI_API_KEY');

const String _geminiBaseUrl =
    'https://generativelanguage.googleapis.com/v1beta/models';
const String _openAiBaseUrl = 'https://api.openai.com/v1/chat/completions';

final _dio = Dio(
  BaseOptions(
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 30),
  ),
);

// ── Public API ────────────────────────────────────────────────────────────

/// Returns true when at least one direct AI key is available.
bool get hasDirectAiKey => _geminiKey.isNotEmpty || _openAiKey.isNotEmpty;

/// Sends a chat completion request directly to Gemini or OpenAI.
///
/// [messages] should follow the OpenAI message format:
///   [ { 'role': 'system'|'user'|'assistant', 'content': '...' } ]
///
/// Returns the assistant reply text, or throws on error.
Future<String> sendDirectChatCompletion(
  List<Map<String, dynamic>> messages,
) async {
  if (_geminiKey.isNotEmpty) {
    return _callGemini(messages);
  } else if (_openAiKey.isNotEmpty) {
    return _callOpenAi(messages);
  }
  throw Exception(
    'No AI key configured. Set GEMINI_API_KEY or OPENAI_API_KEY in env.json.',
  );
}

// ── Gemini ────────────────────────────────────────────────────────────────

Future<String> _callGemini(List<Map<String, dynamic>> messages) async {
  // Extract system prompt (Gemini handles it separately)
  final systemParts = messages
      .where((m) => m['role'] == 'system')
      .map((m) => {'text': m['content'] as String})
      .toList();

  // Build conversation turns for Gemini
  final contents = messages
      .where((m) => m['role'] != 'system')
      .map((m) {
        final role = m['role'] == 'assistant' ? 'model' : 'user';
        return {
          'role': role,
          'parts': [
            {'text': m['content'] as String},
          ],
        };
      })
      .toList();

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

  const model = 'gemini-2.0-flash';
  final url = '$_geminiBaseUrl/$model:generateContent?key=$_geminiKey';

  try {
    final response = await _dio.post<Map<String, dynamic>>(
      url,
      data: body,
      options: Options(headers: {'Content-Type': 'application/json'}),
    );
    final candidates = response.data?['candidates'] as List?;
    final text =
        candidates?.first['content']?['parts']?.first?['text'] as String?;
    return text ?? '';
  } on DioException catch (e) {
    debugPrint('[Gemini] Error: ${e.response?.data}');
    throw Exception('Gemini API error: ${e.message}');
  }
}

// ── OpenAI ────────────────────────────────────────────────────────────────

Future<String> _callOpenAi(List<Map<String, dynamic>> messages) async {
  final body = {
    'model': 'gpt-4o-mini',
    'messages': messages,
    'max_tokens': 512,
    'temperature': 0.7,
  };

  try {
    final response = await _dio.post<Map<String, dynamic>>(
      _openAiBaseUrl,
      data: body,
      options: Options(
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_openAiKey',
        },
      ),
    );
    final content = response.data?['choices']?[0]?['message']?['content']
        as String?;
    return content ?? '';
  } on DioException catch (e) {
    debugPrint('[OpenAI] Error: ${e.response?.data}');
    throw Exception('OpenAI API error: ${e.message}');
  }
}
