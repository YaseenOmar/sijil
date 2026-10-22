# Sijil – Family Management Module

**Module:** Family Management  
**Framework:** Flutter / Dart  
**Database:** Firebase Cloud Firestore  
**Architecture:** MVVM + Repository Pattern (planned integration)  
**Status:** Initial Implementation

---

## 1. Overview

هذا الموديول مسؤول عن إدارة بيانات الأسر المستفيدة في تطبيق Sijil.

الوظائف المتوفرة حاليًا:

- تعريف بيانات الأسرة باستخدام `FamilyModel`.
- إضافة أسرة جديدة إلى Firebase Firestore.
- جلب الأسر التابعة للمناطق المحددة للموظف.
- جلب أسر منطقة معينة.
- التحقق المبدئي من تكرار رقم الهوية.
- ربط الأسرة بالمؤسسة والموظف والمنطقة.

**ملاحظة:** خدمات Firebase متوفرة على مستوى الكود، ولم يتم تأكيد اختبارها فعليًا بعد.

## 2. Project Structure

```text
lib/
├── core/
│   └── constants/
│       └── demo_context.dart
│
└── features/
    └── families/
        ├── models/
        │   └── family_model.dart
        │
        └── data/
            └── datasources/
                └── family_remote_datasource.dart
```

### File Responsibilities

| File | Responsibility |
|---|---|
| `family_model.dart` | Defines family data and conversion methods |
| `family_remote_datasource.dart` | Handles Firestore operations |
| `demo_context.dart` | Provides temporary organization, employee and area IDs |

## 3. FamilyModel

يمثل بيانات الأسرة داخل التطبيق.

### Fields

| Field | Type | Description |
|---|---|---|
| id | String | Unique family record ID |
| headName | String | Head of household name |
| nationalId | String | National ID number |
| phoneNumber | String | Contact number |
| membersCount | int | Number of family members |
| address | String | Detailed address |
| housingStatus | String | Housing status |
| idCardImagePath | String? | Local ID image path |
| needs | List\<String> | Family needs |
| areaId | String | Assigned area ID |
| createdBy | String | Employee ID |
| organizationId | String | Organization ID |

### Model Methods

**`toMap()`**

Converts a `FamilyModel` object into a `Map<String, dynamic>` for data storage.

```dart
final data = family.toMap();
```

**`fromMap()`**

Converts data retrieved from the database into a `FamilyModel` object.

```dart
final family = FamilyModel.fromMap(data);
```

The model does not depend directly on Firebase or Hive.

## 4. Temporary User Context

Current development uses fixed IDs:

```dart
class DemoContext {
  DemoContext._();

  static const organizationId = 'org_001';
  static const employeeId = 'emp_001';

  static const assignedAreaIds = [
    'area_001',
    'area_002',
    'area_003',
  ];
}
```

These are development placeholders and must be replaced with authenticated employee information before production use.

## 5. Firestore Structure

```text
organizations/
    {organizationId}/
        families/
            {familyId}/
                headName
                nationalId
                phoneNumber
                membersCount
                address
                housingStatus
                idCardImagePath
                needs
                areaId
                createdBy
                organizationId
                id
```

Each family is stored inside its organization's collection.

## 6. Firebase Service

**Class:** `FamilyRemoteDataSource`

### 6.1 Add Family

Method:

```dart
Future<void> addFamily(FamilyModel family)
```

Usage:

```dart
final service = FamilyRemoteDataSource();

final family = FamilyModel(
  id: const Uuid().v4(),
  headName: 'أحمد محمد',
  nationalId: '123456789',
  phoneNumber: '0599123456',
  membersCount: 5,
  address: 'حي الأمل',
  housingStatus: 'نازح',
  needs: ['غذاء', 'مياه'],
  areaId: 'area_001',
  createdBy: DemoContext.employeeId,
  organizationId: DemoContext.organizationId,
);

await service.addFamily(family);
```

Required imports include:

```dart
import 'package:uuid/uuid.dart';
```

And the project imports for `FamilyModel`, `DemoContext`, and `FamilyRemoteDataSource`.

The method:

1. Checks organization ID.
2. Checks employee ID.
3. Checks whether the selected area is assigned to the employee.
4. Checks whether the national ID already exists.
5. Saves the family in Firestore.

The duplicate check is preliminary and is not concurrency-safe.

### 6.2 Get All Families

Method:

```dart
Future<List<FamilyModel>> getFamilies()
```

Usage:

```dart
final service = FamilyRemoteDataSource();

final families = await service.getFamilies();
```

Returns families from all areas assigned to the current employee.

### 6.3 Get Families by Area

Method:

```dart
Future<List<FamilyModel>> getFamiliesByArea(
  String areaId,
)
```

Usage:

```dart
final families =
    await service.getFamiliesByArea('area_001');
```

The method checks that the requested area is assigned to the employee.

### 6.4 Check Duplicate Family

Method:

```dart
Future<bool> familyExists(String nationalId)
```

Usage:

```dart
final exists =
    await service.familyExists('123456789');

if (exists) {
  print('Family already exists');
}
```

Returns `true` if a matching national ID exists in the organization's family collection.

This check does not guarantee uniqueness during simultaneous registrations.

## 7. Error Handling

Firestore operations may fail because of:

- Network connectivity issues.
- Missing permissions.
- Invalid employee or organization.
- Area access restrictions.
- Existing family records.

Recommended usage:

```dart
try {
  await service.addFamily(family);
} catch (e) {
  print('Failed to add family: $e');
}
```

Production UI code should display clear messages to the user and avoid exposing sensitive internal error details.

## 8. Important Notes for Developers

- Do not modify `FamilyModel` field names without coordinating with the team.
- Do not generate a new family ID when retrying synchronization of the same record.
- Use UUIDs for family record IDs.
- Do not use `nationalId` as the family document ID.
- Use `areaId` to associate a family with its area.
- The current `createdBy` value is temporary.
- The local `idCardImagePath` is not a Firebase Storage URL.
- All Firestore operations should eventually be accessed through `FamilyRepository`.
- Client-side area checks do not replace Firestore Security Rules.
- Do not use real beneficiary data until authentication, access controls, and storage protection are configured and tested.

## 9. Current Limitations

The following functionality is not completed yet:

- Hive local storage.
- Offline-first synchronization.
- Firebase Storage image uploads.
- Production-ready Firestore Security Rules.
- Reliable duplicate prevention across concurrent devices.
- Family update and deletion operations.
- Integration with GetX Controllers.
- Dynamic employee and organization information.

## 10. Next Development Tasks

- Implement `FamilyLocalDataSource`.
- Implement `FamilyRepository`.
- Configure secure employee access.
- Implement synchronization between Hive and Firebase.
- Integrate the module with `FamilyController`.
- Add automated tests for area restrictions, duplicate detection and data conversion.

---

**Team 3 – Sijil Project**

Family Management Module – Initial Developer Documentation