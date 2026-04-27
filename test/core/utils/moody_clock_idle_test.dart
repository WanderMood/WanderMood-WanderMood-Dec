import 'package:flutter_test/flutter_test.dart';
import 'package:wandermood/core/utils/moody_clock.dart';
import 'package:wandermood/core/utils/moody_idle_checker.dart';

void main() {
  tearDown(MoodyClock.clearBinding);

  test('currentGateSlot is morning 06–11 and evening 17–21 only', () {
    MoodyClock.bind(() => DateTime(2025, 3, 21, 5, 59));
    expect(MoodyIdleChecker.currentGateSlot(), isNull);

    MoodyClock.bind(() => DateTime(2025, 3, 21, 6));
    expect(MoodyIdleChecker.currentGateSlot(), MoodyIdleGateSlot.morning);

    MoodyClock.bind(() => DateTime(2025, 3, 21, 11, 59));
    expect(MoodyIdleChecker.currentGateSlot(), MoodyIdleGateSlot.morning);

    MoodyClock.bind(() => DateTime(2025, 3, 21, 12));
    expect(MoodyIdleChecker.currentGateSlot(), isNull);

    MoodyClock.bind(() => DateTime(2025, 3, 21, 16, 59));
    expect(MoodyIdleChecker.currentGateSlot(), isNull);

    MoodyClock.bind(() => DateTime(2025, 3, 21, 17));
    expect(MoodyIdleChecker.currentGateSlot(), MoodyIdleGateSlot.evening);

    MoodyClock.bind(() => DateTime(2025, 3, 21, 21, 59));
    expect(MoodyIdleChecker.currentGateSlot(), MoodyIdleGateSlot.evening);

    MoodyClock.bind(() => DateTime(2025, 3, 21, 22));
    expect(MoodyIdleChecker.currentGateSlot(), isNull);
  });

  test('getIdleState follows MoodyClock (four buckets)', () {
    MoodyClock.bind(() => DateTime(2025, 3, 21, 10));
    expect(MoodyIdleChecker.getIdleState(), MoodyIdleState.morning);

    MoodyClock.bind(() => DateTime(2025, 3, 21, 14));
    expect(MoodyIdleChecker.getIdleState(), MoodyIdleState.day);

    MoodyClock.bind(() => DateTime(2025, 3, 21, 20));
    expect(MoodyIdleChecker.getIdleState(), MoodyIdleState.evening);

    MoodyClock.bind(() => DateTime(2025, 3, 21, 22));
    expect(MoodyIdleChecker.getIdleState(), MoodyIdleState.night);

    MoodyClock.bind(() => DateTime(2025, 3, 21, 2));
    expect(MoodyIdleChecker.getIdleState(), MoodyIdleState.night);
  });
}
