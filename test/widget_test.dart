import 'package:flutter_test/flutter_test.dart';
import 'package:ressources_relationnelles/main.dart';

void main() {
  testWidgets('App démarre sans erreur', (WidgetTester tester) async {
    await tester.pumpWidget(const RessourcesRelationnellesApp());
    await tester.pump();
    expect(tester.takeException(), isNull);
  });
}
