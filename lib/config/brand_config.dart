/// Public white-label defaults. Override with --dart-define-from-file.
/// Tenant-specific school settings take precedence where available.
class BrandConfig {
  BrandConfig._();
  static const appName =
      String.fromEnvironment('APP_NAME', defaultValue: "School Workspace");
  static const companyName =
      String.fromEnvironment('COMPANY_NAME', defaultValue: "Example Academy");
  static const logoUrl = String.fromEnvironment('LOGO_URL', defaultValue: "");
  static const supportEmail = String.fromEnvironment('SUPPORT_EMAIL',
      defaultValue: "support@example.invalid");
  static const supportPhone =
      String.fromEnvironment('SUPPORT_PHONE', defaultValue: "");
  static const websiteUrl = String.fromEnvironment('WEBSITE_URL',
      defaultValue: "https://example.invalid");
  static const currency =
      String.fromEnvironment('CURRENCY', defaultValue: "PKR");
  static const country = String.fromEnvironment('COUNTRY', defaultValue: "PK");
  static const timeZone =
      String.fromEnvironment('TIME_ZONE', defaultValue: "Asia/Karachi");
  static const dateFormat =
      String.fromEnvironment('DATE_FORMAT', defaultValue: "yyyy-MM-dd");
  static const receiptFooter = String.fromEnvironment('RECEIPT_FOOTER',
      defaultValue: "Thank you. Keep this receipt for your records.");
  static const primaryColor =
      int.fromEnvironment('PRIMARY_COLOR', defaultValue: 0xFF4F46E5);
  static const secondaryColor =
      int.fromEnvironment('SECONDARY_COLOR', defaultValue: 0xFF0F9F75);
  static String formatDate(DateTime date) => dateFormat
      .replaceAll('yyyy', date.year.toString().padLeft(4, '0'))
      .replaceAll('MM', date.month.toString().padLeft(2, '0'))
      .replaceAll('dd', date.day.toString().padLeft(2, '0'));
}
