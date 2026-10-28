import 'package:sijil/core/constants/demo_context.dart';

// Permissions text for one role (use {name} and {area} as placeholders)
class RolePermissions {
  final String scope;
  final String limits;

  const RolePermissions({required this.scope, required this.limits});
}

// Static choices used by the add staff screen
class StaffOptions {
  StaffOptions._();

  // Temporary: the signed in manager until it comes from authentication
  static const String currentManagerLabel = 'خالد عمر · مدير جمعية الأمان';

  // Roles (single select) and what each role can do
  static const Map<String, RolePermissions> roles = {
    'عامل ميداني': RolePermissions(
      scope: 'حساب {name} يرى أسر {area} فقط، ويعدّل الأسر التي أُنشئت من نفس الحساب. ويمكن من خلاله تسجيل المساعدات وإنشاء الإحالات ضمن المنطقة.',
      limits:
          'لا اعتماد للسجلات، ولا إدارة للفريق، ولا تقارير إدارية بهذا الدور.',
    ),
    'مشرف': RolePermissions(
      scope: 'حساب {name} يرى أسر {area} ويتابع عمل الفريق ضمنها، ويعتمد السجلات والإحالات.',
      limits: 'لا إدارة للجهة، ولا تعديل لصلاحيات الموظفين.',
    ),
    'مدير الجهة': RolePermissions(
      scope: 'حساب {name} يرى أسر جميع مناطق الجهة، ويدير الفريق والتقارير.',
      limits: 'لا صلاحيات على مستوى الشبكة.',
    ),
  };

  //static List<String> get roleNames => roles.keys.toList();
  static List<String> get roleNames => ['عامل ميداني'];

  // Requested account status (single select)
  static const List<String> accountStatuses = [
    'نشط بعد قبول الدعوة والتحقق',
    'معلّق حتى اعتماد المدير',
  ];

  // Temporary area names until areas come from Firestore
  static const Map<String, String> _areaNames = {
    'area_001': 'حي النور',
    'area_002': 'حي السلام',
  };

  static String areaName(String areaId) => _areaNames[areaId] ?? areaId;

  // Areas the manager can assign
  static List<String> get areaIds => DemoContext.assignedAreaIds;
}
