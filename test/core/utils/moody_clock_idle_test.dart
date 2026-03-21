import 'package:flutter_test/flutter_test.dart';
import 'package:wandermood/core/utils/moody_clock.dart';
import 'package:wandermood/core/utils/moody_idle_checker.dart';

void main() {
  tearDown(MoodyClock.clearBinding);

  test('getIdleState follows MoodyClock', () {
    MoodyClock.bind(() => DateTime(2025, 3, 21, 10));
    expect(MoodyIdleChecker.getIdleState(), MoodyIdleState.morning);

    MoodyClock.bind(() => DateTime(2025, 3, 21, 22));
    expect(MoodyIdleChecker.getIdleState(), MoodyIdleState.lateNight);

    MoodyClock.bind(() => DateTime(2025, 3, 21, 2));
    expect(MoodyIdleChecker.getIdleState(), MoodyIdleState.sleeping);
  });
}
