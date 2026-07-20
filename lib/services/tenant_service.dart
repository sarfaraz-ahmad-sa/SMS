import 'UserModel.dart';
import 'models/tenant.dart';

/// Data-access layer for the multi-tenant SaaS.
///
/// NOTE: Persistence is intentionally stubbed for now so the app builds and
/// runs against the currently-installed packages (firebase_auth / firebase_core
/// only). To enable real tenant data, add `cloud_firestore` to pubspec.yaml,
/// run `flutter pub get`, then implement the methods below against Firestore.
///
/// Planned Firestore layout:
///   tenants/{tenantId}                          -> Tenant doc
///   tenants/{tenantId}/students/{studentId}
///   tenants/{tenantId}/attendance/{recordId}
///   users/{uid}                                 -> UserModel (holds tenantId + role)
///
/// Keeping every collection under tenants/{tenantId} lets a single Firestore
/// security rule enforce isolation on the path.
class TenantService {
  const TenantService();

  /// Look up the user profile (tenant + role). Returns null until Firestore
  /// is wired up; callers should fall back to a minimal user.
  Future<UserModel?> getUserProfile(String uid) async {
    // TODO(saas): read users/{uid} from Firestore.
    return null;
  }

  /// Load the tenant a user belongs to. Returns null until Firestore is wired.
  Future<Tenant?> getTenant(String tenantId) async {
    // TODO(saas): read tenants/{tenantId} from Firestore.
    return null;
  }

  /// Create a new tenant (used during onboarding / sign-up).
  Future<void> createTenant(Tenant tenant) async {
    // TODO(saas): write tenants/{tenant.id} to Firestore.
  }
}
