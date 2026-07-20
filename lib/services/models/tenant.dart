import 'subscription.dart';

/// A Tenant is a single organization/school on the SaaS platform.
/// All tenant data in Firestore lives under: tenants/{tenantId}/...
class Tenant {
  final String id;
  final String name;
  final String? logoUrl;
  final int? brandColor; // ARGB int, lets each school re-skin the app
  final Subscription subscription;
  final DateTime? createdAt;

  const Tenant({
    required this.id,
    required this.name,
    this.logoUrl,
    this.brandColor,
    required this.subscription,
    this.createdAt,
  });

  factory Tenant.fromMap(String id, Map<String, dynamic> map) {
    return Tenant(
      id: id,
      name: (map['name'] as String?) ?? 'Unnamed School',
      logoUrl: map['logoUrl'] as String?,
      brandColor: map['brandColor'] as int?,
      subscription: Subscription.fromMap(
        (map['subscription'] as Map<String, dynamic>?) ?? const {},
      ),
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt'].toString())
          : null,
    );
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'logoUrl': logoUrl,
        'brandColor': brandColor,
        'subscription': subscription.toMap(),
        'createdAt': (createdAt ?? DateTime.now()).toIso8601String(),
      };
}
