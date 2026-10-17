import 'package:flutter/material.dart';

import '../../core/constants/app_theme.dart';

class HelpScreen extends StatefulWidget {
  final bool showBackButton;
  const HelpScreen({super.key, this.showBackButton = true});

  @override
  State<HelpScreen> createState() => _HelpScreenState();
}

class _HelpScreenState extends State<HelpScreen> {
  final _searchController = TextEditingController();
  String _searchFilter = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = AppBreakpoints.isDesktop(context);
    final maxWidth = AppBreakpoints.desktopContentMaxWidth;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Help Center & User Guide'),
        automaticallyImplyLeading: widget.showBackButton,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: ListView(
            padding: EdgeInsets.symmetric(
              horizontal: isDesktop ? 32 : 16,
              vertical: 20,
            ),
            children: [
              // Header Banner
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppTheme.primaryTeal, AppTheme.primaryTealLight],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: AppTheme.subtleCardShadow,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.help_outline,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 14),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Finders Keepers? Guide',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.3,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'How to report, discover, and securely reclaim campus items',
                                style: TextStyle(
                                  color: Color(0xFFE2E8F0),
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    // Quick Search Inside Help
                    TextField(
                      controller: _searchController,
                      style: const TextStyle(color: Colors.black),
                      decoration: InputDecoration(
                        hintText: 'Search guide (e.g. OTP, handover, offline, draft)...',
                        hintStyle: const TextStyle(color: Color(0xFF64748B)),
                        prefixIcon: const Icon(
                          Icons.search,
                          color: Color(0xFF64748B),
                        ),
                        suffixIcon: _searchFilter.isNotEmpty
                            ? IconButton(
                                icon: const Icon(
                                  Icons.clear,
                                  color: Color(0xFF64748B),
                                ),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() => _searchFilter = '');
                                },
                              )
                            : null,
                        fillColor: Colors.white,
                        filled: true,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onChanged: (val) {
                        setState(
                          () => _searchFilter = val.trim().toLowerCase(),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Filtered / Full Content Sections
              ..._buildHelpSections(),

              const SizedBox(height: 32),
              // Support Notice
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceWhite,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.cardBorder),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.security,
                      color: AppTheme.primaryTeal,
                      size: 28,
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Campus Security & Oversight Desk',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'For sensitive official documents or high-value items, visit the Central Security Desk on Ground Floor of SJT or TT.',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildHelpSections() {
    final sections = [
      _HelpItem(
        icon: Icons.travel_explore,
        title: 'A. Welcome to Finders Keepers?',
        content: 'Finders Keepers? is a student-first university lost-and-found mobile and web platform. It eliminates the chaos of crowded WhatsApp groups and bulletin boards by offering a structured, privacy-preserving workflow to connect students who lose belongings with students who find them.',
      ),
      _HelpItem(
        icon: Icons.search,
        title: 'B. How to Report a Lost Item',
        content:
            '1. Sign in to your campus account.\n'
            '2. Tap "Report Item" from the main feed or navigation bar.\n'
            '3. Select "I Lost an Item".\n'
            '4. Provide an accurate title, detailed description, and category.\n'
            '5. Select the approximate campus landmark where you last saw the item (e.g. Silver Jubilee Tower, Central Library).\n'
            '6. Important: Do not publicly disclose secret markings or serial numbers in the description; keep those private to test claimants.',
      ),
      _HelpItem(
        icon: Icons.add_task,
        title: 'C. How to Report a Found Item',
        content:
            '1. Sign in and open the report form.\n'
            '2. Select "I Found an Item".\n'
            '3. Accurately describe the item type and category.\n'
            '4. Choose the approximate landmark where you recovered it.\n'
            '5. Configure a Private Challenge Question (e.g. "What sticker is on the back?" or "What is the lock screen picture?").\n'
            '6. Submit the report. You will receive notifications when claimants submit answers for review.',
      ),
      _HelpItem(
        icon: Icons.assignment_turned_in,
        title: 'D. How to Claim an Item',
        content:
            '1. Browse the feed or map to find your missing item.\n'
            '2. Open the listing and tap "Submit Ownership Claim".\n'
            '3. Enter your private proof description (e.g. exact scratches, purchase date, or unique identifiers).\n'
            '4. Answer the finder\'s private challenge question.\n'
            '5. Submit your claim. Submitting does not automatically prove ownership; the finder will review your responses in private.',
      ),
      _HelpItem(
        icon: Icons.lock_outline,
        title: 'E. Ownership Verification & 6-Digit Handover OTP',
        content:
            'To prevent false claims and claim-sniping, Finders Keepers? implements a 3-tier Zero-Knowledge verification workflow:\n\n'
            '• Tier 1 (Private Challenge): Challenge answers are stored in isolated subcollections and never exposed in the public feed.\n'
            '• Tier 2 (Review & Approval): The finder evaluates submitted evidence in their private dashboard. If valid, they approve the claim.\n'
            '• Tier 3 (Cryptographic OTP): Upon approval, the system generates a dynamic 6-digit OTP visible only to the verified claimant. The database only stores a salted SHA-256 hash. When meeting in person, the finder inputs this 6-digit code, which mathematically confirms the handover before transitioning the item to "Returned".',
      ),
      _HelpItem(
        icon: Icons.timeline,
        title: 'F. Tracking Item Lifecycle Status',
        content:
            '• Lost: An owner is actively searching for this item.\n'
            '• Found: A finder has recovered the item and is awaiting claims.\n'
            '• Claimed: A claim has been approved by the finder; the 6-digit handover OTP is active for in-person exchange.\n'
            '• Returned: Handover OTP verified in person; item successfully reunited with owner and archived.',
      ),
      _HelpItem(
        icon: Icons.location_on_outlined,
        title: 'G. Location Privacy & Campus Geofencing',
        content: 'To protect student safety and prevent malicious recovery attempts, public item listings only show approximate campus landmarks (e.g., SJT, Technology Tower, Food Mall, Men\'s Hostels). Exact room numbers, seat rows, or specific locker positions remain confidential until confirmed by the finder.',
      ),
      _HelpItem(
        icon: Icons.wifi_off_outlined,
        title: 'H. Offline Mode & Synchronization',
        content:
            '• Drafts: The report form continuously auto-saves your progress locally. If your device restarts or connectivity drops, your draft can be recovered.\n'
            '• Queued Submissions: Submissions created without internet connectivity are queued in an offline Outbox with an amber "Queued Locally" badge.\n'
            '• Sync Confirmation: Once connectivity resumes, the outbox auto-syncs with exponential backoff and updates the badge to green "Synced".',
      ),
      _HelpItem(
        icon: Icons.health_and_safety_outlined,
        title: 'I. Campus Safety & Responsible Handover',
        content:
            '• Always arrange in-person handovers in well-lit, public campus hubs (e.g., SJT Ground Floor, Food Mall Gazebo, Central Library Foyer).\n'
            '• Do not disclose account passwords, private challenge answers, or OTPs over unverified messaging.\n'
            '• For high-value electronics (laptops, expensive jewelry) or official documents (passports, national ID cards), surrender the item to Campus Security.',
      ),
      _HelpItem(
        icon: Icons.question_answer_outlined,
        title: 'J. Frequently Asked Questions (FAQs)',
        content:
            'Q: What if someone answers my challenge question incorrectly?\n'
            'A: You can reject the claim and provide a short rejection reason. The item remains available for valid claims.\n\n'
            'Q: How long does an approved claim remain active?\n'
            'A: We recommend completing physical handover within 48 hours. If the claimant does not collect the item, the claim can be cancelled.\n\n'
            'Q: Why is my report marked "Queued Locally"?\n'
            'A: Your device is currently offline or offline simulation is enabled. As soon as you are reconnected, it will synchronize automatically.\n\n'
            'Q: Can I edit an item after submitting?\n'
            'A: Yes, the original reporter can update descriptions or mark an item resolved from the My Activity tab.',
      ),
    ];

    final filtered = _searchFilter.isEmpty
        ? sections
        : sections.where((item) {
            return item.title.toLowerCase().contains(_searchFilter) ||
                item.content.toLowerCase().contains(_searchFilter);
          }).toList();

    if (filtered.isEmpty) {
      return [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 40),
          child: Column(
            children: [
              const Icon(Icons.search_off, size: 48, color: AppTheme.textMuted),
              const SizedBox(height: 12),
              Text(
                'No matches found for "$_searchFilter"',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ];
    }

    return filtered.map((item) {
      return Card(
        margin: const EdgeInsets.only(bottom: 14),
        child: Theme(
          data: ThemeData().copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            initiallyExpanded: _searchFilter.isNotEmpty,
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.primaryTeal.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(item.icon, color: AppTheme.primaryTeal, size: 20),
            ),
            title: Text(
              item.title,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 15,
                color: AppTheme.textPrimary,
              ),
            ),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 18),
                child: Text(
                  item.content,
                  style: const TextStyle(
                    fontSize: 13.5,
                    color: AppTheme.textSecondary,
                    height: 1.55,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }).toList();
  }
}

class _HelpItem {
  final IconData icon;
  final String title;
  final String content;

  const _HelpItem({
    required this.icon,
    required this.title,
    required this.content,
  });
}
