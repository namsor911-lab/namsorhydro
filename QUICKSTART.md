# Namsor Flutter - Quick Start Guide

## 🚀 Getting Started in 5 Minutes

### 1. Install Dependencies
```bash
cd d:\namsor
flutter pub get
```

### 2. Run the App
```bash
flutter run
```

### 3. Start Using
- Desktop/Web: The app opens in a window
- Android Emulator: Ensure emulator is running
- iOS Simulator: Ensure simulator is open (`open -a Simulator`)

## 📱 Navigation

### Home Screen
The app opens to a **collapsible sidebar** with:

**Financial Section (ລະບົບການເງິນ)**
- 📊 Dashboard - Overview with stats and trends
- 🛒 Purchase Orders - Item management
- 📒 Accounting - Income/Expense ledger
- 📈 Budget Planning - Budget tracking
- 📋 Financial Reports - Quarterly & Annual reports

**HR Section (ລະບົບ HR)**
- 💼 Payroll - Employee salary management
- ➕ Employee Form - Add/Edit employees

## 💡 Common Tasks

### Add a Transaction

```dart
// In any screen that has access to TransactionProvider:
await Provider.of<TransactionProvider>(context, listen: false)
    .addTransaction(
      date: DateTime.now(),
      description: 'ຊື້ນ້ຳມັນ',
      type: TransactionType.expense,
      amount: 500000,
      notes: 'Diesel for generator',
      receiptId: null,
    );
```

### Add an Employee

Navigate to Payroll → Add Employee button, then fill form:
- Name (required)
- Role
- Base Salary
- Overtime
- Travel Allowance
- Other Allowance
- Deductions

Tax calculation is automatic.

### View Financial Dashboard

Navigate to **Dashboard** to see:
- Current Month Income
- Current Month Expense
- Current Month Net (Income - Expense)
- Total Balance (All time)
- 12-month trend chart
- Recent 5 transactions

### Export Data

```dart
// CSV export (transactions)
final csv = transactions
    .map((t) => '${t.date},${t.description},${t.amount}')
    .join('\n');

// Excel export
final workbook = Excel.createExcel();
final sheet = workbook['Sheet1'];
// Add data...
workbook.save();
```

## 📊 Tax Calculation Example

```dart
// For salary of 10,000,000 ₭
final result = TaxCalculator.calculateTax(10000000);
print(result);
// Output:
// {
//   'exempt': 1300000,      // Tax-free amount
//   'tax5': 185000,         // 5% bracket
//   'tax10': 500000,        // 10% bracket
//   'tax15': 0,             // 15% bracket (not applicable)
//   'tax20': 0,             // 20% bracket (not applicable)
//   'tax25': 0,             // 25% bracket (not applicable)
//   'total': 685000         // Total tax
// }
```

## 🎨 Styling Guide

### Use AppTheme for colors:
```dart
Container(
  color: AppTheme.bg1,              // Dark background
  padding: const EdgeInsets.all(16), // Standard padding
  child: Text(
    'Income',
    style: TextStyle(
      color: AppTheme.textPrimary,   // Main text
      fontSize: 14,
      fontWeight: FontWeight.w600,
    ),
  ),
)
```

### Use AppStrings for text:
```dart
Text(AppStrings.dashboard)       // "ພາບລວມ"
Text(AppStrings.purchaseOrders)  // "ບັນຊີລາຍການຊື້ເຄື່ອງ"
Text(AppStrings.payroll)         // "ຕາຕະລາງເງິນເດືອນ"
```

### Use FormatUtils for formatting:
```dart
FormatUtils.formatCurrency(1500000)      // "1,500,000 ₭"
FormatUtils.formatDate(DateTime.now())   // "25/12/2024"
FormatUtils.formatMonthYear('01', '2024') // "ມັງກອນ 2024"
```

## 🗄️ Database Operations

### Access Database Directly

```dart
import 'package:namsor/services/database_service.dart';

final db = DatabaseService();
final dbInstance = await db.database;

// Get transactions for January 2024
final transactions = await db.getTransactions('01', '2024');

// Get specific employee
final employee = await db.getEmployee('employee-id');

// Update employee
await db.updateEmployee(updatedEmployee);
```

### Add to Database

```dart
// Transaction
await db.addTransaction({
  'id': 'uuid-here',
  'date': '2024-01-25',
  'description': 'Some description',
  'type': 'income',
  'amount': 1500000,
  'notes': 'Optional notes',
  'receipt_id': null,
});

// Employee
await db.addEmployee({
  'id': 'uuid-here',
  'name': 'ສະໂມສອນ',
  'role': 'ຜູ້ຈັດການ',
  'base_salary': 5000000,
  'overtime': 500000,
  'travel_allowance': 200000,
  'other_allowance': 100000,
  'deductions': 300000,
  'signature_id': null,
});
```

## 🎯 Provider Usage

### Get Current Data
```dart
// Using Consumer
Consumer<TransactionProvider>(
  builder: (context, provider, _) {
    return Text('Income: ${provider.totalIncome}');
  },
)

// Using Provider.of
final income = Provider.of<TransactionProvider>(context)
    .totalIncome;
```

### Load Data on Screen Init
```dart
@override
void initState() {
  super.initState();
  Future.microtask(() {
    Provider.of<TransactionProvider>(context, listen: false)
        .loadTransactions('01', '2024');
  });
}
```

### Listen for Changes
```dart
// Widget rebuilds when provider changes
Consumer<TransactionProvider>(
  builder: (context, provider, _) => Text('${provider.totalIncome}'),
)

// One-time listen
context.read<TransactionProvider>().loadTransactions('01', '2024');
```

## 📐 Screen Template

When creating new screens, use this template:

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:namsor/config/config.dart';
import 'package:namsor/providers/providers.dart';
import 'package:namsor/utils/utils.dart';

class MyNewScreen extends StatefulWidget {
  const MyNewScreen({Key? key}) : super(key: key);

  @override
  State<MyNewScreen> createState() => _MyNewScreenState();
}

class _MyNewScreenState extends State<MyNewScreen> {
  late String _selectedMonth;
  late String _selectedYear;

  @override
  void initState() {
    super.initState();
    _selectedMonth = DateUtils.getCurrentMonth();
    _selectedYear = DateUtils.getCurrentYear().toString();
    _loadData();
  }

  void _loadData() {
    // Load data from provider
    Future.microtask(() {
      Provider.of<SomeProvider>(context, listen: false).loadData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Text('Title', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 20),
          
          // Content
          Card(
            color: AppTheme.bg2,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Center(child: Text('Content here')),
            ),
          ),
        ],
      ),
    );
  }
}
```

## 🐛 Debug Tips

### View All Transactions
```dart
final allTransactions = 
    Provider.of<TransactionProvider>(context).transactions;
print(allTransactions);
```

### Check Provider State
```dart
// Add to build method temporarily
debugPrint('Income: ${provider.totalIncome}');
debugPrint('Expense: ${provider.totalExpense}');
debugPrint('Net: ${provider.netBalance}');
```

### Test Database
```dart
final db = DatabaseService();
final transactions = await db.getTransactions('01', '2024');
print('Found ${transactions.length} transactions');
```

### View App Theme Colors
```dart
print(AppTheme.bg1);        // #0d1117
print(AppTheme.green);      // #3fb950
print(AppTheme.red);        // #f85149
```

## ⚙️ Configuration

### Change App Settings
Edit `lib/config/constants.dart`:

```dart
class AppConstants {
  // Database
  static const String dbName = 'namsor.db';
  static const int dbVersion = 1;
  
  // Tax brackets
  static const List<Map<String, dynamic>> taxBrackets = [
    {'min': 0, 'max': 1300000, 'rate': 0},
    // ... more brackets
  ];
  
  // Budget categories
  static const List<String> budgetCategories = [
    'ອຸປະກອນ',
    'ວັດສະດຸ',
    // ...
  ];
}
```

### Add New String (Lao)
Edit `lib/config/strings.dart`:

```dart
class AppStrings {
  static const String myNewString = 'ສະບາຍດີ';
  // More strings...
}
```

## 🔒 Important Notes

1. **Data is stored locally** - No automatic cloud backup
2. **Database persists** - Survives app uninstall until device reset
3. **Tax calculation is automatic** - Always verify with Lao tax authority
4. **Signatures are local** - Not cryptographically verified
5. **No authentication** - Add if needed for multi-user

## 📞 Helpful Links

- Flutter Docs: https://flutter.dev/docs
- Provider Package: https://pub.dev/packages/provider
- SQLite Best Practices: https://www.sqlite.org/bestpractice.html
- Material Design: https://material.io/design

## ✅ Verification Checklist

Before deploying:
- [ ] All text is in Lao (check lib/config/strings.dart)
- [ ] Colors match GitHub Copilot theme
- [ ] Database initializes on first run
- [ ] All providers are added to main.dart
- [ ] No console errors when running
- [ ] App navigates between all screens
- [ ] Data persists after app restart
- [ ] Tax calculations are correct
- [ ] Export functionality works

## 🎓 Learning Path

1. **Basics** - Read through lib/config/ files
2. **Models** - Understand data structures in lib/models/
3. **Database** - Study lib/services/database_service.dart
4. **Providers** - Learn lib/providers/ pattern
5. **UI** - Examine lib/screens/ implementations
6. **Advanced** - Create custom widgets in lib/widgets/

---

**Need Help?** Check the comprehensive README_FLUTTER.md file for full documentation.
