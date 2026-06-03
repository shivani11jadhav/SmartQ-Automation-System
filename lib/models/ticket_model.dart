import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:meta/meta.dart';

/// Represents a customer service ticket in the real-time Queue Management System.
@immutable
class TicketModel {
  /// Unique identifier of the ticket.
  final String ticketId;

  /// The sequential token number assigned to the customer.
  final int tokenNumber;

  /// The unique identifier of the user (customer) who owns the ticket.
  final String userId;

  /// The current lifecycle status of the ticket.
  /// 
  /// Guaranteed to be one of: 'waiting', 'serving', 'completed'.
  final String status;

  /// The timestamp when the ticket was created.
  final DateTime timestamp;

  /// The identifier of the counter assigned to serve this ticket (empty if none yet).
  final String counterAssigned;

  /// Default constructor for creating a [TicketModel].
  const TicketModel({
    required this.ticketId,
    required this.tokenNumber,
    required this.userId,
    required this.status,
    required this.timestamp,
    required this.counterAssigned,
  });

  /// Factory constructor for creating a [TicketModel] from a JSON/Firestore Map.
  /// 
  /// Uses highly resilient parsers for both status safety and timestamp conversions.
  factory TicketModel.fromJson(Map<String, dynamic> json) {
    return TicketModel(
      ticketId: json['ticketId'] as String? ?? '',
      tokenNumber: json['tokenNumber'] as int? ?? 0,
      userId: json['userId'] as String? ?? '',
      status: _sanitizeStatus(json['status'] as String?),
      timestamp: _parseDateTime(json['timestamp']),
      counterAssigned: json['counterAssigned'] as String? ?? '',
    );
  }

  /// Converts this [TicketModel] instance to a standard JSON Map.
  /// 
  /// Useful for local storage, caching (e.g. Hive/Shared Preferences), or REST APIs.
  /// Converts the [DateTime] into a standard ISO 8601 String.
  Map<String, dynamic> toJson() {
    return {
      'ticketId': ticketId,
      'tokenNumber': tokenNumber,
      'userId': userId,
      'status': status,
      'timestamp': timestamp.toIso8601String(),
      'counterAssigned': counterAssigned,
    };
  }

  /// Converts this [TicketModel] instance to a Firestore-compatible Map.
  /// 
  /// Converts the [DateTime] into a Firestore [Timestamp] object for precise,
  /// queryable date-time storage in Cloud Firestore.
  Map<String, dynamic> toFirestore() {
    return {
      'ticketId': ticketId,
      'tokenNumber': tokenNumber,
      'userId': userId,
      'status': status,
      'timestamp': Timestamp.fromDate(timestamp),
      'counterAssigned': counterAssigned,
    };
  }

  /// Creates a copy of this [TicketModel] but with the given fields replaced
  /// with the new values.
  TicketModel copyWith({
    String? ticketId,
    int? tokenNumber,
    String? userId,
    String? status,
    DateTime? timestamp,
    String? counterAssigned,
  }) {
    return TicketModel(
      ticketId: ticketId ?? this.ticketId,
      tokenNumber: tokenNumber ?? this.tokenNumber,
      userId: userId ?? this.userId,
      status: status != null ? _sanitizeStatus(status) : this.status,
      timestamp: timestamp ?? this.timestamp,
      counterAssigned: counterAssigned ?? this.counterAssigned,
    );
  }

  /// Helper getters to eliminate manual string checks inside UI logic
  bool get isWaiting => status == 'waiting';
  bool get isServing => status == 'serving';
  bool get isCompleted => status == 'completed';

  // --- Private Helper Parser Methods ---

  /// Resiliently parses dynamic date representation into a Dart [DateTime].
  /// 
  /// Handles the following types:
  /// 1. [Timestamp] - The standard type returned by the Firestore SDK.
  /// 2. [String] - ISO 8601 strings (returned from REST APIs, caching layers, or JSON backups).
  /// 3. [int] - Milliseconds since epoch (common in JS/Web interop).
  /// 4. [DateTime] - Direct DateTime objects (passed during unit tests/local instantiation).
  static DateTime _parseDateTime(dynamic value) {
    if (value == null) {
      return DateTime.now();
    }
    
    if (value is Timestamp) {
      return value.toDate();
    } else if (value is String) {
      return DateTime.tryParse(value) ?? DateTime.now();
    } else if (value is int) {
      return DateTime.fromMillisecondsSinceEpoch(value);
    } else if (value is DateTime) {
      return value;
    }
    
    // Fallback default for unknown formats to prevent runtime crashes.
    return DateTime.now();
  }

  /// Sanitizes raw status values to ensure strict compliance with database design.
  /// 
  /// Valid statuses: 'waiting', 'serving', 'completed'.
  /// Defaults to 'waiting' if the value is invalid or null.
  static String _sanitizeStatus(String? rawStatus) {
    if (rawStatus == null) return 'waiting';
    
    final sanitized = rawStatus.trim().toLowerCase();
    if (sanitized == 'waiting' || sanitized == 'serving' || sanitized == 'completed') {
      return sanitized;
    }
    
    // Fallback status to keep client application state valid.
    return 'waiting';
  }

  @override
  String toString() {
    return 'TicketModel(ticketId: $ticketId, tokenNumber: #$tokenNumber, userId: $userId, status: $status, timestamp: $timestamp, counterAssigned: $counterAssigned)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
  
    return other is TicketModel &&
      other.ticketId == ticketId &&
      other.tokenNumber == tokenNumber &&
      other.userId == userId &&
      other.status == status &&
      other.timestamp == timestamp &&
      other.counterAssigned == counterAssigned;
  }

  @override
  int get hashCode {
    return ticketId.hashCode ^
      tokenNumber.hashCode ^
      userId.hashCode ^
      status.hashCode ^
      timestamp.hashCode ^
      counterAssigned.hashCode;
  }
}
