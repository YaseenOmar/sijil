import 'package:get/get.dart';
import 'package:sijil/features/notifications/constants/notification_demo_data.dart';
import 'package:sijil/features/notifications/models/notification_model.dart';

class NotificationsController extends GetxController {
  // كل الإشعارات
  final RxList<NotificationModel> notifications = <NotificationModel>[].obs;

  // 0 = الكل | 1 = غير المقروءة
  final RxInt selectedTab = 0.obs;

  // ---------- UI states ----------
  final RxBool isLoading = false.obs;
  final RxnString loadError = RxnString();

  // القائمة اللي بتنعرض حسب التاب المختار
  List<NotificationModel> get visibleNotifications {
    if (selectedTab.value == 0) return notifications.toList();
    return notifications.where((n) => !n.isRead).toList();
  }

  // عدد الإشعارات غير المقروءة (لتعطيل زر "تحديد الكل كمقروء")
  int get unreadCount => notifications.where((n) => !n.isRead).length;

  @override
  void onInit() {
    super.onInit();
    loadNotifications();
  }

  void loadNotifications() {
    try {
      isLoading.value = true;
      loadError.value = null;

      // TODO: read the notifications and their read state from the local storage
      notifications.assignAll(NotificationDemoData.notifications);
    } catch (e) {
      loadError.value = 'تعذر تحميل الإشعارات، يرجى المحاولة مرة أخرى';
    } finally {
      isLoading.value = false;
    }
  }

  void changeTab(int index) => selectedTab.value = index;

  // تحويل إشعار واحد لمقروء (لما المستخدم يضغط عليه)
  void markAsRead(String id) {
    final index = notifications.indexWhere((n) => n.id == id);
    if (index == -1 || notifications[index].isRead) return;

    // TODO: save the read state in the local storage
    notifications[index] = notifications[index].copyWith(isRead: true);
  }

  // زر "تحديد إشعاراتي كمقروءة"
  void markAllAsRead() {
    // TODO: save the read state in the local storage
    notifications.assignAll(
      notifications.map((n) => n.copyWith(isRead: true)).toList(),
    );
  }
}
