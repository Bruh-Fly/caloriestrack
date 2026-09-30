import 'package:flutter_test/flutter_test.dart';
import 'package:calo_ai/models/user_profile.dart';

void main() {
  group('UserProfile nutrition calculations', () {
    test('calculates Mifflin–St Jeor target with weight-loss adjustment', () {
      final target = UserProfile.calculateTDEE(
        sex: 'male',
        weight: 70,
        height: 175,
        age: 30,
        activity: 'sedentary',
        goal: 'lose_weight',
      );

      expect(target, 1479);
    });

    test('converts goal calorie shares to macro grams', () {
      final macros = UserProfile.calculateMacros(2000, 'lose_weight');

      expect(macros['protein'], 175);
      expect(macros['carbs'], 175);
      expect(macros['fat'], closeTo(2000 * 0.30 / 9, 0.0001));
    });

    test('adjusts calorie targets by the selected rate', () {
      final gradual = UserProfile.calculateTDEE(
        sex: 'male', weight: 70, height: 175, age: 30,
        activity: 'sedentary', goal: 'lose_weight', rate: 'slow',
      );
      final faster = UserProfile.calculateTDEE(
        sex: 'male', weight: 70, height: 175, age: 30,
        activity: 'sedentary', goal: 'lose_weight', rate: 'fast',
      );

      expect(gradual, 1729);
      expect(faster, 1229);
    });
  });
}
