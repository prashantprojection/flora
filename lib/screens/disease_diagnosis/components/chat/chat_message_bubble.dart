import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';
import 'package:flora/models/llm_models.dart';
import 'package:flora/utils/image_utils.dart';

class ChatMessageBubble extends StatelessWidget {
  final LlmMessage message;
  final XFile? selectedImage;
  final bool isFirstMessage;

  const ChatMessageBubble({
    super.key,
    required this.message,
    this.selectedImage,
    required this.isFirstMessage,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16, left: 40),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
            bottomLeft: Radius.circular(16),
            bottomRight: Radius.circular(4),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (isFirstMessage && selectedImage != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: buildImage(
                    selectedImage!.path,
                    width: 150,
                    height: 150,
                    fit: BoxFit.cover,
                    cacheWidth: 300,
                  ),
                ),
              ),
            Text(
              message.text,
              style: const TextStyle(color: Colors.white, fontSize: 15),
            ),
          ],
        ),
      ),
    );
  }
}
