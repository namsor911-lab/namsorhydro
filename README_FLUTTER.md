# Namsor Hydropower - Production-Ready Flutter Project

A complete, production-ready Flutter application for managing financial accounting and HR/payroll systems for Namsor Hydropower in Laos.

## 📋 Project Overview

This Flutter application converts two HTML-based systems into a native mobile-friendly application:

### **Financial Accounting System** 💰
- Dashboard with real-time financial overview
- Purchase order management with Excel-style tables
- Accounting ledger for income/expense entries
- Budget planning module with progress tracking
- Quarterly and annual financial reports
- Signature pads for document approval
- Receipt image upload and storage
- CSV export functionality

### **HR/Payroll System** 👥
- Employee salary management
- **Lao Progressive Tax Calculation** (5%, 10%, 15%, 20%, 25% brackets)
- Overtime and allowance management
- Digital signature system
- Payroll summaries and reports
- CSV export

## 🏗 Project Structure

```
namsor/
├── lib/
│   ├── config/                    # App configuration
│   │   ├── theme.dart            # Dark theme (GitHub Copilot style)
│   │   ├── strings.dart          # Lao language strings
│   │   ├── constants.dart        # App-wide constants
│   │   └── config.dart           # Exports
│   │
│   ├── models/                    # Data models
│   │   ├── transaction.dart      # Income/Expense transactions
│   │   ├── purchase_order.dart   # Purchase order items
│   │   ├── budget_item.dart      # Budget plan items
│   │   ├── employee.dart         # Employee information
│   │   └── models.dart           # Exports
│   │
│   ├── services/                  # Database & external services
│   │   └── database_service.dart # SQLite database operations
│   │
│   ├── providers/                 # State management (Provider)
│   │   ├── transaction_provider.dart
│   │   ├── purchase_order_provider.dart
│   │   ├── budget_provider.dart
│   │   ├── employee_provider.dart
│   │   └── providers.dart        # Exports
│   │
│   ├── screens/                   # UI Screens
│   │   ├── home_screen.dart      # Main navigation
│   │   ├── financial/            # Financial system screens
│   │   │   ├── financial_dashboard_screen.dart
│   │   │   ├── purchase_orders_screen.dart
│   │   │   ├── accounting_screen.dart
│   │   │   ├── budget_screen.dart
│   │   │   ├── quarterly_report_screen.dart
│   │   │   └── annual_report_screen.dart
│   │   ├── hr/                   # HR system screens
│   │   │   ├── payroll_screen.dart
│   │   │   └── employee_form_screen.dart
│   │   └── screens.dart          # Exports
│   │
│   ├── utils/                     # Utility functions
│   │   └── utils.dart            # Tax calculation, formatting, validation
│   │
│   ├── widgets/                   # Reusable widgets (expandable)
│   │   └── widgets.dart          # Exports (add custom widgets here)
│   │
│   └── main.dart                 # App entry point

├── assets/
│   └── html/                      # Original HTML files (reference)
│       ├── index.html            # Financial system
│       └── hr.html               # HR system
│
├── pubspec.yaml                  # Dependencies
├── analysis_options.yaml         # Linting rules
└── README.md                     # This file
```

## 🎨 Design System

### **Dark Theme (GitHub Copilot Style)**
- **Primary Colors:**
  - Background: `#0d1117`
  - Surface: `#161b22`
  - Border: `#30363d`
  - Text: `#e6edf3`

- **Semantic Colors:**
  - Success/Income: `#3fb950` (Green)
  - Error/Expense: `#f85149` (Red)
  - Warning/Alert: `#d29922` (Yellow)
  - Info/Link: `#58a6ff` (Blue)
  - Accent/Primary: `#238636` (Dark Green)

### **Font System**
- Primary: IBM Plex Sans Thai (Lao support)
- Monospace: IBM Plex Mono (Numbers/currency)

## 💾 Data Storage

### **SQLite Database**
All data persists locally using SQLite with these tables:
- `transactions` - Income/expense entries
- `purchase_orders` - Purchase order items
- `budget_items` - Budget plan items
- `employees` - Employee information
- `signatures` - Digital signatures
- `receipts` - Receipt images

### **Initialize Database**
```dart
final db = DatabaseService();
await db.database; // Creates tables automatically on first run
```

## 📊 Key Features

### **Tax Calculation (Lao Progressive System)**
```dart
// Automatic tax bracket calculation
final taxInfo = TaxCalculator.calculateTax(grossAmount);
// Returns: exempt, tax5, tax10, tax15, tax20, tax25, total
```

### **Currency Formatting**
```dart
FormatUtils.formatCurrency(1500000.50);  // "1,500,000 ₭"
FormatUtils.formatNumber(1500000.50);    // "1,500,000"
FormatUtils.formatDate(DateTime.now());  // "25/12/2024"
```

### **Month/Year Selection**
```dart
FormatUtils.getMonthName(1);             // "ມັງກອນ"
FormatUtils.formatMonthYear('01', '2024'); // "ມັງກອນ 2024"
DateUtils.getYears();                    // [2022, 2023, 2024, ...]
```

## 🔄 State Management (Provider)

### **Transaction Provider**
```dart
// Load transactions for specific month
await provider.loadTransactions('01', '2024');

// Add new transaction
await provider.addTransaction(
  date: DateTime.now(),
  description: 'Description',
  type: TransactionType.income,
  amount: 1500000,
  notes: 'Optional notes',
  receiptId: null,
);

// Get aggregated data
print(provider.totalIncome);
print(provider.totalExpense);
print(provider.netBalance);
```

### **Employee Provider**
```dart
// Load all employees
await provider.loadEmployees();

// Add employee with salary details
await provider.addEmployee(
  name: 'ສະໂມສອນ ບໍລິສັດ',
  role: 'ຜູ້ຈັດການ',
  baseSalary: 5000000,
  overtime: 500000,
  travelAllowance: 200000,
  otherAllowance: 100000,
  deductions: 300000,
);

// Get payroll summary
final payroll = provider.getPayrollSummary();
print(provider.totalGrossSalary);
print(provider.totalTax);
print(provider.totalNetSalary);
```

## 🚀 Getting Started

### **Prerequisites**
- Flutter SDK (v3.0+)
- Dart SDK
- iOS/Android development environment

### **Installation**

1. **Clone the project:**
   ```bash
   cd d:\namsor
   ```

2. **Get dependencies:**
   ```bash
   flutter pub get
   ```

3. **Run the app:**
   ```bash
   flutter run
   ```

4. **Build for release:**
   ```bash
   # Android
   flutter build apk --release
   
   # iOS
   flutter build ios --release
   ```

## 📦 Dependencies

### **Core**
- `flutter` - UI framework
- `provider` - State management
- `sqflite` - SQLite database
- `path_provider` - File system access

### **UI & Visualization**
- `fl_chart` - Charts and graphs
- `flutter_svg` - SVG support
- `signature` - Digital signature drawing

### **Data & Export**
- `excel` - Excel file generation
- `csv` - CSV operations
- `intl` - Internationalization
- `uuid` - Unique ID generation

### **Utilities**
- `image_picker` - Image selection
- `image` - Image processing
- `share_plus` - Share functionality
- `dio` - HTTP client
- `logger` - Logging

## 🔧 Extending the Project

### **Add a New Screen**

1. Create file in `lib/screens/`:
   ```dart
   class MyNewScreen extends StatelessWidget {
     const MyNewScreen({Key? key}) : super(key: key);
     
     @override
     Widget build(BuildContext context) {
       return Scaffold(
         appBar: AppBar(title: Text('My Screen')),
         body: Center(child: Text('Content')),
       );
     }
   }
   ```

2. Add to `lib/screens/screens.dart`:
   ```dart
   export 'my_new_screen.dart';
   ```

3. Add to home_screen navigation

### **Add a New Data Model**

1. Create in `lib/models/`:
   ```dart
   class MyModel {
     final String id;
     final String name;
     
     MyModel({required this.id, required this.name});
     
     factory MyModel.fromMap(Map<String, dynamic> map) {
       return MyModel(id: map['id'], name: map['name']);
     }
     
     Map<String, dynamic> toMap() {
       return {'id': id, 'name': name};
     }
   }
   ```

2. Add database table in `database_service.dart`
3. Create provider in `lib/providers/`
4. Export from `lib/models/models.dart`

### **Add Custom Widgets**

Create reusable components in `lib/widgets/`:
```dart
class MyCustomWidget extends StatelessWidget {
  final String title;
  
  const MyCustomWidget({required this.title});
  
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Text(title),
      ),
    );
  }
}
```

## 📱 Features by Screen

### **Dashboard** 📊
- Monthly income/expense overview
- Summary statistics
- 12-month trends chart
- Recent transaction list
- Quick access to all systems

### **Purchase Orders** 🛒
- Add new purchase items
- Excel-style data table
- Receipt attachment
- Grand total calculation
- CSV export

### **Accounting Ledger** 📒
- Record income/expense transactions
- Month/year filtering
- Search functionality
- Receipt management
- Balance tracking
- Document signatures

### **Budget Planning** 📈
- Monthly budget creation
- Item categorization
- Progress tracking
- Over-budget alerts
- Signature approval

### **Financial Reports** 📋
- Quarterly summaries
- Annual analysis
- Trend visualization
- Comparative reports

### **Payroll** 💼
- Employee management
- Salary components (base, overtime, allowances)
- Automatic tax calculation
- Digital signatures
- Payroll export

## 🔐 Security Features

- **Local Storage**: All data stored securely on device
- **No Network Required**: Works offline
- **Signature Authentication**: Digital approvals
- **Receipt Images**: Stored locally with reference IDs
- **Audit Trail**: Timestamps on all transactions

## 🌐 Localization

### **Lao Language**
All strings in `lib/config/strings.dart`:
```dart
AppStrings.dashboard         // ພາບລວມ
AppStrings.purchaseOrders    // ບັນຊີລາຍການຊື້ເຄື່ອງ
AppStrings.payroll           // ຕາຕະລາງເງິນເດືອນ
```

### **Add More Languages**
Create translation method in StringsProvider or use flutter_localization

## 📊 Tax Calculation Details

### **Lao Progressive Tax Brackets** 🇱🇦

| Bracket | Range | Rate |
|---------|-------|------|
| Exempt | 0 - 1,300,000 | 0% |
| Bracket 1 | 1,300,001 - 5,000,000 | 5% |
| Bracket 2 | 5,000,001 - 15,000,000 | 10% |
| Bracket 3 | 15,000,001 - 25,000,000 | 15% |
| Bracket 4 | 25,000,001 - 65,000,000 | 20% |
| Bracket 5 | 65,000,000+ | 25% |

### **Example Calculation**
```
Gross Salary: 10,000,000 ₭

Exempt: 1,300,000
Bracket 1 (5%): (5,000,000 - 1,300,000) × 0.05 = 185,000
Bracket 2 (10%): (10,000,000 - 5,000,000) × 0.10 = 500,000

Total Tax: 685,000 ₭
Net Salary: 9,315,000 ₭
```

## 🐛 Troubleshooting

### **Database Issues**
```dart
// Reset database
final db = DatabaseService();
await db.close();
// Delete app and reinstall
```

### **State Not Updating**
Ensure Provider is being used correctly:
```dart
// ✓ Correct
Consumer<TransactionProvider>(
  builder: (context, provider, _) => Text(provider.totalIncome.toString()),
)

// ✗ Wrong
final provider = Provider.of<TransactionProvider>(context);
Text(provider.totalIncome.toString());
```

## 📝 Future Enhancements

- [ ] Cloud sync (Firebase/Supabase)
- [ ] Advanced charts (revenue trends, tax forecasting)
- [ ] Multi-company support
- [ ] Approval workflows
- [ ] Mobile signature capture with camera
- [ ] Batch operations
- [ ] Dark/light mode toggle
- [ ] Offline sync
- [ ] Biometric authentication
- [ ] Receipt OCR
- [ ] Real-time collaboration
- [ ] API integration

## 📄 License

This project is proprietary software for Namsor Hydropower.

## 👨‍💻 Development Notes

### **Best Practices**
1. Always use Providers for state management
2. Validate input before saving
3. Use meaningful variable names
4. Document complex functions
5. Test on both platforms (iOS/Android)
6. Use const constructors where possible
7. Handle errors gracefully

### **Code Style**
- Follow Dart style guide
- Use `flutter analyze` to lint
- Format with `flutter format .`
- Maximum line length: 80 characters for comments, 100 for code

### **Database Migrations**
When changing database schema:
1. Update table creation in `_onCreate`
2. Increment `dbVersion` in `AppConstants`
3. Implement `_onUpgrade` method
4. Test with fresh install and upgrade

## 📞 Support

For issues or feature requests related to this Flutter conversion, refer to:
- Original HTML files: `assets/html/index.html`, `assets/html/hr.html`
- Configuration: `lib/config/constants.dart`
- Database schema: `lib/services/database_service.dart`

---

**Last Updated:** June 2, 2026  
**Version:** 3.0  
**Platform:** Flutter 3.0+  
**Target Platforms:** iOS, Android, Web
