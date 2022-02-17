import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'package:soa_frontend/payment/dto/issue_payment_dto.dart';
import 'package:soa_frontend/payment/dto/payment_dto.dart';

class PaymentsPage extends StatefulWidget {
  const PaymentsPage({Key? key}) : super(key: key);

  @override
  State<PaymentsPage> createState() => _PaymentsPageState();
}

class _PaymentsPageState extends State<PaymentsPage>
    with AutomaticKeepAliveClientMixin<PaymentsPage> {
  @override
  bool get wantKeepAlive => true;

  Future<List<PaymentDto>> _payments = Future.value(<PaymentDto>[]);

  final TextEditingController _searchTextController = TextEditingController();
  String? _searchText;

  String? _currentUsername;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      body: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Row(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TextField(
                    controller: _searchTextController,
                    decoration: const InputDecoration(
                      hintText: 'Account username',
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: IconButton(
                    onPressed: () {
                      setState(() {
                        _searchText = _searchTextController.text;
                        _currentUsername = _searchText;
                        _payments = _fetchPayments(_currentUsername ?? "");
                      });
                    },
                    icon: const Icon(Icons.search)),
              )
            ],
          ),
          FutureBuilder<List<PaymentDto>>(
            future: _payments,
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                List<PaymentDto> payments = snapshot.data!;
                return _searchText == null || payments.isEmpty
                    ? const Center(
                        child: Text(
                            'No payments. Create one by using the + button or try to search for another user.'),
                      )
                    : Expanded(
                        child: ListView.builder(
                          itemCount: payments.length,
                          itemBuilder: (context, index) {
                            final payment = payments[index];
                            return Card(
                              child: ListTile(
                                title: Text(payment.transactionId),
                                subtitle: Text(
                                    'Account: ${payment.accountUsername} | Amount: ${payment.amount} | Status: ${payment.status.toString().split('.').last}'),
                                trailing: payment.status ==
                                        PaymentStatusDto.settled
                                    ? null
                                    : TextButton(
                                        onPressed: () {
                                          _settlePayment(payment.transactionId)
                                              .whenComplete(() {
                                            setState(() {
                                              _payments = _fetchPayments(
                                                _currentUsername!,
                                              );
                                            });
                                          });
                                        },
                                        child: const Text('Settle'),
                                      ),
                              ),
                            );
                          },
                        ),
                      );
              } else if (snapshot.hasError) {
                return Text("${snapshot.error}");
              }
              return const Center(
                child: CircularProgressIndicator(),
              );
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          final accountUsernameTextController = TextEditingController();
          final amountTextController = TextEditingController();
          showDialog(
            context: context,
            builder: (context) {
              return AlertDialog(
                title: const Text('Issue payment'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: accountUsernameTextController,
                      decoration: const InputDecoration(
                        hintText: 'Account username',
                      ),
                    ),
                    TextField(
                      controller: amountTextController,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                          RegExp(r'^(\d+)?\.?\d{0,2}'),
                        ),
                        FilteringTextInputFormatter.allow(
                          RegExp(r'^\d+\.?\d*'),
                        ),
                      ],
                      decoration: const InputDecoration(hintText: 'Amount'),
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    child: const Text("Issue"),
                    onPressed: () {
                      final payment = IssuePaymentDto(
                        accountUsername: accountUsernameTextController.text,
                        amount: double.parse(amountTextController.text),
                      );
                      _issuePayment(payment).whenComplete(() {
                        Navigator.pop(context);
                        if (_currentUsername ==
                            accountUsernameTextController.text) {
                          setState(() {
                            _payments = _fetchPayments(_currentUsername!);
                          });
                        }
                      });
                    },
                  )
                ],
              );
            },
          );
        },
        tooltip: 'Issue payment',
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<List<PaymentDto>> _fetchPayments(String accountUsername) async {
    final queryParameters = {'accountUsername': accountUsername};
    final response = await http.get(
      Uri.parse(
        'http://localhost:8080/payments',
      ).replace(queryParameters: queryParameters),
    );
    if (response.statusCode == HttpStatus.ok) {
      List jsonResponse = jsonDecode(utf8.decode(response.bodyBytes));
      return jsonResponse
          .map((payment) => PaymentDto.fromJson(payment))
          .toList();
    } else {
      Fluttertoast.showToast(
        msg: 'Failed to load payments',
        timeInSecForIosWeb: 5,
        webPosition: 'left',
      );
      throw Exception('Failed to fetch payments from API');
    }
  }

  Future<void> _issuePayment(IssuePaymentDto issuePaymentDto) async {
    final body = jsonEncode({
      'accountUsername': issuePaymentDto.accountUsername,
      'amount': issuePaymentDto.amount.toString()
    });
    final response = await http.post(
      Uri.parse('http://localhost:8080/payments/issue'),
      headers: {"Content-Type": "application/json"},
      body: body,
    );
    if (response.statusCode != HttpStatus.created) {
      Fluttertoast.showToast(
        msg:
            "Payment for account '${issuePaymentDto.accountUsername}' couldn't be created",
        timeInSecForIosWeb: 5,
        webPosition: 'left',
      );
      throw Exception('Failed to create payment');
    }
  }

  Future<void> _settlePayment(String transactionId) async {
    final queryParameters = {'transactionId': transactionId};
    final response = await http.put(
      Uri.parse(
        'http://localhost:8080/payments/settle',
      ).replace(queryParameters: queryParameters),
    );
    if (response.statusCode != HttpStatus.ok) {
      Fluttertoast.showToast(
        msg: "Payment '$transactionId' couldn't be settled",
        timeInSecForIosWeb: 5,
        webPosition: 'left',
      );
      throw Exception('Failed to settle payment');
    }
  }
}
