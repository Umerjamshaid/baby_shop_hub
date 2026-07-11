# 📦 Recommended Flutter Packages for Invoice Management App

---

## 🚀 State Management (Pick One)

### 1. **Riverpod** ⭐ RECOMMENDED
- **What it is:** Modern reactive state management with compile-time safety
- **Why use it:** Best balance of simplicity, power, and testability
- **Good for:** Large projects, complex dependencies
- **Package:** `riverpod` + `flutter_riverpod` + `riverpod_generator`

```dart
// Example: Define a simple invoice provider
final invoiceProvider = FutureProvider<Invoice>((ref) async {
  final repository = ref.watch(invoiceRepositoryProvider);
  return repository.getInvoice('invoice_id');
});
```

**Pros:** Type-safe, excellent performance, great documentation
**Cons:** Slight learning curve

---

### 2. **GetX**
- **What it is:** All-in-one solution (state, routing, dependency injection)
- **Why use it:** Fastest to setup, beginner-friendly, has routing built-in
- **Good for:** Quick MVP, small to medium projects
- **Package:** `get`

**Pros:** Simple, less boilerplate, fast development
**Cons:** Less type-safe, harder to test

---

### 3. **BLoC** (flutter_bloc)
- **What it is:** Event-driven state management with streams
- **Why use it:** Enterprise-grade, highly testable, strong community
- **Good for:** Enterprise apps, large teams
- **Package:** `flutter_bloc` + `bloc`

**Pros:** Highly testable, clear separation of concerns, excellent for large teams
**Cons:** More boilerplate, steeper learning curve

---

## 💾 Database & Storage

### 1. **Isar** ⭐ BEST FOR INVOICE APP
```dart
flutter pub add isar isar_flutter_libs
```
- **Why:** Fastest NoSQL database for Flutter, perfect for offline invoices
- **Features:** Full-text search, transactions, relationships
- **Performance:** ~10x faster than Hive

```dart
// Example: Define invoice model
@collection
class InvoiceIsar {
  Id id = Isar.autoIncrement;
  late String invoiceNumber;
  late double total;
  late DateTime createdAt;
  
  // Full-text search enabled
  late List<String> tags;
}
```

---

### 2. **Hive**
- **Why:** Lightning-fast key-value store, good for caching
- **Use for:** Cache layer, offline data
- **Package:** `hive` + `hive_flutter`

---

### 3. **Drift** (SQLite wrapper)
- **Why:** Type-safe SQL with auto-generated queries
- **Use for:** Complex queries, structured data
- **Package:** `drift` + `drift_flutter`

---

## 🌐 Networking & API

### 1. **Dio** ⭐ RECOMMENDED
```dart
flutter pub add dio
```
- **Why:** Powerful HTTP client with interceptors, retries, timeouts
- **Features:** Request/response interceptors, upload/download progress

```dart
final dio = Dio(BaseOptions(
  baseUrl: 'https://api.example.com',
  connectTimeout: Duration(seconds: 5),
  receiveTimeout: Duration(seconds: 3),
));

dio.interceptors.add(InterceptorsWrapper(
  onRequest: (options, handler) {
    // Add auth token
    options.headers['Authorization'] = 'Bearer $token';
    return handler.next(options);
  },
));
```

---

### 2. **Chopper**
- **Why:** Type-safe, code-generated HTTP client
- **Use for:** Type-safe API calls

---

## 📱 UI & UX Enhancements

### 1. **GetX Navigator** (if using GetX)
- **Why:** Easier routing without context
```dart
Get.to(InvoiceDetailScreen(id: 'invoice_1'));
Get.back();
```

---

### 2. **Go Router** (if using Riverpod)
- **Why:** Modern, declarative routing
- **Package:** `go_router`

```dart
final routerProvider = Provider((ref) {
  return GoRouter(
    routes: [
      GoRoute(path: '/', builder: (context, state) => DashboardScreen()),
      GoRoute(path: '/invoice/:id', builder: (context, state) {
        final id = state.pathParameters['id']!;
        return InvoiceDetailScreen(id: id);
      }),
    ],
  );
});
```

---

### 3. **Skeletons** (Loading placeholders)
```dart
flutter pub add skeletons
```
- **Why:** Professional loading states
- **Use for:** Skeleton loading while fetching invoices

---

### 4. **Toastification** (Notifications)
```dart
flutter pub add toastification
```
- **Why:** Beautiful toast notifications
- **Use for:** Success/error messages

```dart
toastification.show(
  title: Text('Invoice created successfully!'),
  autoCloseDuration: Duration(seconds: 3),
);
```

---

## 📊 Data & Charts

### 1. **FL Chart** ⭐ RECOMMENDED
```dart
flutter pub add fl_chart
```
- **Why:** Beautiful, interactive charts
- **Use for:** Revenue graphs, analytics dashboard

```dart
LineChart(
  LineChartData(
    lineBarsData: [
      LineChartBarData(
        spots: [
          FlSpot(0, 3),
          FlSpot(1, 1),
          FlSpot(2, 4),
        ],
      ),
    ],
  ),
)
```

---

### 2. **Syncfusion Flutter Charts**
- **Why:** Professional enterprise charts
- **Use for:** Advanced analytics

---

## 📄 PDF & Document

### 1. **Printing** (already recommended)
```dart
flutter pub add printing
```
- **Why:** Preview and print PDFs

---

### 2. **Open File**
```dart
flutter pub add open_file
```
- **Why:** Open generated PDFs on device

```dart
await OpenFile.open('/path/to/invoice.pdf');
```

---

## 🔐 Security

### 1. **Flutter Secure Storage**
```dart
flutter pub add flutter_secure_storage
```
- **Why:** Store sensitive data securely
- **Use for:** API tokens, passwords

```dart
final storage = FlutterSecureStorage();
await storage.write(key: 'api_token', value: token);
final token = await storage.read(key: 'api_token');
```

---

### 2. **Local Auth**
```dart
flutter pub add local_auth
```
- **Why:** Biometric authentication
- **Use for:** App lock, sensitive operations

---

## 🧪 Testing

### 1. **Mockito**
```dart
flutter pub add --dev mockito
```
- **Why:** Mock dependencies for unit tests

---

### 2. **BDD/Gherkin (Golden Master)**
```dart
flutter pub add --dev golden_toolkit
```
- **Why:** Visual regression testing

---

## 🛠️ Code Generation & Utils

### 1. **Freezed** ⭐ MUST HAVE
```dart
flutter pub add freezed_annotation
flutter pub add --dev freezed
flutter pub add --dev build_runner
```
- **Why:** Auto-generate immutable classes with copyWith, == override
- **Use for:** Models (Invoice, Client, Product)

```dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'invoice.freezed.dart';
part 'invoice.g.dart';

@freezed
class Invoice with _$Invoice {
  const factory Invoice({
    required String id,
    required String invoiceNumber,
    required double total,
  }) = _Invoice;

  factory Invoice.fromJson(Map<String, dynamic> json) =>
      _$InvoiceFromJson(json);
}
```

**Then run:**
```bash
dart run build_runner watch
```

---

### 2. **JSON Serializable** (with Freezed)
- **Why:** Auto-generate fromJson/toJson
- **Package:** `json_serializable` + `build_runner`

---

### 3. **GetIt** (Service Locator)
```dart
flutter pub add get_it
```
- **Why:** Dependency injection container
- **Use for:** Access repositories, services globally

```dart
final getIt = GetIt.instance;

// Register
getIt.registerSingleton<InvoiceRepository>(InvoiceRepository());

// Use anywhere
final repo = getIt<InvoiceRepository>();
```

---

### 4. **Intl** (Internationalization)
```dart
flutter pub add intl
```
- **Why:** Format dates, numbers, multi-language support

```dart
import 'package:intl/intl.dart';

final dateFormat = DateFormat('dd/MM/yyyy');
print(dateFormat.format(DateTime.now())); // 26/10/2025
```

---

## 📧 Email & Notifications

### 1. **Firebase Cloud Messaging** (already in Firebase)
- **Why:** Push notifications
- **Package:** `firebase_messaging`

---

### 2. **URL Launcher**
```dart
flutter pub add url_launcher
```
- **Why:** Send emails via mailto
- **Use for:** Share invoice via email link

```dart
final Uri emailLaunchUri = Uri(
  scheme: 'mailto',
  path: 'client@example.com',
  queryParameters: {
    'subject': 'Invoice INV-001',
    'body': 'Please find attached your invoice',
  },
);
await launchUrl(emailLaunchUri);
```

---

## 📸 File & Media Handling

### 1. **Image Picker**
```dart
flutter pub add image_picker
```
- **Why:** Pick logo/company images
- **Use for:** Business profile image upload

---

### 2. **File Picker**
```dart
flutter pub add file_picker
```
- **Why:** Pick files from device
- **Use for:** Import client list from CSV

---

### 3. **Path Provider**
```dart
flutter pub add path_provider
```
- **Why:** Access device directories
- **Use for:** Save PDFs locally

---

## ⏰ Date & Time

### 1. **Jiffy**
```dart
flutter pub add jiffy
```
- **Why:** Easy date manipulation
- **Alternative:** `intl` package

```dart
final date = Jiffy.now().add(months: 1);
print(date.format(pattern: 'dd MMM yyyy'));
```

---

## 🎨 UI Components Library

### 1. **Flutter Material 3**
- Already built-in, use Material 3 for modern design

---

### 2. **FlutterFlow** (Optional - visual builder)
- **Why:** Rapid UI development with visual builder
- **Use for:** Accelerate UI development

---

## 📊 Analytics & Logging

### 1. **Firebase Analytics** (with Firebase)
```dart
flutter pub add firebase_analytics
```
- **Why:** Track user behavior
- **Use for:** Revenue tracking, feature adoption

---

### 2. **Sentry**
```dart
flutter pub add sentry_flutter
```
- **Why:** Error tracking and crash reporting
- **Use for:** Monitor app crashes in production

```dart
await Sentry.captureException(
  exception,
  stackTrace: stackTrace,
);
```

---

## 💳 Payment Processing

### 1. **Flutter Stripe**
```dart
flutter pub add flutter_stripe
```
- **Why:** Process payments in-app

---

### 2. **Razorpay** (India)
```dart
flutter pub add razorpay_flutter
```

---

## ⚡ Performance

### 1. **Cached Network Image**
```dart
flutter pub add cached_network_image
```
- **Why:** Cache images from network

---

## 📋 Complete pubspec.yaml Template

```yaml
name: invoice_app
description: Professional invoice management app

environment:
  sdk: '>=3.0.0 <4.0.0'

dependencies:
  flutter:
    sdk: flutter

  # State Management
  riverpod: ^2.4.0
  flutter_riverpod: ^2.4.0

  # Firebase
  firebase_core: ^2.24.0
  firebase_auth: ^4.13.0
  cloud_firestore: ^4.13.0
  firebase_storage: ^11.5.0
  firebase_messaging: ^14.6.0
  firebase_analytics: ^10.7.0
  firebase_functions: ^4.4.0

  # Database
  isar: ^3.1.0
  hive: ^2.2.3
  hive_flutter: ^1.1.0

  # Networking
  dio: ^5.4.0

  # Router
  go_router: ^13.0.0

  # UI
  cached_network_image: ^3.3.0
  fl_chart: ^0.65.0
  toastification: ^1.2.0
  skeletons: ^0.0.20

  # PDF & File
  pdf: ^3.10.0
  printing: ^5.11.0
  open_file: ^3.5.0
  file_picker: ^6.0.0
  image_picker: ^1.0.0
  path_provider: ^2.1.0

  # Security
  flutter_secure_storage: ^9.0.0
  local_auth: ^2.1.0

  # Code Generation & Utils
  freezed_annotation: ^2.4.0
  json_serializable: ^6.7.0
  get_it: ^7.6.0
  intl: ^0.19.0
  jiffy: ^5.0.0

  # Analytics & Logging
  sentry_flutter: ^7.13.0

  # URL Launcher
  url_launcher: ^6.2.0

dev_dependencies:
  flutter_test:
    sdk: flutter

  # Code Generation
  build_runner: ^2.4.0
  freezed: ^2.4.0

  # Testing
  mockito: ^5.4.0
  golden_toolkit: ^0.13.0
```

**Install all:**
```bash
flutter pub get
dart run build_runner watch
```

---

## 🎯 Recommended Setup Order

1. **State Management:** Riverpod
2. **Database:** Isar (local) + Firebase (cloud)
3. **Networking:** Dio
4. **Router:** Go Router
5. **Code Gen:** Freezed + Build Runner
6. **DI:** GetIt
7. **Charts:** FL Chart
8. **Security:** Secure Storage + Local Auth
9. **Analytics:** Sentry + Firebase Analytics

---

## 💡 Pro Tips

✅ Use **Freezed** for all models - saves time and prevents bugs
✅ Use **Isar** for offline invoices, sync with Firestore
✅ Use **Riverpod** + **Go Router** for modern architecture
✅ Use **Sentry** in production to catch crashes early
✅ Cache invoice PDFs locally for instant access
✅ Use **Dio interceptors** for automatic token refresh
✅ Test with **Mockito** + **Golden Toolkit**