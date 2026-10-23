import 'package:flutter/material.dart';
import '../models/ai_companion_message.dart';
import '../services/ai_companion_service.dart';

class AiChatProvider extends ChangeNotifier {
  final AiCompanionService _aiService;
  bool _isThinking = false;

  List<AiCompanionMessage> get messages => _aiService.history;
  bool get isThinking => _isThinking;

  AiChatProvider(this._aiService);

  Future<void> sendUserMessage(String text) async {
    if (text.trim().isEmpty) return;
    _isThinking = true;
    notifyListeners();

    try {
      await _aiService.sendMessage(text);
    } finally {
      _isThinking = false;
      notifyListeners();
    }
  }
}
