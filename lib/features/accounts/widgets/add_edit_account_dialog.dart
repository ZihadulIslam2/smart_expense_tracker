import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Dialog for adding or editing an account
class AddEditAccountDialog extends StatefulWidget {
  final String? accountName; // null for add, non-null for edit
  final String? accountType;
  final double? initialBalance;

  const AddEditAccountDialog({
    super.key,
    this.accountName,
    this.accountType,
    this.initialBalance,
  });

  @override
  State<AddEditAccountDialog> createState() => _AddEditAccountDialogState();
}

class _AddEditAccountDialogState extends State<AddEditAccountDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _balanceController = TextEditingController();

  String? _selectedType;

  final List<String> _accountTypes = ['cash', 'bank', 'mobile_wallet'];

  final Map<String, String> _typeDisplay = {
    'cash': '💰 Cash',
    'bank': '🏦 Bank Account',
    'mobile_wallet': '📱 Mobile Wallet',
  };

  @override
  void initState() {
    super.initState();
    if (widget.accountName != null) {
      _nameController.text = widget.accountName!;
      _selectedType = widget.accountType;
      _balanceController.text = widget.initialBalance?.toStringAsFixed(0) ?? '';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _balanceController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      final name = _nameController.text;
      final type = _selectedType!;
      final balance = double.parse(_balanceController.text);

      Navigator.pop(context, {
        'name': name,
        'type': type,
        'initialBalance': balance,
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.accountName != null;

    return AlertDialog(
      title: Text(isEdit ? 'Edit Account' : 'Add Account'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Account Name
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Account Name',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.account_balance_wallet),
                  hintText: 'e.g., My Savings, Daily Cash',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter account name';
                  }
                  if (value.length < 2) {
                    return 'Account name must be at least 2 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Account Type Dropdown
              DropdownButtonFormField<String>(
                value: _selectedType,
                decoration: const InputDecoration(
                  labelText: 'Account Type',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.category),
                ),
                items: _accountTypes.map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Text(_typeDisplay[type]!),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedType = value;
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select account type';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Initial Balance
              TextFormField(
                controller: _balanceController,
                decoration: const InputDecoration(
                  labelText: 'Initial Balance (BDT)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.money),
                  prefixText: '৳ ',
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                ],
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter initial balance';
                  }
                  final balance = double.tryParse(value);
                  if (balance == null || balance < 0) {
                    return 'Please enter a valid balance';
                  }
                  return null;
                },
              ),
              if (!isEdit)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    'Transactions will update this balance',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _submit,
          child: Text(isEdit ? 'Update' : 'Create'),
        ),
      ],
    );
  }
}
