import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'package:soa_frontend/account/dto/account_dto.dart';

class AccountsPage extends StatefulWidget {
  const AccountsPage({Key? key}) : super(key: key);

  @override
  State<AccountsPage> createState() => _AccountsPageState();
}

class _AccountsPageState extends State<AccountsPage>
    with AutomaticKeepAliveClientMixin<AccountsPage> {
  @override
  bool get wantKeepAlive => true;

  late Future<List<AccountDto>> _accounts;

  @override
  void initState() {
    super.initState();
    setState(() {
      _accounts = _fetchAccounts();
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      body: FutureBuilder<List<AccountDto>>(
        future: _accounts,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            List<AccountDto> accounts = snapshot.data!;
            return accounts.isEmpty
                ? const Center(
                    child:
                        Text('No accounts. Create one by using the + button.'))
                : ListView.builder(
                    itemCount: accounts.length,
                    itemBuilder: (context, index) {
                      final account = accounts[index];
                      return Dismissible(
                        background: Stack(
                          children: [
                            Container(color: Colors.redAccent),
                            const Align(
                              alignment: Alignment.centerLeft,
                              child: Icon(
                                Icons.delete,
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                        direction: DismissDirection.startToEnd,
                        key: UniqueKey(),
                        onDismissed: (direction) {
                          _deleteAccount(account).whenComplete(() {
                            accounts.removeAt(index);
                            setState(() {
                              _accounts = _fetchAccounts();
                            });
                          });
                        },
                        child: Card(
                          child: ListTile(
                            title: Text(account.username),
                            subtitle: Text(
                              '${account.firstName} ${account.lastName}',
                            ),
                          ),
                        ),
                      );
                    },
                  );
          } else if (snapshot.hasError) {
            return Text("${snapshot.error}");
          }
          return const Center(
            child: CircularProgressIndicator(),
          );
        },
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: 'refreshAccounts',
            onPressed: () {
              setState(() {
                _accounts = _fetchAccounts();
              });
            },
            tooltip: 'Refresh',
            child: const Icon(Icons.refresh),
          ),
          const SizedBox(height: 10),
          FloatingActionButton(
            heroTag: 'addAccount',
            onPressed: () {
              final usernameTextController = TextEditingController();
              final firstNameTextController = TextEditingController();
              final lastNameTextController = TextEditingController();
              showDialog(
                context: context,
                builder: (context) {
                  return AlertDialog(
                    title: const Text('Create account'),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextField(
                          controller: usernameTextController,
                          decoration:
                              const InputDecoration(hintText: 'Username'),
                        ),
                        TextField(
                          controller: firstNameTextController,
                          decoration:
                              const InputDecoration(hintText: 'First name'),
                        ),
                        TextField(
                          controller: lastNameTextController,
                          decoration:
                              const InputDecoration(hintText: 'Last name'),
                        ),
                      ],
                    ),
                    actions: [
                      TextButton(
                        child: const Text("Create"),
                        onPressed: () {
                          final account = AccountDto(
                            username: usernameTextController.text,
                            firstName: firstNameTextController.text,
                            lastName: lastNameTextController.text,
                          );
                          _createAccount(account).whenComplete(() {
                            setState(() {
                              _accounts = _fetchAccounts();
                            });
                            Navigator.pop(context);
                          });
                        },
                      )
                    ],
                  );
                },
              );
            },
            tooltip: 'Create account',
            child: const Icon(Icons.add),
          ),
        ],
      ),
    );
  }

  Future<List<AccountDto>> _fetchAccounts() async {
    final response =
        await http.get(Uri.parse('http://localhost:8080/accounts'));
    if (response.statusCode == HttpStatus.ok) {
      List jsonResponse = jsonDecode(utf8.decode(response.bodyBytes));
      return jsonResponse
          .map((account) => AccountDto.fromJson(account))
          .toList();
    } else {
      Fluttertoast.showToast(
        msg: 'Failed to load accounts',
        timeInSecForIosWeb: 5,
        webPosition: 'left',
      );
      throw Exception('Failed to fetch accounts from API');
    }
  }

  Future<void> _createAccount(AccountDto account) async {
    final body = jsonEncode({
      'username': account.username,
      'firstName': account.firstName,
      'lastName': account.lastName
    });
    final response = await http.post(
      Uri.parse('http://localhost:8080/accounts'),
      headers: {"Content-Type": "application/json"},
      body: body,
    );
    if (response.statusCode != HttpStatus.created) {
      Fluttertoast.showToast(
        msg: "Account '${account.username}' couldn't be created",
        timeInSecForIosWeb: 5,
        webPosition: 'left',
      );
      throw Exception('Failed to create account');
    }
  }

  Future<void> _deleteAccount(AccountDto account) async {
    final response = await http.delete(
      Uri.parse('http://localhost:8080/accounts/${account.username}'),
    );
    if (response.statusCode == HttpStatus.noContent) {
      Fluttertoast.showToast(
        msg: "Account '${account.username}' deleted",
        timeInSecForIosWeb: 5,
        webPosition: 'left',
      );
    } else {
      Fluttertoast.showToast(
        msg: "Account '${account.username}' couldn't be deleted",
        timeInSecForIosWeb: 5,
        webPosition: 'left',
      );
      throw Exception('Failed to delete account');
    }
  }
}
