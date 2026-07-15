/// Customer entity persisted in SQLite.
class CustomerModel {
  const CustomerModel({
    required this.id,
    required this.name,
    required this.phone,
    this.cnic,
    this.address,
    this.totalUdhaar = 0,
    this.totalReceived = 0,
    this.remainingBalance = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  final int id;
  final String name;
  final String phone;
  final String? cnic;
  final String? address;
  final double totalUdhaar;
  final double totalReceived;
  final double remainingBalance;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory CustomerModel.fromMap(Map<String, Object?> map) {
    return CustomerModel(
      id: map['id'] as int,
      name: (map['name'] as String?) ?? '',
      phone: (map['phone'] as String?) ?? '',
      cnic: map['cnic'] as String?,
      address: map['address'] as String?,
      totalUdhaar: (map['total_udhaar'] as num?)?.toDouble() ?? 0,
      totalReceived: (map['total_received'] as num?)?.toDouble() ?? 0,
      remainingBalance: (map['remaining_balance'] as num?)?.toDouble() ?? 0,
      createdAt: DateTime.tryParse((map['created_at'] as String?) ?? '') ??
          DateTime.now(),
      updatedAt: DateTime.tryParse((map['updated_at'] as String?) ?? '') ??
          DateTime.now(),
    );
  }

  Map<String, Object?> toMap({bool includeId = false}) {
    return {
      if (includeId) 'id': id,
      'name': name,
      'phone': phone,
      'cnic': cnic,
      'address': address,
      'total_udhaar': totalUdhaar,
      'total_received': totalReceived,
      'remaining_balance': remainingBalance,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  CustomerModel copyWith({
    int? id,
    String? name,
    String? phone,
    String? cnic,
    String? address,
    double? totalUdhaar,
    double? totalReceived,
    double? remainingBalance,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CustomerModel(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      cnic: cnic ?? this.cnic,
      address: address ?? this.address,
      totalUdhaar: totalUdhaar ?? this.totalUdhaar,
      totalReceived: totalReceived ?? this.totalReceived,
      remainingBalance: remainingBalance ?? this.remainingBalance,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
