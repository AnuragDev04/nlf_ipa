// expense_item.dart

import 'package:flutter/material.dart';

class ExpenseItem extends StatelessWidget {
  final TextEditingController nameController;
  final TextEditingController detailsController;
  final TextEditingController amountController;
  final VoidCallback? onRemove;
  final VoidCallback? onReceiptUpload;

  const ExpenseItem({
    super.key,
    required this.nameController,
    required this.detailsController,
    required this.amountController,
    this.onRemove,
    this.onReceiptUpload,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Expense Name
          Text(
            'Expense Name',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          SizedBox(height: 4),
          TextFormField(
            controller: nameController,
            decoration: InputDecoration(
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              filled: true,
              fillColor: Colors.grey[50],
              hintText: 'e.g., Travel, Food, etc.',
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter an expense name';
              }
              return null;
            },
          ),
          SizedBox(height: 16),

          // Details
          Text(
            'Details',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          SizedBox(height: 4),
          TextFormField(
            controller: detailsController,
            maxLines: 3,
            decoration: InputDecoration(
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              filled: true,
              fillColor: Colors.grey[50],
              hintText: 'Add description...',
            ),
          ),
          SizedBox(height: 16),

          // Amount & Receipt Row
          Row(
            children: [
              // Amount
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Amount',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    SizedBox(height: 4),
                    TextFormField(
                      controller: amountController,
                      keyboardType: TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        filled: true,
                        fillColor: Colors.grey[50],
                        hintText: '\$0.00',
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) return 'Required';
                        if (double.tryParse(value.replaceAll('\$', '')) == null) {
                          return 'Enter a valid amount';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
              SizedBox(width: 16),

              // Receipt Upload
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Receipt',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    SizedBox(height: 4),
                    GestureDetector(
                      onTap: onReceiptUpload ?? () {},
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          border: Border.all(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.attach_file, size: 18, color: Colors.grey[600]),
                            SizedBox(width: 8),
                            Text('Upload', style: TextStyle(color: Colors.grey[700])),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Remove Button
          if (onRemove != null)
            SizedBox(height: 16),
          if (onRemove != null)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: onRemove,
                icon: Icon(Icons.delete, color: Colors.red, size: 18),
                label: Text(
                  'Remove',
                  style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600),
                ),
              ),
            ),
        ],
      ),
    );
  }
}