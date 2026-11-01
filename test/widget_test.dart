import 'package:flutter_test/flutter_test.dart';
import 'package:gym_app/main.dart';

void main() {
  testWidgets('Test de démarrage SychaFit', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
  });
}