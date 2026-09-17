import 'package:flutter/material.dart';
import 'dart:math' as math;

void main() {
  runApp(const EasyBuyApp());
}

class EasyBuyApp extends StatelessWidget {
  const EasyBuyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EasyBuy',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF003366), // Professional deep blue primary
          primary: const Color(0xFF003366),
          secondary: const Color(0xFFE67E22), // Warm accent for highlights
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          filled: true,
          fillColor: Colors.grey[50],
        ),
      ),
      home: const InstallmentCalculatorScreen(),
    );
  }
}

class ScheduleRow {
  final int month;
  final double interest;
  final double payment;
  final double remainingBalance;

  ScheduleRow({
    required this.month,
    required this.interest,
    required this.payment,
    required this.remainingBalance,
  });
}

class InstallmentCalculatorScreen extends StatefulWidget {
  const InstallmentCalculatorScreen({super.key});

  @override
  State<InstallmentCalculatorScreen> createState() => _InstallmentCalculatorScreenState();
}

class _InstallmentCalculatorScreenState extends State<InstallmentCalculatorScreen> {
  final TextEditingController _priceController = TextEditingController();
  
  String _selectedBrand = 'LG'; // 'LG', 'Haier', 'Other Brand'
  int _selectedPeriod = 3; // 3 or 6

  bool _hasCalculated = false;
  bool _isEligible = true;
  String? _validationError;

  // Calculation Results
  double _productPrice = 0.0;
  double _deposit = 0.0;
  double _remainingBalance = 0.0;
  double _monthlyPayment = 0.0;
  double _totalInterest = 0.0;
  double _totalInstallmentPayments = 0.0;
  double _totalAmountCustomerPays = 0.0;
  List<ScheduleRow> _paymentSchedule = [];

  String _formatCurrency(double amount) {
    String fixed = amount.toStringAsFixed(2);
    List<String> parts = fixed.split('.');
    String digits = parts[0];
    String decimals = parts[1];
    
    String res = '';
    int count = 0;
    for (int i = digits.length - 1; i >= 0; i--) {
      if (count == 3) {
        res = ',$res';
        count = 0;
      }
      res = digits[i] + res;
      count++;
    }
    return 'GH₵$res.$decimals';
  }

  void _calculateInstallment() {
    setState(() {
      _validationError = null;
      _hasCalculated = false;
      _isEligible = true;

      String priceText = _priceController.text.trim();
      if (priceText.isEmpty) {
        _validationError = "Please enter a product price.";
        return;
      }

      double? price = double.tryParse(priceText);
      if (price == null) {
        _validationError = "Please enter a valid numeric price.";
        return;
      }

      if (price <= 0) {
        _validationError = "Price must be greater than zero.";
        return;
      }

      _productPrice = price;

      // Eligibility Check
      if (_productPrice > 10000.0) {
        _isEligible = false;
        _hasCalculated = true;
        return;
      }

      // Deposit Rules
      // LG and Haier products: Deposit = 50% of product price.
      // Every other brand: Deposit = 40% of product price.
      double depositRate = (_selectedBrand == 'LG' || _selectedBrand == 'Haier') ? 0.50 : 0.40;
      _deposit = _productPrice * depositRate;
      _remainingBalance = _productPrice - _deposit;

      // Reducing-balance calculation where each month's interest is based on the outstanding balance at that time.
      double rate = 0.11; // 11% per month
      int months = _selectedPeriod;

      // Equal Monthly Installment (EMI) Formula for reducing balance:
      // EMI = [P * r * (1 + r)^n] / [(1 + r)^n - 1]
      double num = _remainingBalance * rate * math.pow(1 + rate, months);
      double den = math.pow(1 + rate, months) - 1;
      _monthlyPayment = num / den;

      _paymentSchedule = [];
      double currentBalance = _remainingBalance;
      double computedTotalInterest = 0.0;
      double computedTotalPayments = 0.0;

      for (int i = 1; i <= months; i++) {
        double interestThisMonth = currentBalance * rate;
        double paymentThisMonth = _monthlyPayment;

        if (i == months) {
          // Last month adjustment to perfectly settle the loan
          paymentThisMonth = currentBalance + interestThisMonth;
        }

        double principalPaid = paymentThisMonth - interestThisMonth;
        double nextBalance = currentBalance - principalPaid;
        if (nextBalance < 0 || i == months) {
          nextBalance = 0.0;
        }

        _paymentSchedule.add(ScheduleRow(
          month: i,
          interest: interestThisMonth,
          payment: paymentThisMonth,
          remainingBalance: nextBalance,
        ));

        computedTotalInterest += interestThisMonth;
        computedTotalPayments += paymentThisMonth;
        currentBalance = nextBalance;
      }

      _totalInterest = computedTotalInterest;
      _totalInstallmentPayments = computedTotalPayments;
      _totalAmountCustomerPays = _deposit + _totalInstallmentPayments;
      _hasCalculated = true;
    });
  }

  @override
  void dispose() {
    _priceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: theme.colorScheme.primary,
        title: const Text(
          'EASYBUY',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
          ),
        ),
        centerTitle: true,
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Text(
                'Installment Calculator',
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(height: 24),

              // Inputs Section
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Product Price Input
                      Text(
                        'Product Price',
                        style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _priceController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: InputDecoration(
                          hintText: 'Enter product price',
                          prefixText: 'GH₵ ',
                          prefixStyle: const TextStyle(fontWeight: FontWeight.bold),
                          errorText: _validationError,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Brand Selection
                      Text(
                        'Brand',
                        style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          return ToggleButtons(
                            borderRadius: BorderRadius.circular(12),
                            constraints: BoxConstraints(
                              minWidth: math.max(0.0, (constraints.maxWidth - 12) / 3),
                              minHeight: 48,
                            ),
                            isSelected: [
                              _selectedBrand == 'LG',
                              _selectedBrand == 'Haier',
                              _selectedBrand == 'Other Brand',
                            ],
                            onPressed: (index) {
                              setState(() {
                                if (index == 0) _selectedBrand = 'LG';
                                if (index == 1) _selectedBrand = 'Haier';
                                if (index == 2) _selectedBrand = 'Other Brand';
                              });
                            },
                            selectedColor: Colors.white,
                            fillColor: theme.colorScheme.primary,
                            color: theme.colorScheme.primary,
                            children: const [
                              Text('LG', style: TextStyle(fontWeight: FontWeight.bold)),
                              Text('Haier', style: TextStyle(fontWeight: FontWeight.bold)),
                              Text('Other Brand', style: TextStyle(fontWeight: FontWeight.bold)),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 20),

                      // Payment Period Selection
                      Text(
                        'Payment Period',
                        style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          return ToggleButtons(
                            borderRadius: BorderRadius.circular(12),
                            constraints: BoxConstraints(
                              minWidth: math.max(0.0, (constraints.maxWidth - 12) / 2),
                              minHeight: 48,
                            ),
                            isSelected: [
                              _selectedPeriod == 3,
                              _selectedPeriod == 6,
                            ],
                            onPressed: (index) {
                              setState(() {
                                _selectedPeriod = (index == 0) ? 3 : 6;
                              });
                            },
                            selectedColor: Colors.white,
                            fillColor: theme.colorScheme.primary,
                            color: theme.colorScheme.primary,
                            children: const [
                              Text('3 Months', style: TextStyle(fontWeight: FontWeight.bold)),
                              Text('6 Months', style: TextStyle(fontWeight: FontWeight.bold)),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Calculate Button
              ElevatedButton(
                onPressed: _calculateInstallment,
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.secondary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 2,
                ),
                child: const Text(
                  'CALCULATE',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                ),
              ),
              const SizedBox(height: 24),

              // Results Section
              if (_hasCalculated) ...[
                if (!_isEligible) ...[
                  // Non-eligible Result view
                  Card(
                    color: Colors.red[50],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: const BorderSide(color: Colors.red, width: 1.5),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        children: [
                          const Icon(Icons.error_outline, color: Colors.red, size: 48),
                          const SizedBox(height: 12),
                          const Text(
                            'Installment Not Available',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.red,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Products above ${_formatCurrency(10000.0)} are not eligible for installment.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.red[900],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ] else ...[
                  // Eligible Results Summary
                  Text(
                    'Calculation Results',
                    style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),

                  // High-priority Results Highlights (Deposit & Monthly Payment)
                  Row(
                    children: [
                      Expanded(
                        child: Card(
                          color: theme.colorScheme.primary.withValues(alpha: 0.08),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(color: theme.colorScheme.primary.withValues(alpha: 0.2)),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              children: [
                                const Text(
                                  'REQUIRED DEPOSIT',
                                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey),
                                ),
                                const SizedBox(height: 4),
                                FittedBox(
                                  child: Text(
                                    _formatCurrency(_deposit),
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: theme.colorScheme.primary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Card(
                          color: theme.colorScheme.secondary.withValues(alpha: 0.1),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(color: theme.colorScheme.secondary.withValues(alpha: 0.3)),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              children: [
                                const Text(
                                  'MONTHLY PAYMENT',
                                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey),
                                ),
                                const SizedBox(height: 4),
                                FittedBox(
                                  child: Text(
                                    _formatCurrency(_monthlyPayment),
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: theme.colorScheme.secondary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Full Breakdown Card
                  Card(
                    elevation: 1,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          _buildResultRow('Product Price', _formatCurrency(_productPrice)),
                          const Divider(),
                          _buildResultRow('Deposit', _formatCurrency(_deposit)),
                          const Divider(),
                          _buildResultRow('Remaining Balance', _formatCurrency(_remainingBalance)),
                          const Divider(),
                          _buildResultRow('Payment Period', '$_selectedPeriod Months'),
                          const Divider(),
                          _buildResultRow('Interest Rate', '11% per month'),
                          const Divider(),
                          _buildResultRow('Monthly Payment', _formatCurrency(_monthlyPayment), isBold: true),
                          const Divider(),
                          _buildResultRow('Total Interest', _formatCurrency(_totalInterest)),
                          const Divider(),
                          _buildResultRow('Total Installment Payments', _formatCurrency(_totalInstallmentPayments)),
                          const Divider(),
                          _buildResultRow(
                            'Total Amount Customer Pays', 
                            _formatCurrency(_totalAmountCustomerPays),
                            isPrimaryColor: true,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Payment Schedule Section
                  Text(
                    'Payment Schedule',
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Card(
                    elevation: 1,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: DataTable(
                          headingRowColor: WidgetStateProperty.all(theme.colorScheme.primary.withValues(alpha: 0.05)),
                          columnSpacing: 14,
                          horizontalMargin: 12,
                          columns: const [
                            DataColumn(label: Text('Month', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('Interest', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('Payment', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('Balance', style: TextStyle(fontWeight: FontWeight.bold))),
                          ],
                          rows: _paymentSchedule.map((row) {
                            return DataRow(
                              cells: [
                                DataCell(Text('Month ${row.month}')),
                                DataCell(Text(_formatCurrency(row.interest))),
                                DataCell(Text(_formatCurrency(row.payment))),
                                DataCell(Text(_formatCurrency(row.remainingBalance))),
                              ],
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResultRow(String label, String value, {bool isBold = false, bool isPrimaryColor = false}) {
    final style = TextStyle(
      fontSize: 15,
      fontWeight: (isBold || isPrimaryColor) ? FontWeight.bold : FontWeight.normal,
      color: isPrimaryColor ? Theme.of(context).colorScheme.primary : Colors.black87,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label, 
              style: const TextStyle(fontSize: 15, color: Colors.black54),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Text(value, style: style),
        ],
      ),
    );
  }
}
