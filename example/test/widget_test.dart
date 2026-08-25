import 'package:brand_icons/brand_icons.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:marks/main.dart';

void main() {
  testWidgets('shows the catalogue once it has loaded', (tester) async {
    await tester.pumpWidget(const MarksApp());
    expect(find.text('Marks'), findsOneWidget);
    expect(find.text('Loading the catalogue…'), findsWidgets);

    await tester.pumpAndSettle(const Duration(seconds: 5));
    expect(find.textContaining('brands · '), findsOneWidget);
    expect(find.byType(BrandIcon), findsWidgets);
  });

  testWidgets('filters to what was typed', (tester) async {
    await tester.pumpWidget(const MarksApp(initialQuery: 'spotify'));
    await tester.pumpAndSettle(const Duration(seconds: 5));
    expect(find.text('spotify'), findsWidgets);
  });
}
