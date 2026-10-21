import 'package:flutter_test/flutter_test.dart';
import 'package:tu_minh_hien_app/main.dart';

void main() {
  testWidgets('App launches smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const TuMinhHienAttendanceApp());
    expect(find.byType(TuMinhHienAttendanceApp), findsOneWidget);
  });
}
