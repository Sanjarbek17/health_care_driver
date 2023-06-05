import 'package:flutter/material.dart';

class HistoryPage extends StatelessWidget {
  const HistoryPage({super.key});

   final List<Map> lst = const [
    {'name': 'Saidov Aziz', 'phone': '(97) 547-04-01'},
    {'name': 'Olimov Alibek', 'phone': '(99)764-03-37'},
    {'name': 'Melokova Salima', 'phone': '(90) 687-69-90'},
    {'name': 'Islomov Muhammad', 'phone': '(88) 093-64-77'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: BackButton(
          color: Colors.white,
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'History',
          style: TextStyle(fontSize: 28),
        ),
      ),
      body: ListView.builder(
        itemCount: lst.length,
        itemBuilder: (context, index) {
          return ListTile(
            title: Text('Name: ${lst[index]['name']}'),
            subtitle: Text('Phone number: ${lst[index]['phone']}'),
          );
        },
      ),
    );
  }
}
