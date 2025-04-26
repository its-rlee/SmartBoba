import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import '../../../../core/theme/app_theme.dart';

class VoiceInputButton extends StatefulWidget {
  final Function(String) onResult;
  final double size;

  const VoiceInputButton({
    super.key,
    required this.onResult,
    this.size = 60,
  });

  @override
  State<VoiceInputButton> createState() => _VoiceInputButtonState();
}

class _VoiceInputButtonState extends State<VoiceInputButton>
    with SingleTickerProviderStateMixin {
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _initSpeech();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _animation = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );

    _animationController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _animationController.reverse();
      } else if (status == AnimationStatus.dismissed) {
        if (_isListening) {
          _animationController.forward();
        }
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _initSpeech() async {
    try {
      var available = await _speech.initialize(
        onStatus: (status) {
          print('Speech recognition status: $status');
          if (status == 'done' || status == 'notListening') {
            setState(() {
              _isListening = false;
            });
            _animationController.stop();
            _animationController.reset();
          }
        },
        onError: (error) => print('Speech recognition error: $error'),
      );
      print('Speech recognition available: $available');
    } catch (e) {
      print('Error initializing speech recognition: $e');
    }
  }

  void _listen() async {
    if (!_isListening) {
      try {
        bool available = await _speech.initialize();
        if (available) {
          setState(() {
            _isListening = true;
          });
          _animationController.forward();

          await _speech.listen(
            onResult: (result) {
              if (result.finalResult) {
                widget.onResult(result.recognizedWords);
                setState(() {
                  _isListening = false;
                });
                _animationController.stop();
                _animationController.reset();
              }
            },
            listenFor: const Duration(seconds: 30),
            pauseFor: const Duration(seconds: 5),
            partialResults: true,
            cancelOnError: true,
          );
        } else {
          print('Speech recognition not available');
          // Show a snackbar or toast message to the user
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Speech recognition not available on this device'),
              duration: Duration(seconds: 3),
            ),
          );
        }
      } catch (e) {
        print('Error starting speech recognition: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } else {
      setState(() {
        _isListening = false;
      });
      _speech.stop();
      _animationController.stop();
      _animationController.reset();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.scale(
          scale: _isListening ? _animation.value : 1.0,
          child: GestureDetector(
            onTap: _listen,
            child: Container(
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                color:
                    _isListening ? AppTheme.errorColor : AppTheme.primaryColor,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: _isListening
                        ? AppTheme.errorColor.withOpacity(0.3)
                        : AppTheme.primaryColor.withOpacity(0.3),
                    spreadRadius: 2,
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Icon(
                _isListening ? Icons.mic : Icons.mic_none,
                color: Colors.white,
                size: widget.size * 0.5,
              ),
            ),
          ),
        );
      },
    );
  }
}
