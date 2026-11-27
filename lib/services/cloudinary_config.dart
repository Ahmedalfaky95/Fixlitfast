/// إعدادات Cloudinary.
///
/// مهم: لا تضع API_KEY أو API_SECRET هنا أبداً. أي شيء داخل التطبيق يمكن
/// لأي شخص استخراجه من ملف APK. الرفع يتم عن طريق "Unsigned upload preset"
/// ولا يحتاج إلى أي مفتاح سري.
class CloudinaryConfig {
  CloudinaryConfig._();

  static const String cloudName = 'dtkha2cje';

  /// اسم الـ preset غير الموقّع المعرّف في لوحة Cloudinary.
  static const String uploadPreset = 'complaints_uploads';

  static const String uploadUrl =
      'https://api.cloudinary.com/v1_1/$cloudName/image/upload';
}
