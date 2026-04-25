import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../../../theme/app_theme.dart';
import '../../../providers/chat_notifier.dart';
import '../../../core/services/weather_service.dart';

class LeaveNowCardWidget extends ConsumerStatefulWidget {
  const LeaveNowCardWidget({super.key});

  @override
  ConsumerState<LeaveNowCardWidget> createState() => _LeaveNowCardWidgetState();
}

class _LeaveNowCardWidgetState extends ConsumerState<LeaveNowCardWidget>
    with SingleTickerProviderStateMixin {
  bool _expanded = false;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  // Live weather data
  WeatherData? _liveWeather;
  bool _weatherLoading = true;

  // Current conditions (updated from live data or manual override)
  String _trafficSeverity = 'Heavy';
  String _weatherCondition = 'Rain expected';

  final WeatherService _weatherService = WeatherService();

  static const _config = ChatConfig(
    provider: 'GEMINI',
    model: 'gemini/gemini-2.5-flash',
    streaming: false,
  );

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    // Fetch live weather first, then get AI recommendation
    WidgetsBinding.instance.addPostFrameCallback((_) => _initWithLiveWeather());
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _initWithLiveWeather() async {
    final weather = await _weatherService.fetchWeather();
    if (mounted) {
      setState(() {
        _liveWeather = weather;
        _weatherCondition = weather.trafficWeatherString;
        _weatherLoading = false;
      });
      _fetchRecommendation();
    }
  }

  void _fetchRecommendation() {
    final messages = [
      {
        'role': 'system',
        'content':
            'You are a smart city AI assistant for Bhopal, India. Give concise, actionable leave/stay recommendations for commuters. Always respond in 2 parts: 1) A short decision headline (max 5 words, e.g. "Leave now." or "Wait 15 minutes.") 2) A brief reason (1-2 sentences, max 30 words). Format: HEADLINE: <text>\nREASON: <text>',
      },
      {
        'role': 'user',
        'content':
            'Current conditions in Bhopal, MP Nagar:\n- Traffic severity: $_trafficSeverity\n- Weather: $_weatherCondition\n\nShould I leave for work now or wait?',
      },
    ];

    ref
        .read(chatNotifierProvider(_config).notifier)
        .sendMessage(
          messages,
          parameters: {'temperature': 0.7, 'max_tokens': 120},
        );
  }

  /// Parse AI response into headline + reason
  Map<String, String> _parseResponse(String response) {
    String headline = 'Analysing conditions…';
    String reason = '';

    if (response.isEmpty) return {'headline': headline, 'reason': reason};

    final headlineMatch = RegExp(
      r'HEADLINE:\s*(.+)',
      caseSensitive: false,
    ).firstMatch(response);
    final reasonMatch = RegExp(
      r'REASON:\s*(.+)',
      caseSensitive: false,
    ).firstMatch(response);

    if (headlineMatch != null) {
      headline = headlineMatch.group(1)?.trim() ?? headline;
    }
    if (reasonMatch != null) {
      reason = reasonMatch.group(1)?.trim() ?? '';
    }

    // Fallback: if format not followed, use first sentence as headline
    if (headlineMatch == null) {
      final sentences = response.split(RegExp(r'[.!?]'));
      headline = sentences.isNotEmpty ? sentences[0].trim() : response;
      reason = sentences.length > 1
          ? sentences.sublist(1).join('. ').trim()
          : '';
    }

    return {'headline': headline, 'reason': reason};
  }

  Color get _trafficColor {
    switch (_trafficSeverity.toLowerCase()) {
      case 'heavy':
        return AppTheme.trafficHeavy;
      case 'moderate':
        return AppTheme.trafficModerate;
      default:
        return AppTheme.trafficClear;
    }
  }

  String get _liveWeatherPillLabel {
    if (_weatherLoading) return 'Loading weather…';
    final weather = _liveWeather;
    if (weather == null) return _weatherCondition;
    return '${weather.conditionLabel} · ${weather.tempCelsius.round()}°C';
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(chatNotifierProvider(_config));

    ref.listen<ChatState>(chatNotifierProvider(_config), (previous, next) {
      if (next.error != null) {
        Fluttertoast.showToast(
          msg: 'AI unavailable. Showing cached data.',
          backgroundColor: Colors.red.withAlpha(200),
          textColor: Colors.white,
        );
      }
    });

    final parsed = _parseResponse(chatState.response);
    final headline = parsed['headline'] ?? '';
    final reason = parsed['reason'] ?? '';

    return GestureDetector(
      onTap: () => setState(() => _expanded = !_expanded),
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF1250C4), Color(0xFF1A6BF5), Color(0xFF4A8FFF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primary.withAlpha(82),
              blurRadius: 24,
              offset: const Offset(0, 10),
              spreadRadius: -4,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            children: [
              // Decorative circles
              Positioned(
                top: -30,
                right: -20,
                child: Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(20),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              Positioned(
                bottom: -40,
                left: -10,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(13),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header row: AI tag + refresh button
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withAlpha(46),
                            borderRadius: BorderRadius.circular(100),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              AnimatedBuilder(
                                animation: _pulseAnimation,
                                builder: (_, __) => Transform.scale(
                                  scale: _pulseAnimation.value,
                                  child: Container(
                                    width: 6,
                                    height: 6,
                                    decoration: BoxDecoration(
                                      color: chatState.isLoading
                                          ? Colors.amber
                                          : const Color(0xFF7EFFB2),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                chatState.isLoading
                                    ? 'AI Thinking…'
                                    : 'AI Recommendation · Live',
                                style: GoogleFonts.dmSans(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white.withAlpha(230),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Spacer(),
                        // Refresh button
                        GestureDetector(
                          onTap: (chatState.isLoading || _weatherLoading)
                              ? null
                              : _initWithLiveWeather,
                          child: Container(
                            padding: const EdgeInsets.all(7),
                            decoration: BoxDecoration(
                              color: Colors.white.withAlpha(38),
                              shape: BoxShape.circle,
                            ),
                            child: (chatState.isLoading || _weatherLoading)
                                ? SizedBox(
                                    width: 14,
                                    height: 14,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white.withAlpha(200),
                                      ),
                                    ),
                                  )
                                : Icon(
                                    Icons.refresh_rounded,
                                    size: 16,
                                    color: Colors.white.withAlpha(200),
                                  ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Should you leave now?',
                      style: GoogleFonts.dmSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Colors.white.withAlpha(191),
                      ),
                    ),
                    const SizedBox(height: 6),
                    // Headline — shimmer when loading
                    chatState.isLoading
                        ? _buildShimmerHeadline()
                        : Text(
                            headline.isNotEmpty
                                ? headline
                                : 'Analysing conditions…',
                            style: GoogleFonts.dmSans(
                              fontSize: 26,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              letterSpacing: -0.5,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                    const SizedBox(height: 8),
                    // Reason
                    chatState.isLoading
                        ? _buildShimmerReason()
                        : Text(
                            reason.isNotEmpty
                                ? reason
                                : 'Fetching live traffic and weather data…',
                            style: GoogleFonts.dmSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w400,
                              color: Colors.white.withAlpha(204),
                              height: 1.5,
                            ),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                    const SizedBox(height: 16),
                    // Condition pills row
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildConditionPill(
                            Icons.directions_car_rounded,
                            'Traffic: $_trafficSeverity',
                            _trafficColor.withAlpha(80),
                          ),
                          const SizedBox(width: 8),
                          _buildConditionPill(
                            Icons.cloud_rounded,
                            _liveWeatherPillLabel,
                            Colors.white.withAlpha(38),
                          ),
                          if (_liveWeather?.hasAlert == true) ...[
                            const SizedBox(width: 8),
                            _buildConditionPill(
                              Icons.warning_amber_rounded,
                              'Weather alert',
                              Colors.orange.withAlpha(80),
                            ),
                          ],
                        ],
                      ),
                    ),
                    // Condition selector (expanded)
                    AnimatedCrossFade(
                      duration: const Duration(milliseconds: 280),
                      crossFadeState: _expanded
                          ? CrossFadeState.showSecond
                          : CrossFadeState.showFirst,
                      firstChild: const SizedBox(height: 0),
                      secondChild: _buildConditionSelector(),
                    ),
                    const SizedBox(height: 16),
                    // Action row
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () =>
                                Navigator.pushNamed(context, '/traffic-screen'),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Center(
                                child: Text(
                                  'View Route',
                                  style: GoogleFonts.dmSans(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.primary,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        GestureDetector(
                          onTap: () =>
                              Navigator.pushNamed(context, '/3d-map-screen'),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withAlpha(46),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: Colors.white.withAlpha(77),
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.map_outlined,
                                  size: 16,
                                  color: Colors.white,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Open Map',
                                  style: GoogleFonts.dmSans(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildShimmerHeadline() {
    return Container(
      height: 30,
      width: 200,
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(40),
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }

  Widget _buildShimmerReason() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 14,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white.withAlpha(30),
            borderRadius: BorderRadius.circular(6),
          ),
        ),
        const SizedBox(height: 6),
        Container(
          height: 14,
          width: 220,
          decoration: BoxDecoration(
            color: Colors.white.withAlpha(20),
            borderRadius: BorderRadius.circular(6),
          ),
        ),
      ],
    );
  }

  Widget _buildConditionPill(IconData icon, String label, Color bg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(100),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.white.withAlpha(230)),
          const SizedBox(width: 5),
          Text(
            label,
            style: GoogleFonts.dmSans(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: Colors.white.withAlpha(230),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConditionSelector() {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(31),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Adjust Conditions',
              style: GoogleFonts.dmSans(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Colors.white.withAlpha(180),
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 10),
            // Traffic severity selector
            Text(
              'Traffic Severity',
              style: GoogleFonts.dmSans(
                fontSize: 11,
                color: Colors.white.withAlpha(160),
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: ['Light', 'Moderate', 'Heavy'].map((level) {
                final selected = _trafficSeverity == level;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () {
                      setState(() => _trafficSeverity = level);
                      _fetchRecommendation();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: selected
                            ? Colors.white.withAlpha(60)
                            : Colors.white.withAlpha(20),
                        borderRadius: BorderRadius.circular(100),
                        border: selected
                            ? Border.all(color: Colors.white.withAlpha(120))
                            : null,
                      ),
                      child: Text(
                        level,
                        style: GoogleFonts.dmSans(
                          fontSize: 11,
                          fontWeight: selected
                              ? FontWeight.w700
                              : FontWeight.w400,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 10),
            // Weather selector
            Text(
              'Weather',
              style: GoogleFonts.dmSans(
                fontSize: 11,
                color: Colors.white.withAlpha(160),
              ),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: ['Clear', 'Rain expected', 'Heavy rain', 'Foggy'].map((
                w,
              ) {
                final selected = _weatherCondition == w;
                return GestureDetector(
                  onTap: () {
                    setState(() => _weatherCondition = w);
                    _fetchRecommendation();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: selected
                          ? Colors.white.withAlpha(60)
                          : Colors.white.withAlpha(20),
                      borderRadius: BorderRadius.circular(100),
                      border: selected
                          ? Border.all(color: Colors.white.withAlpha(120))
                          : null,
                    ),
                    child: Text(
                      w,
                      style: GoogleFonts.dmSans(
                        fontSize: 11,
                        fontWeight: selected
                            ? FontWeight.w700
                            : FontWeight.w400,
                        color: Colors.white,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
