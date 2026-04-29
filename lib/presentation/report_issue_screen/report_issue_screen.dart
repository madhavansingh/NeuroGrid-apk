import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import '../../providers/issues_provider.dart';
import '../../services/image_upload_service.dart';
import '../../theme/app_theme.dart';

class ReportIssueScreen extends ConsumerStatefulWidget {
  const ReportIssueScreen({super.key});
  @override
  ConsumerState<ReportIssueScreen> createState() => _ReportIssueScreenState();
}

class _ReportIssueScreenState extends ConsumerState<ReportIssueScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();

  String _selectedIssueType = 'garbage_overflow';
  Uint8List? _imageBytes;
  double? _latitude;
  double? _longitude;
  String _locationName = '';
  bool _isFetchingLocation = false;
  bool _isSubmitting = false;
  double _uploadProgress = 0;

  final List<Map<String, dynamic>> _issueTypes = [
    {'value': 'garbage_overflow', 'label': 'Garbage Overflow', 'icon': Icons.delete_sweep_rounded},
    {'value': 'missed_pickup', 'label': 'Missed Pickup', 'icon': Icons.local_shipping_outlined},
    {'value': 'illegal_dumping', 'label': 'Illegal Dumping', 'icon': Icons.warning_amber_rounded},
    {'value': 'road', 'label': 'Road Damage', 'icon': Icons.construction_rounded},
    {'value': 'water', 'label': 'Water Issue', 'icon': Icons.water_drop_outlined},
    {'value': 'streetlight', 'label': 'Streetlight', 'icon': Icons.lightbulb_outline_rounded},
    {'value': 'other', 'label': 'Other', 'icon': Icons.report_problem_outlined},
  ];

  @override
  void initState() {
    super.initState();
    _fetchLocation();
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _fetchLocation() async {
    setState(() => _isFetchingLocation = true);
    try {
      bool svc = await Geolocator.isLocationServiceEnabled();
      if (!svc) { _setDefault(); return; }
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) perm = await Geolocator.requestPermission();
      if (perm == LocationPermission.denied || perm == LocationPermission.deniedForever) {
        _setDefault(); return;
      }
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.medium, timeLimit: Duration(seconds: 10)),
      );
      setState(() {
        _latitude = pos.latitude; _longitude = pos.longitude;
        _locationName = _areaName(pos.latitude, pos.longitude);
        _isFetchingLocation = false;
      });
    } catch (_) { _setDefault(); }
  }

  void _setDefault() => setState(() {
    _locationName = 'Patel Nagar, Bhopal'; _latitude = 23.2354; _longitude = 77.4307;
    _isFetchingLocation = false;
  });

  String _areaName(double lat, double lng) {
    if (lat >= 23.22 && lat <= 23.26 && lng >= 77.41 && lng <= 77.45) return 'Patel Nagar, Bhopal';
    if (lat >= 23.28 && lat <= 23.32 && lng >= 77.40 && lng <= 77.45) return 'New Market, Bhopal';
    if (lat >= 23.24 && lat <= 23.28 && lng >= 77.42 && lng <= 77.46) return 'MP Nagar, Bhopal';
    if (lat >= 23.20 && lat <= 23.24 && lng >= 77.40 && lng <= 77.44) return 'Hoshangabad Road, Bhopal';
    return 'Bhopal, Madhya Pradesh';
  }

  Future<void> _pickSource(ImageSource source) async {
    try {
      final picked = await ImagePicker().pickImage(source: source, imageQuality: 75, maxWidth: 1400);
      if (picked != null) {
        final bytes = await picked.readAsBytes();
        setState(() { _imageBytes = bytes; });
      }
    } on PlatformException catch (e) {
      if (!mounted) return;
      _showPermissionDialog(source == ImageSource.camera ? 'Camera' : 'Photos');
      debugPrint('[ReportIssue] picker error: $e');
    }
  }

  void _showPermissionDialog(String name) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('$name Permission Needed', style: GoogleFonts.dmSans(fontWeight: FontWeight.w700)),
        content: Text('Please allow $name access in Settings to attach a photo.', style: GoogleFonts.dmSans(fontSize: 14)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(onPressed: () { Navigator.pop(context); /* openAppSettings() */ }, child: const Text('Open Settings')),
        ],
      ),
    );
  }

  void _showImagePicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 40, height: 4, decoration: BoxDecoration(color: const Color(0xFFE2E8F0), borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 20),
          Text('Attach Photo', style: GoogleFonts.dmSans(fontSize: 16, fontWeight: FontWeight.w700, color: const Color(0xFF0F172A))),
          const SizedBox(height: 4),
          Text('Document the issue clearly', style: GoogleFonts.dmSans(fontSize: 13, color: const Color(0xFF64748B))),
          const SizedBox(height: 20),
          Row(children: [
            Expanded(child: _SourceBtn(icon: Icons.camera_alt_rounded, label: 'Take Photo', onTap: () { Navigator.pop(context); _pickSource(ImageSource.camera); })),
            const SizedBox(width: 12),
            Expanded(child: _SourceBtn(icon: Icons.photo_library_rounded, label: 'Gallery', onTap: () { Navigator.pop(context); _pickSource(ImageSource.gallery); })),
          ]),
          const SizedBox(height: 8),
        ]),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _isSubmitting = true; _uploadProgress = 0; });

    // Image is optional — try to upload if selected, continue without on failure
    String? imageUrl;
    if (_imageBytes != null) {
      imageUrl = await ImageUploadService.instance.uploadImage(
        _imageBytes!,
        onProgress: (p) => setState(() => _uploadProgress = p),
      );
      if (imageUrl == null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Photo upload failed — submitting without image', style: GoogleFonts.dmSans()),
          backgroundColor: AppTheme.warning, behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));
      }
    }

    final typeLabel = _issueTypes.firstWhere((t) => t['value'] == _selectedIssueType)['label'] as String;

    try {
      final issue = await ref.read(issuesProvider.notifier).submitIssue(
        title: typeLabel,
        description: _descriptionController.text.trim().isEmpty
            ? typeLabel : _descriptionController.text.trim(),
        issueType: _selectedIssueType,
        imageUrl: imageUrl,
        latitude: _latitude,
        longitude: _longitude,
        locationName: _locationName.isNotEmpty ? _locationName : null,
      );

      if (!mounted) return;
      setState(() => _isSubmitting = false);

      if (issue != null) {
        await _showSuccessModal();
        if (mounted) Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Submission failed — no data returned from server.', style: GoogleFonts.dmSans()),
          backgroundColor: AppTheme.error, behavior: SnackBarBehavior.floating,
          action: SnackBarAction(label: 'Retry', textColor: Colors.white, onPressed: _submit),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));
      }
    } catch (e) {
      // Show the actual server error so we can diagnose the real problem
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      final msg = e.toString().replaceAll('Exception: ', '');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Error: $msg', style: GoogleFonts.dmSans(fontSize: 13)),
        backgroundColor: AppTheme.error,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 6),
        action: SnackBarAction(label: 'Retry', textColor: Colors.white, onPressed: _submit),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
    }
  }

  Future<void> _showSuccessModal() async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const _SuccessDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(children: [
          _buildHeader(),
          Expanded(child: Form(
            key: _formKey,
            child: ListView(padding: const EdgeInsets.fromLTRB(20, 0, 20, 100), children: [
              const SizedBox(height: 16),
              _buildLocationCard(),
              const SizedBox(height: 16),
              _buildTypeSelector(),
              const SizedBox(height: 16),
              _buildPhotoSection(),
              const SizedBox(height: 16),
              _buildDescriptionField(),
              const SizedBox(height: 24),
              _buildSubmitBtn(),
            ]),
          )),
        ]),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      decoration: const BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Color(0x08000000), blurRadius: 8, offset: Offset(0, 2))]),
      child: Row(children: [
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(width: 40, height: 40, decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.arrow_back_ios_new_rounded, size: 16, color: Color(0xFF0F172A)),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Report Issue', style: GoogleFonts.dmSans(fontSize: 18, fontWeight: FontWeight.w700, color: const Color(0xFF0F172A))),
          Text('Help improve your city', style: GoogleFonts.dmSans(fontSize: 12, color: const Color(0xFF64748B))),
        ])),
        Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(10)),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.verified_rounded, size: 13, color: Color(0xFF1A6BF5)),
            const SizedBox(width: 4),
            Text('Live', style: GoogleFonts.dmSans(fontSize: 11, fontWeight: FontWeight.w600, color: const Color(0xFF1A6BF5))),
          ]),
        ),
      ]),
    );
  }

  Widget _buildLocationCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(8), blurRadius: 10, offset: const Offset(0, 3))]),
      child: Row(children: [
        Container(width: 42, height: 42, decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(12)),
          child: const Icon(Icons.location_on_rounded, color: Color(0xFF1A6BF5), size: 20)),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Your Location', style: GoogleFonts.dmSans(fontSize: 11, color: const Color(0xFF64748B))),
          const SizedBox(height: 2),
          _isFetchingLocation
              ? Row(children: [
                  SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primary)),
                  const SizedBox(width: 8),
                  Text('Detecting…', style: GoogleFonts.dmSans(fontSize: 14, color: const Color(0xFF64748B))),
                ])
              : Text(_locationName.isNotEmpty ? _locationName : 'Bhopal, Madhya Pradesh',
                  style: GoogleFonts.dmSans(fontSize: 14, fontWeight: FontWeight.w600, color: const Color(0xFF0F172A))),
        ])),
        GestureDetector(onTap: _fetchLocation, child: const Icon(Icons.refresh_rounded, size: 18, color: Color(0xFF1A6BF5))),
      ]),
    );
  }

  Widget _buildTypeSelector() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Issue Type', style: GoogleFonts.dmSans(fontSize: 14, fontWeight: FontWeight.w700, color: const Color(0xFF0F172A))),
      const SizedBox(height: 10),
      Wrap(spacing: 8, runSpacing: 8, children: _issueTypes.map((t) {
        final selected = _selectedIssueType == t['value'];
        return GestureDetector(
          onTap: () => setState(() => _selectedIssueType = t['value'] as String),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: selected ? const Color(0xFF1A6BF5) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: selected ? const Color(0xFF1A6BF5) : const Color(0xFFE2E8F0)),
              boxShadow: selected ? [BoxShadow(color: const Color(0xFF1A6BF5).withAlpha(50), blurRadius: 8, offset: const Offset(0, 3))] : [],
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(t['icon'] as IconData, size: 14, color: selected ? Colors.white : const Color(0xFF64748B)),
              const SizedBox(width: 6),
              Text(t['label'] as String, style: GoogleFonts.dmSans(fontSize: 12, fontWeight: FontWeight.w600,
                color: selected ? Colors.white : const Color(0xFF0F172A))),
            ]),
          ),
        );
      }).toList()),
    ]);
  }

  Widget _buildPhotoSection() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Text('Photo Evidence', style: GoogleFonts.dmSans(fontSize: 14, fontWeight: FontWeight.w700, color: const Color(0xFF0F172A))),
        const SizedBox(width: 6),
        Container(padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
          decoration: BoxDecoration(color: const Color(0xFFDCFCE7), borderRadius: BorderRadius.circular(6)),
          child: Text('Optional', style: GoogleFonts.dmSans(fontSize: 10, fontWeight: FontWeight.w600, color: const Color(0xFF16A34A)))),
      ]),
      const SizedBox(height: 10),
      GestureDetector(
        onTap: _showImagePicker,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: _imageBytes != null ? 180 : 120,
          width: double.infinity,
          decoration: BoxDecoration(
            color: _imageBytes != null ? Colors.transparent : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _imageBytes != null ? Colors.transparent : const Color(0xFFCBD5E1), width: 1.5),
            boxShadow: [BoxShadow(color: Colors.black.withAlpha(8), blurRadius: 10, offset: const Offset(0, 3))],
          ),
          child: _imageBytes != null
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Stack(fit: StackFit.expand, children: [
                    Image.memory(_imageBytes!, fit: BoxFit.cover),
                    Positioned(top: 8, right: 8, child: GestureDetector(
                      onTap: () => setState(() { _imageBytes = null; }),
                      child: Container(width: 30, height: 30, decoration: BoxDecoration(color: Colors.black.withAlpha(150), shape: BoxShape.circle),
                        child: const Icon(Icons.close_rounded, size: 16, color: Colors.white)),
                    )),
                    Positioned(bottom: 8, right: 8, child: GestureDetector(
                      onTap: _showImagePicker,
                      child: Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(color: Colors.black.withAlpha(150), borderRadius: BorderRadius.circular(8)),
                        child: Text('Change', style: GoogleFonts.dmSans(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w600))),
                    )),
                  ]),
                )
              : Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Container(width: 44, height: 44, decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(12)),
                    child: const Icon(Icons.add_a_photo_rounded, color: Color(0xFF1A6BF5), size: 22)),
                  const SizedBox(height: 8),
                  Text('Tap to add photo', style: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF1A6BF5))),
                  const SizedBox(height: 2),
                  Text('Camera or gallery', style: GoogleFonts.dmSans(fontSize: 11, color: const Color(0xFF94A3B8))),
                ]),
        ),
      ),
    ]);
  }

  Widget _buildDescriptionField() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Description (Optional)', style: GoogleFonts.dmSans(fontSize: 14, fontWeight: FontWeight.w700, color: const Color(0xFF0F172A))),
      const SizedBox(height: 10),
      TextFormField(
        controller: _descriptionController,
        maxLines: 3, maxLength: 300,
        style: GoogleFonts.dmSans(fontSize: 14, color: const Color(0xFF0F172A)),
        decoration: InputDecoration(
          hintText: 'Describe the issue in more detail…',
          hintStyle: GoogleFonts.dmSans(fontSize: 13, color: const Color(0xFF94A3B8)),
          counterStyle: GoogleFonts.dmSans(fontSize: 11, color: const Color(0xFF94A3B8)),
          filled: true, fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFF1A6BF5), width: 1.5)),
          contentPadding: const EdgeInsets.all(14),
        ),
      ),
    ]);
  }

  Widget _buildSubmitBtn() {
    return Column(children: [
      if (_isSubmitting && _uploadProgress > 0 && _uploadProgress < 1) ...[
        ClipRRect(borderRadius: BorderRadius.circular(8), child: LinearProgressIndicator(
          value: _uploadProgress, backgroundColor: const Color(0xFFE2E8F0),
          color: const Color(0xFF1A6BF5), minHeight: 4)),
        const SizedBox(height: 8),
        Text('Uploading photo… ${(_uploadProgress * 100).toInt()}%',
          style: GoogleFonts.dmSans(fontSize: 12, color: const Color(0xFF64748B))),
        const SizedBox(height: 12),
      ],
      SizedBox(
        width: double.infinity, height: 52,
        child: ElevatedButton(
          onPressed: _isSubmitting ? null : _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1A6BF5),
            disabledBackgroundColor: const Color(0xFF93B4FB),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            elevation: 0,
          ),
          child: _isSubmitting
              ? Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)),
                  const SizedBox(width: 10),
                  Text(_uploadProgress > 0 && _uploadProgress < 1 ? 'Uploading…' : 'Submitting…',
                    style: GoogleFonts.dmSans(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white)),
                ])
              : Text('Submit Report', style: GoogleFonts.dmSans(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
        ),
      ),
    ]);
  }
}

// ── Source picker button ────────────────────────────────────────────────────────

class _SourceBtn extends StatelessWidget {
  final IconData icon; final String label; final VoidCallback onTap;
  const _SourceBtn({required this.icon, required this.label, required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(14)),
      child: Column(children: [
        Icon(icon, color: const Color(0xFF1A6BF5), size: 26),
        const SizedBox(height: 6),
        Text(label, style: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF0F172A))),
      ]),
    ),
  );
}

// ── Success dialog ─────────────────────────────────────────────────────────────

class _SuccessDialog extends StatefulWidget {
  const _SuccessDialog();
  @override
  State<_SuccessDialog> createState() => _SuccessDialogState();
}

class _SuccessDialogState extends State<_SuccessDialog> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _scale = CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut);
    _fade = CurvedAnimation(parent: _ctrl, curve: const Interval(0, 0.4));
    _ctrl.forward();
    Future.delayed(const Duration(seconds: 3), () { if (mounted) Navigator.pop(context); });
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            ScaleTransition(scale: _scale, child: Container(
              width: 80, height: 80,
              decoration: BoxDecoration(color: const Color(0xFFDCFCE7), shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: const Color(0xFF16A34A).withAlpha(60), blurRadius: 20, spreadRadius: 4)]),
              child: const Icon(Icons.check_rounded, size: 44, color: Color(0xFF16A34A)),
            )),
            const SizedBox(height: 20),
            Text('Issue Reported!', style: GoogleFonts.dmSans(fontSize: 20, fontWeight: FontWeight.w800, color: const Color(0xFF0F172A))),
            const SizedBox(height: 8),
            Text('Your report has been submitted\nand is now being reviewed.',
              textAlign: TextAlign.center,
              style: GoogleFonts.dmSans(fontSize: 14, color: const Color(0xFF64748B), height: 1.5)),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(12)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.track_changes_rounded, size: 16, color: Color(0xFF1A6BF5)),
                const SizedBox(width: 6),
                Text('Track in Civic Issues tab', style: GoogleFonts.dmSans(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF1A6BF5))),
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}
