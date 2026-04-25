import '../heuristic_tokenizer.dart';
import '../llm_model.dart';

/// Estimates the token overhead of tool (function) definitions sent to an LLM.
///
/// The exact token count for tool definitions is not officially documented by
/// most providers, so this uses a heuristic: serialize the definition to a
/// canonical string representation and count its tokens using the appropriate
/// family's heuristic tokenizer.
///
/// For OpenAI's function-calling format the overhead is roughly proportional
/// to the total character length of the serialized JSON schema. This
/// estimator provides ±15–25 % accuracy for typical tool schemas.
class ToolTokenEstimator {
  const ToolTokenEstimator._();

  /// Estimates the tokens consumed by a list of tool definitions.
  ///
  /// Each [tools] entry is a plain-Dart map that follows the provider's tool
  /// schema format.  For OpenAI this is the `tools` array element:
  ///
  /// ```dart
  /// final tokens = ToolTokenEstimator.estimate(
  ///   model: LlmModel.gpt4o,
  ///   tools: [
  ///     {
  ///       'type': 'function',
  ///       'function': {
  ///         'name': 'get_weather',
  ///         'description': 'Get current weather for a city.',
  ///         'parameters': {
  ///           'type': 'object',
  ///           'properties': {
  ///             'city': {'type': 'string', 'description': 'City name'},
  ///           },
  ///           'required': ['city'],
  ///         },
  ///       },
  ///     },
  ///   ],
  /// );
  /// ```
  static int estimate({
    required LlmModel model,
    required List<Map<String, dynamic>> tools,
  }) {
    if (tools.isEmpty) return 0;

    final tokenizer = HeuristicTokenizer(model.family);
    var total = 0;

    for (final tool in tools) {
      final repr = _serialize(tool);
      total += tokenizer.count(repr);
    }

    // Add a small per-call overhead for the tools wrapper structure.
    // OpenAI charges ~2-3 extra tokens per call for the tools array framing.
    total += tools.length * 3;
    return total;
  }

  /// Converts a tool definition map to a canonical text representation that
  /// a tokenizer can count. Uses a compact key=value style that approximates
  /// how most providers encode tool metadata internally.
  static String _serialize(Object? obj) {
    if (obj == null) return '';
    if (obj is String) return obj;
    if (obj is num || obj is bool) return obj.toString();
    if (obj is List) return obj.map(_serialize).join(' ');
    if (obj is Map) {
      return obj.entries.map((e) => '${e.key} ${_serialize(e.value)}').join(' ');
    }
    return obj.toString();
  }
}
