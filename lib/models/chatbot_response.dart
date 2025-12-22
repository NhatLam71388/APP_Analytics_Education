class ChatbotResponse {
  final String answer;
  final String? mdxGenerated;
  final String? model;

  ChatbotResponse({
    required this.answer,
    this.mdxGenerated,
    this.model,
  });

  factory ChatbotResponse.fromJson(Map<String, dynamic> json) {
    return ChatbotResponse(
      answer: json['answer'] ?? '',
      mdxGenerated: json['mdx_generated'],
      model: json['model'],
    );
  }
}








