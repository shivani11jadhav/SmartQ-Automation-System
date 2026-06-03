import 'package:meta/meta.dart';

/// Represents a business counter setup in the AI-powered Queue Management System.
@immutable
class BusinessModel {
  /// Unique identifier of the business.
  final String businessId;

  /// The name of the specific counter (e.g., "Reception", "Billing").
  final String counterName;

  /// Number of counters currently active/serving customers.
  final int activeCounters;

  /// Average time (in minutes) spent to serve a single customer.
  final double averageServiceTime;

  /// Default constructor for creating a [BusinessModel].
  const BusinessModel({
    required this.businessId,
    required this.counterName,
    required this.activeCounters,
    required this.averageServiceTime,
  });

  /// Factory constructor for creating a [BusinessModel] from a JSON/Firestore Map.
  /// 
  /// Handles type safety strictly. In Firestore/JSON, numbers can sometimes be 
  /// stored as integers (e.g., `5`) even if they represent double fields. To prevent
  /// runtime type assertion failures, `averageServiceTime` parses the value via `num.toDouble()`.
  factory BusinessModel.fromJson(Map<String, dynamic> json) {
    return BusinessModel(
      businessId: json['businessId'] as String? ?? '',
      counterName: json['counterName'] as String? ?? '',
      activeCounters: json['activeCounters'] as int? ?? 0,
      averageServiceTime: (json['averageServiceTime'] as num? ?? 0.0).toDouble(),
    );
  }

  /// Converts this [BusinessModel] instance to a JSON Map for writing to Firestore.
  Map<String, dynamic> toJson() {
    return {
      'businessId': businessId,
      'counterName': counterName,
      'activeCounters': activeCounters,
      'averageServiceTime': averageServiceTime,
    };
  }

  /// Creates a copy of this [BusinessModel] but with the given fields replaced
  /// with the new values.
  BusinessModel copyWith({
    String? businessId,
    String? counterName,
    int? activeCounters,
    double? averageServiceTime,
  }) {
    return BusinessModel(
      businessId: businessId ?? this.businessId,
      counterName: counterName ?? this.counterName,
      activeCounters: activeCounters ?? this.activeCounters,
      averageServiceTime: averageServiceTime ?? this.averageServiceTime,
    );
  }

  @override
  String toString() {
    return 'BusinessModel(businessId: $businessId, counterName: $counterName, activeCounters: $activeCounters, averageServiceTime: ${averageServiceTime}m)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
  
    return other is BusinessModel &&
      other.businessId == businessId &&
      other.counterName == counterName &&
      other.activeCounters == activeCounters &&
      other.averageServiceTime == averageServiceTime;
  }

  @override
  int get hashCode {
    return businessId.hashCode ^
      counterName.hashCode ^
      activeCounters.hashCode ^
      averageServiceTime.hashCode;
  }
}
