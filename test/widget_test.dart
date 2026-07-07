// Tests de base — (RE)Sources Relationnelles
import 'package:flutter_test/flutter_test.dart';
import 'package:ressources_relationnelles/main.dart';

void main() {
  testWidgets('App démarre correctement', (WidgetTester tester) async {
    await tester.pumpWidget(const RessourcesRelationnellesApp());
    expect(find.byType(MainScaffold), findsOneWidget);
  });
}
