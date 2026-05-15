import 'package:flutter_test/flutter_test.dart';
import 'package:unshelf_buyer/services/nominatim_service.dart';

void main() {
  group('NominatimService rate limiter', () {
    test('5 sequential search() calls take ~5 seconds (1 req/sec)', () async {
      final service = NominatimService.withMockResponder(
        responder: (uri) async => '[]',
      );

      final stopwatch = Stopwatch()..start();
      await Future.wait(List.generate(5, (i) => service.search('test $i')));
      stopwatch.stop();

      // At 1 req/sec, 5 requests take 4-5 seconds. Allow 3.5-6 second window for CI variance.
      expect(stopwatch.elapsedMilliseconds, greaterThanOrEqualTo(3500));
      expect(stopwatch.elapsedMilliseconds, lessThanOrEqualTo(6000));
    });
  });
}
