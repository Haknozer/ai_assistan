import 'package:flutter_test/flutter_test.dart';
import 'package:ai_asisstan/core/api/api_client.dart';
import 'package:ai_asisstan/core/api/api_exceptions.dart';
import 'package:ai_asisstan/features/email/data/datasources/email_remote_datasource.dart';
import 'package:ai_asisstan/models/email.dart';
import 'package:mocktail/mocktail.dart';

class MockApiClient extends Mock implements ApiClient {}

void main() {
  group('EmailRemoteDataSource', () {
    late EmailRemoteDataSource dataSource;
    late MockApiClient mockApiClient;

    setUp(() {
      mockApiClient = MockApiClient();
      dataSource = EmailRemoteDataSource(apiClient: mockApiClient);
    });

    group('getEmails', () {
      test('should return list of emails when API call is successful', () async {
        // Arrange
        final emailsJson = [
          {
            'id': 1,
            'user_id': 1,
            'account_id': 1,
            'subject': 'Test Email',
            'from_email': 'test@example.com',
            'to_emails': ['recipient@example.com'],
            'email_status': 2,
            'email_importance': 0,
            'is_read': 0,
            'is_starred': 0,
            'is_archived': 0,
            'is_deleted': 0,
            'is_spam': 0,
            'folder': 'inbox',
            'created_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          }
        ];

        when(() => mockApiClient.get(
              any(),
              queryParameters: any(named: 'queryParameters'),
              accessToken: any(named: 'accessToken'),
            )).thenAnswer((_) async => {'data': emailsJson});

        // Act
        final result = await dataSource.getEmails();

        // Assert
        expect(result, isA<List<Email>>());
        expect(result.length, 1);
        expect(result.first.subject, 'Test Email');
        verify(() => mockApiClient.get(
              any(),
              queryParameters: any(named: 'queryParameters'),
              accessToken: any(named: 'accessToken'),
            )).called(1);
      });

      test('should throw ApiException when API call fails', () async {
        // Arrange
        when(() => mockApiClient.get(
              any(),
              queryParameters: any(named: 'queryParameters'),
              accessToken: any(named: 'accessToken'),
            )).thenThrow(ApiException(message: 'Network error'));

        // Act & Assert
        expect(
          () => dataSource.getEmails(),
          throwsA(isA<ApiException>()),
        );
      });
    });

    group('getEmailById', () {
      test('should return email when API call is successful', () async {
        // Arrange
        final emailJson = {
          'id': 1,
          'user_id': 1,
          'account_id': 1,
          'subject': 'Test Email',
          'from_email': 'test@example.com',
          'to_emails': ['recipient@example.com'],
          'email_status': 2,
          'email_importance': 0,
          'is_read': 0,
          'is_starred': 0,
          'is_archived': 0,
          'is_deleted': 0,
          'is_spam': 0,
          'folder': 'inbox',
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        };

        when(() => mockApiClient.get(
              any(),
              accessToken: any(named: 'accessToken'),
            )).thenAnswer((_) async => {'data': emailJson});

        // Act
        final result = await dataSource.getEmailById(1);

        // Assert
        expect(result, isA<Email>());
        expect(result.subject, 'Test Email');
      });

      test('should throw NotFoundException when email not found', () async {
        // Arrange
        when(() => mockApiClient.get(
              any(),
              accessToken: any(named: 'accessToken'),
            )).thenThrow(NotFoundException(message: 'Email not found'));

        // Act & Assert
        expect(
          () => dataSource.getEmailById(999),
          throwsA(isA<NotFoundException>()),
        );
      });
    });

    group('sendEmail', () {
      test('should return sent email when API call is successful', () async {
        // Arrange
        final emailJson = {
          'id': 1,
          'user_id': 1,
          'account_id': 1,
          'subject': 'Test Email',
          'from_email': 'test@example.com',
          'to_emails': ['recipient@example.com'],
          'email_status': 1,
          'email_importance': 0,
          'is_read': 1,
          'is_starred': 0,
          'is_archived': 0,
          'is_deleted': 0,
          'is_spam': 0,
          'folder': 'sent',
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        };

        when(() => mockApiClient.post(
              any(),
              body: any(named: 'body'),
              accessToken: any(named: 'accessToken'),
            )).thenAnswer((_) async => {'data': emailJson});

        // Act
        final result = await dataSource.sendEmail(
          accountId: 1,
          toEmails: ['recipient@example.com'],
          subject: 'Test Email',
        );

        // Assert
        expect(result, isA<Email>());
        expect(result.subject, 'Test Email');
        expect(result.status, EmailStatus.sent);
      });
    });

    group('markAsRead', () {
      test('should return updated email when API call is successful', () async {
        // Arrange
        final emailJson = {
          'id': 1,
          'user_id': 1,
          'account_id': 1,
          'subject': 'Test Email',
          'from_email': 'test@example.com',
          'to_emails': ['recipient@example.com'],
          'email_status': 3,
          'email_importance': 0,
          'is_read': 1,
          'is_starred': 0,
          'is_archived': 0,
          'is_deleted': 0,
          'is_spam': 0,
          'folder': 'inbox',
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        };

        when(() => mockApiClient.patch(
              any(),
              accessToken: any(named: 'accessToken'),
            )).thenAnswer((_) async => {'data': emailJson});

        // Act
        final result = await dataSource.markAsRead(1);

        // Assert
        expect(result, isA<Email>());
        expect(result.isRead, true);
        expect(result.status, EmailStatus.read);
      });
    });

    group('deleteEmail', () {
      test('should complete successfully when API call is successful', () async {
        // Arrange
        when(() => mockApiClient.delete(
              any(),
              accessToken: any(named: 'accessToken'),
            )).thenAnswer((_) async => {});

        // Act & Assert
        await expectLater(
          dataSource.deleteEmail(1),
          completes,
        );
      });
    });
  });
}
