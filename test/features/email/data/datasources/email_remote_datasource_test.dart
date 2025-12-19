import 'package:flutter_test/flutter_test.dart';
import 'package:ai_asisstan/core/api/api_exceptions.dart';
import 'package:ai_asisstan/features/email/data/datasources/email_remote_datasource.dart';
import 'package:ai_asisstan/models/email.dart';
import 'package:ai_asisstan/models/email_account.dart';
import 'package:ai_asisstan/services/backend_email_service.dart';
import 'package:mocktail/mocktail.dart';

class MockBackendEmailService extends Mock implements BackendEmailService {}

void main() {
  group('EmailRemoteDataSource', () {
    late EmailRemoteDataSource dataSource;
    late MockBackendEmailService mockBackendEmailService;

    setUp(() {
      mockBackendEmailService = MockBackendEmailService();
      dataSource = EmailRemoteDataSource(backendEmailService: mockBackendEmailService);
    });

    group('getEmails', () {
      test('should return list of emails when API call is successful', () async {
        // Arrange
        final response = BackendEmailResponse(
          emails: [
            BackendEmail(
              id: '1',
              subject: 'Test Email',
              sender: 'test@example.com',
              recipient: 'recipient@example.com',
              preview: 'Test preview',
              receivedDate: DateTime.now(),
              isRead: false,
              category: 'inbox',
              hasAttachments: false,
            )
          ],
          total: 1,
          category: 'inbox',
        );

        when(() => mockBackendEmailService.fetchGmailEmails(
              accessToken: any(named: 'accessToken'),
              category: any(named: 'category'),
              limit: any(named: 'limit'),
            )).thenAnswer((_) async => response);

        // Act
        final result = await dataSource.getEmails(
          accessToken: 'test_token',
          provider: EmailProvider.gmail,
        );

        // Assert
        expect(result, isA<List<Email>>());
        expect(result.length, 1);
        expect(result.first.subject, 'Test Email');
        verify(() => mockBackendEmailService.fetchGmailEmails(
              accessToken: 'test_token',
              category: 'inbox',
              limit: 50,
            )).called(1);
      });

      test('should throw ApiException when API call fails', () async {
        // Arrange
        when(() => mockBackendEmailService.fetchGmailEmails(
              accessToken: any(named: 'accessToken'),
              category: any(named: 'category'),
              limit: any(named: 'limit'),
            )).thenThrow(ApiException(message: 'Network error'));

        // Act & Assert
        expect(
          () => dataSource.getEmails(
            accessToken: 'test_token',
            provider: EmailProvider.gmail,
          ),
          throwsA(isA<ApiException>()),
        );
      });
    });

    group('getEmailById', () {
      test('should return email when API call is successful', () async {
        // Arrange
        final response = BackendEmailResponse(
          emails: [
            BackendEmail(
              id: '1',
              subject: 'Test Email',
              sender: 'test@example.com',
              recipient: 'recipient@example.com',
              preview: 'Test preview',
              receivedDate: DateTime.now(),
              isRead: false,
              category: 'inbox',
              hasAttachments: false,
            )
          ],
          total: 1,
          category: 'inbox',
        );

        when(() => mockBackendEmailService.fetchGmailEmails(
              accessToken: any(named: 'accessToken'),
              category: any(named: 'category'),
              limit: any(named: 'limit'),
            )).thenAnswer((_) async => response);

        // Act
        final result = await dataSource.getEmailById(
          1,
          accessToken: 'test_token',
          provider: EmailProvider.gmail,
        );

        // Assert
        expect(result, isA<Email>());
        expect(result.subject, 'Test Email');
      });

      test('should throw NotFoundException when email not found', () async {
        // Arrange
        when(() => mockBackendEmailService.fetchGmailEmails(
              accessToken: any(named: 'accessToken'),
              category: any(named: 'category'),
              limit: any(named: 'limit'),
            )).thenAnswer((_) async => BackendEmailResponse(
              emails: [],
              total: 0,
              category: 'inbox',
            ));

        // Act & Assert
        expect(
          () => dataSource.getEmailById(
            999,
            accessToken: 'test_token',
            provider: EmailProvider.gmail,
          ),
          throwsA(isA<NotFoundException>()),
        );
      });
    });

    group('sendEmail', () {
      test('should return sent email when API call is successful', () async {
        // Arrange
        final backendEmail = BackendEmail(
          id: '1',
          subject: 'Test Email',
          sender: 'test@example.com',
          recipient: 'recipient@example.com',
          preview: 'Test preview',
          receivedDate: DateTime.now(),
          isRead: true,
          category: 'sent',
          hasAttachments: false,
        );

        when(() => mockBackendEmailService.sendGmailEmail(
              accessToken: any(named: 'accessToken'),
              toEmails: any(named: 'toEmails'),
              subject: any(named: 'subject'),
              plainText: any(named: 'plainText'),
              htmlContent: any(named: 'htmlContent'),
              ccEmails: any(named: 'ccEmails'),
              bccEmails: any(named: 'bccEmails'),
            )).thenAnswer((_) async => backendEmail);

        // Act
        final result = await dataSource.sendEmail(
          accountId: 1,
          toEmails: ['recipient@example.com'],
          subject: 'Test Email',
          accessToken: 'test_token',
          provider: EmailProvider.gmail,
        );

        // Assert
        expect(result, isA<Email>());
        expect(result.subject, 'Test Email');
        verify(() => mockBackendEmailService.sendGmailEmail(
              accessToken: 'test_token',
              toEmails: ['recipient@example.com'],
              subject: 'Test Email',
              plainText: null,
              htmlContent: null,
              ccEmails: null,
              bccEmails: null,
            )).called(1);
      });
    });

    group('markAsRead', () {
      test('should return updated email when API call is successful', () async {
        // Arrange
        final backendEmail = BackendEmail(
          id: '1',
          subject: 'Test Email',
          sender: 'test@example.com',
          recipient: 'recipient@example.com',
          preview: 'Test preview',
          receivedDate: DateTime.now(),
          isRead: true,
          category: 'inbox',
          hasAttachments: false,
        );

        when(() => mockBackendEmailService.markGmailAsRead(
              accessToken: any(named: 'accessToken'),
              messageId: any(named: 'messageId'),
            )).thenAnswer((_) async => backendEmail);

        // Act
        final result = await dataSource.markAsRead(
          1,
          accessToken: 'test_token',
          provider: EmailProvider.gmail,
        );

        // Assert
        expect(result, isA<Email>());
        expect(result.isRead, true);
        verify(() => mockBackendEmailService.markGmailAsRead(
              accessToken: 'test_token',
              messageId: '1',
            )).called(1);
      });
    });

    group('deleteEmail', () {
      test('should complete successfully when API call is successful', () async {
        // Arrange
        when(() => mockBackendEmailService.deleteGmailEmail(
              accessToken: any(named: 'accessToken'),
              messageId: any(named: 'messageId'),
            )).thenAnswer((_) async => Future.value());

        // Act & Assert
        await expectLater(
          dataSource.deleteEmail(
            1,
            accessToken: 'test_token',
            provider: EmailProvider.gmail,
          ),
          completes,
        );
        verify(() => mockBackendEmailService.deleteGmailEmail(
              accessToken: 'test_token',
              messageId: '1',
            )).called(1);
      });
    });
  });
}
