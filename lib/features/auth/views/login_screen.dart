import 'package:flutter/material.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool showPassword = false;

  // ألوان التطبيق
  static const Color primaryColor = Color(0xFF155E59);
  static const Color backgroundColor = Color(0xFFF8F7F4);
  static const Color appBarColor = Color(0xFFFFFFFF);
  static const Color textColor = Color(0xFF202D2B);

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: backgroundColor,

        appBar: _buildHeader(),

        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [

               const SizedBox(height: 40),

                // logo
                _buildLogo(),

                const SizedBox(height: 8),

                // title
                const Text(
                  'سِجل',
                  style: TextStyle(
                    fontSize: 42,
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                  ),
                ),

                const SizedBox(height: 8),

                const Text(
                  'بيانات موثوقة. مساعدة في وقتها.',
                  style: TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),

                const SizedBox(height: 12),

                const Text(
                  'مساحة عمل فريقك لتسجيل الأسر ومتابعة '
                  'المساعدات والإحالات بكرامة وخصوصية.',
                  style: TextStyle(
                    fontSize: 15,
                    height: 1.7,
                    color: Colors.blueGrey,
                  ),
                ),

                const SizedBox(height: 40),

                // email
                _buildLabel('البريد الإلكتروني *'),

                const SizedBox(height: 6),

                TextField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  textDirection: TextDirection.ltr,
                  decoration: _inputDecoration(
                    hint: 'ahmad@alaman.org',
                    icon: Icons.mail_outline,
                  ),
                ),

                const SizedBox(height: 20),

                // كلمة المرور
                _buildLabel('كلمة المرور *'),

                const SizedBox(height: 6),

                TextField(
                  controller: passwordController,
                  obscureText: !showPassword,
                  textDirection: TextDirection.ltr,
                  decoration: _inputDecoration(
                    hint: '••••••••',
                    icon: showPassword
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    onIconPressed: () {
                      setState(() {
                        showPassword = !showPassword;
                      });
                    },
                  ),
                ),

                const SizedBox(height: 48),

                // login button
                SizedBox(
                  height: 56,
                  child: ElevatedButton(
                    onPressed: (){},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'تسجيل الدخول',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(width: 8),
                        Icon(Icons.arrow_forward),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // contact with supervisor
                OutlinedButton(
                  onPressed: () {},
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 56),
                    side: const BorderSide(color: Color(0xFFD5DFDC)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'تحتاج إلى مساعدة؟ تواصل مع المشرف',
                    style: TextStyle(
                      color: primaryColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // connectivity note
                _buildInfoBox(),

                const SizedBox(height: 20),

                const Text(
                  'مخصص للموظفين المعتمدين لدى جهات العمل المشاركة.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: Colors.blueGrey),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // app bar
  PreferredSizeWidget _buildHeader() {
    return AppBar(
      backgroundColor: appBarColor,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      automaticallyImplyLeading: false,

      title: const Text(
        'أهلاً بك في سِجل',
        style: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: textColor,
        ),
      ),

      actions: [
        Padding(
          padding: const EdgeInsets.only(left: 20),
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F3F0),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.verified_user_outlined,
              color: primaryColor,
            ),
          ),
        ),
      ],
    );
  }

  // logo
  Widget _buildLogo() {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          color: primaryColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(
          Icons.menu_book_outlined,
          color: Colors.white,
          size: 32,
        ),
      ),
    );
  }

  // label
  Widget _buildLabel(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.bold,
        color: textColor,
      ),
    );
  }

  // text field
  InputDecoration _inputDecoration({
    required String hint,
    required IconData icon,
    VoidCallback? onIconPressed,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.grey),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      suffixIcon: IconButton(
        onPressed: onIconPressed,
        icon: Icon(icon, color: Colors.blueGrey),
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFD5DFDC)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFD5DFDC)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: primaryColor, width: 1.5),
      ),
    );
  }

  // connectivity note
  Widget _buildInfoBox() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFE4F2EF),
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.wifi, color: primaryColor),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'الاتصال مطلوب لأول تسجيل دخول',
                  style: TextStyle(
                    color: primaryColor,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'بعد تسجيل الدخول بنجاح، يمكنك استخدام '
                  'جلستك المحفوظة دون اتصال. لا يمكن بدء '
                  'جلسة جديدة دون إنترنت.',
                  style: TextStyle(
                    color: primaryColor,
                    fontSize: 16,
                    height: 1.7,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

}
