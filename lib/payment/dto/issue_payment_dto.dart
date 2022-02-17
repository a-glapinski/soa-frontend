class IssuePaymentDto {
  final String accountUsername;
  final double amount;

  const IssuePaymentDto({
    required this.accountUsername,
    required this.amount,
  });
}
