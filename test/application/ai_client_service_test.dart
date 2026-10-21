import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:habit_tracker/application/services/ai_client_service.dart';
import 'package:habit_tracker/data/models/dtos/dtos.dart';

void main() {
  group('AiClientService', () {
    test('throws when endpoint or apiKey is empty', () async {
      final service = AiClientService();
      final messages = [
        AiMessageDto(
          id: '1',
          conversationId: 'c1',
          role: 'user',
          content: 'hi',
          createdAt: DateTime.now().toUtc(),
        ),
      ];

      expect(
        () => service.sendMessage(apiEndpoint: '', apiKey: 'key', messages: messages),
        throwsA(isA<AiClientException>()),
      );
      expect(
        () => service.sendMessage(apiEndpoint: 'https://example.com', apiKey: '', messages: messages),
        throwsA(isA<AiClientException>()),
      );
    });

    test('OpenAI-compatible request is formatted and parsed correctly', () async {
      http.Request? capturedRequest;
      final mockClient = MockClient((request) async {
        capturedRequest = request;
        final responseJson = jsonEncode({
          'choices': [
            {
              'message': {
                'role': 'assistant',
                'content': 'Hello from Groq Llama!',
              },
            },
          ],
        });
        return http.Response(responseJson, 200, headers: {'content-type': 'application/json'});
      });

      final service = AiClientService(client: mockClient);
      final messages = [
        AiMessageDto(
          id: '1',
          conversationId: 'c1',
          role: 'system',
          content: 'System prompt',
          createdAt: DateTime.now().toUtc(),
        ),
        AiMessageDto(
          id: '2',
          conversationId: 'c1',
          role: 'user',
          content: 'Hello',
          createdAt: DateTime.now().toUtc(),
        ),
      ];

      final reply = await service.sendMessage(
        apiEndpoint: 'https://api.groq.com/openai/v1',
        apiKey: 'gsk_test123',
        messages: messages,
      );

      expect(reply, 'Hello from Groq Llama!');
      expect(capturedRequest, isNotNull);
      expect(
        capturedRequest!.url.toString(),
        'https://api.groq.com/openai/v1/chat/completions',
      );
      expect(capturedRequest!.headers['Authorization'], 'Bearer gsk_test123');

      final body = jsonDecode(capturedRequest!.body) as Map<String, dynamic>;
      expect(body['model'], 'openai/gpt-oss-120b');
      expect((body['messages'] as List).length, 2);
    });

    test('modelOverride overrides default model', () async {
      http.Request? capturedRequest;
      final mockClient = MockClient((request) async {
        capturedRequest = request;
        return http.Response(
          jsonEncode({
            'choices': [
              {
                'message': {'role': 'assistant', 'content': 'Custom reply'},
              },
            ],
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final service = AiClientService(client: mockClient);
      final messages = [
        AiMessageDto(
          id: '1',
          conversationId: 'c1',
          role: 'user',
          content: 'Hello',
          createdAt: DateTime.now().toUtc(),
        ),
      ];

      await service.sendMessage(
        apiEndpoint: 'https://api.groq.com/openai/v1',
        apiKey: 'gsk_test123',
        messages: messages,
        modelOverride: 'custom-groq-model-v2',
      );

      final body = jsonDecode(capturedRequest!.body) as Map<String, dynamic>;
      expect(body['model'], 'custom-groq-model-v2');
    });

    test('Gemini OpenAI-compatible endpoint is routed properly', () async {
      http.Request? capturedRequest;
      final mockClient = MockClient((request) async {
        capturedRequest = request;
        final responseJson = jsonEncode({
          'choices': [
            {
              'message': {
                'role': 'assistant',
                'content': 'Hello from Gemini Flash!',
              },
            },
          ],
        });
        return http.Response(responseJson, 200, headers: {'content-type': 'application/json'});
      });

      final service = AiClientService(client: mockClient);
      final messages = [
        AiMessageDto(
          id: '1',
          conversationId: 'c1',
          role: 'user',
          content: 'Test Gemini',
          createdAt: DateTime.now().toUtc(),
        ),
      ];

      final reply = await service.sendMessage(
        apiEndpoint: 'https://generativelanguage.googleapis.com/v1beta',
        apiKey: 'gemini_key_123',
        messages: messages,
      );

      expect(reply, 'Hello from Gemini Flash!');
      expect(
        capturedRequest!.url.toString(),
        'https://generativelanguage.googleapis.com/v1beta/openai/chat/completions',
      );
      expect(capturedRequest!.headers['Authorization'], 'Bearer gemini_key_123');
    });

    test('Claude endpoint formats system prompt and anthropic headers', () async {
      http.Request? capturedRequest;
      final mockClient = MockClient((request) async {
        capturedRequest = request;
        final responseJson = jsonEncode({
          'content': [
            {
              'type': 'text',
              'text': 'Greetings from Claude!',
            },
          ],
        });
        return http.Response(responseJson, 200, headers: {'content-type': 'application/json'});
      });

      final service = AiClientService(client: mockClient);
      final messages = [
        AiMessageDto(
          id: '1',
          conversationId: 'c1',
          role: 'system',
          content: 'Be a wise mentor',
          createdAt: DateTime.now().toUtc(),
        ),
        AiMessageDto(
          id: '2',
          conversationId: 'c1',
          role: 'user',
          content: 'How should I start?',
          createdAt: DateTime.now().toUtc(),
        ),
      ];

      final reply = await service.sendMessage(
        apiEndpoint: 'https://api.anthropic.com/v1',
        apiKey: 'sk-ant-test',
        messages: messages,
      );

      expect(reply, 'Greetings from Claude!');
      expect(capturedRequest!.url.toString(), 'https://api.anthropic.com/v1/messages');
      expect(capturedRequest!.headers['x-api-key'], 'sk-ant-test');
      expect(capturedRequest!.headers['anthropic-version'], '2023-06-01');

      final body = jsonDecode(capturedRequest!.body) as Map<String, dynamic>;
      expect(body['system'], 'Be a wise mentor');
      expect((body['messages'] as List).length, 1);
      expect(body['messages'][0]['role'], 'user');
    });

    test('handles 401 and 429 error codes cleanly', () async {
      final mockClient401 = MockClient((request) async {
        return http.Response('{"error":{"message":"Invalid key"}}', 401);
      });
      final service401 = AiClientService(client: mockClient401);

      final messages = [
        AiMessageDto(
          id: '1',
          conversationId: 'c1',
          role: 'user',
          content: 'hi',
          createdAt: DateTime.now().toUtc(),
        ),
      ];

      expect(
        () => service401.sendMessage(
          apiEndpoint: 'https://api.openai.com/v1',
          apiKey: 'wrong_key',
          messages: messages,
        ),
        throwsA(predicate((e) => e is AiClientException && e.statusCode == 401)),
      );

      final mockClient429 = MockClient((request) async {
        return http.Response('Rate limit exceeded', 429);
      });
      final service429 = AiClientService(client: mockClient429);

      expect(
        () => service429.sendMessage(
          apiEndpoint: 'https://api.openai.com/v1',
          apiKey: 'key',
          messages: messages,
        ),
        throwsA(predicate((e) => e is AiClientException && e.statusCode == 429)),
      );
    });

    test('handles 404 model not found and endpoint not found with descriptive messages', () async {
      final mockClientModel404 = MockClient((request) async {
        return http.Response(
          '{"error":{"message":"The model \'foo\' does not exist","type":"invalid_request_error","code":"model_not_found"}}',
          404,
        );
      });
      final serviceModel404 = AiClientService(client: mockClientModel404);

      final messages = [
        AiMessageDto(
          id: '1',
          conversationId: 'c1',
          role: 'user',
          content: 'hi',
          createdAt: DateTime.now().toUtc(),
        ),
      ];

      expect(
        () => serviceModel404.sendMessage(
          apiEndpoint: 'https://api.groq.com/openai/v1',
          apiKey: 'key',
          messages: messages,
        ),
        throwsA(predicate((e) =>
            e is AiClientException &&
            e.statusCode == 404 &&
            e.message.contains('Model not found (404)') &&
            e.message.contains("The model 'foo' does not exist"))),
      );

      final mockClientEndpoint404 = MockClient((request) async {
        return http.Response('Not Found', 404);
      });
      final serviceEndpoint404 = AiClientService(client: mockClientEndpoint404);

      expect(
        () => serviceEndpoint404.sendMessage(
          apiEndpoint: 'https://api.groq.com/bad/path',
          apiKey: 'key',
          messages: messages,
        ),
        throwsA(predicate((e) =>
            e is AiClientException &&
            e.statusCode == 404 &&
            e.message.contains('Endpoint not found (404)'))),
      );
    });
  });
}
