import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/ticket_model.dart';
import '../../providers/queue_provider.dart';

/// Screen allowing service staff to manage the live queue line,
/// calling next customers and completing active tasks.
class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  // Available counters in the organization.
  final List<String> _counters = const [
    'Billing Counter',
    'Technical Support Desk',
    'Customer Inquiry & Returns',
    'Express Check-In',
    'Special Needs Assisting',
  ];

  String? _selectedCounter;

  @override
  void dispose() {
    // Unsubscribe when leaving the admin panel
    Future.microtask(() {
      if (mounted) {
        context.read<QueueProvider>().unsubscribeFromLiveQueue();
      }
    });
    super.dispose();
  }

  void _onCounterChanged(String? newCounter) {
    if (newCounter == null || newCounter == _selectedCounter) return;

    setState(() {
      _selectedCounter = newCounter;
    });

    // Subscribe to the selected counter's live updates
    context.read<QueueProvider>().subscribeToLiveQueue(newCounter);
  }

  Future<void> _callNextClient(BuildContext context, List<TicketModel> tickets) async {
    final waitingTickets = tickets.where((t) => t.status == 'waiting').toList();
    
    if (waitingTickets.isEmpty) {
      _showFeedbackMessage(context, 'No clients waiting in line.', Colors.orange);
      return;
    }

    final nextTicket = waitingTickets.first; // FIFO first item
    final provider = context.read<QueueProvider>();

    final success = await provider.transitionTicketStatus(
      ticketId: nextTicket.ticketId,
      newStatus: 'serving',
    );

    if (context.mounted) {
      if (success) {
        _showFeedbackMessage(
          context,
          'Called Client Token #${nextTicket.tokenNumber}!',
          Colors.teal,
        );
      } else {
        _showFeedbackMessage(
          context,
          provider.errorMessage ?? 'Failed to call client.',
          Colors.red,
        );
      }
    }
  }

  Future<void> _completeCurrentTask(BuildContext context, List<TicketModel> tickets) async {
    final servingTickets = tickets.where((t) => t.status == 'serving').toList();

    if (servingTickets.isEmpty) {
      _showFeedbackMessage(context, 'No active client currently being served.', Colors.orange);
      return;
    }

    // Complete the oldest active serving ticket first
    final currentTicket = servingTickets.first;
    final provider = context.read<QueueProvider>();

    final success = await provider.transitionTicketStatus(
      ticketId: currentTicket.ticketId,
      newStatus: 'completed',
    );

    if (context.mounted) {
      if (success) {
        _showFeedbackMessage(
          context,
          'Task Completed for Token #${currentTicket.tokenNumber}!',
          Colors.blueGrey,
        );
      } else {
        _showFeedbackMessage(
          context,
          provider.errorMessage ?? 'Failed to complete task.',
          Colors.red,
        );
      }
    }
  }

  void _showFeedbackMessage(BuildContext context, String message, Color color) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = context.watch<QueueProvider>();
    final tickets = provider.activeTickets;
    final isLoading = provider.isLoading;

    // Separate active tickets list
    final servingTickets = tickets.where((t) => t.status == 'serving').toList();
    final waitingTickets = tickets.where((t) => t.status == 'waiting').toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Operations Desk', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 0,
        backgroundColor: theme.colorScheme.primaryContainer.withOpacity(0.3),
        foregroundColor: theme.colorScheme.onSurface,
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Section 1: Selector
                _buildCounterSelector(theme),
                
                const SizedBox(height: 24),

                if (_selectedCounter == null)
                  Expanded(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.arrow_circle_up,
                            size: 64,
                            color: theme.colorScheme.primary.withOpacity(0.5),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Please select a counter to manage queue lines.',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else ...[
                  // Section 2: Active Monitor
                  _buildMonitorPanel(theme, servingTickets),
                  
                  const SizedBox(height: 24),

                  // Section 3: FIFO Queue List
                  Expanded(
                    child: _buildQueueListPanel(theme, waitingTickets),
                  ),

                  const SizedBox(height: 24),

                  // Section 4: Operational Action Buttons
                  _buildActionControls(context, isLoading, tickets, servingTickets, waitingTickets),
                ],
              ],
            ),
          ),

          // Global loading overlay to prevent double-taps
          if (isLoading && tickets.isNotEmpty)
            Container(
              color: Colors.black.withOpacity(0.15),
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }

  // --- Widget Builders ---

  Widget _buildCounterSelector(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.outlineBorderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedCounter,
          hint: Row(
            children: [
              Icon(Icons.storefront, color: theme.colorScheme.primary),
              const SizedBox(width: 12),
              Text(
                'Select Operating Counter',
                style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
              ),
            ],
          ),
          isExpanded: true,
          icon: Icon(Icons.keyboard_arrow_down, color: theme.colorScheme.primary),
          borderRadius: BorderRadius.circular(16),
          items: _counters.map((counter) {
            return DropdownMenuItem<String>(
              value: counter,
              child: Text(
                counter,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            );
          }).toList(),
          onChanged: _onCounterChanged,
        ),
      ),
    );
  }

  Widget _buildMonitorPanel(ThemeData theme, List<TicketModel> servingTickets) {
    final hasActiveSession = servingTickets.isNotEmpty;
    final primaryTicket = hasActiveSession ? servingTickets.first : null;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: hasActiveSession
            ? theme.colorScheme.primary.withOpacity(0.08)
            : theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: hasActiveSession
              ? theme.colorScheme.primary.withOpacity(0.5)
              : theme.colorScheme.outlineVariant,
          width: 1.5,
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'CURRENTLY SERVING',
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                  color: hasActiveSession
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurfaceVariant,
                ),
              ),
              if (hasActiveSession)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.teal.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.teal.shade200),
                  ),
                  child: Text(
                    'ACTIVE SESSION',
                    style: TextStyle(
                      color: Colors.teal.shade800,
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 24),
          if (hasActiveSession && primaryTicket != null) ...[
            Text(
              '#${primaryTicket.tokenNumber}',
              style: theme.textTheme.displayMedium?.copyWith(
                fontWeight: FontWeight.w900,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'User ID: ${primaryTicket.userId}',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ] else ...[
            Text(
              '--',
              style: theme.textTheme.displayMedium?.copyWith(
                fontWeight: FontWeight.w900,
                color: theme.colorScheme.onSurfaceVariant.withOpacity(0.3),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Desk Idle - Waiting to call next client',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildQueueListPanel(ThemeData theme, List<TicketModel> waitingTickets) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'UPCOMING QUEUE LINE',
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurface.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${waitingTickets.length} Waiting',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Expanded(
          child: waitingTickets.isEmpty
              ? _buildEmptyQueuePlaceholder(theme)
              : ListView.builder(
                  physics: const BouncingScrollPhysics(),
                  itemCount: waitingTickets.length,
                  itemBuilder: (context, index) {
                    final ticket = waitingTickets[index];
                    final isFirstInLine = index == 0;

                    return Card(
                      elevation: 0,
                      margin: const EdgeInsets.only(bottom: 8.0),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: isFirstInLine
                              ? theme.colorScheme.primary.withOpacity(0.3)
                              : theme.colorScheme.outlineVariant,
                          width: isFirstInLine ? 1.5 : 1.0,
                        ),
                      ),
                      child: ListTile(
                        leading: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: isFirstInLine
                                ? theme.colorScheme.primary.withOpacity(0.1)
                                : theme.colorScheme.surfaceVariant,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '#${ticket.tokenNumber}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: isFirstInLine
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.onSurface,
                            ),
                          ),
                        ),
                        title: Text(
                          'Client ID: ${ticket.userId}',
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                        ),
                        subtitle: Text(
                          'Joined at: ${_formatTime(ticket.timestamp)}',
                          style: const TextStyle(fontSize: 12),
                        ),
                        trailing: isFirstInLine
                            ? Chip(
                                label: const Text('NEXT', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                                backgroundColor: theme.colorScheme.primary.withOpacity(0.15),
                                labelStyle: TextStyle(color: theme.colorScheme.primary),
                                padding: EdgeInsets.zero,
                                visualDensity: VisualDensity.compact,
                              )
                            : null,
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildEmptyQueuePlaceholder(ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.people_outline,
              size: 48,
              color: theme.colorScheme.onSurfaceVariant.withOpacity(0.4),
            ),
            const SizedBox(height: 12),
            Text(
              'No clients waiting in line',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'New tokens will appear here automatically.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant.withOpacity(0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionControls(
    BuildContext context,
    bool isLoading,
    List<TicketModel> tickets,
    List<TicketModel> servingTickets,
    List<TicketModel> waitingTickets,
  ) {
    final hasActiveSession = servingTickets.isNotEmpty;
    final hasWaitingClients = waitingTickets.isNotEmpty;

    return Row(
      children: [
        // Complete Task Action
        Expanded(
          child: SizedBox(
            height: 56,
            child: OutlinedButton.icon(
              onPressed: (isLoading || !hasActiveSession)
                  ? null
                  : () => _completeCurrentTask(context, tickets),
              icon: const Icon(Icons.done_all, color: Colors.orange),
              label: const Text(
                'Complete Task',
                style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold),
              ),
              style: OutlinedButton.styleFrom(
                side: BorderSide(
                  color: hasActiveSession ? Colors.orange : Colors.grey.shade300,
                  width: 1.5,
                ),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ),
        ),
        
        const SizedBox(width: 16),

        // Call Next Action
        Expanded(
          child: SizedBox(
            height: 56,
            child: ElevatedButton.icon(
              onPressed: (isLoading || !hasWaitingClients)
                  ? null
                  : () => _callNextClient(context, tickets),
              icon: const Icon(Icons.campaign_outlined, color: Colors.white),
              label: const Text(
                'Call Next Client',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal.shade700,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                disabledBackgroundColor: Colors.grey.shade300,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // --- Helper Methods ---

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}

// Extension to fetch color tokens easily safely
extension ThemeExtension on ThemeData {
  Color get outlineBorderColor => colorScheme.outlineVariant;
}
