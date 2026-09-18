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
  final String periodLabel;
  final double termChargePortion;
  final double payment;
  final double remainingBalance;

  ScheduleRow({
    required this.periodLabel,
    required this.termChargePortion,
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
  final TextEditingController _specController = TextEditingController();
  
  String _selectedBrand = 'LG'; // 'LG', 'Haier', 'Other Brand'
  String _selectedCategory = 'TV'; // 'TV', 'Fridge', 'Freezer', 'Air Conditioner', 'Other Products'
  String _selectedPeriod = '3 Months'; // '3 Months', '4 Months', '5 Months', '6 Months', '13 Weeks'

  bool _hasCalculated = false;
  bool _isEligible = true;
  String? _validationError;
  String? _specValidationError;

  // Calculation Results
  double _productPrice = 0.0;
  double _depositPercentage = 0.0;
  double _deposit = 0.0;
  double _remainingBalance = 0.0;
  double _termChargePercentage = 0.0;
  double _termCharge = 0.0;
  double _totalRepayment = 0.0;
  double _periodicPayment = 0.0;
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
      _specValidationError = null;
      _hasCalculated = false;
      _isEligible = true;

      // Price Validation
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

      // Product Price Eligibility Check
      if (_productPrice > 10000.0) {
        _isEligible = false;
        _hasCalculated = true;
        return;
      }

      // Determine Deposit Percentage automatically
      double depositPct = 0.50; // Default for LG and Haier

      if (_selectedBrand == 'Other Brand') {
        if (_selectedCategory == 'Other Products') {
          depositPct = 0.40;
        } else {
          String specText = _specController.text.trim();
          if (specText.isEmpty) {
            _specValidationError = "Please enter the required specification value.";
            return;
          }
          double? specValue = double.tryParse(specText);
          if (specValue == null || specValue < 0) {
            _specValidationError = "Please enter a valid numeric value.";
            return;
          }

          if (_selectedCategory == 'TV') {
            // 50 inches and above = 50%, below 50 inches = 40%
            depositPct = (specValue >= 50.0) ? 0.50 : 0.40;
          } else if (_selectedCategory == 'Fridge' || _selectedCategory == 'Freezer') {
            // 168 litres and above = 50%, below 168 litres = 40%
            depositPct = (specValue >= 168.0) ? 0.50 : 0.40;
          } else if (_selectedCategory == 'Air Conditioner') {
            // 2.0 HP and above = 50%, below 2.0 HP = 40%
            depositPct = (specValue >= 2.0) ? 0.50 : 0.40;
          }
        }
      }

      _depositPercentage = depositPct;
      _deposit = _productPrice * _depositPercentage;
      _remainingBalance = _productPrice - _deposit;

      // Repayment Term Charges & Periods
      int totalPeriods = 3;
      bool isWeekly = false;

      if (_selectedPeriod == '3 Months') {
        _termChargePercentage = 0.40;
        totalPeriods = 3;
      } else if (_selectedPeriod == '4 Months') {
        _termChargePercentage = 0.50;
        totalPeriods = 4;
      } else if (_selectedPeriod == '5 Months') {
        _termChargePercentage = 0.60;
        totalPeriods = 5;
      } else if (_selectedPeriod == '6 Months') {
        _termChargePercentage = 0.70;
        totalPeriods = 6;
      } else if (_selectedPeriod == '13 Weeks') {
        _termChargePercentage = 0.40; // Same structure base as 3 months
        totalPeriods = 13;
        isWeekly = true;
      }

      _termCharge = _remainingBalance * _termChargePercentage;
      _totalRepayment = _remainingBalance + _termCharge;
      _periodicPayment = _totalRepayment / totalPeriods;
      _totalAmountCustomerPays = _deposit + _totalRepayment;

      // Generate payment schedule
      _paymentSchedule = [];
      double currentBalance = _totalRepayment;
      double termChargePerPeriod = _termCharge / totalPeriods;

      for (int i = 1; i <= totalPeriods; i++) {
        double paymentThisPeriod = _periodicPayment;
        double nextBalance = currentBalance - paymentThisPeriod;
        
        if (nextBalance < 0 || i == totalPeriods) {
          nextBalance = 0.0;
        }

        _paymentSchedule.add(ScheduleRow(
          periodLabel: isWeekly ? 'Week $i' : 'Month $i',
          termChargePortion: termChargePerPeriod,
          payment: paymentThisPeriod,
          remainingBalance: nextBalance,
        ));

        currentBalance = nextBalance;
      }

      _hasCalculated = true;
    });
  }

  String _getSpecLabel() {
    if (_selectedCategory == 'TV') return 'TV Size (Inches)';
    if (_selectedCategory == 'Fridge') return 'Fridge Capacity (Litres)';
    if (_selectedCategory == 'Freezer') return 'Freezer Capacity (Litres)';
    if (_selectedCategory == 'Air Conditioner') return 'AC Horsepower (HP)';
    return '';
  }

  String _getSpecHint() {
    if (_selectedCategory == 'TV') return 'e.g. 43, 50, 55';
    if (_selectedCategory == 'Fridge' || _selectedCategory == 'Freezer') return 'e.g. 150, 168, 200';
    if (_selectedCategory == 'Air Conditioner') return 'e.g. 1.5, 2.0, 2.5';
    return '';
  }

  @override
  void dispose() {
    _priceController.dispose();
    _specController.dispose();
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

                      // Dynamic Category and Spec Inputs for Other Brands
                      if (_selectedBrand == 'Other Brand') ...[
                        Text(
                          'Product Category',
                          style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          key: ValueKey(_selectedCategory),
                          initialValue: _selectedCategory,
                          decoration: InputDecoration(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          items: <String>['TV', 'Fridge', 'Freezer', 'Air Conditioner', 'Other Products']
                              .map((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(value),
                            );
                          }).toList(),
                          onChanged: (newValue) {
                            setState(() {
                              _selectedCategory = newValue ?? 'TV';
                            });
                          },
                        ),
                        const SizedBox(height: 20),

                        if (_selectedCategory != 'Other Products') ...[
                          Text(
                            _getSpecLabel(),
                            style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _specController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: InputDecoration(
                              hintText: _getSpecHint(),
                              errorText: _specValidationError,
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],
                      ],

                      // Payment Period Selection
                      Text(
                        'Payment Period',
                        style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        key: ValueKey(_selectedPeriod),
                        initialValue: _selectedPeriod,
                        decoration: InputDecoration(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        items: <String>['3 Months', '4 Months', '5 Months', '6 Months', '13 Weeks']
                            .map((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
                          );
                        }).toList(),
                        onChanged: (newValue) {
                          setState(() {
                            _selectedPeriod = newValue ?? '3 Months';
                          });
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

                  // High-priority Results Highlights (Deposit & Periodic Payment)
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
                                Text(
                                  _selectedPeriod == '13 Weeks' ? 'WEEKLY PAYMENT' : 'MONTHLY PAYMENT',
                                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey),
                                ),
                                const SizedBox(height: 4),
                                FittedBox(
                                  child: Text(
                                    _formatCurrency(_periodicPayment),
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
                          _buildResultRow('Deposit Percentage', '${(_depositPercentage * 100).toStringAsFixed(0)}%'),
                          const Divider(),
                          _buildResultRow('Deposit Amount', _formatCurrency(_deposit)),
                          const Divider(),
                          _buildResultRow('Remaining Balance', _formatCurrency(_remainingBalance)),
                          const Divider(),
                          _buildResultRow('Payment Period', _selectedPeriod),
                          const Divider(),
                          _buildResultRow('Term Charge Percentage', '${(_termChargePercentage * 100).toStringAsFixed(0)}%'),
                          const Divider(),
                          _buildResultRow('Term Charge Amount', _formatCurrency(_termCharge)),
                          const Divider(),
                          _buildResultRow('Total Repayment Balance', _formatCurrency(_totalRepayment)),
                          const Divider(),
                          _buildResultRow(
                            _selectedPeriod == '13 Weeks' ? 'Weekly Payment' : 'Monthly Payment', 
                            _formatCurrency(_periodicPayment), 
                            isBold: true,
                          ),
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
                          columnSpacing: 20,
                          horizontalMargin: 12,
                          columns: const [
                            DataColumn(label: Text('Period', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('Term Charge Portion', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('Payment', style: TextStyle(fontWeight: FontWeight.bold))),
                            DataColumn(label: Text('Remaining Balance', style: TextStyle(fontWeight: FontWeight.bold))),
                          ],
                          rows: _paymentSchedule.map((row) {
                            return DataRow(
                              cells: [
                                DataCell(Text(row.periodLabel)),
                                DataCell(Text(_formatCurrency(row.termChargePortion))),
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
