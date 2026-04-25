import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../../theme/app_theme.dart';
import '../../services/civic_issues_service.dart';

class ReportIssueScreen extends StatefulWidget {
  const ReportIssueScreen({super.key});

  @override
  State<ReportIssueScreen> createState() => _ReportIssueScreenState();
}

class _ReportIssueScreenState extends State<ReportIssueScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  String _selectedIssueType = 'other';
  XFile? _pickedImage;
  Uint8List? _imageBytes;
  double? _latitude;
  double? _longitude;
  String _locationName = '';
  bool _isFetchingLocation = false;
  bool _isSubmitting = false;

  final List<Map<String, dynamic>> _issueTypes = [
    {'value': 'road', 'label': 'Road', 'icon': Icons.construction_rounded},
    {'value': 'water', 'label': 'Water', 'icon': Icons.water_drop_outlined},
    {
      'value': 'electricity',
      'label': 'Electricity',
      'icon': Icons.bolt_rounded,
    },
    {
      'value': 'sanitation',
      'label': 'Sanitation',
      'icon': Icons.delete_outline_rounded,
    },
    {
      'value': 'streetlight',
      'label': 'Streetlight',
      'icon': Icons.lightbulb_outline_rounded,
    },
    {'value': 'other', 'label': 'Other', 'icon': Icons.report_problem_outlined},
  ];

  @override
  void initState() {
    super.initState();
    _fetchLocation();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _fetchLocation() async {
    setState(() => _isFetchingLocation = true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _locationName = 'Bhopal, Madhya Pradesh';
          _latitude = 23.2599;
          _longitude = 77.4126;
          _isFetchingLocation = false;
        });
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        setState(() {
          _locationName = 'Bhopal, Madhya Pradesh';
          _latitude = 23.2599;
          _longitude = 77.4126;
          _isFetchingLocation = false;
        });
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 10),
        ),
      );

      // Use Bhopal area location names based on coordinates
      final locationName = _getBhopalAreaName(
        position.latitude,
        position.longitude,
      );

      setState(() {
        _latitude = position.latitude;
        _longitude = position.longitude;
        _locationName = locationName;
        _isFetchingLocation = false;
      });
    } catch (e) {
      setState(() {
        _locationName = 'Bhopal, Madhya Pradesh';
        _latitude = 23.2599;
        _longitude = 77.4126;
        _isFetchingLocation = false;
      });
    }
  }

  String _getBhopalAreaName(double lat, double lng) {
    // Map coordinates to Bhopal area names
    if (lat >= 23.28 && lat <= 23.32 && lng >= 77.40 && lng <= 77.45) {
      return 'New Market, Bhopal';
    } else if (lat >= 23.24 && lat <= 23.28 && lng >= 77.42 && lng <= 77.46) {
      return 'MP Nagar, Bhopal';
    } else if (lat >= 23.20 && lat <= 23.24 && lng >= 77.40 && lng <= 77.44) {
      return 'Hoshangabad Road, Bhopal';
    } else if (lat >= 23.30 && lat <= 23.34 && lng >= 77.38 && lng <= 77.42) {
      return 'Shyamla Hills, Bhopal';
    } else if (lat >= 23.22 && lat <= 23.26 && lng >= 77.44 && lng <= 77.48) {
      return 'Arera Colony, Bhopal';
    } else {
      return 'Bhopal, Madhya Pradesh';
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
      maxWidth: 1200,
    );
    if (picked != null) {
      final bytes = await picked.readAsBytes();
      setState(() {
        _pickedImage = picked;
        _imageBytes = bytes;
      });
    }
  }

  Future<void> _captureImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 70,
      maxWidth: 1200,
    );
    if (picked != null) {
      final bytes = await picked.readAsBytes();
      setState(() {
        _pickedImage = picked;
        _imageBytes = bytes;
      });
    }
  }

  Future<void> _submitIssue() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      String? imageUrl;

      // Upload image if selected
      if (_pickedImage != null && _imageBytes != null) {
        if (kIsWeb) {
          imageUrl = await CivicIssuesService.instance.uploadImage(
            _imageBytes!,
          );
        } else {
          imageUrl = await CivicIssuesService.instance.uploadImage(
            File(_pickedImage!.path),
          );
        }
      }

      final issue = await CivicIssuesService.instance.submitIssue(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        issueType: _selectedIssueType,
        imageUrl: imageUrl,
        latitude: _latitude,
        longitude: _longitude,
        locationName: _locationName.isNotEmpty ? _locationName : null,
      );

      if (issue != null && mounted) {
        Fluttertoast.showToast(
          msg: 'Issue reported successfully!',
          backgroundColor: AppTheme.success,
          textColor: Colors.white,
        );
        Navigator.pop(context);
      } else {
        Fluttertoast.showToast(
          msg: 'Failed to submit. Please try again.',
          backgroundColor: AppTheme.error,
          textColor: Colors.white,
        );
      }
    } catch (e) {
      Fluttertoast.showToast(
        msg: 'Something went wrong. Please try again.',
        backgroundColor: AppTheme.error,
        textColor: Colors.white,
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionLabel('Issue Type'),
                      const SizedBox(height: 10),
                      _buildIssueTypeSelector(),
                      const SizedBox(height: 20),
                      _buildSectionLabel('Title *'),
                      const SizedBox(height: 8),
                      _buildTitleField(),
                      const SizedBox(height: 20),
                      _buildSectionLabel('Description'),
                      const SizedBox(height: 8),
                      _buildDescriptionField(),
                      const SizedBox(height: 20),
                      _buildSectionLabel('Photo'),
                      const SizedBox(height: 10),
                      _buildImagePicker(),
                      const SizedBox(height: 20),
                      _buildSectionLabel('Location'),
                      const SizedBox(height: 10),
                      _buildLocationCard(),
                      const SizedBox(height: 32),
                      _buildSubmitButton(),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(10),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 16,
                color: AppTheme.textPrimary,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'Report an Issue',
            style: GoogleFonts.dmSans(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Text(
      label,
      style: GoogleFonts.dmSans(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: AppTheme.textSecondary,
      ),
    );
  }

  Widget _buildIssueTypeSelector() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _issueTypes.map((type) {
        final isSelected = _selectedIssueType == type['value'];
        return GestureDetector(
          onTap: () => setState(() => _selectedIssueType = type['value']),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected ? AppTheme.primary : AppTheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? AppTheme.primary : AppTheme.outline,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  type['icon'] as IconData,
                  size: 15,
                  color: isSelected ? Colors.white : AppTheme.textSecondary,
                ),
                const SizedBox(width: 6),
                Text(
                  type['label'] as String,
                  style: GoogleFonts.dmSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? Colors.white : AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTitleField() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(6),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextFormField(
        controller: _titleController,
        style: GoogleFonts.dmSans(fontSize: 14, color: AppTheme.textPrimary),
        decoration: InputDecoration(
          hintText: 'e.g. Pothole on main road',
          hintStyle: GoogleFonts.dmSans(
            fontSize: 14,
            color: AppTheme.textMuted,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: AppTheme.surface,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
        validator: (v) =>
            (v == null || v.trim().isEmpty) ? 'Title is required' : null,
      ),
    );
  }

  Widget _buildDescriptionField() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(6),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextFormField(
        controller: _descriptionController,
        maxLines: 3,
        style: GoogleFonts.dmSans(fontSize: 14, color: AppTheme.textPrimary),
        decoration: InputDecoration(
          hintText: 'Describe the issue in detail...',
          hintStyle: GoogleFonts.dmSans(
            fontSize: 14,
            color: AppTheme.textMuted,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: AppTheme.surface,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildImagePicker() {
    return Column(
      children: [
        if (_imageBytes != null)
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Image.memory(
                  _imageBytes!,
                  height: 180,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  semanticLabel: 'Selected issue photo',
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: GestureDetector(
                  onTap: () => setState(() {
                    _pickedImage = null;
                    _imageBytes = null;
                  }),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.black.withAlpha(140),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close_rounded,
                      size: 16,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          )
        else
          Row(
            children: [
              Expanded(
                child: _buildImageButton(
                  icon: Icons.photo_library_outlined,
                  label: 'Gallery',
                  onTap: _pickImage,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildImageButton(
                  icon: Icons.camera_alt_outlined,
                  label: 'Camera',
                  onTap: _captureImage,
                ),
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildImageButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 80,
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.outline, style: BorderStyle.solid),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 24, color: AppTheme.primary),
            const SizedBox(height: 6),
            Text(
              label,
              style: GoogleFonts.dmSans(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(6),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppTheme.primaryLight,
              borderRadius: BorderRadius.circular(10),
            ),
            child: _isFetchingLocation
                ? const Padding(
                    padding: EdgeInsets.all(10),
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppTheme.primary,
                    ),
                  )
                : const Icon(
                    Icons.location_on_rounded,
                    size: 20,
                    color: AppTheme.primary,
                  ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isFetchingLocation
                      ? 'Fetching location...'
                      : _locationName.isNotEmpty
                      ? _locationName
                      : 'Location unavailable',
                  style: GoogleFonts.dmSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
                if (_latitude != null && _longitude != null)
                  Text(
                    '${_latitude!.toStringAsFixed(4)}, ${_longitude!.toStringAsFixed(4)}',
                    style: GoogleFonts.dmSans(
                      fontSize: 11,
                      color: AppTheme.textMuted,
                    ),
                  ),
              ],
            ),
          ),
          GestureDetector(
            onTap: _fetchLocation,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.primaryLight,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Refresh',
                style: GoogleFonts.dmSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: _isSubmitting ? null : _submitIssue,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primary,
          disabledBackgroundColor: AppTheme.primaryMuted,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
        ),
        child: _isSubmitting
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Colors.white,
                ),
              )
            : Text(
                'Submit Report',
                style: GoogleFonts.dmSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
      ),
    );
  }
}
