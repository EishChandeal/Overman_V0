import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../../data/models/dtos/dtos.dart';

class AiClientException implements Exception {
  final String message;
  final int? statusCode;

  const AiClientException(this.message, {this.statusCode});

  @override
  String toString() => message;
}

class AiClientService {
  final http.Client _client;

  AiClientService({http.Client? client}) : _client = client ?? http.Client();

  /// Sends the conversation [messages] to the configured LLM [apiEndpoint] using [apiKey].
  /// Returns the text response from the assistant.
  Future<String> sendMessage({
    required String apiEndpoint,
    required String apiKey,
    required List<AiMessageDto> messages,
    String? modelOverride,
  }) async {
    final cleanEndpoint = apiEndpoint.trim();
    final cleanKey = apiKey.trim();

    if (cleanEndpoint.isEmpty) {
      throw const AiClientException('API endpoint is missing. Please set it in Settings.');
    }
    if (cleanKey.isEmpty) {
      throw const AiClientException('API key is missing. Please set it in Settings.');
    }
    if (messages.isEmpty) {
      throw const AiClientException('No messages to send.');
    }

    try {
      if (_isClaude(cleanEndpoint)) {
        return await _callClaude(cleanEndpoint, cleanKey, messages, modelOverride);
      } else if (_isGeminiNative(cleanEndpoint)) {
        return await _callGeminiNative(cleanEndpoint, cleanKey, messages, modelOverride);
      } else {
        // OpenAI-compatible endpoint (OpenAI, Groq, OpenRouter, Ollama, Gemini OpenAI endpoint)
        return await _callOpenAiCompatible(cleanEndpoint, cleanKey, messages, modelOverride);
      }
    } on SocketException catch (e) {
      final details = e.osError != null ? '${e.message} (${e.osError!.message})' : e.message;
      throw AiClientException('Network error: $details');
    } on http.ClientException catch (e) {
      throw AiClientException('Network client error: ${e.message}');
    } on HandshakeException catch (e) {
      throw AiClientException('SSL/TLS error: ${e.message}');
    } on TimeoutException {
      throw const AiClientException('Request timed out. Please try again.');
    } on AiClientException {
      rethrow;
    } catch (e) {
      throw AiClientException('Unexpected error: $e');
    }
  }

  bool _isClaude(String endpoint) {
    return endpoint.toLowerCase().contains('anthropic.com');
  }

  bool _isGeminiNative(String endpoint) {
    final lower = endpoint.toLowerCase();
    return lower.contains(':generatecontent');
  }

  bool _isGeminiUrl(String endpoint) {
    final lower = endpoint.toLowerCase();
    return lower.contains('generativelanguage.googleapis.com');
  }

  String _resolveDefaultModel(String endpoint, String? override) {
    if (override != null && override.trim().isNotEmpty) {
      return override.trim();
    }
    final lower = endpoint.toLowerCase();
    if (lower.contains('groq.com')) {
      return 'openai/gpt-oss-120b';
    } else if (lower.contains('openai.com')) {
      return 'gpt-4o-mini';
    } else if (lower.contains('openrouter.ai')) {
      return 'meta-llama/llama-3.3-70b-instruct';
    } else if (lower.contains('anthropic.com')) {
      return 'claude-3-5-haiku-20241022';
    } else if (lower.contains('generativelanguage.googleapis.com')) {
      return 'gemini-2.0-flash';
    }
    return 'gemini-2.0-flash';
  }

  /// Handles OpenAI-compatible endpoints (`/chat/completions`)
  Future<String> _callOpenAiCompatible(
    String endpoint,
    String apiKey,
    List<AiMessageDto> messages,
    String? modelOverride,
  ) async {
    var urlStr = endpoint.trim();

    // If Gemini baseUrl like `https://generativelanguage.googleapis.com/v1beta` is passed,
    // point to the official OpenAI compatibility path
    if (_isGeminiUrl(urlStr) && !urlStr.contains('/openai')) {
      if (urlStr.endsWith('/')) {
        urlStr = '${urlStr}openai/chat/completions';
      } else {
        urlStr = '$urlStr/openai/chat/completions';
      }
    } else if (!urlStr.endsWith('/chat/completions')) {
      if (urlStr.endsWith('/')) {
        urlStr = '${urlStr}chat/completions';
      } else {
        urlStr = '$urlStr/chat/completions';
      }
    }

    final model = _resolveDefaultModel(endpoint, modelOverride);
    final payloadMessages = messages.map((m) {
      return {
        'role': m.role,
        'content': m.content,
      };
    }).toList();

    final body = jsonEncode({
      'model': model,
      'messages': payloadMessages,
    });

    final response = await _client
        .post(
          Uri.parse(urlStr),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $apiKey',
          },
          body: body,
        )
        .timeout(const Duration(seconds: 45));

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final choices = data['choices'] as List<dynamic>?;
      if (choices != null && choices.isNotEmpty) {
        final firstChoice = choices[0] as Map<String, dynamic>;
        final message = firstChoice['message'] as Map<String, dynamic>?;
        final content = message?['content'];
        if (content is String) {
          return content.trim();
        }
      }
      throw const AiClientException('Empty response received from LLM.');
    } else {
      _handleHttpError(response.statusCode, response.body);
      return '';
    }
  }

  /// Handles Anthropic Claude `/v1/messages` format
  Future<String> _callClaude(
    String endpoint,
    String apiKey,
    List<AiMessageDto> messages,
    String? modelOverride,
  ) async {
    var urlStr = endpoint.trim();
    if (!urlStr.endsWith('/messages')) {
      if (urlStr.endsWith('/')) {
        urlStr = '${urlStr}messages';
      } else {
        urlStr = '$urlStr/messages';
      }
    }

    final model = _resolveDefaultModel(endpoint, modelOverride);

    // Claude separates system prompt from conversation messages
    String? systemText;
    final userAndAssistantMessages = <Map<String, String>>[];

    for (final m in messages) {
      if (m.role == 'system') {
        systemText = systemText == null ? m.content : '$systemText\n\n${m.content}';
      } else if (m.role == 'user' || m.role == 'assistant') {
        userAndAssistantMessages.add({
          'role': m.role,
          'content': m.content,
        });
      }
    }

    final bodyMap = <String, dynamic>{
      'model': model,
      'messages': userAndAssistantMessages,
      'max_tokens': 1024,
    };
    if (systemText != null && systemText.trim().isNotEmpty) {
      bodyMap['system'] = systemText;
    }

    final response = await _client
        .post(
          Uri.parse(urlStr),
          headers: {
            'Content-Type': 'application/json',
            'x-api-key': apiKey,
            'anthropic-version': '2023-06-01',
          },
          body: jsonEncode(bodyMap),
        )
        .timeout(const Duration(seconds: 45));

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final contentList = data['content'] as List<dynamic>?;
      if (contentList != null && contentList.isNotEmpty) {
        final firstBlock = contentList[0] as Map<String, dynamic>;
        final text = firstBlock['text'];
        if (text is String) {
          return text.trim();
        }
      }
      throw const AiClientException('Empty response received from Claude.');
    } else {
      _handleHttpError(response.statusCode, response.body);
      return '';
    }
  }

  /// Handles native Gemini `:generateContent?key=`
  Future<String> _callGeminiNative(
    String endpoint,
    String apiKey,
    List<AiMessageDto> messages,
    String? modelOverride,
  ) async {
    var urlStr = endpoint.trim();
    if (!urlStr.contains('key=')) {
      final separator = urlStr.contains('?') ? '&' : '?';
      urlStr = '$urlStr${separator}key=$apiKey';
    }

    String? systemText;
    final contents = <Map<String, dynamic>>[];

    for (final m in messages) {
      if (m.role == 'system') {
        systemText = systemText == null ? m.content : '$systemText\n\n${m.content}';
      } else {
        contents.add({
          'role': m.role == 'assistant' ? 'model' : 'user',
          'parts': [
            {'text': m.content}
          ],
        });
      }
    }

    final bodyMap = <String, dynamic>{
      'contents': contents,
    };
    if (systemText != null && systemText.isNotEmpty) {
      bodyMap['systemInstruction'] = {
        'parts': [
          {'text': systemText}
        ],
      };
    }

    final response = await _client
        .post(
          Uri.parse(urlStr),
          headers: {
            'Content-Type': 'application/json',
          },
          body: jsonEncode(bodyMap),
        )
        .timeout(const Duration(seconds: 45));

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final candidates = data['candidates'] as List<dynamic>?;
      if (candidates != null && candidates.isNotEmpty) {
        final firstCandidate = candidates[0] as Map<String, dynamic>;
        final content = firstCandidate['content'] as Map<String, dynamic>?;
        final parts = content?['parts'] as List<dynamic>?;
        if (parts != null && parts.isNotEmpty) {
          final firstPart = parts[0] as Map<String, dynamic>;
          final text = firstPart['text'];
          if (text is String) {
            return text.trim();
          }
        }
      }
      throw const AiClientException('Empty response received from Gemini.');
    } else {
      _handleHttpError(response.statusCode, response.body);
      return '';
    }
  }

  void _handleHttpError(int statusCode, String body) {
    String snippet = body;
    try {
      final parsed = jsonDecode(body);
      if (parsed is Map) {
        if (parsed['error'] is Map && parsed['error']['message'] is String) {
          snippet = parsed['error']['message'] as String;
        } else if (parsed['message'] is String) {
          snippet = parsed['message'] as String;
        }
      }
    } catch (_) {}

    if (snippet.length > 120) {
      snippet = '${snippet.substring(0, 120)}...';
    }

    if (statusCode == 401) {
      throw AiClientException('Unauthorized (401): $snippet', statusCode: 401);
    } else if (statusCode == 403) {
      throw AiClientException('Forbidden (403): $snippet', statusCode: 403);
    } else if (statusCode == 404) {
      if (snippet.toLowerCase().contains('model')) {
        throw AiClientException('Model not found (404): $snippet', statusCode: 404);
      }
      throw AiClientException('Endpoint not found (404): $snippet', statusCode: 404);
    } else if (statusCode == 429) {
      throw AiClientException('Rate limit exceeded (429): $snippet', statusCode: 429);
    } else {
      throw AiClientException('Error $statusCode: $snippet', statusCode: statusCode);
    }
  }

  void dispose() {
    _client.close();
  }
}
