import 'package:flutter_test/flutter_test.dart';
import 'package:school_management/core/erp/erp_catalog.dart';

void main() {
  test('enterprise catalog has unique modules and collections', () {
    final moduleIds = ErpCatalog.modules.map((module) => module.id).toList();
    final collections = ErpCatalog.modules
        .expand((module) => module.entities)
        .map((entity) => entity.collection)
        .toList();

    expect(moduleIds.toSet().length, moduleIds.length);
    expect(collections.toSet().length, collections.length);
    expect(ErpCatalog.modules.length, greaterThanOrEqualTo(24));
    expect(collections.length, greaterThanOrEqualTo(100));
  });

  test('every entity has valid primary and list fields', () {
    for (final module in ErpCatalog.modules) {
      expect(module.entities, isNotEmpty, reason: module.title);
      for (final entity in module.entities) {
        final keys = entity.fields.map((field) => field.key).toList();
        expect(keys.toSet().length, keys.length, reason: entity.title);
        expect(keys, contains(entity.primaryField), reason: entity.title);
        if (entity.secondaryField != null) {
          expect(keys, contains(entity.secondaryField), reason: entity.title);
        }
        if (entity.statusField != null) {
          expect(keys, contains(entity.statusField), reason: entity.title);
        }
      }
    }
  });

  test('all configured collections can be resolved', () {
    for (final module in ErpCatalog.modules) {
      for (final entity in module.entities) {
        expect(
          ErpCatalog.entityByCollection(entity.collection),
          same(entity),
          reason: entity.collection,
        );
      }
    }
  });
}
