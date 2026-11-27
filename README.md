# FixItFast (fixltfast)

تطبيق Flutter لإدارة شكاوى المجمعات السكنية: المستخدم يرسل شكوى مع صورة ويتابع حالتها،
والمسؤول يستقبل الشكاوى وينقلها بين الحالات (Pending → In Progress → Completed).

## مشروع Firebase

التطبيق مربوط بمشروع **alroad** (`alroad-76fe5`). الشكاوى في مجموعة `complaints`،
والملفات الشخصية في `users`، والمسؤولون في `admins`.

## هيكل المشروع

```
lib/
  main.dart                 نقطة البداية وتسجيل الخدمات (Provider)
  firebase_options.dart     إعدادات Firebase (مولّد بواسطة FlutterFire)
  models/                   نماذج البيانات (Complaint, ComplaintStatus, UserProfile)
  services/                 Firebase Auth و Firestore و Cloudinary
  widgets/                  عناصر واجهة مشتركة (أزرار، بطاقات، قوائم)
  screens/                  شاشات المستخدم
  screens/admin/            شاشات المسؤول
firestore.rules             قواعد أمان Firestore
firestore.indexes.json      الفهارس المطلوبة للاستعلامات
```

## التشغيل

```bash
flutter pub get
flutter run
flutter test
```

## إعداد Firebase (مرة واحدة)

```bash
npm install -g firebase-tools
firebase login
firebase deploy --only firestore
```

هذا ينشر قواعد الأمان والفهارس. بدون الفهارس لن تظهر قوائم الشكاوى.

لجعل حساب ما مسؤولاً: من Firebase Console أنشئ مستنداً في مجموعة `admins`
معرّفه هو UID المستخدم، وفيه الحقل `isAdmin: true` (Boolean).

## النشر على Google Play

أنشئ مفتاح توقيع وملف `android/key.properties` حسب
https://docs.flutter.dev/deployment/android#sign-the-app
ولا ترفع هذا الملف أو المفتاح على git.
