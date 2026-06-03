import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/ticket_model.dart';

/// Exception thrown when a queue operation fails.
class QueueServiceException implements Exception {
  final String message;
  final dynamic originalError;
  final StackTrace? stackTrace;

  QueueServiceException(this.message, [this.originalError, this.stackTrace]);

  @override
  String toString() => 'QueueServiceException: $message (Details: $originalError)';
}

/// A production-grade service class that handles real-time database operations
/// for the AI-powered Queue Management System using Cloud Firestore.
class QueueService {
  final FirebaseFirestore _firestore;

  /// Constructor allowing dependency injection of [FirebaseFirestore].
  /// 
  /// Defaults to [FirebaseFirestore.instance], facilitating simple mock testing.
  QueueService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// A reference to the tickets collection in Firestore.
  CollectionReference<Map<String, dynamic>> get _ticketsCollection =>
      _firestore.collection('tickets');

  /// A reference to the token trackers collection in Firestore.
  CollectionReference<Map<String, dynamic>> get _trackersCollection =>
      _firestore.collection('token_trackers');

  /// Returns a real-time stream of the active queue for a specific counter.
  /// 
  /// The stream listens for tickets where:
  /// - The counter is assigned to [counterName].
  /// - The status is either 'waiting' or 'serving'.
  /// - Ordered by [timestamp] ascending (first-come, first-served).
  /// 
  /// NOTE: This query requires a Firestore composite index to work in production:
  /// - **Collection ID**: `tickets`
  /// - **Fields**:
  ///   1. `counterAssigned` (Ascending)
  ///   2. `status` (Arrays/whereIn)
  ///   3. `timestamp` (Ascending)
  /// 
  /// If the index is not created, Firestore will throw a [FirebaseException] with a link
  /// to create it in the Firebase Console.
  Stream<List<TicketModel>> getLiveQueueStream(String counterName) {
    try {
      return _ticketsCollection
          .where('counterAssigned', isEqualTo: counterName)
          .where('status', whereIn: const ['waiting', 'serving'])
          .orderBy('timestamp', descending: false)
          .snapshots()
          .map((snapshot) {
            return snapshot.docs.map((doc) {
              // Extract data map from document snapshot
              final data = doc.data();
              // Inject the document ID into 'ticketId' field if it is missing
              if (!data.containsKey('ticketId') || data['ticketId'] == '') {
                data['ticketId'] = doc.id;
              }
              return TicketModel.fromJson(data);
            }).toList();
          });
    } catch (e, stackTrace) {
      // Log error using a logging framework in production
      print('Error setting up live queue stream for counter $counterName: $e');
      print(stackTrace);
      rethrow;
    }
  }

  /// Safely generates the next token number and creates a new ticket in a transaction.
  /// 
  /// To ensure token uniqueness and sequential integrity (no skipped or duplicate numbers),
  /// this method executes all reads and writes inside a Firestore Transaction:
  /// 1. Reads the latest token number from the tracker document `token_trackers/{counterName}`.
  /// 2. Increments the token counter safely (starting at 1 if no tracker exists).
  /// 3. Updates the tracker document with the new token number.
  /// 4. Generates a new ticket document with the incremented token and status 'waiting'.
  /// 
  /// Returns the newly created [TicketModel].
  Future<TicketModel> generateNextToken({
    required String counterName,
    required String userId,
  }) async {
    if (counterName.trim().isEmpty) {
      throw ArgumentError('counterName cannot be empty');
    }
    if (userId.trim().isEmpty) {
      throw ArgumentError('userId cannot be empty');
    }

    try {
      return await _firestore.runTransaction<TicketModel>((transaction) async {
        final trackerDocRef = _trackersCollection.doc(counterName);
        final ticketDocRef = _ticketsCollection.doc(); // Pre-generate a doc ID

        // Step A: Read the latest token number inside the transaction block
        final trackerSnapshot = await transaction.get(trackerDocRef);

        int nextTokenNumber = 1;
        if (trackerSnapshot.exists) {
          final data = trackerSnapshot.data();
          final currentToken = data?['lastTokenNumber'] as int? ?? 0;
          nextTokenNumber = currentToken + 1;
        }

        // Step B: Increment the tracker state inside the transaction
        transaction.set(
          trackerDocRef,
          {
            'lastTokenNumber': nextTokenNumber,
            'counterName': counterName,
            'updatedAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );

        // Step C: Build the TicketModel object with the new token number
        final newTicket = TicketModel(
          ticketId: ticketDocRef.id,
          tokenNumber: nextTokenNumber,
          userId: userId,
          status: 'waiting',
          timestamp: DateTime.now(),
          counterAssigned: counterName,
        );

        // Save the new ticket to the database
        transaction.set(ticketDocRef, newTicket.toFirestore());

        return newTicket;
      });
    } catch (e, stackTrace) {
      print('Transaction failed during token generation for $counterName: $e');
      throw QueueServiceException(
        'Failed to generate next token and save ticket.',
        e,
        stackTrace,
      );
    }
  }

  /// Transitions a ticket's status to a new state in Firestore.
  /// 
  /// Valid statuses are: 'waiting', 'serving', 'completed'.
  /// This ensures validation happens at the service boundary before writing.
  Future<void> updateTicketStatus({
    required String ticketId,
    required String newStatus,
  }) async {
    if (ticketId.trim().isEmpty) {
      throw ArgumentError('ticketId cannot be empty');
    }

    final sanitizedStatus = newStatus.trim().toLowerCase();
    if (sanitizedStatus != 'waiting' &&
        sanitizedStatus != 'serving' &&
        sanitizedStatus != 'completed') {
      throw ArgumentError(
        'Invalid status transition: "$newStatus". Status must be "waiting", "serving", or "completed".',
      );
    }

    try {
      await _ticketsCollection.doc(ticketId).update({
        'status': sanitizedStatus,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e, stackTrace) {
      print('Failed to update status of ticket $ticketId to $newStatus: $e');
      throw QueueServiceException(
        'Failed to transition ticket $ticketId to status: $newStatus.',
        e,
        stackTrace,
      );
    }
  }
}
