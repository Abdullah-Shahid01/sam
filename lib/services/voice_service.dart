// lib/services/voice_service.dart

import 'package:speech_to_text/speech_to_text.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_recognition_error.dart';

/// Service for handling speech-to-text functionality.
/// Note: The primary voice input code path is in transactions_screen.dart.
/// This service is used by voice_input_dialog.dart (secondary path).
class VoiceService {
  static final VoiceService _instance = VoiceService._internal();
  SpeechToText _speechToText = SpeechToText();
  
  bool _isInitialized = false;
  bool _isListening = false;
  String _lastError = '';
  
  Function(bool isListening)? _onListeningStateChanged;

  factory VoiceService() => _instance;

  VoiceService._internal();

  bool get isListening => _isListening;
  bool get isInitialized => _isInitialized;
  String get lastError => _lastError;

  /// Initialize the speech recognition service.
  Future<bool> initialize() async {
    if (_isInitialized) return true;

    try {
      _isInitialized = await _speechToText.initialize(
        onError: _onError,
        onStatus: _onStatus,
      );
      return _isInitialized;
    } catch (e) {
      _lastError = 'Failed to initialize speech recognition: $e';
      return false;
    }
  }

  /// Start listening for speech.
  /// Creates a fresh SpeechToText instance each call to avoid stale plugin state.
  Future<void> startListening({
    required Function(String text, bool isFinal) onResult,
    Function(bool isListening)? onListeningStateChanged,
  }) async {
    _onListeningStateChanged = onListeningStateChanged;
    
    try { await _speechToText.cancel(); } catch (_) {}
    _isListening = false;
    
    // Fresh instance — the plugin's internal _initWorked flag persists
    // on reused instances, causing initialize() to silently skip callbacks.
    _speechToText = SpeechToText();
    _isInitialized = false;
    
    final success = await initialize();
    if (!success) {
      _lastError = 'Speech recognition not available';
      onListeningStateChanged?.call(false);
      return;
    }

    _isListening = true;
    onListeningStateChanged?.call(true);

    await _speechToText.listen(
      onResult: (SpeechRecognitionResult result) {
        onResult(result.recognizedWords, result.finalResult);
      },
      listenFor: const Duration(seconds: 30),
      pauseFor: const Duration(seconds: 3),
      partialResults: true,
      listenMode: ListenMode.confirmation,
    );
  }

  /// Stop listening for speech.
  Future<void> stopListening() async {
    if (!_isListening) return;
    
    try {
      await _speechToText.stop();
    } catch (_) {}
    _isListening = false;
    _onListeningStateChanged?.call(false);
  }

  /// Cancel listening without processing.
  Future<void> cancelListening() async {
    try { await _speechToText.cancel(); } catch (_) {}
    _isListening = false;
    _onListeningStateChanged?.call(false);
    _onListeningStateChanged = null;
  }

  void _onError(SpeechRecognitionError error) {
    _lastError = error.errorMsg;
    _isListening = false;
    _onListeningStateChanged?.call(false);
  }

  void _onStatus(String status) {
    if (status == 'done' || status == 'notListening') {
      _isListening = false;
      _onListeningStateChanged?.call(false);
    }
  }

  /// Check if speech recognition is available on this device.
  Future<bool> isAvailable() async {
    if (!_isInitialized) {
      await initialize();
    }
    return _isInitialized;
  }

  /// Get list of available locales for speech recognition.
  Future<List<LocaleName>> getLocales() async {
    if (!_isInitialized) {
      await initialize();
    }
    return await _speechToText.locales();
  }
}
