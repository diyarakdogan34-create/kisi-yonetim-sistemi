class Person {
  const Person({
    this.id,
    required this.fullName,
    required this.department,
    required this.photoUrl,
    required this.birthPlace,
    required this.birthDate,
    required this.email,
    required this.phone,
  });

  final int? id;
  final String fullName;
  final String department;
  final String photoUrl;
  final String birthPlace;
  final String birthDate;
  final String email;
  final String phone;

  factory Person.fromJson(Map<String, dynamic> json) => Person(
    id: json['id'] as int,
    fullName: json['fullName'] as String,
    department: json['department'] as String,
    photoUrl: json['photoUrl'] as String? ?? '',
    birthPlace: json['birthPlace'] as String,
    birthDate: json['birthDate'] as String,
    email: json['email'] as String,
    phone: json['phone'] as String,
  );

  // ID sunucuda üretilir; POST/PUT gövdesine eklenmez.
  Map<String, dynamic> toJson() => {
    'fullName': fullName,
    'department': department,
    'photoUrl': photoUrl,
    'birthPlace': birthPlace,
    'birthDate': birthDate,
    'email': email,
    'phone': phone,
  };

  String get displayBirthDate => birthDate.split('-').reversed.join('.');
}
