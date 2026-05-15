import 'package:flutter_test/flutter_test.dart';
import 'package:unshelf_buyer/viewmodels/dashboard_viewmodel.dart';

void main() {
  group('DashboardViewModel', () {
    test('initial state is zeroed counters and zero sales', () {
      final viewModel = DashboardViewModel();

      expect(viewModel.pendingOrders, 0);
      expect(viewModel.processedOrders, 0);
      expect(viewModel.completedOrders, 0);
      expect(viewModel.totalOrders, 0);
      expect(viewModel.totalSales, 0.0);
    });

    test('fetchDashboardData populates simulated values and notifies', () async {
      final viewModel = DashboardViewModel();
      var notified = false;
      viewModel.addListener(() => notified = true);

      await viewModel.fetchDashboardData();

      expect(viewModel.pendingOrders, 5);
      expect(viewModel.processedOrders, 8);
      expect(viewModel.completedOrders, 12);
      expect(viewModel.totalOrders, 200);
      expect(viewModel.totalSales, 10000.0);
      expect(notified, isTrue);
    });
  });
}
