import 'package:flutter_test/flutter_test.dart';
import 'package:kichub_loca/app/app.dart';
import 'package:kichub_loca/core/services/supabase_service.dart';

void main() {
  testWidgets('Kichub app root loads without crashing', (tester) async {
    await tester.pumpWidget(const KichubApp());

    expect(find.byType(KichubApp), findsOneWidget);
  });

  test('Supabase auth state is safely null before initialization', () {
    expect(SupabaseService.currentUser, isNull);
    expect(SupabaseService.authStateChanges, isNotNull);
  });
}
