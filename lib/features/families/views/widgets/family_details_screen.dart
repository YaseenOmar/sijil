
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:sijil/core/theme/app_colors.dart';
import 'package:sijil/core/widgets/custom_app_bar.dart';

import '../../../../core/widgets/app_button.dart';
import '../../data/models/family_model.dart';

class FamilyDetailsScreen extends StatefulWidget {
  final FamilyModel family;

  const FamilyDetailsScreen({
    super.key,
    required this.family,
  });

  @override
  State<FamilyDetailsScreen> createState() =>
      _FamilyDetailsScreenState();
}

class _FamilyDetailsScreenState
    extends State<FamilyDetailsScreen> {

  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  final FirebaseAuth _auth =
      FirebaseAuth.instance;

  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _membersController;
  late final TextEditingController _addressController;
  late final TextEditingController _reasonController;

  Map<String, dynamic>? _familyData;

  List<Map<String, dynamic>> _changeHistory = [];

  String _areaName = '';
  String _organizationId = '';
  String _currentUserName = '';

  // Editable housing status.
  String? _selectedHousingStatus;

  // Use the same stored values as family creation.
  static const List<String> _housingOptions = [
    'ملك',
    'إيجار',
    'استضافة',
    'نزوح',
    'مركز إيواء',
    'خيمة',
    'أخرى',
  ];

  bool _isLoading = true;
  bool _isSaving = false;
  bool _canEdit = false;

  String? _errorMessage;

  @override
  void initState() {
    super.initState();

    _nameController = TextEditingController(
      text: widget.family.headName,
    );

    _phoneController = TextEditingController(
      text: widget.family.phoneNumber,
    );

    _membersController = TextEditingController(
      text: widget.family.membersCount.toString(),
    );

    _addressController = TextEditingController(
      text: widget.family.address,
    );

    _reasonController = TextEditingController();

    _selectedHousingStatus =
        widget.family.housingStatus;

    _loadFamilyData();
  }

  // ==========================================
  // 1. Load Family and User Permissions
  // ==========================================

  Future<void> _loadFamilyData() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final user = _auth.currentUser;

      if (user == null) {
        throw Exception('يجب تسجيل الدخول أولاً');
      }

      final userDoc = await _firestore
          .collection('users')
          .doc(user.uid)
          .get(
        const GetOptions(source: Source.server),
      );

      if (!userDoc.exists) {
        throw Exception('بيانات المستخدم غير موجودة');
      }

      final userData = userDoc.data()!;

      if (userData['status'] != 'active') {
        throw Exception('حساب المستخدم غير نشط');
      }

      final role = userData['role'];
      final orgId = userData['organizationId'];
      final userAreaId = userData['areaId'];

      if (orgId is! String || orgId.isEmpty) {
        throw Exception('المؤسسة غير محددة');
      }

      if (orgId != widget.family.organizationId) {
        throw Exception('الأسرة لا تتبع مؤسستك');
      }

      final familyDoc = await _firestore
          .collection('organizations')
          .doc(orgId)
          .collection('families')
          .doc(widget.family.id)
          .get(
        const GetOptions(source: Source.server),
      );

      if (!familyDoc.exists) {
        throw Exception('ملف الأسرة غير موجود');
      }

      final data = familyDoc.data()!;

      // ======================================
      // Load Real Area Name
      // ======================================

      String resolvedAreaName = '';

      final familyAreaId = data['areaId'];

      if (familyAreaId is String &&
          familyAreaId.trim().isNotEmpty) {

        final areaDoc = await _firestore
            .collection('organizations')
            .doc(orgId)
            .collection('areas')
            .doc(familyAreaId.trim())
            .get(
          const GetOptions(source: Source.server),
        );

        if (areaDoc.exists) {
          resolvedAreaName =
              (areaDoc.data()?['name'] as String?)
                  ?.trim() ??
                  '';
        }
      }

      // ======================================
      // Check Edit Permissions
      // ======================================

      final isSupervisor = role == 'supervisor';

      final isOwnerWorker =
          role == 'field_worker' &&
              data['createdBy'] == user.uid &&
              data['areaId'] == userAreaId &&
              data['organizationId'] == orgId;

      final canEdit = isSupervisor || isOwnerWorker;

      final history = _parseHistory(
        data['changeHistory'],
      );

      if (!mounted) return;

      setState(() {
        _organizationId = orgId;

        _currentUserName =
            (userData['fullName'] as String?)
                ?.trim() ??
                '';

        _familyData = data;
        _changeHistory = history;
        _canEdit = canEdit;

        _areaName = resolvedAreaName;

        _nameController.text =
            (data['headName'] as String?) ?? '';

        _phoneController.text =
            (data['phoneNumber'] as String?) ?? '';

        _membersController.text =
            (data['membersCount'] ?? 0).toString();

        _addressController.text =
            (data['address'] as String?) ?? '';

        // Load current housing status.
        final housingValue = data['housingStatus'];

        _selectedHousingStatus =
        housingValue is String &&
            housingValue.trim().isNotEmpty
            ? housingValue.trim()
            : null;

        _errorMessage = null;
      });

    } on FirebaseException catch (e) {
      if (!mounted) return;

      setState(() {
        _errorMessage = e.code == 'permission-denied'
            ? 'ليس لديك صلاحية لعرض بيانات هذه الأسرة'
            : 'تعذر تحميل بيانات الأسرة';
      });

    } catch (e) {
      if (!mounted) return;

      setState(() {
        _errorMessage = e.toString().replaceFirst(
          'Exception: ',
          '',
        );
      });

    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // ==========================================
  // 2. Parse Change History
  // ==========================================

  List<Map<String, dynamic>> _parseHistory(
      dynamic raw,
      ) {
    if (raw is! List) return [];

    final entries = raw
        .whereType<Map>()
        .map(
          (item) => Map<String, dynamic>.from(item),
    )
        .toList();

    entries.sort((a, b) {
      final aDate = a['createdAt'];
      final bDate = b['createdAt'];

      final aMillis = aDate is Timestamp
          ? aDate.millisecondsSinceEpoch
          : 0;

      final bMillis = bDate is Timestamp
          ? bDate.millisecondsSinceEpoch
          : 0;

      return bMillis.compareTo(aMillis);
    });

    return entries;
  }

  // ==========================================
  // 3. Save Family Changes
  // ==========================================

  Future<void> _saveChanges() async {
    if (_isSaving ||
        !_canEdit ||
        _familyData == null) {
      return;
    }

    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    FocusManager.instance.primaryFocus?.unfocus();

    final currentUser = _auth.currentUser;

    if (currentUser == null) {
      Get.snackbar(
        'تنبيه',
        'يجب تسجيل الدخول أولاً',
      );
      return;
    }

    final original = _familyData!;

    final newName = _nameController.text.trim();
    final newPhone = _phoneController.text.trim();

    final newMembers = int.parse(
      _membersController.text.trim(),
    );

    final newAddress =
    _addressController.text.trim();

    final newHousingStatus =
        _selectedHousingStatus?.trim() ?? '';

    final reason = _reasonController.text.trim();

    if (newHousingStatus.isEmpty) {
      Get.snackbar(
        'تنبيه',
        'يرجى اختيار حالة السكن',
      );
      return;
    }

    // ======================================
    // Detect Changed Fields
    // ======================================

    final changedFields = <String>[];

    if (original['headName'] != newName) {
      changedFields.add('اسم رب الأسرة');
    }

    if (original['phoneNumber'] != newPhone) {
      changedFields.add('رقم الجوال');
    }

    if (original['membersCount'] != newMembers) {
      changedFields.add('عدد الأفراد');
    }

    if (original['address'] != newAddress) {
      changedFields.add('العنوان التفصيلي');
    }

    if (original['housingStatus'] !=
        newHousingStatus) {
      changedFields.add('حالة السكن');
    }

    if (changedFields.isEmpty) {
      Get.snackbar(
        'تنبيه',
        'لم يتم إجراء أي تغييرات على بيانات الأسرة',
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final familyRef = _firestore
          .collection('organizations')
          .doc(_organizationId)
          .collection('families')
          .doc(widget.family.id);

      // Record this edit in the family's history.
      final historyEntry = <String, dynamic>{
        'type': 'updated',
        'createdBy': currentUser.uid,
        'createdByName': _currentUserName,
        'createdAt': Timestamp.now(),
        'description':
        'تم تعديل: ${changedFields.join('، ')}',
        'reason': reason,
      };

      await _firestore.runTransaction(
            (transaction) async {
          final latestDoc =
          await transaction.get(familyRef);

          if (!latestDoc.exists) {
            throw Exception('ملف الأسرة غير موجود');
          }

          final latest = latestDoc.data()!;

          // Prevent overwriting newer changes.
          for (final key in [
            'headName',
            'phoneNumber',
            'membersCount',
            'address',
            'housingStatus',
          ]) {
            if (latest[key] != original[key]) {
              throw Exception(
                'تم تعديل بيانات الأسرة من جهاز آخر. '
                    'يرجى تحديث الصفحة قبل الحفظ',
              );
            }
          }

          // ==================================
          // Update Family Data
          // ==================================

          transaction.update(familyRef, {
            'headName': newName,
            'phoneNumber': newPhone,
            'membersCount': newMembers,
            'address': newAddress,

            // Save editable housing status.
            'housingStatus': newHousingStatus,

            'updatedAt':
            FieldValue.serverTimestamp(),

            'updatedBy': currentUser.uid,

            'changeHistory': FieldValue.arrayUnion([
              historyEntry,
            ]),
          });
        },
      );

      if (!mounted) return;

      _reasonController.clear();

      await _loadFamilyData();

      if (!mounted) return;

      Get.snackbar(
        'تم الحفظ',
        'تم تحديث بيانات الأسرة بنجاح',
        snackPosition: SnackPosition.BOTTOM,
      );

    } on FirebaseException catch (e) {
      if (!mounted) return;

      Get.snackbar(
        'تعذر حفظ التعديلات',
        e.code == 'permission-denied'
            ? 'ليس لديك صلاحية لتعديل هذه الأسرة'
            : e.message ?? 'تعذر حفظ البيانات',
        snackPosition: SnackPosition.BOTTOM,
      );

    } catch (e) {
      if (!mounted) return;

      Get.snackbar(
        'تعذر حفظ التعديلات',
        e.toString().replaceFirst('Exception: ', ''),
        snackPosition: SnackPosition.BOTTOM,
      );

    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  // ==========================================
  // 4. Editable Text Field
  // ==========================================

  Widget _buildField({
    required String label,
    required TextEditingController controller,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment.stretch,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 9),
          TextFormField(
            controller: controller,
            enabled: _canEdit && !_isSaving,
            keyboardType: keyboardType,
            maxLines: maxLines,
            textAlign: TextAlign.right,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textPrimary,
            ),
            decoration: InputDecoration(
              filled: true,
              fillColor: AppColors.surface,
              contentPadding:
              const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 14,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: AppColors.border,
                ),
              ),
              disabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: AppColors.border,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: AppColors.primary,
                ),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: Colors.red,
                ),
              ),
              focusedErrorBorder:
              OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: Colors.red,
                ),
              ),
            ),
            validator: validator,
          ),
        ],
      ),
    );
  }

  // ==========================================
  // 5. Editable Housing Status
  // ==========================================

  Widget _buildHousingStatusField() {
    final currentValue = _selectedHousingStatus;

    // Include an existing value even if it is
    // not part of the predefined options.
    final options = <String>[
      ..._housingOptions,
      if (currentValue != null &&
          currentValue.isNotEmpty &&
          !_housingOptions.contains(currentValue))
        currentValue,
    ];

    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment.stretch,
        children: [
          const Text(
            'حالة السكن *',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),

          const SizedBox(height: 9),

          DropdownButtonFormField<String>(
            key: ValueKey(currentValue),
            initialValue: currentValue != null &&
                options.contains(currentValue)
                ? currentValue
                : null,

            isExpanded: true,

            decoration: InputDecoration(
              filled: true,
              fillColor: AppColors.surface,

              contentPadding:
              const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 10,
              ),

              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: AppColors.border,
                ),
              ),

              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: AppColors.border,
                ),
              ),

              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: AppColors.primary,
                ),
              ),
            ),

            hint: const Text(
              'اختر حالة السكن',
              style: TextStyle(
                color: AppColors.textSecondary,
              ),
            ),

            items: options.map((status) {
              return DropdownMenuItem<String>(
                value: status,
                child: Text(status),
              );
            }).toList(),

            onChanged: _canEdit && !_isSaving
                ? (value) {
              setState(() {
                _selectedHousingStatus = value;
              });
            }
                : null,

            validator: (value) {
              if (value == null ||
                  value.trim().isEmpty) {
                return 'يرجى اختيار حالة السكن';
              }

              return null;
            },
          ),
        ],
      ),
    );
  }

  // ==========================================
  // 6. Change History
  // ==========================================

  Widget _buildHistoryCard() {
    return Column(
      crossAxisAlignment:
      CrossAxisAlignment.stretch,
      children: [
        const Text(
          'سجل التغييرات',
          style: TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),

        const SizedBox(height: 14),

        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),

          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
              color: AppColors.border,
            ),
          ),

          child: _changeHistory.isEmpty
              ? const Padding(
            padding: EdgeInsets.symmetric(
              vertical: 18,
            ),
            child: Text(
              'لا توجد تعديلات مسجلة لهذه الأسرة بعد.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
          )
              : Column(
            crossAxisAlignment:
            CrossAxisAlignment.stretch,
            children: [
              for (var i = 0;
              i < _changeHistory.length;
              i++) ...[
                _buildHistoryItem(
                  _changeHistory[i],
                ),

                if (i != _changeHistory.length - 1)
                  const Divider(height: 26),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHistoryItem(
      Map<String, dynamic> event,
      ) {
    final actorName =
    (event['createdByName'] as String?)
        ?.trim();

    final description =
    (event['description'] as String?)
        ?.trim();

    final reason =
    (event['reason'] as String?)
        ?.trim();

    final timestamp = event['createdAt'];

    final date = timestamp is Timestamp
        ? timestamp.toDate()
        : null;

    return Column(
      crossAxisAlignment:
      CrossAxisAlignment.stretch,
      children: [
        Text(
          actorName != null &&
              actorName.isNotEmpty
              ? actorName
              : 'مستخدم',
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),

        if (date != null) ...[
          const SizedBox(height: 5),
          Text(
            _formatDate(date),
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ],

        const SizedBox(height: 8),

        Text(
          description != null &&
              description.isNotEmpty
              ? description
              : 'تم تعديل بيانات الأسرة',
          style: const TextStyle(
            fontSize: 13,
            color: AppColors.textSecondary,
          ),
        ),

        if (reason != null &&
            reason.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(
            'السبب: $reason',
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ],
    );
  }

  String _formatDate(DateTime date) {
    final hour = date.hour % 12 == 0
        ? 12
        : date.hour % 12;

    final minute =
    date.minute.toString().padLeft(2, '0');

    final period =
    date.hour >= 12 ? 'م' : 'ص';

    return '${date.day}/${date.month}/${date.year} '
        '· $hour:$minute $period';
  }

  // ==========================================
  // 7. Action Buttons
  // ==========================================

  Widget _buildActions() {
    if (!_canEdit) {
      return const SizedBox.shrink();
    }

    return Row(
      children: [
        Expanded(
          child: AppButton(text: 'حفظ التعديلات', onPressed: _isSaving ? null : _saveChanges,)
    ),]);
  }

  // ==========================================
  // 8. Screen
  // ==========================================

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,

      child: Scaffold(
        backgroundColor:
        AppColors.neutralBackground,

        appBar: CustomAppBar(
          title: _canEdit
              ? 'تعديل الأسرة'
              : 'ملف الأسرة',

          subtitle: widget.family.headName,

          leading: Icons.arrow_back,

          onLeadingPressed: () =>
              Navigator.of(context).pop(),
        ),

        body: _isLoading
            ? const Center(
          child: CircularProgressIndicator(
            color: AppColors.primary,
          ),
        )
            : _errorMessage != null
            ? _buildErrorState()
            : _buildContent(),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),

        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline,
              color: Colors.red,
              size: 46,
            ),

            const SizedBox(height: 12),

            Text(
              _errorMessage ??
                  'تعذر تحميل البيانات',
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 16),

            OutlinedButton(
              onPressed: _loadFamilyData,
              child: const Text('إعادة المحاولة'),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // 9. Main Content
  // ==========================================

  Widget _buildContent() {
    final data = _familyData!;

    final nationalId =
        (data['nationalId'] as String?) ?? '';

    return Form(
      key: _formKey,

      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          20, 18, 20, 30,
        ),

        child: Column(
          crossAxisAlignment:
          CrossAxisAlignment.stretch,

          children: [
            Align(
              alignment: Alignment.centerRight,

              child: Container(
                padding:
                const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 7,
                ),

                decoration: BoxDecoration(
                  color: AppColors.primary
                      .withValues(alpha: 0.08),

                  borderRadius:
                  BorderRadius.circular(8),
                ),

                child: Text(
                  _canEdit
                      ? 'التعديل متاح لهذا السجل'
                      : 'عرض السجل فقط',

                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 22),

            // Read-only national ID.
            _buildInfoLine(
              'رقم الهوية',
              nationalId,
            ),

            const SizedBox(height: 12),

            // Read-only area name.
            _buildInfoLine(
              'المنطقة',
              _areaName.isNotEmpty
                  ? _areaName
                  : 'غير محددة',
            ),

            const SizedBox(height: 22),

            _buildField(
              label: 'اسم رب الأسرة *',
              controller: _nameController,

              validator: (value) {
                if (value == null ||
                    value.trim().isEmpty) {
                  return 'يرجى إدخال اسم رب الأسرة';
                }

                return null;
              },
            ),

            _buildField(
              label: 'رقم الجوال *',
              controller: _phoneController,
              keyboardType: TextInputType.phone,

              validator: (value) {
                if (value == null ||
                    value.trim().isEmpty) {
                  return 'يرجى إدخال رقم الجوال';
                }

                return null;
              },
            ),

            _buildField(
              label: 'عدد أفراد الأسرة *',
              controller: _membersController,
              keyboardType: TextInputType.number,

              validator: (value) {
                final count = int.tryParse(
                  value?.trim() ?? '',
                );

                if (count == null || count < 1) {
                  return 'يرجى إدخال عدد أفراد صحيح';
                }

                return null;
              },
            ),

            _buildField(
              label: 'العنوان التفصيلي *',
              controller: _addressController,
              maxLines: 2,

              validator: (value) {
                if (value == null ||
                    value.trim().isEmpty) {
                  return 'يرجى إدخال العنوان';
                }

                return null;
              },
            ),

            // Editable housing status.
            _buildHousingStatusField(),

            if (_canEdit)
              _buildField(
                label: 'سبب التعديل - اختياري',
                controller: _reasonController,
                maxLines: 2,
              ),

            const SizedBox(height: 4),

            _buildActions(),

            const SizedBox(height: 30),

            _buildHistoryCard(),

            const SizedBox(height: 22),

            _buildPrivacyNotice(),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoLine(
      String label,
      String value,
      ) {
    return Row(
      children: [
        Text(
          '$label:',
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),

        const SizedBox(width: 8),

        Expanded(
          child: Text(
            value.isNotEmpty
                ? value
                : 'غير محدد',

            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }

  // ==========================================
  // 10. Privacy Notice
  // ==========================================

  Widget _buildPrivacyNotice() {
    return Container(
      padding: const EdgeInsets.all(15),

      decoration: BoxDecoration(
        color: AppColors.primary.withValues(
          alpha: 0.06,
        ),

        borderRadius:
        BorderRadius.circular(13),
      ),

      child: const Row(
        crossAxisAlignment:
        CrossAxisAlignment.start,

        children: [
          Icon(
            Icons.lock_outline,
            size: 21,
            color: AppColors.textSecondary,
          ),

          SizedBox(width: 10),

          Expanded(
            child: Text(
              'تعديل بيانات الأسرة متاح فقط '
                  'للمستخدمين المخوّلين وفق صلاحيات المؤسسة. '
                  'رقم الهوية والمنطقة لا يمكن تغييرهما '
                  'من هذه الشاشة.',

              style: TextStyle(
                fontSize: 12,
                height: 1.6,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // 11. Dispose
  // ==========================================

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _membersController.dispose();
    _addressController.dispose();
    _reasonController.dispose();

    super.dispose();
  }
}
