import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'dashboard_viewmodel.g.dart';

class DashboardState {
  DashboardState({
    DateTime? today,
    this.pendingOrders = 0,
    this.processedOrders = 0,
    this.completedOrders = 0,
    this.totalOrders = 0,
    this.totalSales = 0.0,
  }) : today = today ?? DateTime.now();

  final DateTime today;
  final int pendingOrders;
  final int processedOrders;
  final int completedOrders;
  final int totalOrders;
  final double totalSales;

  DashboardState copyWith({
    DateTime? today,
    int? pendingOrders,
    int? processedOrders,
    int? completedOrders,
    int? totalOrders,
    double? totalSales,
  }) {
    return DashboardState(
      today: today ?? this.today,
      pendingOrders: pendingOrders ?? this.pendingOrders,
      processedOrders: processedOrders ?? this.processedOrders,
      completedOrders: completedOrders ?? this.completedOrders,
      totalOrders: totalOrders ?? this.totalOrders,
      totalSales: totalSales ?? this.totalSales,
    );
  }
}

@riverpod
class DashboardViewModel extends _$DashboardViewModel {
  @override
  DashboardState build() => DashboardState();

  Future<void> fetchDashboardData() async {
    // Fetch data from the server
    // For now, we'll just simulate the data
    await Future.delayed(const Duration(seconds: 2));
    state = state.copyWith(
      today: DateTime.now(),
      pendingOrders: 5,
      processedOrders: 8,
      completedOrders: 12,
      totalOrders: 200,
      totalSales: 10000.0,
    );
  }
}
