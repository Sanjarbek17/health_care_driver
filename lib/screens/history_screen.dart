import 'package:flutter/material.dart';

class HistoryPage extends StatelessWidget {
  const HistoryPage({super.key});

  final List<Map> lst = const [
    {'name': 'Aziz Silva', 'phone': '(57) 5447-0401'},
    {'name': 'Ojas Kavser', 'phone': '7640337308'},
    {'name': 'Alyssa Mccarthy', 'phone': '076 687 6990'},
    {'name': 'Jade Cote', 'phone': 'A76 I22-6477'},
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
