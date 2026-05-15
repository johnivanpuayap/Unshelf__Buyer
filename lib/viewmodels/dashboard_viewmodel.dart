import 'package:flutter/foundation.dart';

class DashboardViewModel extends ChangeNotifier {
  // Example data for the day
  DateTime today;
  int pendingOrders;
  int processedOrders;
  int completedOrders;
  int totalOrders;
  double totalSales;

  DashboardViewModel()
      : today = DateTime.now(),
        pendingOrders = 0,
        processedOrders = 0,
        completedOrders = 0,
        totalOrders = 0,
        totalSales = 0.0;

  Future<void> fetchDashboardData() async {
    // Fetch data from the server
    // For now, we'll just simulate the data
    await Future.delayed(const Duration(seconds: 2));
    today = DateTime.now();
    pendingOrders = 5;
    processedOrders = 8;
    completedOrders = 12;
    totalOrders = 200;
    totalSales = 10000.0;
    notifyListeners();
  }
}
