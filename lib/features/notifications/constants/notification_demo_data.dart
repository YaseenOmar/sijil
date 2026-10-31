import 'package:sijil/features/notifications/models/notification_model.dart';

// Temporary data until notifications come from the local storage / Firestore.
// Replace it with the real service before production use.
class NotificationDemoData {
  NotificationDemoData._();

  // Temporary: the signed in supervisor until it comes from authentication
  static const String supervisorLabel = 'نورا إبراهيم · مشرفة جمعية الأمان';

  // بيانات تجريبية مطابقة للتصميم
  static const List<NotificationModel> notifications = [
    NotificationModel(
      id: 'n1',
      title: 'تعذّر رفع إثبات الاستلام',
      body: 'إثبات مساعدة يوسف لا يزال على الجهاز. أعد المحاولة من مركز المزامنة.',
      time: '٢١ أكتوبر ٢٠٢٦، ٩:٤٠ ص',
      isRead: false,
      type: NotificationType.alert,
    ),
    NotificationModel(
      id: 'n2',
      title: 'تعارض يحتاج إلى اطلاع المشرفة',
      body: 'احتُفظ بآخر تعديل لعدد أفراد أسرة محمود تلقائيًا. التفاصيل متاحة للمشرفة نورا فقط.',
      time: '٢١ أكتوبر ٢٠٢٦، ٩:٣٨ ص',
      isRead: false,
      type: NotificationType.supervisorOnly,
    ),
    NotificationModel(
      id: 'n3',
      title: 'تم تقديم الخدمة · الإحالة ٠٠٤٢',
      body: 'إلى أحمد سالم: أنهى مركز الشفاء خدمة الرعاية الصحية لأسرة محمود حسن العلي.',
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
      title: 'استُلمت الإحالة ٠٠٤٢',
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
  ];
}
