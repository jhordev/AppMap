import 'package:flutter_test/flutter_test.dart';

import 'package:appmap/features/places/data/action_categories_config.dart';
import 'package:appmap/features/places/widgets/category_bottom_sheet.dart';

void main() {
  group('ActionCategoriesConfig', () {
    test('swimming configuration prioritises aquatic venues', () {
      final categories = ActionCategoriesConfig.getCategoriesForAction(
        PlaceCategory.swimming,
      );
      expect(categories, contains('swimming_pool'));

      final rules = ActionCategoriesConfig.getFilterRules(
        PlaceCategory.swimming,
      );
      expect(rules.primaryKeywords, contains('piscina'));
      expect(rules.allowFallbackWithoutPrimary, isFalse);
    });

    test('running configuration requires track related keywords', () {
      final rules = ActionCategoriesConfig.getFilterRules(
        PlaceCategory.running,
      );
      expect(rules.primaryKeywords, contains('pista'));
      expect(rules.primaryKeywords, contains('atletismo'));
      expect(rules.highValueTypes, contains('stadium'));
      expect(rules.allowFallbackWithoutPrimary, isFalse);
    });
  });
}
