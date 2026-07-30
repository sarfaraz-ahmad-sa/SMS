/// Stable SaaS feature keys used by subscription plans, UI guards and the
/// trusted backend. Keep these values backward compatible once deployed.
class SaasFeature {
  SaasFeature._();

  static const String coreSchool = 'core_school';
  static const String admissions = 'admissions';
  static const String attendance = 'attendance';
  static const String academics = 'academics';
  static const String examinations = 'examinations';
  static const String fees = 'fees';
  static const String accounting = 'accounting';
  static const String hrPayroll = 'hr_payroll';
  static const String library = 'library';
  static const String transport = 'transport';
  static const String hostel = 'hostel';
  static const String inventory = 'inventory';
  static const String communication = 'communication';
  static const String documents = 'documents';
  static const String helpdesk = 'helpdesk';
  static const String welfare = 'welfare';
  static const String reporting = 'reporting';
  static const String integrations = 'integrations';
  static const String apiAccess = 'api_access';
  static const String customDomain = 'custom_domain';
  static const String whiteLabel = 'white_label';
  static const String aiAutomation = 'ai_automation';
  static const String advancedAudit = 'advanced_audit';
  static const String multiCampus = 'multi_campus';

  static const List<String> all = <String>[
    coreSchool,
    admissions,
    attendance,
    academics,
    examinations,
    fees,
    accounting,
    hrPayroll,
    library,
    transport,
    hostel,
    inventory,
    communication,
    documents,
    helpdesk,
    welfare,
    reporting,
    integrations,
    apiAccess,
    customDomain,
    whiteLabel,
    aiAutomation,
    advancedAudit,
    multiCampus,
  ];

  static const Map<String, String> labels = <String, String>{
    coreSchool: 'Core school management',
    admissions: 'Admissions',
    attendance: 'Attendance',
    academics: 'Academics',
    examinations: 'Examinations',
    fees: 'Fees and collections',
    accounting: 'Accounting',
    hrPayroll: 'HR and payroll',
    library: 'Library',
    transport: 'Transport',
    hostel: 'Hostel',
    inventory: 'Inventory and assets',
    communication: 'Communication channels',
    documents: 'Documents and certificates',
    helpdesk: 'Helpdesk and reception',
    welfare: 'Student welfare',
    reporting: 'Advanced reporting',
    integrations: 'External integrations',
    apiAccess: 'API access',
    customDomain: 'Custom domain',
    whiteLabel: 'White-label branding',
    aiAutomation: 'AI and automation',
    advancedAudit: 'Advanced audit and compliance',
    multiCampus: 'Multi-campus operations',
  };

  static String labelOf(String key) => labels[key] ?? key;
}
