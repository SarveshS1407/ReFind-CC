import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_theme.dart';
import '../../core/constants/categories.dart';
import '../../core/constants/campus_locations.dart';
import '../../core/models/item_model.dart';
import '../../providers/app_providers.dart';

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
  final DateTime _reportedDate = DateTime.now();

  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _rewardController = TextEditingController();
  final _verificationQuestionController = TextEditingController();

  bool _isSubmitting = false;
  bool _hasDraftLoaded = false;

  @override
  void initState() {
    super.initState();
    _selectedType = widget.initialType;
    _selectedCategory = CategoryConstants.allCategories.first.id;
    _selectedLocationId = CampusConstants.locations.first.id;

    // Attach auto-save listener
    _titleController.addListener(_autoSaveDraft);
    _descriptionController.addListener(_autoSaveDraft);
    _rewardController.addListener(_autoSaveDraft);
    _verificationQuestionController.addListener(_autoSaveDraft);

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
        _selectedCategory =
            draft['category'] ?? CategoryConstants.allCategories.first.id;
        _selectedLocationId =
            draft['locationId'] ?? CampusConstants.locations.first.id;
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
      'category': _selectedCategory,
      'locationId': _selectedLocationId,
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
      _hasDraftLoaded = false;
    });
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Draft discarded.')));
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

      final item = await ref
          .read(itemsListProvider.notifier)
          .reportItem(
            title: _titleController.text.trim(),
            description: _descriptionController.text.trim(),
            category: _selectedCategory,
            type: _selectedType,
            campusLocationId: campusLocation.id,
            campusLocationName: campusLocation.name,
            latitude: campusLocation.latitude,
            longitude: campusLocation.longitude,
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
                        color: AppTheme.primaryTeal.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppTheme.primaryTeal.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.history,
                            size: 18,
                            color: AppTheme.primaryTeal,
                          ),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              'Restored from your previous unfinished draft.',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.primaryTeal,
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: _discardDraft,
                            child: const Text(
                              'Discard',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppTheme.statusLost,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Segmented Lost / Found Switcher
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(12),
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
                                    ? Colors.white
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: _selectedType == ItemType.lost
                                    ? [
                                        BoxShadow(
                                          color: Colors.black.withValues(
                                            alpha: 0.05,
                                          ),
                                          blurRadius: 4,
                                        ),
                                      ]
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
                                        : Colors.grey.shade600,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'I Lost Something',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      color: _selectedType == ItemType.lost
                                          ? AppTheme.statusLost
                                          : Colors.grey.shade600,
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
                                    ? Colors.white
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: _selectedType == ItemType.found
                                    ? [
                                        BoxShadow(
                                          color: Colors.black.withValues(
                                            alpha: 0.05,
                                          ),
                                          blurRadius: 4,
                                        ),
                                      ]
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
                                        : Colors.grey.shade600,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'I Found Something',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      color: _selectedType == ItemType.found
                                          ? AppTheme.statusFound
                                          : Colors.grey.shade600,
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
                  const Text(
                    'Item Title *',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0F172A),
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
                  const Text(
                    'Category *',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedCategory,
                    decoration: const InputDecoration(),
                    items: CategoryConstants.allCategories.map((cat) {
                      return DropdownMenuItem(
                        value: cat.id,
                        child: Row(
                          children: [
                            Icon(
                              cat.icon,
                              size: 20,
                              color: AppTheme.primaryTeal,
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

                  // Campus Location Field
                  const Text(
                    'Approximate Campus Location *',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedLocationId,
                    decoration: const InputDecoration(),
                    items: CampusConstants.locations.map((loc) {
                      return DropdownMenuItem(
                        value: loc.id,
                        child: Text('${loc.name} (${loc.zone})'),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() => _selectedLocationId = val);
                        _autoSaveDraft();
                      }
                    },
                  ),
                  const SizedBox(height: 16),

                  // Description Field
                  const Text(
                    'Detailed Description *',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0F172A),
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
                          : const Color(0xFF64748B),
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
                    const Text(
                      'Reward for Safe Return (Optional)',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0F172A),
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
                        color: AppTheme.statusFoundBg.withValues(alpha: 0.5),
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
                          const Text(
                            'To prevent false claims, enter a question only the legitimate owner can answer. Claimants will submit their answers privately for you to review before handover.',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF334155),
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
