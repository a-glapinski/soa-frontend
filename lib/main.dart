import 'package:flutter/material.dart';
import 'package:soa_frontend/account/accounts_page.dart';
import 'package:soa_frontend/payment/payments_page.dart';

void main() {
  runApp(const SoaApp());
}

class SoaApp extends StatelessWidget {
  const SoaApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'SOA',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: DefaultTabController(
        length: 2,
        child: Scaffold(
          appBar: AppBar(
            title: const Text('SOA'),
            bottom: const TabBar(
              tabs: [
                Tab(text: 'Accounts', icon: Icon(Icons.person)),
                Tab(text: 'Payments', icon: Icon(Icons.payment)),
              ],
            ),
          ),
          body: const TabBarView(
            children: [
              AccountsPage(),
              PaymentsPage(),
            ],
          ),
        ),
      ),
    );
  }
}
