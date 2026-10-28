import 'package:get/get.dart';
import 'package:sijil/features/notifications/models/notification_model.dart';

class NotificationsController extends GetxController {
  // كل الإشعارات
  final RxList<NotificationModel> notifications = <NotificationModel>[].obs;

  // 0 = الكل | 1 = غير المقروءة
  final RxInt selectedTab = 0.obs;

  // القائمة اللي بتنعرض حسب التاب المختار
  List<NotificationModel> get visibleNotifications {
    if (selectedTab.value == 0) return notifications.toList();
    return notifications.where((n) => !n.isRead).toList();
  }

  @override
  void onInit() {
    super.onInit();
    _loadDemoNotifications();
  }

  void changeTab(int index) => selectedTab.value = index;

  // تحويل إشعار واحد لمقروء (لما المستخدم يضغط عليه)
  void markAsRead(String id) {
    final index = notifications.indexWhere((n) => n.id == id);
    if (index == -1 || notifications[index].isRead) return;
    notifications[index] = notifications[index].copyWith(isRead: true);
  }

  // زر "تحديد إشعاراتي كمقروءة"
  void markAllAsRead() {
    notifications.assignAll(
      notifications.map((n) => n.copyWith(isRead: true)).toList(),
    );
  }

  // بيانات تجريبية مطابقة للتصميم، لحد ما ننربط مع Firebase
  void _loadDemoNotifications() {
    notifications.assignAll(const [
      NotificationModel(
        id: 'n1',
        title: 'تعذّر رفع إثبات الاستلام',
        body:
        'إثبات مساعدة يوسف لا يزال على الجهاز. أعد المحاولة من مركز المزامنة.',
        time: '٢١ أكتوبر ٢٠٢٦، ٩:٤٠ ص',
        isRead: false,
        type: NotificationType.alert,
      ),
      NotificationModel(
        id: 'n2',
        title: 'تعارض يحتاج إلى اطلاع المشرفة',
        body:
        'احتُفظ بآخر تعديل لعدد أفراد أسرة محمود تلقائيًا. التفاصيل متاحة للمشرفة نورا فقط.',
        time: '٢١ أكتوبر ٢٠٢٦، ٩:٣٨ ص',
        isRead: false,
        type: NotificationType.supervisorOnly,
      ),
      NotificationModel(
        id: 'n3',
        title: 'تم تقديم الخدمة · الإحالة ٠٠٤٢',
        body:
        'إلى أحمد سالم: أنهى مركز الشفاء خدمة الرعاية الصحية لأسرة محمود حسن العلي.',
        time: '٢٠ أكتوبر ٢٠٢٦، ٢:٠٥ م',
        isRead: false,
      ),
      NotificationModel(
        id: 'n4',
        title: 'الإحالة ٠٠٤٢ قيد المراجعة',
        body: 'بدأ مركز الشفاء مراجعة طلب الرعاية الصحية.',
        time: '١٩ أكتوبر ٢٠٢٦، ١١:١٥ ص',
        isRead: true,
      ),
      NotificationModel(
        id: 'n5',
        title: 'استلمت الإحالة ٠٠٤٢',
        body: 'أكد مركز الشفاء استلام الإحالة المرسلة في ١٧ أكتوبر.',
        time: '١٨ أكتوبر ٢٠٢٦، ٩:٠٠ ص',
        isRead: true,
      ),
      NotificationModel(
        id: 'n6',
        title: 'أُرسلت الإحالة ٠٠٤٢',
        body: 'نجح إرسال الإحالة من جمعية الأمان؛ بانتظار تأكيد الاستلام.',
        time: '١٧ أكتوبر ٢٠٢٦، ١٠:٣٠ ص',
        isRead: true,
      ),
    ]);
  }
}