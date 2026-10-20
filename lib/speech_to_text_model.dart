import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:provider/provider.dart';
import 'providers.dart';
import 'voice_overlay.dart';

class SpeechToTextModel with ChangeNotifier {
  late stt.SpeechToText _speech;
  bool _isListening = false;
  String _recognizedText = "";
  Timer? _stopListeningTimer;
  OverlayEntry? _overlayEntry;

  bool get isListening => _isListening;
  String get recognizedText => _recognizedText;

  SpeechToTextModel() {
    _speech = stt.SpeechToText();
  }

  void startListening(BuildContext context) async {
    bool available = await _speech.initialize();
    debugPrint("Speech available: $available");
    if (available) {
      _isListening = true;
      _recognizedText = "";
      Provider.of<RecognizedTextProvider>(context, listen: false)
          .clearRecognizedText();
      Provider.of<CircleSizeProvider>(context, listen: false)
          .setCircleSize(150.0);
      _showOverlay(context);
      notifyListeners();
      _speech.listen(
          onResult: (val) {
            final recognizedWords = val.recognizedWords;
            final capitalizedText = recognizedWords.isNotEmpty
                ? recognizedWords[0].toUpperCase() +
                    recognizedWords.substring(1)
                : recognizedWords;
            Provider.of<RecognizedTextProvider>(context, listen: false)
                .setRecognizedText(capitalizedText);
            _recognizedText = capitalizedText;
            debugPrint("Recognized text: $_recognizedText");
            notifyListeners();
            _resetStopListeningTimer(context);
          },
          onSoundLevelChange: (level) {
            debugPrint("Sound level: $level");
            Provider.of<CircleSizeProvider>(context, listen: false)
                .setCircleSize(150.0 + (level * 2));
          },
          // listenFor: const Duration(seconds: 30),
          listenOptions: stt.SpeechListenOptions(
            partialResults: true,
            cancelOnError: true,
          ));
    }
  }

  void _resetStopListeningTimer(BuildContext context) {
    _stopListeningTimer?.cancel();
    _stopListeningTimer =
        Timer(const Duration(seconds: 1), () => stopListening(context));
  }

  void stopListening(BuildContext context) {
    debugPrint("Stop listening");
    _isListening = false;
    _speech.stop();
    _removeOverlay();
    _stopListeningTimer?.cancel();
    notifyListeners();

    if (_recognizedText.isEmpty) return;

    TreeProvider treeProvider =
        Provider.of<TreeProvider>(context, listen: false);

    if (treeProvider.selectedNode == null) return;

    final prefs = SharedPreferences.getInstance();
    prefs.then((value) {
      final autoGenerateAIList = value.getBool('autoGenerateAIList') ?? false;
      if (autoGenerateAIList) {
        treeProvider.generateSubtree(
            treeProvider.selectedNode!, _recognizedText, context);
      }
    });
  }

  void _showOverlay(BuildContext context) {
    _overlayEntry = OverlayEntry(
      builder: (context) => VoiceOverlay(
        onStopListening: () => stopListening(context),
      ),
    );
    Overlay.of(context)?.insert(_overlayEntry!);
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }
}
