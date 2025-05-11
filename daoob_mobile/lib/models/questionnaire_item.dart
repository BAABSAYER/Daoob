class QuestionnaireItem {
  final int id;
  final int eventTypeId;
  final String questionText;
  final String questionType;
  final dynamic options;
  final bool required;
  final int? displayOrder;
  final DateTime createdAt;

  QuestionnaireItem({
    required this.id,
    required this.eventTypeId,
    required this.questionText,
    required this.questionType,
    this.options,
    this.required = false,
    this.displayOrder,
    required this.createdAt,
  });

  factory QuestionnaireItem.fromJson(Map<String, dynamic> json) {
    return QuestionnaireItem(
      id: json['id'],
      eventTypeId: json['eventTypeId'],
      questionText: json['questionText'],
      questionType: json['questionType'],
      options: json['options'],
      required: json['required'] ?? false,
      displayOrder: json['displayOrder'],
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt']) 
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'eventTypeId': eventTypeId,
      'questionText': questionText,
      'questionType': questionType,
      'options': options,
      'required': required,
      'displayOrder': displayOrder,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}