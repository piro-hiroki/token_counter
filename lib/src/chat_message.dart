import 'multimodal/image_token_estimator.dart';

export 'multimodal/image_token_estimator.dart' show ImageDetail;

/// Role of a chat message.
enum ChatRole { system, user, assistant, tool }

/// An image attachment that can be included in a [ChatMessage].
///
/// Pixel dimensions are used to calculate the token cost via
/// [ImageTokenEstimator] for each provider. If dimensions are unknown,
/// supply the provider-specific flat cost via [flatTokens] instead.
class ImageAttachment {
  const ImageAttachment({
    this.width,
    this.height,
    this.detail = ImageDetail.auto,
    this.flatTokens,
  }) : assert(
         (width != null && height != null) || flatTokens != null,
         'Provide either width+height or flatTokens',
       );

  /// Actual image width in pixels.
  final int? width;

  /// Actual image height in pixels.
  final int? height;

  /// Detail level hint for OpenAI vision models.
  final ImageDetail detail;

  /// Override: use this fixed token count instead of the formula-based
  /// calculation. Useful when exact dimensions are unavailable.
  final int? flatTokens;

  @override
  String toString() =>
      'ImageAttachment(${width}x$height, detail: ${detail.name})';
}

/// A single message in a chat-style LLM call.
///
/// Chat APIs add per-message overhead (role tokens, separators). Use
/// [TokenCounter.countMessages] to include that overhead in the total.
///
/// To include images, pass them via [images]:
/// ```dart
/// ChatMessage.user(
///   'What is in this image?',
///   images: [ImageAttachment(width: 1024, height: 768)],
/// )
/// ```
class ChatMessage {
  const ChatMessage({
    required this.role,
    required this.content,
    this.name,
    this.images = const [],
  });

  const ChatMessage.system(String content)
    : this(role: ChatRole.system, content: content);

  const ChatMessage.user(String content, {List<ImageAttachment> images = const []})
    : this(role: ChatRole.user, content: content, images: images);

  const ChatMessage.assistant(String content)
    : this(role: ChatRole.assistant, content: content);

  const ChatMessage.tool(String content, {String? name})
    : this(role: ChatRole.tool, content: content, name: name);

  final ChatRole role;
  final String content;
  final String? name;

  /// Images attached to this message (for vision models).
  final List<ImageAttachment> images;

  @override
  String toString() =>
      'ChatMessage(${role.name}: ${content.length} chars, '
      '${images.length} image(s))';
}
