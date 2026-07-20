import 'package:cloud_firestore/cloud_firestore.dart';

class Student {
  final String? id;
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
  final String address;
  final String? address2;
  final String city;
  final String? zip;
  final String fatherName;
  final String fatherPhone;
  final String motherName;
  final String motherPhone;
  final String parentAddress;
  final String className;
  final String section;
  final String? boardRegNo;
  final String tenantId;
  final String? photoUrl;
  final bool isArchived;
  final DateTime? createdAt;
  final DateTime? updatedAt;

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
    required this.tenantId,
    this.photoUrl,
    this.isArchived = false,
    this.createdAt,
    this.updatedAt,
  });

  String get fullName => '$firstName $lastName'.trim();

  Student copyWithTenant(String tenantId) {
    return Student(
      id: id,
      firstName: firstName,
      lastName: lastName,
      email: email,
      birthday: birthday,
      gender: gender,
      bloodType: bloodType,
      religion: religion,
      nationality: nationality,
      phone: phone,
      idCardNumber: idCardNumber,
      address: address,
      address2: address2,
      city: city,
      zip: zip,
      fatherName: fatherName,
      fatherPhone: fatherPhone,
      motherName: motherName,
      motherPhone: motherPhone,
      parentAddress: parentAddress,
      className: className,
      section: section,
      boardRegNo: boardRegNo,
      tenantId: tenantId,
      photoUrl: photoUrl,
      isArchived: isArchived,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  Map<String, dynamic> toCreateMap({required String createdBy}) =>
      <String, dynamic>{
        ..._baseMap(),
        'createdBy': createdBy,
        'updatedBy': createdBy,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

  Map<String, dynamic> _baseMap() => <String, dynamic>{
        'firstName': firstName,
        'lastName': lastName,
        'fullNameLower': fullName.toLowerCase(),
        'email': email.trim().toLowerCase(),
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
        'isArchived': isArchived,
      };

  factory Student.fromDoc(String id, Map<String, dynamic> map) {
    String stringValue(String key) => map[key]?.toString() ?? '';

    return Student(
      id: id,
      firstName: stringValue('firstName'),
      lastName: stringValue('lastName'),
      email: stringValue('email'),
      birthday: map['birthday']?.toString(),
      gender: stringValue('gender'),
      bloodType: stringValue('bloodType'),
      religion: stringValue('religion'),
      nationality: stringValue('nationality'),
      phone: stringValue('phone'),
      idCardNumber: stringValue('idCardNumber'),
      address: stringValue('address'),
      address2: map['address2']?.toString(),
      city: stringValue('city'),
      zip: map['zip']?.toString(),
      fatherName: stringValue('fatherName'),
      fatherPhone: stringValue('fatherPhone'),
      motherName: stringValue('motherName'),
      motherPhone: stringValue('motherPhone'),
      parentAddress: stringValue('parentAddress'),
      className: stringValue('className'),
      section: stringValue('section'),
      boardRegNo: map['boardRegNo']?.toString(),
      tenantId: stringValue('tenantId'),
      photoUrl: map['photoUrl']?.toString(),
      isArchived:
          map['isArchived'] is bool ? map['isArchived'] as bool : false,
      createdAt: _dateFromValue(map['createdAt']),
      updatedAt: _dateFromValue(map['updatedAt']),
    );
  }
}

DateTime? _dateFromValue(dynamic value) {
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;
  if (value == null) return null;
  return DateTime.tryParse(value.toString());
}
