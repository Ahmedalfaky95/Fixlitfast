/// بيانات الملف الشخصي للمستخدم، محفوظة في Firestore تحت users/{uid}
/// حتى تكون مرتبطة بالحساب وليس بالجهاز.
class UserProfile {
  final String name;
  final String phone;
  final String email;
  final String birthDate; // بصيغة yyyy-MM-dd
  final String gender;
  final String address;

  const UserProfile({
    this.name = '',
    this.phone = '',
    this.email = '',
    this.birthDate = '',
    this.gender = '',
    this.address = '',
  });

  factory UserProfile.fromMap(Map<String, dynamic>? data) {
    return UserProfile(
      name: data?['name'] as String? ?? '',
      phone: data?['phone'] as String? ?? '',
      email: data?['email'] as String? ?? '',
      birthDate: data?['birthDate'] as String? ?? '',
      gender: data?['gender'] as String? ?? '',
      address: data?['address'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'phone': phone,
      'email': email,
      'birthDate': birthDate,
      'gender': gender,
      'address': address,
    };
  }

  UserProfile copyWith({
    String? name,
    String? phone,
    String? email,
    String? birthDate,
    String? gender,
    String? address,
  }) {
    return UserProfile(
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      birthDate: birthDate ?? this.birthDate,
      gender: gender ?? this.gender,
      address: address ?? this.address,
    );
  }
}
