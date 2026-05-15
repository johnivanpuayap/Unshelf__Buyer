import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unshelf_buyer/viewmodels/dashboard_viewmodel.dart';

void main() {
  group('DashboardViewModel', () {
    ProviderContainer makeContainer() {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      return container;
    }

    test('initial state is zeroed counters and zero sales', () {
      final container = makeContainer();
      final state = container.read(dashboardViewModelProvider);

      expect(state.pendingOrders, 0);
      expect(state.processedOrders, 0);
      expect(state.completedOrders, 0);
      expect(state.totalOrders, 0);
      expect(state.totalSales, 0.0);
    });

    test('fetchDashboardData populates simulated values and notifies', () async {
      final container = makeContainer();
      var notified = false;
      container.listen(dashboardViewModelProvider, (_, __) => notified = true);

      await container.read(dashboardViewModelProvider.notifier).fetchDashboardData();

      final state = container.read(dashboardViewModelProvider);
      expect(state.pendingOrders, 5);
      expect(state.processedOrders, 8);
      expect(state.completedOrders, 12);
      expect(state.totalOrders, 200);
      expect(state.totalSales, 10000.0);
      expect(notified, isTrue);
    });
  });
}
