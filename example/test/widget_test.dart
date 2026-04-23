import 'package:flutter_test/flutter_test.dart';
import 'package:token_counter_example/main.dart';

void main() {
  testWidgets('demo app launches and shows initial token count', (tester) async {
    await tester.pumpWidget(const TokenCounterDemoApp());
    await tester.pumpAndSettle();

    expect(find.text('token_counter demo'), findsOneWidget);
    expect(find.text('Chars'), findsOneWidget);
    expect(find.text('Tokens'), findsOneWidget);
  });
}
