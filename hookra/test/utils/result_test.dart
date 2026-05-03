import 'package:test/test.dart';
import 'package:hookra/src/utils/result.dart';

void main() {
  group('Result', () {
    test('Success stores and returns value', () {
      final result = const Result.success(42);
      expect(result.value, 42);
      expect(result.isSuccess, isTrue);
      expect(result.isFailure, isFalse);
      expect(result.valueOrNull, 42);
      expect(result.errorOrNull, isNull);
    });

    test('Failure throws on .value and returns error', () {
      final error = Exception('Something went wrong');
      final result = Result.failure(error);

      expect(result.isSuccess, isFalse);
      expect(result.isFailure, isTrue);
      expect(() => result.value, throwsA(same(error)));
      expect(result.valueOrNull, isNull);
      expect(result.errorOrNull, error);
    });

    test('Result.voidResult behaves like return;', () {
      const result = Result.voidResult();
      expect(result, isA<Result<void>>());
      // This is unnecesary as per https://dart.dev/tools/diagnostics/use_of_void_result
      // This expression has a type of 'void' so its value can't be used.
      // expect(result.value, isNull);
    });

    test('can return Result.voidResult() from void function', () {
      Result<void> sideEffect() {
        // pretend to perform a side-effect
        return const Result.voidResult();
      }

      final result = sideEffect();
      expect(result, isA<Result<void>>());
      // This is unnecesary as per https://dart.dev/tools/diagnostics/use_of_void_result
      // This expression has a type of 'void' so its value can't be used.
      // expect(result.valueOrNull, isNull);
    });

    test('Result.value throws for failure, returns for success', () {
      final s = const Result.success(10);
      final f = Result.failure(Exception('nope'));

      expect(s.value, 10);
      expect(() => f.value, throwsA(isA<Exception>()));
    });

    test('Result.valueOrNull and errorOrNull behave correctly', () {
      final s = const Result.success('hello');
      final f = Result.failure(Exception('oops'));

      expect(s.valueOrNull, 'hello');
      expect(s.errorOrNull, null);

      expect(f.valueOrNull, null);
      expect(f.errorOrNull, isA<Exception>());
    });
  });
}
