import 'package:cloud_firestore/cloud_firestore.dart';

import 'subscription.dart';

class Tenant {
  final String id;
  final String name;
  final String? code;
  final String? logoUrl;
  final int? brandColor;
  final String timezone;
  final String currency;
  final String? activeAcademicYearId;
  final bool isActive;
  final Subscription subscription;
  final DateTime? createdAt;

  const Tenant({
    required this.id,
    required this.name,
    required this.subscription,
    this.code,
    this.logoUrl,
    this.brandColor,
    this.timezone = 'Asia/Karachi',
    this.currency = 'PKR',
    this.activeAcademicYearId,
    this.isActive = true,
    this.createdAt,
  });

  factory Tenant.fromMap(String id, Map<String, dynamic> map) {
    final rawSubscription = map['subscription'];
    final subscriptionMap = rawSubscription is Map
        ? Map<String, dynamic>.from(rawSubscription)
        : <String, dynamic>{};

    final rawName = map['name']?.toString().trim();
    return Tenant(
      id: id,
      name: rawName?.isNotEmpty == true ? rawName! : 'Unnamed School',
      code: map['code']?.toString(),
      logoUrl: map['logoUrl']?.toString(),
      brandColor: map['brandColor'] is int ? map['brandColor'] as int : null,
      timezone: map['timezone']?.toString() ?? 'Asia/Karachi',
      currency: map['currency']?.toString() ?? 'PKR',
      activeAcademicYearId: map['activeAcademicYearId']?.toString(),
      isActive: map['isActive'] is bool ? map['isActive'] as bool : true,
      subscription: Subscription.fromMap(subscriptionMap),
      createdAt: _dateFromValue(map['createdAt']),
    );
  }

  Map<String, dynamic> toMap() => <String, dynamic>{
        'name': name,
        'code': code,
        'logoUrl': logoUrl,
        'brandColor': brandColor,
        'timezone': timezone,
        'currency': currency,
        'activeAcademicYearId': activeAcademicYearId,
        'isActive': isActive,
        'subscription': subscription.toMap(),
        'createdAt': createdAt == null
            ? FieldValue.serverTimestamp()
            : Timestamp.fromDate(createdAt!),
      };
}

DateTime? _dateFromValue(dynamic value) {
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;
  if (value == null) return null;
  return DateTime.tryParse(value.toString());
}
