import 'package:flutter/material.dart';
import 'screens/chat_topics_screen.dart';

export 'models/chat_message.dart';
export 'models/chat_topic.dart';
export 'config/chat_module_config.dart';
export 'services/chat_auth_adapter.dart';
export 'services/wiki_chat_api_service.dart';
export 'services/wiki_event_stream_service.dart';
export 'state/chat_providers.dart';
export 'screens/chat_topics_screen.dart';
export 'screens/chat_conversation_screen.dart';

/// Facade entrypoint for the WikiChat module.
class WikiChatModule {
  static const String id = 'chat';
  static const String defaultTitle = 'WikiChat';

  /// Returns the main topics screen widget.
  static Widget createScreen() {
    return const ChatTopicsScreen();
  }
}
