import 'package:cloud_firestore/cloud_firestore.dart';

/// Full student record persisted to Firestore.
class Student {
  final String? id;

  // Personal
  final String firstName;
  final String lastName;
  final String email;
  final String? birthday;
  final String gender;
  final String bloodType;
  final String religion;
  final String nationality;
  final String phone;
  final String idCardNumber;

  // Address
  final String address;
  final String? address2;
  final String city;
  final String? zip;

  // Parents
  final String fatherName;
  final String fatherPhone;
  final String motherName;
  final String motherPhone;
  final String parentAddress;

  // Academic
  final String className;
  final String section;
  final String? boardRegNo;

  final String tenantId;
  final String? photoUrl;

  const Student({
    this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    this.birthday,
    required this.gender,
    required this.bloodType,
    required this.religion,
    required this.nationality,
    required this.phone,
    required this.idCardNumber,
    required this.address,
    this.address2,
    required this.city,
    this.zip,
    required this.fatherName,
    required this.fatherPhone,
    required this.motherName,
    required this.motherPhone,
    required this.parentAddress,
    required this.className,
    required this.section,
    this.boardRegNo,
    this.tenantId = '',
    this.photoUrl,
  });

  String get fullName => '$firstName $lastName'.trim();

  Map<String, dynamic> toMap() => {
        'firstName': firstName,
        'lastName': lastName,
        'email': email,
        'birthday': birthday,
        'gender': gender,
        'bloodType': bloodType,
        'religion': religion,
        'nationality': nationality,
        'phone': phone,
        'idCardNumber': idCardNumber,
        'address': address,
        'address2': address2,
        'city': city,
        'zip': zip,
        'fatherName': fatherName,
        'fatherPhone': fatherPhone,
        'motherName': motherName,
        'motherPhone': motherPhone,
        'parentAddress': parentAddress,
        'className': className,
        'section': section,
        'boardRegNo': boardRegNo,
        'tenantId': tenantId,
        'photoUrl': photoUrl,
        'createdAt': FieldValue.serverTimestamp(),
      };

  factory Student.fromDoc(String id, Map<String, dynamic> m) {
    String s(String k) => (m[k] as String?) ?? '';
    return Student(
      id: id,
      firstName: s('firstName'),
      lastName: s('lastName'),
      email: s('email'),
      birthday: m['birthday'] as String?,
      gender: s('gender'),
      bloodType: s('bloodType'),
      religion: s('religion'),
      nationality: s('nationality'),
      phone: s('phone'),
      idCardNumber: s('idCardNumber'),
      address: s('address'),
      address2: m['address2'] as String?,
      city: s('city'),
      zip: m['zip'] as String?,
      fatherName: s('fatherName'),
      fatherPhone: s('fatherPhone'),
      motherName: s('motherName'),
      motherPhone: s('motherPhone'),
      parentAddress: s('parentAddress'),
      className: s('className'),
      section: s('section'),
      boardRegNo: m['boardRegNo'] as String?,
      tenantId: s('tenantId'),
      photoUrl: m['photoUrl'] as String?,
    );
  }
}
