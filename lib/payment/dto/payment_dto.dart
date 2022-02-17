class PaymentDto {
  final String transactionId;
  final String accountUsername;
  final double amount;
  final PaymentStatusDto status;

  const PaymentDto({
    required this.transactionId,
    required this.accountUsername,
    required this.amount,
    required this.status,
  });

  factory PaymentDto.fromJson(Map<String, dynamic> json) {
    return PaymentDto(
      transactionId: json['transactionId'],
      accountUsername: json['accountUsername'],
      amount: json['amount'],
      status: _PaymentStatusDtoMapping.fromString(json['status']),
    );
  }
}

enum PaymentStatusDto { issued, settled }

extension _PaymentStatusDtoMapping on PaymentStatusDto {
  static PaymentStatusDto fromString(String name) =>
      PaymentStatusDto.values.byName(name.toLowerCase());
}
