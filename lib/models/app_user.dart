class AppUser {
  final String uid;
  final String name;
  final String email;
  final String phone;
  final String role; // 'doctor' | 'patient'
  // Doctor-specific
  final String licenseNumber;
  final String specialization;
  // Patient-specific
  final String age;
  final String gender;
  final String bloodGroup;
  final String? photoUrl;

  const AppUser({
    required this.uid,
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
    this.licenseNumber = '',
    this.specialization = '',
    this.age = '',
    this.gender = '',
    this.bloodGroup = '',
    this.photoUrl,
  });

  factory AppUser.fromMap(String uid, Map<String, dynamic> m) => AppUser(
        uid: uid,
        name: m['name'] ?? '',
        email: m['email'] ?? '',
        phone: m['phone'] ?? '',
        role: m['role'] ?? 'patient',
        licenseNumber: m['licenseNumber'] ?? '',
        specialization: m['specialization'] ?? '',
        age: m['age'] ?? '',
        gender: m['gender'] ?? '',
        bloodGroup: m['bloodGroup'] ?? '',
        photoUrl: m['photoUrl'],
      );

  Map<String, dynamic> toMap() => {
        'name': name,
        'email': email,
        'phone': phone,
        'role': role,
        'licenseNumber': licenseNumber,
        'specialization': specialization,
        'age': age,
        'gender': gender,
        'bloodGroup': bloodGroup,
        'photoUrl': photoUrl,
      };

  AppUser copyWith({
    String? name,
    String? email,
    String? phone,
    String? age,
    String? gender,
    String? bloodGroup,
    String? licenseNumber,
    String? specialization,
    String? photoUrl,
  }) => AppUser(
        uid: uid,
        name: name ?? this.name,
        email: email ?? this.email,
        phone: phone ?? this.phone,
        role: role,
        licenseNumber: licenseNumber ?? this.licenseNumber,
        specialization: specialization ?? this.specialization,
        age: age ?? this.age,
        gender: gender ?? this.gender,
        bloodGroup: bloodGroup ?? this.bloodGroup,
        photoUrl: photoUrl ?? this.photoUrl,
      );
}
