/// Role of a chat message.
enum ChatRole { system, user, assistant, tool }

/// A single message in a chat-style LLM call.
///
/// Chat APIs add per-message overhead (role tokens, separators). Use
/// [TokenCounter.countMessages] to include that overhead in the total.
class ChatMessage {
  const ChatMessage({required this.role, required this.content, this.name});

  const ChatMessage.system(String content) : this(role: ChatRole.system, content: content);
  const ChatMessage.user(String content) : this(role: ChatRole.user, content: content);
  const ChatMessage.assistant(String content) : this(role: ChatRole.assistant, content: content);
  const ChatMessage.tool(String content, {String? name})
    : this(role: ChatRole.tool, content: content, name: name);

  final ChatRole role;
  final String content;
  final String? name;

  @override
  String toString() => 'ChatMessage(${role.name}: ${content.length} chars)';
}
