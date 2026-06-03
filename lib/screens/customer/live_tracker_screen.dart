import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/business_model.dart';
import '../../models/ticket_model.dart';
import '../../providers/queue_provider.dart';

/// Screen displaying real-time tracking metrics and queue predictive analytics
/// to the customer.
class LiveTrackerScreen extends StatefulWidget {
  final String userId;
  final BusinessModel businessInfo;

  const LiveTrackerScreen({
    super.key,
    required this.userId,
    required this.businessInfo,
  });

  @override
  State<LiveTrackerScreen> createState() => _LiveTrackerScreenState();
}

class _LiveTrackerScreenState extends State<LiveTrackerScreen> {
  @override
  void initState() {
    super.initState();
    // Register the stream subscription after the first frame completes.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context
          .read<QueueProvider>()
          .subscribeToLiveQueue(widget.businessInfo.counterName);
    });
  }

  @override
  void dispose() {
    // Unsubscribe from queue updates when leaving the tracker screen to conserve network resources.
    // Use WidgetsBinding if needed, but since we are not referencing context during build,
    // we can access the provider directly or rely on the provider's own dispose cleaning.
    // To be safe, we invoke unsubscribeFromLiveQueue.
    Future.microtask(() {
      if (mounted) {
        context.read<QueueProvider>().unsubscribeFromLiveQueue();
      }
    });
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final counterName = widget.businessInfo.counterName;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          counterName,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: theme.colorScheme.onSurface,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Consumer<QueueProvider>(
        builder: (context, provider, child) {
          final tickets = provider.activeTickets;
          final isLoading = provider.isLoading;

          // Frame A: Uninitialized / Loading state
          if (isLoading && tickets.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Loading Live Queue Streams...'),
                ],
              ),
            );
          }

          // Search for the user's specific ticket in the current active collection
          final userTicketIndex = tickets.indexWhere((t) => t.userId == widget.userId);
          
          // Frame B: User's ticket is missing from active queue (either completed or cancelled)
          if (userTicketIndex == -1) {
            return _buildCompletedOrMissingView(theme);
          }

          final userTicket = tickets[userTicketIndex];
          final peopleAhead = provider.calculatePeopleAhead(widget.userId);
          final waitTime = provider.calculateEstimatedWaitingTime(widget.userId, widget.businessInfo);
          final isQueueFrozen = waitTime == double.infinity;

          // Find what token is currently being served by active counters
          final servingTickets = tickets.where((t) => t.status == 'serving').toList();
          final nowServingText = servingTickets.isNotEmpty
              ? servingTickets.map((t) => '#${t.tokenNumber}').join(', ')
              : 'None';

          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Warning Banner: Queue is currently frozen/paused
                if (isQueueFrozen) _buildFrozenQueueBanner(theme),
                
                const SizedBox(height: 16),

                // Main Token Status Card
                _buildTokenStatusCard(theme, userTicket, nowServingText),

                const SizedBox(height: 24),

                // Live Estimated Waiting Time Indicator
                _buildWaitingTimeCircle(theme, waitTime, isQueueFrozen),

                const SizedBox(height: 24),

                // Milestone Badges & Info Cards
                _buildQueueMilestoneBadges(theme, peopleAhead, userTicket),

                const SizedBox(height: 32),

                // Exit Button
                OutlinedButton.icon(
                  onPressed: () => _showLeaveQueueDialog(context, provider, userTicket.ticketId),
                  icon: const Icon(Icons.exit_to_app, color: Colors.red),
                  label: const Text(
                    'Cancel Ticket & Leave Queue',
                    style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: const BorderSide(color: Colors.redAccent, width: 1.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // --- UI Builder Components ---

  Widget _buildFrozenQueueBanner(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.shade300, width: 1.2),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: Colors.orange.shade800),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Queue is currently paused/frozen. Active counters are currently offline.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.orange.shade900,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTokenStatusCard(ThemeData theme, TicketModel userTicket, String nowServingText) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [theme.colorScheme.primary, theme.colorScheme.secondary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            'YOUR TOKEN NUMBER',
            style: TextStyle(
              color: Colors.white75,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '#${userTicket.tokenNumber}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 48,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 16),
          const Divider(color: Colors.white24, height: 1),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Column(
                children: [
                  const Text(
                    'STATUS',
                    style: TextStyle(color: Colors.white75, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      userTicket.status.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              Column(
                children: [
                  const Text(
                    'NOW SERVING',
                    style: TextStyle(color: Colors.white75, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    nowServingText,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWaitingTimeCircle(ThemeData theme, double waitTime, bool isQueueFrozen) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 32.0),
        child: Column(
          children: [
            Text(
              'ESTIMATED WAITING TIME',
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 24),
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 160,
                  height: 160,
                  child: CircularProgressIndicator(
                    value: isQueueFrozen ? 1.0 : (waitTime > 60 ? 1.0 : waitTime / 60),
                    strokeWidth: 12,
                    backgroundColor: theme.colorScheme.outlineVariant.withOpacity(0.5),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      isQueueFrozen
                          ? Colors.orange
                          : (waitTime > 20
                              ? Colors.redAccent
                              : (waitTime > 10 ? Colors.amber : Colors.teal)),
                    ),
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      isQueueFrozen ? '--' : waitTime.toStringAsFixed(0),
                      style: theme.textTheme.displayMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: isQueueFrozen ? Colors.orange : theme.colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      isQueueFrozen ? 'PAUSED' : 'MINUTES',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Text(
                isQueueFrozen
                    ? 'Service is temporarily halted. Wait times will recalculate once counters open.'
                    : 'Calculated dynamically based on real-time activity metrics.',
                textAlign: Center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQueueMilestoneBadges(ThemeData theme, int peopleAhead, TicketModel userTicket) {
    return Row(
      children: [
        // Card 1: People Ahead
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: theme.colorScheme.outlineVariant),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.people_outline, color: theme.colorScheme.primary, size: 24),
                const SizedBox(height: 12),
                Text(
                  '$peopleAhead',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'People Ahead',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
        
        const SizedBox(width: 16),

        // Card 2: Your Position
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: theme.colorScheme.outlineVariant),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  userTicket.status == 'serving'
                      ? Icons.check_circle_outline
                      : Icons.hourglass_empty_rounded,
                  color: userTicket.status == 'serving' ? Colors.teal : Colors.amber,
                  size: 24,
                ),
                const SizedBox(height: 12),
                Text(
                  userTicket.status == 'serving' ? 'Serving' : '${peopleAhead + 1}',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: userTicket.status == 'serving' ? Colors.teal : theme.colorScheme.onSurface,
                    fontSize: userTicket.status == 'serving' ? 22 : null,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  userTicket.status == 'serving' ? 'Your Turn Now!' : 'Queue Position',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCompletedOrMissingView(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.teal.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.check_circle, size: 64, color: Colors.teal.shade700),
            ),
            const SizedBox(height: 24),
            Text(
              'Service Completed!',
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Your ticket has either been completed or was removed from the active queue. Thank you for using our automated service counter.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Back to Counter Selection'),
            ),
          ],
        ),
      ),
    );
  }

  // --- Dialogs ---

  void _showLeaveQueueDialog(BuildContext context, QueueProvider provider, String ticketId) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Cancel Queue Ticket?'),
          content: const Text(
            'Are you sure you want to cancel your queue ticket and leave the queue? This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Stay in Queue'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop(); // Dismiss dialog
                
                final success = await provider.transitionTicketStatus(
                  ticketId: ticketId,
                  // Transition to 'completed' status to terminate session
                  newStatus: 'completed',
                );

                if (context.mounted) {
                  if (success) {
                    Navigator.of(context).pop(); // Back to Counter Selection
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(provider.errorMessage ?? 'Failed to leave queue')),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Leave Queue'),
            ),
          ],
        );
      },
    );
  }
}
