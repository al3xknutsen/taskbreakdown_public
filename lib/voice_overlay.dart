import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers.dart'; // Update this import

class VoiceOverlay extends StatelessWidget {
  final VoidCallback onStopListening;

  const VoiceOverlay({
    required this.onStopListening,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    debugPrint("VoiceOverlay build");
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      bottom: 0,
      child: Material(
        color: Colors.black.withOpacity(0.5),
        child: Stack(
          children: [
            Center(
              child: GestureDetector(
                onTap: onStopListening,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Consumer<RecognizedTextProvider>(
                      builder: (context, provider, child) {
                        return Text(
                          provider.recognizedText,
                          style: const TextStyle(
                              color: Colors.white, fontSize: 24),
                          textAlign: TextAlign.center,
                        );
                      },
                    ),
                    const SizedBox(height: 20),
                    Consumer<CircleSizeProvider>(
                      builder: (context, provider, child) {
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          curve: Curves.easeInOut,
                          width: provider.circleSize,
                          height: provider.circleSize,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: Colors.white,
                                width: 10), // Increased thickness
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.mic,
                              size: 100.0,
                              color: Colors.white,
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              top: 40,
              right: 20,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 30),
                onPressed: onStopListening,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
