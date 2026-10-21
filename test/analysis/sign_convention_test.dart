import 'package:flutter_test/flutter_test.dart';
import 'package:structlab/analysis/conventions/sign_convention.dart';

void main() {
  test('standard keeps internal signs', () {
    const c = SignConvention.standard;
    expect(c.x(3), 3);
    expect(c.y(-2), -2);
    expect(c.moment(5), 5);
  });

  test('flipped convention changes only the displayed sign', () {
    const c = SignConvention(ySign: -1, momentSign: -1);
    expect(c.y(2), -2);
    expect(c.moment(5), -5);
    expect(c.x(1), 1);
  });

  test('orderTerms follows termOrder and is stable', () {
    final terms = [(2.0, 'b'), (0.0, 'a1'), (0.0, 'a2'), (5.0, 'c')];
    String join(SignConvention c) =>
        c.orderTerms(terms, (t) => t.$1).map((t) => t.$2).join(',');
    expect(join(const SignConvention()), 'a1,a2,b,c');
    expect(join(const SignConvention(termOrder: TermOrder.rightToLeft)),
        'c,b,a1,a2');
  });
}