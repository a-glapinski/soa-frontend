import 'package:json_annotation/json_annotation.dart';

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
      status: json['status'],
    );
  }
}

enum PaymentStatusDto {
  @JsonValue('ISSUED')
  issued,
  @JsonValue('SETTLED')
  settled
}
