import 'dart:async';
import 'package:flutter/material.dart';
import '../models/business_model.dart';
import '../models/ticket_model.dart';
import '../services/queue_service.dart';

/// Manages UI state and runs predictive waiting-time computations
/// for the AI-powered Queue Management System.
class QueueProvider extends ChangeNotifier {
  final QueueService _queueService;

  /// Holds the current active tickets (waiting or serving) for the subscribed counter.
  List<TicketModel> _activeTickets = [];

  /// Subscription to the live Firestore queue stream.
  StreamSubscription<List<TicketModel>>? _queueSubscription;

  bool _isLoading = false;
  String? _errorMessage;

  /// Constructor allowing dependency injection of [QueueService].
  /// 
  /// Defaults to a new [QueueService] instance.
  QueueProvider({QueueService? queueService})
      : _queueService = queueService ?? QueueService();

  // --- Getters ---

  /// The list of active tickets in the current queue (ordered ascending by timestamp).
  List<TicketModel> get activeTickets => List.unmodifiable(_activeTickets);

  /// State flag indicating if an asynchronous operation is in progress.
  bool get isLoading => _isLoading;

  /// Displays the latest error message if an operation fails, else null.
  String? get errorMessage => _errorMessage;

  // --- Stream Management ---

  /// Subscribes to a real-time live queue stream for a specific [counterName].
  /// 
  /// Automatically cancels any existing stream subscriptions to prevent memory leaks
  /// and redundant updates when transitioning between different counters.
  void subscribeToLiveQueue(String counterName) {
    _setLoading(true);
    _errorMessage = null;

    _queueSubscription?.cancel();
    _queueSubscription = _queueService.getLiveQueueStream(counterName).listen(
      (tickets) {
        _activeTickets = tickets;
        _errorMessage = null;
        _setLoading(false);
        notifyListeners();
      },
      onError: (error) {
        _errorMessage = 'Stream Error: ${error.toString()}';
        _setLoading(false);
        notifyListeners();
      },
    );
  }

  /// Cancels the live queue subscription.
  /// 
  /// Exposed if the UI wants to manually pause listening to queue changes.
  Future<void> unsubscribeFromLiveQueue() async {
    await _queueSubscription?.cancel();
    _queueSubscription = null;
    _activeTickets = [];
    notifyListeners();
  }

  // --- Predictive Analytics Engine (AI Logic) ---

  /// Calculates the number of tickets in 'waiting' status positioned ahead of [currentUserId].
  /// 
  /// Since the queue list is sorted chronologically by timestamp, this method:
  /// 1. Finds the index of the ticket belonging to the user.
  /// 2. Iterates from the start of the queue up to that index.
  /// 3. Counts how many tickets have the status 'waiting'.
  /// 
  /// Returns `0` if the user is not found, is already being served, or has completed service.
  int calculatePeopleAhead(String currentUserId) {
    if (_activeTickets.isEmpty) return 0;

    final userIndex = _activeTickets.indexWhere((ticket) => ticket.userId == currentUserId);
    
    // User not in the queue
    if (userIndex == -1) return 0;

    final userTicket = _activeTickets[userIndex];
    
    // If the user is already being served or has finished, no one is ahead of them
    if (userTicket.status != 'waiting') {
      return 0;
    }

    int waitingAheadCount = 0;
    for (int i = 0; i < userIndex; i++) {
      if (_activeTickets[i].status == 'waiting') {
        waitingAheadCount++;
      }
    }

    return waitingAheadCount;
  }

  /// Calculates the estimated waiting time in minutes for [currentUserId].
  /// 
  /// Formula: `(People Ahead * Average Service Time) / Active Counters`
  /// 
  /// Resolves the following edge cases:
  /// 1. User not found in the queue: Returns `0.0`.
  /// 2. User is already being served: Returns `0.0`.
  /// 3. Active counters is 0: Returns [double.infinity] because the queue is frozen.
  double calculateEstimatedWaitingTime(String currentUserId, BusinessModel businessInfo) {
    final userIndex = _activeTickets.indexWhere((ticket) => ticket.userId == currentUserId);
    if (userIndex == -1) {
      return 0.0;
    }

    final userTicket = _activeTickets[userIndex];
    if (userTicket.status == 'serving') {
      return 0.0;
    }

    // Safely handle edge case where business has 0 active counters.
    // In this state, the queue cannot progress, yielding infinite wait time.
    if (businessInfo.activeCounters <= 0) {
      return double.infinity;
    }

    final peopleAhead = calculatePeopleAhead(currentUserId);
    return (peopleAhead * businessInfo.averageServiceTime) / businessInfo.activeCounters;
  }

  // --- Atomic Action Wrappers ---

  /// Requests a new ticket for the user at a specified counter.
  /// 
  /// Returns the created [TicketModel], or null if the transaction fails.
  Future<TicketModel?> issueNewTicket({
    required String counterName,
    required String userId,
  }) async {
    _setLoading(true);
    _errorMessage = null;
    notifyListeners();

    try {
      final ticket = await _queueService.generateNextToken(
        counterName: counterName,
        userId: userId,
      );
      _setLoading(false);
      return ticket;
    } catch (e) {
      _errorMessage = e.toString();
      _setLoading(false);
      return null;
    }
  }

  /// Transitions a ticket's status (e.g. 'waiting' -> 'serving' -> 'completed').
  /// 
  /// Returns true if successful, false if the operation failed.
  Future<bool> transitionTicketStatus({
    required String ticketId,
    required String newStatus,
  }) async {
    _setLoading(true);
    _errorMessage = null;
    notifyListeners();

    try {
      await _queueService.updateTicketStatus(
        ticketId: ticketId,
        newStatus: newStatus,
      );
      _setLoading(false);
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _setLoading(false);
      return false;
    }
  }

  // --- Helper Methods ---

  void _setLoading(bool value) {
    if (_isLoading != value) {
      _isLoading = value;
      notifyListeners();
    }
  }

  // --- Lifecycle Clean-up ---

  @override
  void dispose() {
    // Prevent memory leaks by canceling the active stream subscription
    _queueSubscription?.cancel();
    super.dispose();
  }
}
