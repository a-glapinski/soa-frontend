class AccountDto {
  final String username;
  final String firstName;
  final String lastName;

  const AccountDto({
    required this.username,
    required this.firstName,
    required this.lastName,
  });

  factory AccountDto.fromJson(Map<String, dynamic> json) {
    return AccountDto(
      username: json['username'],
      firstName: json['firstName'],
      lastName: json['lastName'],
    );
  }
}
