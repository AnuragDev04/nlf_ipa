// new_claim_screen.dart

import 'package:flutter/material.dart';

import 'expense_item.dart';

class NewClaimScreen extends StatefulWidget {
  const NewClaimScreen({super.key});

  @override
  State<NewClaimScreen> createState() => _NewClaimScreenState();
}

class _NewClaimScreenState extends State<NewClaimScreen> {
  final _formKey = GlobalKey<FormState>();

  // Form Controllers
  final TextEditingController _employeeIdController = TextEditingController();
  final TextEditingController _employeeNameController = TextEditingController();
  final TextEditingController _projectCodeController = TextEditingController();
  final TextEditingController _claimDescriptionController =
      TextEditingController();
  final TextEditingController _fromDateController = TextEditingController();
  final TextEditingController _toDateController = TextEditingController();
  final TextEditingController _approvedDateController = TextEditingController();
  final TextEditingController _totalController = TextEditingController(
    text: '\$0.00',
  );
  final TextEditingController _claimAmountController = TextEditingController(
    text: '\$0.00',
  );
  final TextEditingController _messageController = TextEditingController();

  // List to store added expenses
  final List<Expense> _expenses = [];

  @override
  void dispose() {
    // Dispose all controllers
    _employeeIdController.dispose();
    _employeeNameController.dispose();
    _projectCodeController.dispose();
    _claimDescriptionController.dispose();
    _fromDateController.dispose();
    _toDateController.dispose();
    _approvedDateController.dispose();
    _totalController.dispose();
    _claimAmountController.dispose();
    _messageController.dispose();

    // Dispose expense controllers
    for (var expense in _expenses) {
      expense.dispose();
    }
    super.dispose();
  }

  // Date picker
  Future<void> _selectDate(TextEditingController controller) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (pickedDate != null) {
      setState(() {
        controller.text =
            "${pickedDate.month.toString().padLeft(2, '0')}/"
            "${pickedDate.day.toString().padLeft(2, '0')}/"
            "${pickedDate.year}";
      });
    }
  }

  // Open modal to add new expense
  void _openAddExpenseModal() {
    final newExpense = Expense(
      nameController: TextEditingController(),
      detailsController: TextEditingController(),
      amountController: TextEditingController(text: ''),
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, innerSetState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(
                16,
                16,
                16,
                MediaQuery.of(context).viewInsets.bottom + 16,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Handle
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[400],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  SizedBox(height: 12),

                  // Title
                  Text(
                    'Add New Expense',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 16),

                  // Expense Form
                  ExpenseItem(
                    nameController: newExpense.nameController,
                    detailsController: newExpense.detailsController,
                    amountController: newExpense.amountController,
                    onReceiptUpload: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Receipt upload clicked")),
                      );
                    },
                  ),

                  // Action Buttons
                  SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text('Cancel'),
                        ),
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            final String name = newExpense.nameController.text;
                            if (name.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text("Expense name is required"),
                                ),
                              );
                              return;
                            }

                            // Add expense
                            _expenses.add(newExpense);
                            _updateTotals();

                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text("Expense added successfully!"),
                              ),
                            );
                          },
                          child: Text('Add Expense'),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // Update total and claim amount
  void _updateTotals() {
    double total = 0.0;
    for (var expense in _expenses) {
      final text = expense.amountController.text.replaceAll('\$', '').trim();
      if (text.isNotEmpty) {
        final value = double.tryParse(text);
        if (value != null) total += value;
      }
    }

    setState(() {
      _totalController.text = '\$${total.toStringAsFixed(2)}';
      _claimAmountController.text = '\$${total.toStringAsFixed(2)}';
    });
  }

  // Submit claim
  void _submitClaim() {
    if (_formKey.currentState?.validate() ?? false) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Claim submitted successfully!"),
          backgroundColor: Colors.green,
        ),
      );

      // You can send data to API here
      print("Employee ID: ${_employeeIdController.text}");
      print("Total Expenses: ${_expenses.length}");
      for (var e in _expenses) {
        print("- ${e.nameController.text}: ${e.amountController.text}");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'New Claim',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Claim Details
              Text(
                'Claim Details',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              SizedBox(height: 16),

              _buildTextField(
                controller: _employeeIdController,
                label: 'Employee ID',
              ),
              SizedBox(height: 16),

              _buildTextField(
                controller: _employeeNameController,
                label: 'Employee Name',
              ),
              SizedBox(height: 16),

              _buildTextField(
                controller: _projectCodeController,
                label: 'Project Code',
              ),
              SizedBox(height: 16),

              _buildTextField(
                controller: _claimDescriptionController,
                label: 'Claim Description',
                maxLines: 4,
              ),
              SizedBox(height: 24),

              // Date Fields
              Row(
                children: [
                  Expanded(
                    child: _buildDateField(
                      controller: _fromDateController,
                      label: 'From Date',
                      hintText: 'mm/dd/yyyy',
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: _buildDateField(
                      controller: _toDateController,
                      label: 'To Date',
                      hintText: 'mm/dd/yyyy',
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),

              _buildDateField(
                controller: _approvedDateController,
                label: 'Approved Date',
                hintText: 'mm/dd/yyyy',
              ),
              SizedBox(height: 32),

              // Expenses Section
              Text(
                'Expenses',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              SizedBox(height: 16),

              // Add Expense Button
              GestureDetector(
                onTap: _openAddExpenseModal,
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(vertical: 20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.add_circle_outline,
                        color: Colors.grey[600],
                        size: 24,
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Add Expenses',
                        style: TextStyle(color: Colors.grey[700], fontSize: 16),
                      ),
                    ],
                  ),
                ),
              ),

              // Show Added Expenses
              if (_expenses.isNotEmpty) ...[
                SizedBox(height: 16),
                ..._expenses.asMap().entries.map((entry) {
                  final index = entry.key;
                  final expense = entry.value;
                  return Card(
                    margin: EdgeInsets.symmetric(vertical: 4),
                    child: Padding(
                      padding: EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      expense.nameController.text.isEmpty
                                          ? "Unnamed Expense"
                                          : expense.nameController.text,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      expense.detailsController.text.isEmpty
                                          ? "No details"
                                          : expense.detailsController.text,
                                      style: TextStyle(
                                        color: Colors.grey,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                expense.amountController.text.isEmpty
                                    ? '\$0.00'
                                    : '\$${double.tryParse(expense.amountController.text.replaceAll('\$', ''))?.toStringAsFixed(2) ?? '0.00'}',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          SizedBox(height: 8),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton.icon(
                              onPressed: () {
                                setState(() {
                                  _expenses.removeAt(index);
                                  _updateTotals();
                                });
                              },
                              icon: Icon(
                                Icons.delete,
                                size: 16,
                                color: Colors.red,
                              ),
                              label: Text(
                                'Remove',
                                style: TextStyle(
                                  color: Colors.red,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ],

              SizedBox(height: 32),

              // Summary
              Text(
                'Summary',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      controller: _totalController,
                      label: 'Total',
                      readOnly: true,
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: _buildTextField(
                      controller: _claimAmountController,
                      label: 'Claim Amount',
                      readOnly: true,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 24),

              // View Uploaded Receipts
              Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.receipt_long_outlined,
                      color: Colors.grey[700],
                      size: 20,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'View Uploaded Receipts',
                      style: TextStyle(color: Colors.grey[700], fontSize: 16),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 24),

              // Message to Employee
              _buildTextField(
                controller: _messageController,
                label: 'Message to Employee',
                hintText: 'Add an optional message...',
                maxLines: 4,
              ),
              SizedBox(height: 32),

              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _submitClaim,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[600],
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'Submit',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? hintText,
    int maxLines = 1,
    bool readOnly = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.grey[700],
          ),
        ),
        SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          readOnly: readOnly,
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: TextStyle(color: Colors.grey[400]),
            filled: true,
            fillColor: readOnly ? Colors.grey[50] : Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.blue[600]!),
            ),
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildDateField({
    required TextEditingController controller,
    required String label,
    required String hintText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.grey[700],
          ),
        ),
        SizedBox(height: 8),
        TextFormField(
          controller: controller,
          readOnly: true,
          onTap: () => _selectDate(controller),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: TextStyle(color: Colors.grey[400]),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            suffixIcon: Icon(
              Icons.calendar_today,
              color: Colors.grey[600],
              size: 20,
            ),
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
      ],
    );
  }
}

// Helper class to manage each expense instance
class Expense {
  final TextEditingController nameController;
  final TextEditingController detailsController;
  final TextEditingController amountController;

  Expense({
    required this.nameController,
    required this.detailsController,
    required this.amountController,
  });

  void dispose() {
    nameController.dispose();
    detailsController.dispose();
    amountController.dispose();
  }
}
