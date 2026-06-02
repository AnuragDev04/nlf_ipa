// claim.dart

import 'package:flutter/material.dart';

import 'new_claim_screen.dart';

class Claim {
  final String title;
  final String description;
  final double amount;
  final String status;
  final DateTime submittedDate;
  final IconData iconData;
  final Color iconColor;

  Claim({
    required this.title,
    required this.description,
    required this.amount,
    required this.status,
    required this.submittedDate,
    required this.iconData,
    required this.iconColor,
  });
}

class ClaimsScreen extends StatelessWidget {
  const ClaimsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Sample data for claims
    final List<Claim> claims = [
      Claim(
        title: "Travel Expense",
        description: "Submitted on 2023-08-15",
        amount: 150.00,
        status: "Pending",
        submittedDate: DateTime(2023, 8, 15),
        iconData: Icons.flight,
        iconColor: Colors.blue,
      ),
      Claim(
        title: "Medical Reimbursement",
        description: "Submitted on 2023-07-22",
        amount: 75.50,
        status: "Approved",
        submittedDate: DateTime(2023, 7, 22),
        iconData: Icons.favorite,
        iconColor: Colors.red,
      ),
      Claim(
        title: "Office Supplies",
        description: "Submitted on 2023-06-10",
        amount: 32.00,
        status: "Rejected",
        submittedDate: DateTime(2023, 6, 10),
        iconData: Icons.description,
        iconColor: Colors.grey,
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text('Claims'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8.0),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.2),
                    blurRadius: 4.0,
                    spreadRadius: 1.0,
                  ),
                ],
              ),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Search claims',
                  prefixIcon: Icon(Icons.search),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12.0, vertical: 16.0),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            SizedBox(height: 16.0),
            Expanded(
              child: ListView.builder(
                itemCount: claims.length,
                itemBuilder: (context, index) {
                  final claim = claims[index];
                  return Card(
                    margin: EdgeInsets.symmetric(vertical: 8.0, horizontal: 0),
                    elevation: 2.0,
                    child: ListTile(
                      leading: Container(
                        width: 40.0,
                        height: 40.0,
                        decoration: BoxDecoration(
                          color: claim.iconColor.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          claim.iconData,
                          color: claim.iconColor,
                          size: 24.0,
                        ),
                      ),
                      title: Text(
                        claim.title,
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        claim.description,
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                      trailing: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '\$${claim.amount.toStringAsFixed(2)}',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 4.0),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                            decoration: BoxDecoration(
                              color: _getStatusColor(claim.status),
                              borderRadius: BorderRadius.circular(12.0),
                            ),
                            child: Text(
                              claim.status,
                              style: TextStyle(
                                color: _getStatusTextColor(claim.status),
                                fontSize: 12.0,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(
            builder: (context) => const NewClaimScreen(),
          ));
        },
        backgroundColor: Colors.blue,
        child: Icon(Icons.add),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Approved':
        return Colors.green.withOpacity(0.2);
      case 'Rejected':
        return Colors.red.withOpacity(0.2);
      case 'Pending':
        return Colors.yellow.withOpacity(0.2);
      default:
        return Colors.grey.withOpacity(0.2);
    }
  }

  Color _getStatusTextColor(String status) {
    switch (status) {
      case 'Approved':
        return Colors.green;
      case 'Rejected':
        return Colors.red;
      case 'Pending':
        return Colors.yellow;
      default:
        return Colors.grey;
    }
  }
}