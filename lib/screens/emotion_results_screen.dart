import 'package:flutter/material.dart';

class EmotionResultsScreen extends StatelessWidget {
  final Map<String, dynamic> emotionResults;

  const EmotionResultsScreen({super.key, required this.emotionResults});

  Color _getEmotionColor(String emotion) {
    switch (emotion.toLowerCase()) {
      case 'joy':
      case 'happy':
        return const Color(0xFFFFB84D);
      case 'sadness':
      case 'sad':
        return const Color(0xFF4A90E2);
      case 'anger':
      case 'angry':
        return const Color(0xFFE74C3C);
      case 'fear':
      case 'afraid':
        return const Color(0xFF9B59B6);
      case 'surprise':
      case 'surprised':
        return const Color(0xFF3498DB);
      case 'neutral':
        return const Color(0xFF95A5A6);
      default:
        return const Color(0xFF2F8F83);
    }
  }

  @override
  Widget build(BuildContext context) {
    final List emotionList = (emotionResults['emotion_results'] ?? []) as List;

    final Map emotionCounts = (emotionResults['emotion_counts'] ?? {}) as Map;
    final size = MediaQuery.of(context).size;

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFFF5F6F3),
        surfaceTintColor: Colors.transparent,
        title: const Text(
          'Emotion Analysis',
          style: TextStyle(
            color: Color(0xFF1D2A28),
            fontWeight: FontWeight.w700,
          ),
        ),
        iconTheme: const IconThemeData(color: Color(0xFF2A4A44)),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFF5F1E8), Color(0xFFEAF6F3), Color(0xFFFDF8EF)],
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              top: -60,
              right: -40,
              child: Container(
                width: 170,
                height: 170,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0x332F8F83),
                ),
              ),
            ),
            Positioned(
              left: -70,
              bottom: size.height * 0.3,
              child: Container(
                width: 220,
                height: 220,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0x33D88A4D),
                ),
              ),
            ),
            SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Dominant Emotion
                  if (emotionResults['dominant_emotion'] != null)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFD9E1DE)),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x1F1F3D38),
                            blurRadius: 16,
                            offset: Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Text(
                            'Dominant Emotion',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.black.withOpacity(0.6),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: _getEmotionColor(
                                    emotionResults['dominant_emotion'],
                                  ),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                emotionResults['dominant_emotion']
                                    .toString()
                                    .toUpperCase(),
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF1D2A28),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${emotionResults['dominant_emotion_count'] ?? 0} messages',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF8A9491),
                            ),
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 24),

                  // Emotion Breakdown Section
                  const Text(
                    'Emotion Breakdown',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1D2A28),
                    ),
                  ),

                  const SizedBox(height: 12),

                  if (emotionCounts.isNotEmpty)
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.95),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFD9E1DE)),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x0F1F3D38),
                            blurRadius: 12,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children:
                            emotionCounts.entries.map((entry) {
                              final emotion = entry.key.toString();
                              final count = entry.value as int;
                              final totalMessages = emotionCounts.values.fold(
                                0,
                                (a, b) => a + (b as int),
                              );
                              final percentage = ((count / totalMessages) * 100)
                                  .toStringAsFixed(1);

                              return Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Row(
                                          children: [
                                            Container(
                                              width: 10,
                                              height: 10,
                                              decoration: BoxDecoration(
                                                color: _getEmotionColor(
                                                  emotion,
                                                ),
                                                shape: BoxShape.circle,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Text(
                                              emotion
                                                  .replaceFirst(
                                                    emotion[0],
                                                    emotion[0].toUpperCase(),
                                                  )
                                                  .toUpperCase(),
                                              style: const TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w600,
                                                color: Color(0xFF1D2A28),
                                              ),
                                            ),
                                          ],
                                        ),
                                        Text(
                                          '$count msgs • $percentage%',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Color(0xFF8A9491),
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(6),
                                      child: LinearProgressIndicator(
                                        value: count / totalMessages,
                                        minHeight: 6,
                                        backgroundColor: const Color(
                                          0xFFE8EFED,
                                        ),
                                        valueColor: AlwaysStoppedAnimation(
                                          _getEmotionColor(emotion),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                      ),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFD9E1DE)),
                      ),
                      child: const Center(
                        child: Text(
                          'No emotion data available',
                          style: TextStyle(
                            color: Color(0xFF8A9491),
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),

                  const SizedBox(height: 24),

                  // Messages Section
                  const Text(
                    'Message Analysis',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1D2A28),
                    ),
                  ),

                  const SizedBox(height: 12),

                  if (emotionList.isNotEmpty)
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.95),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFD9E1DE)),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x0F1F3D38),
                            blurRadius: 12,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(12),
                      child: ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: emotionList.length,
                        itemBuilder: (context, index) {
                          final result = emotionList[index];
                          final message = result['message'] ?? '';
                          final emotion = result['emotion'] ?? 'Unknown';

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(10),
                                border: Border(
                                  left: BorderSide(
                                    color: _getEmotionColor(emotion),
                                    width: 4,
                                  ),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    message,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: Color(0xFF1D2A28),
                                      height: 1.4,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Container(
                                        width: 6,
                                        height: 6,
                                        decoration: BoxDecoration(
                                          color: _getEmotionColor(emotion),
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        emotion
                                            .replaceFirst(
                                              emotion[0],
                                              emotion[0].toUpperCase(),
                                            )
                                            .toUpperCase(),
                                        style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF8A9491),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFD9E1DE)),
                      ),
                      child: const Center(
                        child: Text(
                          'No messages analyzed',
                          style: TextStyle(
                            color: Color(0xFF8A9491),
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),

                  const SizedBox(height: 24),

                  // Back Button
                  Center(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        elevation: 0,
                        backgroundColor: const Color(0xFF2F8F83),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Back to Chat',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
