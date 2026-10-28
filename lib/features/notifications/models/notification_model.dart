// نوع الإشعار: بيحدد شكل الشارة (البادج) فقط
enum NotificationType {
  normal, // إشعار عادي
  alert, // تنبيه مهم (مثل: تعذّر رفع إثبات الاستلام)
  supervisorOnly, // للمشرف فقط (مثل: تعارض يحتاج إلى اطلاع المشرفة)
}

class NotificationModel {
  final String id;
  final String title; // العنوان
  final String body; // النص تحت العنوان
  final String time; // الوقت (نص جاهز مؤقتاً لحد ما ينربط مع Firebase)
  final bool isRead; // مقروء أو لا
  final NotificationType type;

  const NotificationModel({
    required this.id,
    required this.title,
    required this.body,
    required this.time,
    required this.isRead,
    this.type = NotificationType.normal,
  });

  // بننسخ الإشعار مع تغيير حالة القراءة فقط
  NotificationModel copyWith({bool? isRead}) {
    return NotificationModel(
      id: id,
      title: title,
      body: body,
      time: time,
      isRead: isRead ?? this.isRead,
      type: type,
    );
  }
}