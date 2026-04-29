import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/app_export.dart';
import '../../core/services/aiIntegrations/direct_ai_service.dart';
import '../../providers/voice_provider.dart';
import '../../widgets/voice_fab.dart';
import '../../routes/app_routes.dart';
import '../voice_assistant/voice_modal.dart';

class AiAssistantScreen extends ConsumerStatefulWidget {
  const AiAssistantScreen({super.key});

  @override
  ConsumerState<AiAssistantScreen> createState() => _AiAssistantScreenState();
}

class _AiAssistantScreenState extends ConsumerState<AiAssistantScreen>
    with TickerProviderStateMixin {
  int _navIndex = 3;
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isTyping = false;
  late AnimationController _typingController;
  late Animation<double> _typingAnimation;

  final List<_ChatMessage> _messages = [
    _ChatMessage(
      text:
          'Hello! I\'m NeuroGrid AI. Ask me anything about city conditions, traffic, parking, or events in Bhopal.',
      isUser: false,
      time: ''
    ),
  ];

  static const String _systemPrompt =
      'You are NeuroGrid AI, the intelligent city assistant for Bhopal, '
      'Madhya Pradesh, India. You have access to real-time city data including '
      'traffic conditions, parking availability, waste pickup schedules, weather, '
      'civic issue status, and city infrastructure metrics. '
      'Always give concise, actionable, data-driven answers. '
      'If asked about conditions, mention specific Bhopal landmarks and roads '
      '(e.g., MP Nagar, Hamidia Road, DB City Mall, New Market). '
      'Keep responses under 80 words unless a detailed explanation is required.';

  // Conversation history (sent to AI for context)
  final List<Map<String, dynamic>> _history = [];

  final List<String> _suggestions = [
    'Best route to New Market?',
    'Air quality today',
    'Waste pickup schedule',
    'Parking near DB City Mall',
  ];

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
    );
    _typingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
    _typingAnimation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _typingController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    _typingController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final text = _inputController.text.trim();
    if (text.isEmpty || _isTyping) return;

    setState(() {
      _messages.add(_ChatMessage(text: text, isUser: true, time: _currentTime()));
      _inputController.clear();
      _isTyping = true;
    });
    _scrollToBottom();

    _history.add({'role': 'user', 'content': text});

    final apiMessages = [
      {'role': 'system', 'content': _systemPrompt},
      ..._history,
    ];

    sendDirectChatCompletion(apiMessages).then((reply) {
      if (!mounted) return;
      _history.add({'role': 'assistant', 'content': reply});
      setState(() {
        _isTyping = false;
        _messages.add(_ChatMessage(text: reply, isUser: false, time: _currentTime()));
      });
      _scrollToBottom();
    }).catchError((e) {
      if (!mounted) return;
      String errMsg;
      final errStr = e.toString();
      if (errStr.contains('No AI key')) {
        errMsg = '⚠️ No AI key configured. Add GEMINI_API_KEY to assets/env.json.';
      } else if (errStr.contains('401') || errStr.contains('403')) {
        errMsg = '⚠️ AI key is invalid or expired. Check GEMINI_API_KEY / OPENAI_API_KEY.';
      } else if (errStr.contains('429')) {
        errMsg = '⚠️ AI rate limit reached. Please wait a moment and try again.';
      } else if (errStr.contains('SocketException') || errStr.contains('NetworkException')) {
        errMsg = '⚠️ No internet connection. Please check your network.';
      } else {
        errMsg = '⚠️ ${errStr.replaceAll('Exception: ', '')}';
      }
      setState(() {
        _isTyping = false;
        _messages.add(_ChatMessage(text: errMsg, isUser: false, time: _currentTime()));
      });
      _scrollToBottom();
    });
  }


  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  String _currentTime() {
    final now = DateTime.now();
    final h = now.hour > 12 ? now.hour - 12 : now.hour;
    final m = now.minute.toString().padLeft(2, '0');
    final period = now.hour >= 12 ? 'PM' : 'AM';
    return '$h:$m $period';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      extendBody: true,
      body: Column(
        children: [
          // Header
          _buildHeader(context),
          // Messages
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              itemCount: _messages.length + (_isTyping ? 1 : 0) + 1,
              itemBuilder: (context, index) {
                if (index == 0) return _buildSuggestions();
                final msgIndex = index - 1;
                if (_isTyping && msgIndex == _messages.length) {
                  return _buildTypingIndicator();
                }
                if (msgIndex >= _messages.length) return null;
                return _buildMessageBubble(_messages[msgIndex]);
              },
            ),
          ),
          // Input area
          _buildInputArea(context),
        ],
      ),
      bottomNavigationBar: AppNavigation(
        currentIndex: _navIndex,
        onTap: (i) {
          setState(() => _navIndex = i);
          if (i == 0) Navigator.pushNamed(context, AppRoutes.homeScreen);
          if (i == 1) Navigator.pushNamed(context, AppRoutes.mapScreen);
          if (i == 2) Navigator.pushNamed(context, AppRoutes.trafficScreen);
          if (i == 4) Navigator.pushNamed(context, AppRoutes.profileScreen);
        },
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFEEF2FF), Color(0xFFF8FAFF)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
          child: Row(
            children: [
              // Back button
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 42, height: 42,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(10),
                        blurRadius: 12, offset: const Offset(0, 3)),
                    ],
                  ),
                  child: const Icon(Icons.arrow_back_ios_new_rounded,
                      size: 16, color: Color(0xFF0F172A)),
                ),
              ),
              const SizedBox(width: 14),

              // AI avatar with glow
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1250C4), Color(0xFF4A8FFF)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF1A6BF5).withAlpha(70),
                      blurRadius: 14, offset: const Offset(0, 5)),
                  ],
                ),
                child: const Icon(Icons.smart_toy_rounded, size: 22, color: Colors.white),
              ),
              const SizedBox(width: 12),

              // Title + status
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('NeuroGrid AI',
                        style: GoogleFonts.dmSans(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF0F172A),
                            letterSpacing: -0.3)),
                    const SizedBox(height: 2),
                    Row(children: [
                      Container(
                        width: 7, height: 7,
                        decoration: const BoxDecoration(
                          color: Color(0xFF22C55E), shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 5),
                      Text('Online · City data synced',
                          style: GoogleFonts.dmSans(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF64748B))),
                    ]),
                  ],
                ),
              ),

              // Voice button with gradient glow
              GestureDetector(
                onTap: () async {
                  final granted = await ref
                      .read(voiceProvider.notifier)
                      .requestMicPermission();
                  if (!granted || !context.mounted) return;
                  unawaited(ref.read(voiceProvider.notifier).startCall());
                  await VoiceModal.show(context);
                },
                child: Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF1A6BF5), Color(0xFF4A8FFF)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF1A6BF5).withAlpha(90),
                        blurRadius: 14, offset: const Offset(0, 5)),
                    ],
                  ),
                  child: const Icon(Icons.mic_rounded, size: 22, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSuggestions() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Voice-first banner ─────────────────────────────────────────
          GestureDetector(
            onTap: () async {
              final granted = await ref.read(voiceProvider.notifier).requestMicPermission();
              if (!granted || !context.mounted) return;
              unawaited(ref.read(voiceProvider.notifier).startCall());
              await VoiceModal.show(context);
            },
            child: Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1250C4), Color(0xFF1A6BF5), Color(0xFF4A8FFF)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF1A6BF5).withAlpha(80),
                    blurRadius: 20,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(children: [
                Container(
                  width: 52, height: 52,
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(25),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.mic_rounded, size: 26, color: Colors.white),
                ),
                const SizedBox(width: 14),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Talk to City AI', style: GoogleFonts.dmSans(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
                  const SizedBox(height: 2),
                  Text('Tap to start a voice conversation', style: GoogleFonts.dmSans(fontSize: 12, color: Colors.white.withAlpha(180))),
                ])),
                const Icon(Icons.chevron_right_rounded, color: Colors.white, size: 22),
              ]),
            ),
          ),
          Text(
            'Quick questions',
            style: GoogleFonts.dmSans(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppTheme.textMuted,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _suggestions
                .map(
                  (s) => GestureDetector(
                    onTap: () {
                      _inputController.text = s;
                      _sendMessage();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: const Color(0xFF1A6BF5).withAlpha(50),
                            width: 1.2),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF1A6BF5).withAlpha(12),
                            blurRadius: 8,
                            offset: const Offset(0, 2)),
                        ],
                      ),
                      child: Text(
                        s,
                        style: GoogleFonts.dmSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF1A6BF5),
                        ),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(_ChatMessage msg) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment:
            msg.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!msg.isUser) ...[
            Container(
              width: 30, height: 30,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1250C4), Color(0xFF4A8FFF)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.smart_toy_rounded,
                  size: 16, color: Colors.white),
            ),
            const SizedBox(width: 10),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: msg.isUser
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    // User bubbles: gradient; AI bubbles: clean white card
                    gradient: msg.isUser
                        ? const LinearGradient(
                            colors: [Color(0xFF1250C4), Color(0xFF1A6BF5)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : null,
                    color: msg.isUser ? null : Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(18),
                      topRight: const Radius.circular(18),
                      bottomLeft: Radius.circular(msg.isUser ? 18 : 4),
                      bottomRight: Radius.circular(msg.isUser ? 4 : 18),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: msg.isUser
                            ? const Color(0xFF1A6BF5).withAlpha(60)
                            : Colors.black.withAlpha(10),
                        blurRadius: 14,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Text(
                    msg.text,
                    style: GoogleFonts.dmSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: msg.isUser
                          ? Colors.white
                          : const Color(0xFF0F172A),
                      height: 1.55,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  msg.time,
                  style: GoogleFonts.dmSans(
                    fontSize: 10,
                    color: const Color(0xFFB0BCCE),
                  ),
                ),
              ],
            ),
          ),
          if (msg.isUser) const SizedBox(width: 8),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1250C4), Color(0xFF4A8FFF)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.smart_toy_rounded,
              size: 16,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(18),
                topRight: Radius.circular(18),
                bottomLeft: Radius.circular(4),
                bottomRight: Radius.circular(18),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(10),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(
                3,
                (i) => AnimatedBuilder(
                  animation: _typingAnimation,
                  builder: (_, __) => Container(
                    margin: EdgeInsets.only(right: i < 2 ? 4 : 0),
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withAlpha(
                        (((_typingAnimation.value + i * 0.3) % 1.0) * 200 + 55)
                            .toInt(),
                      ),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputArea(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final bottomPad = MediaQuery.of(context).padding.bottom;
    return Container(
      padding: EdgeInsets.fromLTRB(
          16, 10, 16, bottomInset > 0 ? 12 : bottomPad + 80),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: const Color(0xFFE8EDF5), width: 1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(8),
            blurRadius: 20, offset: const Offset(0, -4)),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                    color: const Color(0xFFCDD9EE), width: 1.2),
              ),
              child: TextField(
                controller: _inputController,
                style: GoogleFonts.dmSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFF0F172A)),
                decoration: InputDecoration(
                  hintText: 'Ask about city conditions…',
                  hintStyle: GoogleFonts.dmSans(
                    fontSize: 14, color: const Color(0xFFB0BCCE)),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding:
                      const EdgeInsets.symmetric(vertical: 10),
                ),
                maxLines: 3,
                minLines: 1,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: _sendMessage,
            child: Container(
              width: 46, height: 46,
              decoration: BoxDecoration(
                gradient: _isTyping
                    ? const LinearGradient(
                        colors: [Color(0xFFCDD9EE), Color(0xFFCDD9EE)])
                    : const LinearGradient(
                        colors: [Color(0xFF1250C4), Color(0xFF4A8FFF)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: _isTyping
                    ? []
                    : [
                        BoxShadow(
                          color: const Color(0xFF1A6BF5).withAlpha(90),
                          blurRadius: 14, offset: const Offset(0, 5)),
                      ],
              ),
              child: const Icon(Icons.send_rounded,
                  size: 20, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatMessage {
  final String text;
  final bool isUser;
  final String time;

  const _ChatMessage({
    required this.text,
    required this.isUser,
    required this.time,
  });
}
