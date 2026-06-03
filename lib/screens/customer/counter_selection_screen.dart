import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/business_model.dart';
import '../../providers/queue_provider.dart';
import 'live_tracker_screen.dart';

/// Screen allowing customers to browse and select a service counter
/// to join the queue.
class CounterSelectionScreen extends StatefulWidget {
  const CounterSelectionScreen({super.key});

  @override
  State<CounterSelectionScreen> createState() => _CounterSelectionScreenState();
}

class _CounterSelectionScreenState extends State<CounterSelectionScreen> {
  // A mock list of available business counters with diverse configuration settings.
  final List<BusinessModel> _counters = const [
    BusinessModel(
      businessId: 'biz_hq_001',
      counterName: 'Billing Counter',
      activeCounters: 2,
      averageServiceTime: 4.5,
    ),
    BusinessModel(
      businessId: 'biz_hq_001',
      counterName: 'Technical Support Desk',
      activeCounters: 1,
      averageServiceTime: 12.0,
    ),
    BusinessModel(
      businessId: 'biz_hq_001',
      counterName: 'Customer Inquiry & Returns',
      activeCounters: 3,
      averageServiceTime: 7.5,
    ),
    BusinessModel(
      businessId: 'biz_hq_001',
      counterName: 'Express Check-In',
      activeCounters: 4,
      averageServiceTime: 2.0,
    ),
    BusinessModel(
      businessId: 'biz_hq_001',
      counterName: 'Special Needs Assisting',
      activeCounters: 0, // Mocking 0 active counters to test the frozen queue UI state
      averageServiceTime: 15.0,
    ),
  ];

  int? _selectedCounterIndex;
  
  // Generating a unique identifier for this customer session.
  late final String _mockUserId;

  @override
  void initState() {
    super.initState();
    // Simulate a unique user ID for this customer
    final uniqueId = DateTime.now().millisecondsSinceEpoch.toString().substring(8);
    _mockUserId = 'usr_$uniqueId';
  }

  Future<void> _handleTokenGeneration(BuildContext context, BusinessModel selectedCounter) async {
    final provider = context.read<QueueProvider>();
    
    // Call the atomic service wrapper on the provider
    final ticket = await provider.issueNewTicket(
      counterName: selectedCounter.counterName,
      userId: _mockUserId,
    );

    if (!context.mounted) return;

    if (ticket != null) {
      // Show success micro-toast
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_outline, color: Colors.white),
              const SizedBox(width: 12),
              Text('Token #${ticket.tokenNumber} issued successfully!'),
            ],
          ),
          backgroundColor: Colors.teal.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );

      // Navigate to live tracker screen
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => LiveTrackerScreen(
            userId: _mockUserId,
            businessInfo: selectedCounter,
          ),
        ),
      );
    } else {
      // Display error banner
      final errorMsg = provider.errorMessage ?? 'An error occurred while generating token';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(child: Text(errorMsg)),
            ],
          ),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLoading = context.watch<QueueProvider>().isLoading;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              theme.colorScheme.primaryContainer.withOpacity(0.4),
              theme.colorScheme.surface,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Beautiful Glassmorphic Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AI-Powered Queue',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Select a Service Counter',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Choose a department counter below to generate your real-time tracking token.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),

              // Scrollable list of counters
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  itemCount: _counters.length,
                  itemBuilder: (context, index) {
                    final counter = _counters[index];
                    final isSelected = _selectedCounterIndex == index;
                    final isCounterActive = counter.activeCounters > 0;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: InkWell(
                        onTap: isLoading
                            ? null
                            : () {
                                setState(() {
                                  _selectedCounterIndex = index;
                                });
                              },
                        borderRadius: BorderRadius.circular(16.0),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          curve: Curves.easeInOut,
                          padding: const EdgeInsets.all(18.0),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? theme.colorScheme.primary.withOpacity(0.08)
                                : theme.colorScheme.surface,
                            borderRadius: BorderRadius.circular(16.0),
                            border: Border.all(
                              color: isSelected
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.outlineVariant,
                              width: isSelected ? 2.0 : 1.0,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: isSelected
                                    ? theme.colorScheme.primary.withOpacity(0.05)
                                    : Colors.black.withOpacity(0.02),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              // Counter status/icon badge
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: isCounterActive
                                      ? Colors.teal.shade50
                                      : Colors.red.shade50,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  isCounterActive
                                      ? Icons.room_service_outlined
                                      : Icons.report_gmailerrorred_outlined,
                                  color: isCounterActive
                                      ? Colors.teal.shade700
                                      : Colors.red.shade700,
                                ),
                              ),
                              const SizedBox(width: 16),
                              
                              // Counter details
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      counter.counterName,
                                      style: theme.textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: theme.colorScheme.onSurface,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.people_alt_outlined,
                                          size: 14,
                                          color: theme.colorScheme.onSurfaceVariant,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          isCounterActive
                                              ? '${counter.activeCounters} counter(s) active'
                                              : 'Closed/Paused',
                                          style: theme.textTheme.bodySmall?.copyWith(
                                            color: isCounterActive
                                                ? theme.colorScheme.onSurfaceVariant
                                                : Colors.red.shade700,
                                            fontWeight: isCounterActive ? null : FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Icon(
                                          Icons.access_time_outlined,
                                          size: 14,
                                          color: theme.colorScheme.onSurfaceVariant,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          '${counter.averageServiceTime.toStringAsFixed(1)} min avg',
                                          style: theme.textTheme.bodySmall?.copyWith(
                                            color: theme.colorScheme.onSurfaceVariant,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              
                              // Select Indicator
                              Icon(
                                isSelected
                                    ? Icons.radio_button_checked
                                    : Icons.radio_button_off,
                                color: isSelected
                                    ? theme.colorScheme.primary
                                    : theme.colorScheme.onSurfaceVariant.withOpacity(0.5),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

              // Button area
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: SizedBox(
                  height: 56,
                  child: ElevatedButton(
                    onPressed: (_selectedCounterIndex == null || isLoading)
                        ? null
                        : () => _handleTokenGeneration(
                              context,
                              _counters[_selectedCounterIndex!],
                            ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: theme.colorScheme.onPrimary,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16.0),
                      ),
                      disabledBackgroundColor: theme.colorScheme.onSurface.withOpacity(0.12),
                      disabledForegroundColor: theme.colorScheme.onSurface.withOpacity(0.38),
                    ),
                    child: isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Icon(Icons.qr_code_2),
                              SizedBox(width: 10),
                              Text(
                                'Generate Queue Token',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
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
      ),
    );
  }
}
