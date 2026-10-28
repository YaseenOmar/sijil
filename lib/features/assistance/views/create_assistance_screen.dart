import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sijil/features/assistance/controllers/assistance_controller.dart';
import 'package:sijil/features/assistance/data/models/assistance_model.dart';
import '../../../../core/widgets/custom_app_bar.dart';
import 'assistance_duplicate_warning_screen.dart';

class FamilyInfo {
  final String id;
  final String name;
  final int membersCount;
  final String area;
  final String nationalId;

  const FamilyInfo({
    required this.id,
    required this.name,
    required this.membersCount,
    required this.area,
    required this.nationalId,
  });
}

class CreateAssistanceScreen extends StatefulWidget {
  final FamilyInfo? initialFamily;

  const CreateAssistanceScreen({super.key, this.initialFamily});

  @override
  State<CreateAssistanceScreen> createState() => _CreateAssistanceScreenState();
}

class _CreateAssistanceScreenState extends State<CreateAssistanceScreen> {
  final List<FamilyInfo> availableFamilies = const [
    FamilyInfo(
      id: '408532936',
      name: 'محمود حسن العلي',
      membersCount: 6,
      area: 'حي النور',
      nationalId: '408532936',
    ),
    FamilyInfo(
      id: '408532937',
      name: 'يوسف ناصر حمد',
      membersCount: 4,
      area: 'حي النور',
      nationalId: '408532937',
    ),
    FamilyInfo(
      id: '408532938',
      name: 'هناء علي منصور',
      membersCount: 5,
      area: 'حي السلام',
      nationalId: '408532938',
    ),
    FamilyInfo(
      id: '408532939',
      name: 'خالد إبراهيم النجار',
      membersCount: 8,
      area: 'حي النور',
      nationalId: '408532939',
    ),
  ];

  late FamilyInfo selectedFamily;

  String selectedType = 'طرد غذائي';
  int deliveryProofType = 0; // 0 = توقيع المستلم, 1 = صورة إثبات الاستلام
  DateTime selectedDate = DateTime.now();
  final quantityController = TextEditingController(text: '1');
  final notesController = TextEditingController();
  List<Offset?> signaturePoints = [];

  @override
  void initState() {
    super.initState();
    selectedFamily = widget.initialFamily ?? availableFamilies.first;
  }

  void _openFamilySelectionSheet() {
    Get.bottomSheet(
      Directionality(
        textDirection: TextDirection.rtl,
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'اختيار الأسرة المستفيدة',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A202C),
                  ),
                ),
              ),
              const Divider(height: 20),
              ListView.builder(
                shrinkWrap: true,
                itemCount: availableFamilies.length,
                itemBuilder: (context, index) {
                  final family = availableFamilies[index];
                  final isSelected = family.id == selectedFamily.id;
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: isSelected
                          ? const Color(0xFF135354)
                          : const Color(0xFFE8F3EE),
                      child: Icon(
                        Icons.person,
                        color: isSelected
                            ? Colors.white
                            : const Color(0xFF135354),
                        size: 20,
                      ),
                    ),
                    title: Text(
                      family.name,
                      style: TextStyle(
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color: const Color(0xFF1A202C),
                      ),
                    ),
                    subtitle: Text(
                      '${family.membersCount} أفراد · ${family.area} · ${family.nationalId}',
                    ),
                    trailing: isSelected
                        ? const Icon(
                            Icons.check_circle,
                            color: Color(0xFF135354),
                          )
                        : null,
                    onTap: () {
                      setState(() {
                        selectedFamily = family;
                      });
                      Get.back();
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2025),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF135354),
              onPrimary: Colors.white,
              onSurface: Color(0xFF1A202C),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => selectedDate = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final AssistanceController controller = Get.find<AssistanceController>();

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFFF9FAFB),
        appBar: CustomAppBar(
          title: 'تسجيل مساعدة',
          subtitle: 'توثيق التسليم',
          action: Icons.arrow_forward,
          onActionPressed: () => Get.back(),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFEBF7F4),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFCCE7DF)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      selectedFamily.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF135354),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${selectedFamily.membersCount} أفراد · ${selectedFamily.area} · ${selectedFamily.nationalId}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.blueGrey,
                      ),
                    ),
                    const SizedBox(height: 10),
                    OutlinedButton(
                      onPressed: _openFamilySelectionSheet,
                      style: OutlinedButton.styleFrom(
                        backgroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 36),
                        side: BorderSide(color: Colors.grey.shade300),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'تغيير الأسرة',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF135354),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              const Text(
                'نوع المساعدة *',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                value: selectedType,
                items: ['طرد غذائي', 'مستلزمات نظافة', 'كسوة شتاء']
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (val) => setState(() => selectedType = val!),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                ),
              ),
              const SizedBox(height: 14),

              const Text(
                'الكمية *',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              TextFormField(
                controller: quantityController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  helperText: 'الوحدة: طرد واحد (أدخل عدداً صحيحاً)',
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                ),
              ),
              const SizedBox(height: 14),

              const Text(
                'تاريخ التسليم *',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              InkWell(
                onTap: () => _pickDate(context),
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.calendar_today_outlined,
                        size: 18,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${selectedDate.year}/${selectedDate.month}/${selectedDate.day}',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      const Icon(Icons.arrow_drop_down, color: Colors.grey),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),

              const Text(
                'إثبات الاستلام * (اختر وسيلة واحدة)',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: ChoiceChip(
                      label: const Center(child: Text('توقيع المستلم')),
                      selected: deliveryProofType == 0,
                      onSelected: (val) =>
                          setState(() => deliveryProofType = 0),
                      selectedColor: const Color(0xFF135354),
                      labelStyle: TextStyle(
                        color: deliveryProofType == 0
                            ? Colors.white
                            : Colors.black87,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ChoiceChip(
                      label: const Center(child: Text('صورة إثبات الاستلام')),
                      selected: deliveryProofType == 1,
                      onSelected: (val) =>
                          setState(() => deliveryProofType = 1),
                      selectedColor: const Color(0xFF135354),
                      labelStyle: TextStyle(
                        color: deliveryProofType == 1
                            ? Colors.white
                            : Colors.black87,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (deliveryProofType == 0)
                Container(
                  height: 140,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Stack(
                    children: [
                      GestureDetector(
                        onPanUpdate: (details) {
                          setState(() {
                            signaturePoints.add(details.localPosition);
                          });
                        },
                        onPanEnd: (details) => signaturePoints.add(null),
                        child: CustomPaint(
                          painter: SignaturePainter(points: signaturePoints),
                          size: Size.infinite,
                        ),
                      ),
                      Positioned(
                        bottom: 4,
                        left: 8,
                        child: TextButton.icon(
                          onPressed: () =>
                              setState(() => signaturePoints.clear()),
                          icon: const Icon(
                            Icons.refresh,
                            size: 14,
                            color: Colors.grey,
                          ),
                          label: const Text(
                            'مسح التوقيع وإعادته',
                            style: TextStyle(fontSize: 11, color: Colors.grey),
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              else
                Container(
                  height: 120,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Center(
                    child: TextButton.icon(
                      onPressed: () {},
                      icon: const Icon(
                        Icons.camera_alt_outlined,
                        color: Color(0xFF135354),
                      ),
                      label: const Text(
                        'التقاط صورة إثبات الاستلام',
                        style: TextStyle(color: Color(0xFF135354)),
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F3EE),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Icon(
                      Icons.verified_user_outlined,
                      size: 20,
                      color: Color(0xFF135354),
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'التثبت من التكرار قبل الحفظ: نوع والكمية وتاريخ وإثبات الاستلام مطلوبة لتفادي تكرار الخدمة عند المراجعة.',
                        style: TextStyle(
                          fontSize: 11,
                          color: Color(0xFF135354),
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: () {
                    final duplicateRecord = controller.checkDuplicate(
                      selectedFamily.id,
                      selectedType,
                      selectedDate,
                    );

                    if (duplicateRecord != null) {
                      Get.to(() => const AssistanceDuplicateWarningScreen());
                      return;
                    }

                    final newRecord = AssistanceRecord(
                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                      beneficiaryId: selectedFamily.id,
                      beneficiaryName: selectedFamily.name,
                      assistanceType: selectedType,
                      quantity: '${quantityController.text.trim()} طرد',
                      deliveryDate: selectedDate,
                      officerName: 'أحمد سالم',
                      area: selectedFamily.area,
                      status: 'pending',
                      proofType: deliveryProofType == 0 ? 'signature' : 'photo',
                      notes: notesController.text.trim(),
                    );

                    controller.addAssistance(newRecord);

                    Get.back();
                    Get.snackbar(
                      'تم بنجاح',
                      'تم تسجيل المساعدة لـ (${selectedFamily.name}) وحفظها محلياً',
                      snackPosition: SnackPosition.BOTTOM,
                      backgroundColor: const Color(0xFF135354),
                      colorText: Colors.white,
                    );
                  },
                  icon: const Icon(Icons.save_outlined, color: Colors.white),
                  label: const Text(
                    'حفظ المساعدة على الجهاز',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF135354),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SignaturePainter extends CustomPainter {
  final List<Offset?> points;
  SignaturePainter({required this.points});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF135354)
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 2.5;

    for (int i = 0; i < points.length - 1; i++) {
      if (points[i] != null && points[i + 1] != null) {
        canvas.drawLine(points[i]!, points[i + 1]!, paint);
      }
    }
  }

  @override
  bool shouldRepaint(SignaturePainter oldDelegate) => true;
}
