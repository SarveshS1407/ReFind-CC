import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../core/constants/app_theme.dart';
import '../../core/constants/categories.dart';
import '../../core/constants/campus_locations.dart';
import '../../core/models/item_model.dart';
import '../../providers/app_providers.dart';
import '../widgets/campus_map_picker.dart';

class ReportItemScreen extends ConsumerStatefulWidget {
  final ItemType initialType;

  const ReportItemScreen({super.key, this.initialType = ItemType.lost});

  @override
  ConsumerState<ReportItemScreen> createState() => _ReportItemScreenState();
}

class _ReportItemScreenState extends ConsumerState<ReportItemScreen> {
  final _formKey = GlobalKey<FormState>();

  late ItemType _selectedType;
  late String _selectedCategory;
  late String _selectedLocationId;
  late double _selectedLat;
  late double _selectedLng;
  String _specificLocationNotes = '';
  final DateTime _reportedDate = DateTime.now();

  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _rewardController = TextEditingController();
  final _verificationQuestionController = TextEditingController();
  final _secretAnswerNotesController = TextEditingController();

  bool _isSubmitting = false;
  bool _hasDraftLoaded = false;

  @override
  void initState() {
    super.initState();
    _selectedType = widget.initialType;
    _selectedCategory = CategoryConstants.allCategories.first.id;
    _selectedLocationId = CampusConstants.locations.first.id;
    final defaultLoc = CampusConstants.locations.first;
    _selectedLat = defaultLoc.latitude;
    _selectedLng = defaultLoc.longitude;

    // Attach auto-save listener
    _titleController.addListener(_autoSaveDraft);
    _descriptionController.addListener(_autoSaveDraft);
    _rewardController.addListener(_autoSaveDraft);
    _verificationQuestionController.addListener(_autoSaveDraft);
    _secretAnswerNotesController.addListener(_autoSaveDraft);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadDraftIfExists();
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _rewardController.dispose();
    _verificationQuestionController.dispose();
    _secretAnswerNotesController.dispose();
    super.dispose();
  }

  void _loadDraftIfExists() {
    final storage = ref.read(localStorageServiceProvider);
    final draft = storage.getReportDraft();
    if (draft != null && mounted) {
      setState(() {
        _titleController.text = draft['title'] ?? '';
        _descriptionController.text = draft['description'] ?? '';
        _rewardController.text = draft['reward'] ?? '';
        _verificationQuestionController.text =
            draft['verificationQuestion'] ?? '';
        _secretAnswerNotesController.text = draft['secretAnswer'] ?? '';
        _selectedCategory =
            draft['category'] ?? CategoryConstants.allCategories.first.id;
        _selectedLocationId =
            draft['locationId'] ?? CampusConstants.locations.first.id;
        _selectedLat = (draft['lat'] as num?)?.toDouble() ?? _selectedLat;
        _selectedLng = (draft['lng'] as num?)?.toDouble() ?? _selectedLng;
        _specificLocationNotes = draft['locationNotes'] ?? '';

        if (draft['type'] != null) {
          _selectedType = draft['type'] == 'lost'
              ? ItemType.lost
              : ItemType.found;
        }
        _hasDraftLoaded = true;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Interrupted submission draft restored.'),
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  void _autoSaveDraft() {
    if (_titleController.text.isEmpty && _descriptionController.text.isEmpty) {
      return;
    }
    final storage = ref.read(localStorageServiceProvider);
    storage.saveReportDraft({
      'title': _titleController.text,
      'description': _descriptionController.text,
      'reward': _rewardController.text,
      'verificationQuestion': _verificationQuestionController.text,
      'secretAnswer': _secretAnswerNotesController.text,
      'category': _selectedCategory,
      'locationId': _selectedLocationId,
      'lat': _selectedLat,
      'lng': _selectedLng,
      'locationNotes': _specificLocationNotes,
      'type': _selectedType.name,
    });
  }

  void _discardDraft() {
    final storage = ref.read(localStorageServiceProvider);
    storage.clearReportDraft();
    setState(() {
      _titleController.clear();
      _descriptionController.clear();
      _rewardController.clear();
      _verificationQuestionController.clear();
      _secretAnswerNotesController.clear();
      _specificLocationNotes = '';
      _hasDraftLoaded = false;
    });
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Draft discarded.')));
  }

  Future<void> _openMapPicker() async {
    final result = await CampusMapPickerDialog.show(
      context,
      initialLat: _selectedLat,
      initialLng: _selectedLng,
      initialLocationId: _selectedLocationId,
      initialDetails: _specificLocationNotes,
    );

    if (result != null && mounted) {
      setState(() {
        _selectedLat = result.latitude;
        _selectedLng = result.longitude;
        _selectedLocationId = result.locationId;
        _specificLocationNotes = result.specificDetails;
      });
      _autoSaveDraft();
    }
  }

  Future<void> _submitReport() async {
    if (!_formKey.currentState!.validate()) return;

    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in to report an item.')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final campusLocation = CampusConstants.findById(_selectedLocationId);
      final double? reward = _rewardController.text.isNotEmpty
          ? double.tryParse(_rewardController.text.trim())
          : null;

      final isFound = _selectedType == ItemType.found;
      final verificationQuestion = isFound
          ? _verificationQuestionController.text.trim()
          : null;

      // Append specific location notes to description if entered via map
      String finalDescription = _descriptionController.text.trim();
      if (_specificLocationNotes.isNotEmpty &&
          !finalDescription.contains(_specificLocationNotes)) {
        finalDescription += '\n[Exact Spot Notes: $_specificLocationNotes]';
      }

      final item = await ref
          .read(itemsListProvider.notifier)
          .reportItem(
            title: _titleController.text.trim(),
            description: finalDescription,
            category: _selectedCategory,
            type: _selectedType,
            campusLocationId: campusLocation.id,
            campusLocationName: campusLocation.name,
            latitude: _selectedLat,
            longitude: _selectedLng,
            reporterId: currentUser.id,
            reporterName: currentUser.displayName,
            reporterContact: currentUser.email,
            dateReported: _reportedDate,
            rewardAmount: reward,
            verificationQuestion: verificationQuestion,
          );

      // Clear draft on successful submission
      await ref.read(localStorageServiceProvider).clearReportDraft();

      if (mounted) {
        final isQueued = item.syncStatus == SyncStatus.queuedLocally;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: isQueued
                ? AppTheme.syncWarning
                : AppTheme.statusReturned,
            content: Text(
              isQueued
                  ? 'No network: Report saved in local outbox queue.'
                  : 'Report submitted successfully!',
            ),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppTheme.statusLost,
            content: Text('Failed to submit report: $e'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isOffline = ref.watch(offlineModeProvider);
    final isDark = AppTheme.isDark(context);
    final selectedLocation = CampusConstants.findById(_selectedLocationId);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _selectedType == ItemType.lost
              ? 'Report Lost Item'
              : 'Report Found Item',
        ),
        actions: [
          if (_hasDraftLoaded)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Discard Draft',
              onPressed: _discardDraft,
            ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680),
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Interrupted Draft Banner
                  if (_hasDraftLoaded)
                    Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryIndigo.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppTheme.primaryIndigo.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.history,
                            size: 18,
                            color: AppTheme.primaryIndigo,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Restored your unfinished draft from previous session.',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textPrimaryColor(context),
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: _discardDraft,
                            style: TextButton.styleFrom(
                              visualDensity: VisualDensity.compact,
                              padding: EdgeInsets.zero,
                            ),
                            child: const Text(
                              'Discard',
                              style: TextStyle(fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Segmented Lost / Found Switcher
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceSubtleColor(context),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.borderColor(context)),
                    ),
                    padding: const EdgeInsets.all(4),
                    child: Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              setState(() => _selectedType = ItemType.lost);
                              _autoSaveDraft();
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: _selectedType == ItemType.lost
                                    ? AppTheme.cardColor(context)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: _selectedType == ItemType.lost
                                    ? AppTheme.subtleCardShadow
                                    : null,
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.search,
                                    size: 18,
                                    color: _selectedType == ItemType.lost
                                        ? AppTheme.statusLost
                                        : AppTheme.textSecondaryColor(context),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'I Lost Something',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      color: _selectedType == ItemType.lost
                                          ? AppTheme.statusLost
                                          : AppTheme.textSecondaryColor(
                                              context,
                                            ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              setState(() => _selectedType = ItemType.found);
                              _autoSaveDraft();
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: _selectedType == ItemType.found
                                    ? AppTheme.cardColor(context)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: _selectedType == ItemType.found
                                    ? AppTheme.subtleCardShadow
                                    : null,
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.inventory_2_outlined,
                                    size: 18,
                                    color: _selectedType == ItemType.found
                                        ? AppTheme.statusFound
                                        : AppTheme.textSecondaryColor(context),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'I Found Something',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      color: _selectedType == ItemType.found
                                          ? AppTheme.statusFound
                                          : AppTheme.textSecondaryColor(
                                              context,
                                            ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Title Field
                  Text(
                    'Item Title *',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimaryColor(context),
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                      hintText: 'e.g. Apple AirPods Pro 2 in white case',
                    ),
                    validator: (val) {
                      if (val == null || val.trim().length < 4) {
                        return 'Please enter a descriptive title (at least 4 characters).';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Category Field
                  Text(
                    'Category *',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimaryColor(context),
                    ),
                  ),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedCategory,
                    decoration: const InputDecoration(),
                    dropdownColor: AppTheme.cardColor(context),
                    items: CategoryConstants.allCategories.map((cat) {
                      return DropdownMenuItem(
                        value: cat.id,
                        child: Row(
                          children: [
                            Icon(
                              cat.icon,
                              size: 20,
                              color: AppTheme.primaryIndigo,
                            ),
                            const SizedBox(width: 10),
                            Text(cat.name),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() => _selectedCategory = val);
                        _autoSaveDraft();
                      }
                    },
                  ),
                  const SizedBox(height: 16),

                  // --- INTERACTIVE CAMPUS MAP LOCATION SECTION ---
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Campus Location (VIT Vellore) *',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimaryColor(context),
                        ),
                      ),
                      TextButton.icon(
                        icon: const Icon(Icons.map_outlined, size: 16),
                        label: const Text(
                          'Open Interactive Map',
                          style: TextStyle(fontSize: 12.5),
                        ),
                        onPressed: _openMapPicker,
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),

                  // Location Card with Mini Map Preview
                  Container(
                    decoration: BoxDecoration(
                      color: AppTheme.cardColor(context),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.borderColor(context)),
                      boxShadow: AppTheme.subtleCardShadow,
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      children: [
                        // Mini Map Preview
                        SizedBox(
                          height: 140,
                          child: Stack(
                            children: [
                              FlutterMap(
                                key: ValueKey('$_selectedLat-$_selectedLng'),
                                options: MapOptions(
                                  initialCenter: LatLng(
                                    _selectedLat,
                                    _selectedLng,
                                  ),
                                  initialZoom: 16.5,
                                  interactionOptions: const InteractionOptions(
                                    flags: InteractiveFlag.none,
                                  ),
                                ),
                                children: [
                                  TileLayer(
                                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                    userAgentPackageName:
                                        'com.codechefvit.refind',
                                  ),
                                  MarkerLayer(
                                    markers: [
                                      Marker(
                                        point: LatLng(
                                          _selectedLat,
                                          _selectedLng,
                                        ),
                                        width: 32,
                                        height: 32,
                                        child: const Icon(
                                          Icons.location_on,
                                          color: AppTheme.statusLost,
                                          size: 30,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              Positioned(
                                bottom: 8,
                                right: 8,
                                child: ElevatedButton.icon(
                                  icon: const Icon(
                                    Icons.edit_location_alt,
                                    size: 15,
                                  ),
                                  label: const Text(
                                    'Adjust on Map',
                                    style: TextStyle(fontSize: 12),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 6,
                                    ),
                                    visualDensity: VisualDensity.compact,
                                  ),
                                  onPressed: _openMapPicker,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Building info & details
                        Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(
                                    Icons.apartment,
                                    size: 18,
                                    color: AppTheme.primaryIndigo,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      selectedLocation.name,
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: AppTheme.textPrimaryColor(
                                          context,
                                        ),
                                      ),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppTheme.primaryIndigo.withValues(
                                        alpha: 0.1,
                                      ),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      selectedLocation.zone,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: AppTheme.primaryIndigo,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              if (_specificLocationNotes.isNotEmpty) ...[
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.notes,
                                      size: 16,
                                      color: AppTheme.accentAmber,
                                    ),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        'Spot: $_specificLocationNotes',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: AppTheme.textSecondaryColor(
                                            context,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Description Field
                  Text(
                    'Detailed Description *',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimaryColor(context),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _selectedType == ItemType.found
                        ? 'Note: Do NOT write private identifying details here (e.g. phone lock screen photo, engraved initials). Use the verification challenge below instead!'
                        : 'Describe where and approximately when you last saw the item.',
                    style: TextStyle(
                      fontSize: 12,
                      color: _selectedType == ItemType.found
                          ? AppTheme.statusLost
                          : AppTheme.textMutedColor(context),
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: _descriptionController,
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText: _selectedType == ItemType.lost
                          ? 'Left on 4th floor lab table after afternoon session...'
                          : 'Found on bench outside Anna Auditorium...',
                    ),
                    validator: (val) {
                      if (val == null || val.trim().length < 10) {
                        return 'Please provide more details (at least 10 characters).';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Reward Field (For Lost items)
                  if (_selectedType == ItemType.lost) ...[
                    Text(
                      'Reward for Safe Return (Optional)',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimaryColor(context),
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _rewardController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        prefixText: '₹ ',
                        hintText: 'e.g. 200',
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Non-Public Ownership Verification Challenge (For Found items)
                  if (_selectedType == ItemType.found) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppTheme.surfaceDarkSubtle
                            : AppTheme.statusFoundBg.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppTheme.statusFound.withValues(alpha: 0.4),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(
                                Icons.security,
                                size: 18,
                                color: AppTheme.statusFound,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Ownership Verification Challenge *',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.statusFound,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'To prevent false claims, enter a question only the legitimate owner can answer. Claimants will submit their answers privately for you to review before handover.',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.textSecondaryColor(context),
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _verificationQuestionController,
                            decoration: const InputDecoration(
                              hintText: 'e.g. What sticker is on the lid? / What is the phone wallpaper?',
                            ),
                            validator: (val) {
                              if (_selectedType == ItemType.found &&
                                  (val == null || val.trim().length < 8)) {
                                return 'Please provide a non-public challenge question (at least 8 chars).';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 14),
                          // Private Reference Notes for Finder
                          Text(
                            'Private Reference Notes / Answer (Optional, Never Shown Publicly)',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textSecondaryColor(context),
                            ),
                          ),
                          const SizedBox(height: 4),
                          TextFormField(
                            controller: _secretAnswerNotesController,
                            decoration: const InputDecoration(
                              hintText: 'e.g. "Yellow Pikachu sticker on lower-left" (Kept private for comparison)',
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Offline Queue Notice
                  if (isOffline)
                    Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.syncWarningBg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppTheme.syncWarning.withValues(alpha: 0.4),
                        ),
                      ),
                      child: const Row(
                        children: [
                          Icon(
                            Icons.wifi_off,
                            size: 18,
                            color: AppTheme.syncWarning,
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Offline Mode is active. Your report will be safely saved in local storage and synced automatically once connection is restored.',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF92400E),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Submit Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _submitReport,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _selectedType == ItemType.lost
                            ? AppTheme.statusLost
                            : AppTheme.statusFound,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: _isSubmitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              _selectedType == ItemType.lost
                                  ? 'Publish Lost Item Report'
                                  : 'Publish Found Item Report',
                              style: const TextStyle(fontSize: 16),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
