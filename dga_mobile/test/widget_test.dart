import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:dga_mobile/main.dart';
import 'package:dga_mobile/services/storage_service.dart';

void main() {
  testWidgets('App initialization smoke test', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final sharedPreferences = await SharedPreferences.getInstance();
    const secureStorage = FlutterSecureStorage();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          storageServiceProvider.overrideWithValue(
            StorageService(sharedPreferences, secureStorage),
          ),
        ],
        child: const MyApp(),
      ),
    );

    // Verify app renders without errors
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
