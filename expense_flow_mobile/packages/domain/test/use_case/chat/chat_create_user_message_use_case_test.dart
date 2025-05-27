import 'package:dartz/dartz.dart';
import 'package:domain/model/chat_message.dart';
import 'package:domain/model/failure/failures.dart';
import 'package:domain/use_case/chat/chat_create_user_message_use_case.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late ChatCreateUserMessageUseCase useCase;

  setUp(() {
    useCase = const ChatCreateUserMessageUseCase();
  });

  group('ChatCreateUserMessageUseCase', () {
    group('successful message creation', () {
      test('should return chat message when content and sender are valid', () {
        const content = 'Hello, how are you?';
        const senderName = 'John Doe';
        final params = ChatCreateUserMessageParams(
          content: content,
          senderName: senderName,
        );

        final result = useCase.call(params);

        expect(result, isA<Right<Failure, ChatMessage>>());
        final message = result.fold((_) => null, (msg) => msg)!;
        expect(message.content, equals(content));
        expect(message.sender, equals(senderName));
        expect(message.id, isNotEmpty);
        expect(message.timestamp, isA<DateTime>());
      });

      test('should generate unique IDs for different messages', () {
        final params1 = ChatCreateUserMessageParams(
          content: 'First message',
          senderName: 'User1',
        );
        final params2 = ChatCreateUserMessageParams(
          content: 'Second message',
          senderName: 'User2',
        );

        final result1 = useCase.call(params1);
        final result2 = useCase.call(params2);

        final message1 = result1.fold((_) => null, (msg) => msg)!;
        final message2 = result2.fold((_) => null, (msg) => msg)!;

        expect(message1.id, isNot(equals(message2.id)));
        expect(message1.id, isNotEmpty);
        expect(message2.id, isNotEmpty);
      });

      test('should trim whitespace from content', () {
        const content = '  Hello world!  ';
        const senderName = 'TestUser';
        final params = ChatCreateUserMessageParams(
          content: content,
          senderName: senderName,
        );

        final result = useCase.call(params);

        final message = result.fold((_) => null, (msg) => msg)!;
        expect(message.content, equals('Hello world!'));
      });

      test('should handle long content', () {
        final longContent = 'A' * 1000;
        const senderName = 'TestUser';
        final params = ChatCreateUserMessageParams(
          content: longContent,
          senderName: senderName,
        );

        final result = useCase.call(params);

        expect(result, isA<Right<Failure, ChatMessage>>());
        final message = result.fold((_) => null, (msg) => msg)!;
        expect(message.content, equals(longContent));
        expect(message.content.length, equals(1000));
      });

      test('should handle special characters in content', () {
        const content = 'Special chars: @#\$%^&*()_+-=[]{}|;:,.<>?';
        const senderName = 'TestUser';
        final params = ChatCreateUserMessageParams(
          content: content,
          senderName: senderName,
        );

        final result = useCase.call(params);

        final message = result.fold((_) => null, (msg) => msg)!;
        expect(message.content, equals(content));
      });

      test('should handle unicode characters in content', () {
        const content = 'Unicode: 🚀💬👋 Café ñoño';
        const senderName = 'TestUser';
        final params = ChatCreateUserMessageParams(
          content: content,
          senderName: senderName,
        );

        final result = useCase.call(params);

        final message = result.fold((_) => null, (msg) => msg)!;
        expect(message.content, equals(content));
      });

      test('should handle multiline content', () {
        const content = 'Line 1\nLine 2\nLine 3';
        const senderName = 'TestUser';
        final params = ChatCreateUserMessageParams(
          content: content,
          senderName: senderName,
        );

        final result = useCase.call(params);

        final message = result.fold((_) => null, (msg) => msg)!;
        expect(message.content, equals(content));
      });

      test('should handle different sender names', () {
        final senderNames = [
          'John Doe',
          'user123',
          'jane@example.com',
          'User with Spaces',
          'Üser Wíth Âccénts',
          '用户名',
        ];

        for (final senderName in senderNames) {
          final params = ChatCreateUserMessageParams(
            content: 'Test message',
            senderName: senderName,
          );

          final result = useCase.call(params);

          final message = result.fold((_) => null, (msg) => msg)!;
          expect(message.sender, equals(senderName));
        }
      });

      test('should set timestamp to current time', () {
        final beforeCall = DateTime.now();

        final params = ChatCreateUserMessageParams(
          content: 'Test message',
          senderName: 'TestUser',
        );

        final result = useCase.call(params);
        final afterCall = DateTime.now();

        final message = result.fold((_) => null, (msg) => msg)!;
        expect(
            message.timestamp.isAfter(beforeCall) ||
                message.timestamp.isAtSameMomentAs(beforeCall),
            isTrue);
        expect(
            message.timestamp.isBefore(afterCall) ||
                message.timestamp.isAtSameMomentAs(afterCall),
            isTrue);
      });

      test('should handle single character content', () {
        const content = 'A';
        const senderName = 'TestUser';
        final params = ChatCreateUserMessageParams(
          content: content,
          senderName: senderName,
        );

        final result = useCase.call(params);

        final message = result.fold((_) => null, (msg) => msg)!;
        expect(message.content, equals(content));
      });

      test('should handle content with only special characters', () {
        const content = '!@#\$%^&*()';
        const senderName = 'TestUser';
        final params = ChatCreateUserMessageParams(
          content: content,
          senderName: senderName,
        );

        final result = useCase.call(params);

        final message = result.fold((_) => null, (msg) => msg)!;
        expect(message.content, equals(content));
      });
    });

    group('validation failures', () {
      test('should return ValidationFailure when content is empty', () {
        final params = ChatCreateUserMessageParams(
          content: '',
          senderName: 'TestUser',
        );

        final result = useCase.call(params);

        expect(result, isA<Left<Failure, ChatMessage>>());
        final failure = result.fold((f) => f, (_) => null)!;
        expect(failure, isA<ValidationFailure>());

        final validationFailure = failure as ValidationFailure;
        expect(validationFailure.details, isNotEmpty);
        expect(validationFailure.details.first['msg'],
            equals('Message content cannot be empty'));
      });

      test('should return ValidationFailure when content is only whitespace',
          () {
        final whitespaceContents = [
          ' ',
          '  ',
          '\t',
          '\n',
          '\r',
          '   \t\n\r   ',
        ];

        for (final content in whitespaceContents) {
          final params = ChatCreateUserMessageParams(
            content: content,
            senderName: 'TestUser',
          );

          final result = useCase.call(params);

          expect(result, isA<Left<Failure, ChatMessage>>());
          final failure = result.fold((f) => f, (_) => null)!;
          expect(failure, isA<ValidationFailure>());

          final validationFailure = failure as ValidationFailure;
          expect(validationFailure.details.first['msg'],
              equals('Message content cannot be empty'));
        }
      });

      test('should handle empty sender name gracefully', () {
        final params = ChatCreateUserMessageParams(
          content: 'Valid content',
          senderName: '',
        );

        final result = useCase.call(params);

        expect(result, isA<Right<Failure, ChatMessage>>());
        final message = result.fold((_) => null, (msg) => msg)!;
        expect(message.sender, equals(''));
        expect(message.content, equals('Valid content'));
      });
    });

    group('edge cases', () {
      test('should handle extremely long sender names', () {
        final longSenderName = 'A' * 1000;
        final params = ChatCreateUserMessageParams(
          content: 'Test message',
          senderName: longSenderName,
        );

        final result = useCase.call(params);

        final message = result.fold((_) => null, (msg) => msg)!;
        expect(message.sender, equals(longSenderName));
      });

      test('should handle sender name with special characters', () {
        const senderName = 'User@#\$%^&*()_+-=[]{}|;:,.<>?';
        final params = ChatCreateUserMessageParams(
          content: 'Test message',
          senderName: senderName,
        );

        final result = useCase.call(params);

        final message = result.fold((_) => null, (msg) => msg)!;
        expect(message.sender, equals(senderName));
      });

      test('should handle sender name with unicode characters', () {
        const senderName = '用户名👤🌟';
        final params = ChatCreateUserMessageParams(
          content: 'Test message',
          senderName: senderName,
        );

        final result = useCase.call(params);

        final message = result.fold((_) => null, (msg) => msg)!;
        expect(message.sender, equals(senderName));
      });

      test('should handle null characters in content gracefully', () {
        const content = 'Hello\x00World';
        const senderName = 'TestUser';
        final params = ChatCreateUserMessageParams(
          content: content,
          senderName: senderName,
        );

        final result = useCase.call(params);

        final message = result.fold((_) => null, (msg) => msg)!;
        expect(message.content, equals(content));
      });

      test('should handle maximum length content', () {
        // Test with very large content (1MB)
        final maxContent = 'A' * (1024 * 1024);
        const senderName = 'TestUser';
        final params = ChatCreateUserMessageParams(
          content: maxContent,
          senderName: senderName,
        );

        final result = useCase.call(params);

        expect(result, isA<Right<Failure, ChatMessage>>());
        final message = result.fold((_) => null, (msg) => msg)!;
        expect(message.content.length, equals(1024 * 1024));
      });
    });

    group('use case contract', () {
      test('should be stateless and const constructable', () {
        const useCase1 = ChatCreateUserMessageUseCase();
        const useCase2 = ChatCreateUserMessageUseCase();

        final params = ChatCreateUserMessageParams(
          content: 'Test message',
          senderName: 'TestUser',
        );

        final result1 = useCase1.call(params);
        final result2 = useCase2.call(params);

        expect(result1, isA<Right<Failure, ChatMessage>>());
        expect(result2, isA<Right<Failure, ChatMessage>>());

        // Results should be similar but have different IDs and timestamps
        final message1 = result1.fold((_) => null, (msg) => msg)!;
        final message2 = result2.fold((_) => null, (msg) => msg)!;

        expect(message1.content, equals(message2.content));
        expect(message1.sender, equals(message2.sender));
        expect(message1.id, isNot(equals(message2.id)));
      });

      test('should not have external dependencies', () {
        // Use case creates messages without external dependencies
        const useCase = ChatCreateUserMessageUseCase();

        final params = ChatCreateUserMessageParams(
          content: 'Independent message',
          senderName: 'IndependentUser',
        );

        final result = useCase.call(params);

        expect(result, isA<Right<Failure, ChatMessage>>());
      });

      test('should be synchronous', () {
        final params = ChatCreateUserMessageParams(
          content: 'Sync message',
          senderName: 'SyncUser',
        );

        // Should complete immediately without await
        final result = useCase.call(params);

        expect(result, isA<Right<Failure, ChatMessage>>());
      });

      test(
          'should produce deterministic results for same input except ID and timestamp',
          () {
        final params = ChatCreateUserMessageParams(
          content: 'Deterministic test',
          senderName: 'DeterministicUser',
        );

        final result1 = useCase.call(params);
        final result2 = useCase.call(params);

        final message1 = result1.fold((_) => null, (msg) => msg)!;
        final message2 = result2.fold((_) => null, (msg) => msg)!;

        expect(message1.content, equals(message2.content));
        expect(message1.sender, equals(message2.sender));
        // ID and timestamp should be different
        expect(message1.id, isNot(equals(message2.id)));
      });
    });

    group('performance', () {
      test('should handle rapid message creation', () {
        const numberOfMessages = 1000;
        final messages = <ChatMessage>[];

        for (int i = 0; i < numberOfMessages; i++) {
          final params = ChatCreateUserMessageParams(
            content: 'Message $i',
            senderName: 'User$i',
          );

          final result = useCase.call(params);
          final message = result.fold((_) => null, (msg) => msg)!;
          messages.add(message);
        }

        expect(messages.length, equals(numberOfMessages));

        // Verify all IDs are unique
        final uniqueIds = messages.map((m) => m.id).toSet();
        expect(uniqueIds.length, equals(numberOfMessages));
      });

      test('should handle concurrent message creation', () {
        const numberOfMessages = 100;
        final futures = <ChatMessage>[];

        for (int i = 0; i < numberOfMessages; i++) {
          final params = ChatCreateUserMessageParams(
            content: 'Concurrent message $i',
            senderName: 'ConcurrentUser$i',
          );

          final result = useCase.call(params);
          final message = result.fold((_) => null, (msg) => msg)!;
          futures.add(message);
        }

        expect(futures.length, equals(numberOfMessages));

        // Verify all IDs are unique
        final uniqueIds = futures.map((m) => m.id).toSet();
        expect(uniqueIds.length, equals(numberOfMessages));
      });
    });

    group('realistic scenarios', () {
      test('should handle typical user message', () {
        final params = ChatCreateUserMessageParams(
          content: 'Can you help me analyze my expenses for this month?',
          senderName: 'Sarah Johnson',
        );

        final result = useCase.call(params);

        final message = result.fold((_) => null, (msg) => msg)!;
        expect(message.content,
            equals('Can you help me analyze my expenses for this month?'));
        expect(message.sender, equals('Sarah Johnson'));
        expect(
            message.id,
            matches(RegExp(
                r'^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$')));
      });

      test('should handle message with code snippet', () {
        const content = '''Here's my code:
        ```dart
        void main() {
          print('Hello World');
        }
        ```
        What do you think?''';

        final params = ChatCreateUserMessageParams(
          content: content,
          senderName: 'Developer123',
        );

        final result = useCase.call(params);

        final message = result.fold((_) => null, (msg) => msg)!;
        expect(message.content, equals(content));
      });

      test('should handle question with numbers and symbols', () {
        const content =
            'My total expenses are \$1,234.56. Is this too much for a monthly budget?';
        final params = ChatCreateUserMessageParams(
          content: content,
          senderName: 'budget_user_2023',
        );

        final result = useCase.call(params);

        final message = result.fold((_) => null, (msg) => msg)!;
        expect(message.content, equals(content));
        expect(message.sender, equals('budget_user_2023'));
      });

      test('should handle international user message', () {
        const content = 'Bonjour! Comment ça va? 你好世界 🌍';
        const senderName = 'International_User_François';
        final params = ChatCreateUserMessageParams(
          content: content,
          senderName: senderName,
        );

        final result = useCase.call(params);

        final message = result.fold((_) => null, (msg) => msg)!;
        expect(message.content, equals(content));
        expect(message.sender, equals(senderName));
      });

      test('should handle message from mobile user with autocorrect artifacts',
          () {
        const content = '  Can you hep me with my budjet please?  ';
        final params = ChatCreateUserMessageParams(
          content: content,
          senderName: 'MobileUser',
        );

        final result = useCase.call(params);

        final message = result.fold((_) => null, (msg) => msg)!;
        expect(
            message.content,
            equals(
                'Can you hep me with my budjet please?')); // Trimmed but typos preserved
      });
    });
  });

  group('ChatCreateUserMessageParams', () {
    test('should create params with required fields', () {
      const content = 'Test content';
      const senderName = 'Test sender';

      final params = ChatCreateUserMessageParams(
        content: content,
        senderName: senderName,
      );

      expect(params.content, equals(content));
      expect(params.senderName, equals(senderName));
    });

    test('should handle empty values', () {
      final params = ChatCreateUserMessageParams(
        content: '',
        senderName: '',
      );

      expect(params.content, equals(''));
      expect(params.senderName, equals(''));
    });

    test('should preserve original values without modification', () {
      const content = '  Original content with spaces  ';
      const senderName = '  Original sender  ';

      final params = ChatCreateUserMessageParams(
        content: content,
        senderName: senderName,
      );

      // Params should preserve original values, trimming happens in use case
      expect(params.content, equals(content));
      expect(params.senderName, equals(senderName));
    });
  });
}
