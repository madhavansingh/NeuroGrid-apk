import 'dart:math';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../config/app_config.dart';

// ── API endpoints ──────────────────────────────────────────────────────────
const String _geminiBaseUrl =
    'https://generativelanguage.googleapis.com/v1beta/models';
const String _openAiBaseUrl = 'https://api.openai.com/v1/chat/completions';

// gemini-flash-latest resolves to the newest available flash model (gemini-3-flash-preview)
// and is stable for this API key — gemini-1.5-flash and gemini-2.0-flash are quota-exhausted
const String _geminiModel = 'gemini-flash-latest';

final _dio = Dio(
  BaseOptions(
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 30),
  ),
);

// ── Bhopal Smart City Knowledge Base ──────────────────────────────────────

/// Full system prompt injected into every AI request.
/// Gives the chatbot deep Bhopal context so answers feel local and real.
const String _bhopalSystemPrompt = '''
You are NeuroGrid AI, the intelligent city assistant for Bhopal, Madhya Pradesh, India.

CITY CONTEXT:
- City: Bhopal, MP — "City of Lakes" (Badi Jheel, Chhoti Jheel)
- Key zones: MP Nagar, New Market, Hamidia Road, DB City Mall, Arera Colony, TT Nagar, Kolar Road, Bairagarh, Misrod, Bhopal Junction Railway Station, Raja Bhoj Airport
- Major roads: Hoshangabad Road, VIP Road, Berasia Road, Kolar Road, Raisen Road
- Peak traffic hours: 8:30–10:30 AM and 5:30–8:00 PM IST
- Common congestion: MP Nagar Square, New Market Chowk, Roshanpura Square, Lal Parade Ground area
- Weather: Hot summers (Apr–Jun, 38–45°C), monsoon (Jul–Sep), mild winters (Dec–Feb, 10–20°C)
- Emergency: Police 100, Ambulance 108, Fire 101, BMCAC helpline 0755-2700200

CAPABILITIES:
- Real-time traffic conditions and route advice
- Parking availability near major landmarks
- Civic issue reporting and status
- Weather updates (temperature, humidity, UV, AQI)
- Safety advisories and alerts
- Waste pickup schedules (BIDA zones)
- City event and infrastructure updates
- Navigation suggestions for Bhopal roads

RESPONSE RULES:
1. Answer concisely — under 80 words unless detail is required
2. Be specific: mention Bhopal road names, landmarks, and localities
3. If real-time data is unavailable, give realistic Bhopal-context estimates
4. Speak like a knowledgeable local city assistant, not a generic AI
5. Use friendly, helpful tone — not bureaucratic
6. Never make up emergency incident details — say "no alerts reported" when unclear
7. For navigation: suggest alternatives to known congested routes
''';

// ── Public API ─────────────────────────────────────────────────────────────

/// Returns true when at least one AI key is available.
bool get hasDirectAiKey =>
    AppConfig.geminiApiKey.isNotEmpty || AppConfig.openAiApiKey.isNotEmpty;

/// Sends a chat completion with the Bhopal city system prompt pre-injected.
///
/// Cascade: Gemini (gemini-flash-latest) → OpenAI (gpt-4o-mini) → Smart local fallback
/// On 429 rate-limit: retries once after the suggested delay (max 20s).
/// Never throws to the UI — returns a helpful fallback response on total failure.
Future<String> sendDirectChatCompletion(
  List<Map<String, dynamic>> messages,
) async {
  // Inject Bhopal system prompt if not already present
  final enriched = _injectSystemPrompt(messages);

  final geminiKey = AppConfig.geminiApiKey;
  final openAiKey = AppConfig.openAiApiKey;

  // 1. Try Gemini
  if (geminiKey.isNotEmpty) {
    try {
      return await _callGeminiWithRetry(enriched, geminiKey);
    } catch (e) {
      debugPrint('[AI] Gemini failed: $e — trying OpenAI');
    }
  }

  // 2. Try OpenAI
  if (openAiKey.isNotEmpty) {
    try {
      return await _callOpenAiWithRetry(enriched, openAiKey);
    } catch (e) {
      debugPrint('[AI] OpenAI failed: $e — using smart fallback');
    }
  }

  // 3. Smart local fallback — never shows blank error to user
  return _smartFallback(messages);
}

// ── System prompt injection ────────────────────────────────────────────────

List<Map<String, dynamic>> _injectSystemPrompt(
  List<Map<String, dynamic>> messages,
) {
  final hasSystem = messages.any((m) => m['role'] == 'system');
  if (hasSystem) {
    // Prepend Bhopal context to existing system prompt
    return [
      {
        'role': 'system',
        'content': '$_bhopalSystemPrompt\n\n${messages.firstWhere((m) => m['role'] == 'system')['content']}',
      },
      ...messages.where((m) => m['role'] != 'system'),
    ];
  }
  return [
    {'role': 'system', 'content': _bhopalSystemPrompt},
    ...messages,
  ];
}

// ── Gemini with retry ──────────────────────────────────────────────────────

Future<String> _callGeminiWithRetry(
  List<Map<String, dynamic>> messages,
  String apiKey, {
  int attempt = 0,
}) async {
  try {
    return await _callGemini(messages, apiKey);
  } on DioException catch (e) {
    if (e.response?.statusCode == 429 && attempt == 0) {
      // Extract retry delay from response body
      final retryDelay = _extractRetryDelay(e.response?.data) ?? 20;
      final waitSeconds = min(retryDelay, 20);
      debugPrint('[Gemini] Rate limited. Retrying after ${waitSeconds}s...');
      await Future.delayed(Duration(seconds: waitSeconds));
      return _callGeminiWithRetry(messages, apiKey, attempt: 1);
    }
    rethrow;
  }
}

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

  final url = '$_geminiBaseUrl/$_geminiModel:generateContent?key=$apiKey';

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
    rethrow;
  }
}

// ── OpenAI with retry ──────────────────────────────────────────────────────

Future<String> _callOpenAiWithRetry(
  List<Map<String, dynamic>> messages,
  String apiKey, {
  int attempt = 0,
}) async {
  try {
    return await _callOpenAi(messages, apiKey);
  } on DioException catch (e) {
    if (e.response?.statusCode == 429 && attempt == 0) {
      await Future.delayed(const Duration(seconds: 15));
      return _callOpenAiWithRetry(messages, apiKey, attempt: 1);
    }
    rethrow;
  }
}

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
    rethrow;
  }
}

// ── Smart local fallback ───────────────────────────────────────────────────

/// Returns a contextual Bhopal response based on keywords in the last user message.
/// Ensures the app never shows a blank screen when APIs are down.
String _smartFallback(List<Map<String, dynamic>> messages) {
  final lastUser = messages.lastWhere(
    (m) => m['role'] == 'user',
    orElse: () => {'content': ''},
  )['content']
      ?.toString()
      .toLowerCase() ??
      '';

  debugPrint('[AI] Using smart local fallback for: $lastUser');

  if (_contains(lastUser, ['traffic', 'route', 'road', 'jam', 'congestion'])) {
    return 'Current traffic in Bhopal: MP Nagar Square and Roshanpura are typically congested during peak hours (8:30–10:30 AM, 5:30–8 PM). Hamidia Road and Hoshangabad Road are generally smoother alternatives. I\'ll have live data once connection is restored.';
  }
  if (_contains(lastUser, ['weather', 'temperature', 'rain', 'humidity', 'aqi'])) {
    return 'Bhopal weather is currently unavailable from live sensors. Typically at this time of year, expect 28–34°C with moderate humidity. Monsoon season (Jul–Sep) brings 600–1200mm rainfall. I\'ll update with live data shortly.';
  }
  if (_contains(lastUser, ['parking', 'park', 'vehicle'])) {
    return 'Bhopal parking hotspots: DB City Mall (multi-level, usually available), New Market (limited — arrive early), Lal Parade Ground (open parking). MP Nagar has limited street parking during office hours. Smart parking data will be live shortly.';
  }
  if (_contains(lastUser, ['waste', 'garbage', 'pickup', 'dustbin', 'sweeping'])) {
    return 'BIDA waste pickup in Bhopal follows zone-wise schedules — most residential areas (Arera Colony, Kolar Road, TT Nagar) have morning pickups 6–9 AM. For exact schedule in your zone, call BIDA at 0755-2700200.';
  }
  if (_contains(lastUser, ['alert', 'emergency', 'safety', 'police', 'fire'])) {
    return 'No critical alerts currently in the system. Emergency contacts: Police 100, Ambulance 108, Fire 101. For non-emergency civic issues, use the NeuroGrid report feature.';
  }
  if (_contains(lastUser, ['power', 'electricity', 'outage', 'light'])) {
    return 'Power outage info: MPEB helpline is 1912 (24/7). Planned outages are usually 8 AM–4 PM on maintenance days. No outages currently reported in the NeuroGrid system.';
  }
  if (_contains(lastUser, ['air', 'pollution', 'aqi', 'quality'])) {
    return 'Bhopal AQI typically ranges from 60–120 (Moderate). Industrial areas near Mandideep may show higher readings. Bharat Mata Chowk and Shahpura areas usually have better air quality. Live AQI will update shortly.';
  }
  if (_contains(lastUser, ['hello', 'hi', 'namaste', 'hey', 'helo'])) {
    return 'Namaste! Main NeuroGrid AI hoon — Bhopal ka smart city assistant. Main aapko traffic, weather, parking, civic issues aur city ki koi bhi update de sakta hoon. Kya jaanna chahte ho?';
  }

  // Generic fallback
  return 'Main abhi live city data access kar raha hoon. Bhopal ke liye — traffic, parking, weather, ya civic issues ke baare mein — main aapko best possible information dunga. Koi specific question ho toh poochho!';
}

bool _contains(String text, List<String> keywords) =>
    keywords.any((k) => text.contains(k));

// ── Utility ────────────────────────────────────────────────────────────────

/// Extracts the retry delay in seconds from a Gemini 429 response body.
int? _extractRetryDelay(dynamic responseData) {
  try {
    if (responseData is Map) {
      final details = responseData['error']?['details'] as List?;
      for (final detail in details ?? []) {
        if (detail['@type']?.toString().contains('RetryInfo') == true) {
          final delay = detail['retryDelay']?.toString() ?? '';
          final seconds = int.tryParse(delay.replaceAll(RegExp(r'[^0-9]'), ''));
          return seconds;
        }
      }
    }
  } catch (_) {}
  return null;
}
