/// Notion 블록 모델
/// 다양한 블록 타입(paragraph, heading, todo 등)을 지원
class NotionBlock {
  final String id;
  final String type;
  final Map<String, dynamic> content;
  final bool hasChildren;
  final List<NotionBlock>? children;

  NotionBlock({
    required this.id,
    required this.type,
    required this.content,
    this.hasChildren = false,
    this.children,
  });

  factory NotionBlock.fromJson(Map<String, dynamic> json) {
    final type = json['type'] as String;
    final typeContent = json[type] as Map<String, dynamic>?;

    return NotionBlock(
      id: json['id'] as String,
      type: type,
      content: typeContent ?? {},
      hasChildren: json['has_children'] as bool? ?? false,
      children: null, // Children loaded separately if needed
    );
  }

  /// 텍스트 콘텐츠 추출 (paragraph, heading 등)
  String get plainText {
    if (content['rich_text'] != null) {
      final richText = content['rich_text'] as List;
      return richText
          .map((item) => (item['plain_text'] as String?) ?? '')
          .join('');
    }

    // to_do 블록
    if (type == 'to_do' && content['rich_text'] != null) {
      final richText = content['rich_text'] as List;
      return richText
          .map((item) => (item['plain_text'] as String?) ?? '')
          .join('');
    }

    return '';
  }

  /// 체크박스 상태 (to_do 블록용)
  bool get isChecked {
    if (type == 'to_do') {
      return content['checked'] as bool? ?? false;
    }
    return false;
  }

  /// 헤딩 레벨 (heading_1, heading_2, heading_3)
  int? get headingLevel {
    if (type.startsWith('heading_')) {
      return int.tryParse(type.split('_').last);
    }
    return null;
  }

  /// 블록을 Notion API 형식으로 변환
  Map<String, dynamic> toJson() {
    return {
      'type': type,
      type: content,
    };
  }

  /// 텍스트 블록 생성 헬퍼
  static NotionBlock createParagraph(String text, {String? id}) {
    return NotionBlock(
      id: id ?? 'temp_${DateTime.now().millisecondsSinceEpoch}',
      type: 'paragraph',
      content: {
        'rich_text': [
          {
            'type': 'text',
            'text': {'content': text},
            'plain_text': text,
          }
        ]
      },
    );
  }

  /// 헤딩 블록 생성 헬퍼
  static NotionBlock createHeading(String text, int level, {String? id}) {
    return NotionBlock(
      id: id ?? 'temp_${DateTime.now().millisecondsSinceEpoch}',
      type: 'heading_$level',
      content: {
        'rich_text': [
          {
            'type': 'text',
            'text': {'content': text},
            'plain_text': text,
          }
        ]
      },
    );
  }

  /// To-do 블록 생성 헬퍼
  static NotionBlock createTodo(String text, bool checked, {String? id}) {
    return NotionBlock(
      id: id ?? 'temp_${DateTime.now().millisecondsSinceEpoch}',
      type: 'to_do',
      content: {
        'rich_text': [
          {
            'type': 'text',
            'text': {'content': text},
            'plain_text': text,
          }
        ],
        'checked': checked,
      },
    );
  }

  /// 블록 복사
  NotionBlock copyWith({
    String? id,
    String? type,
    Map<String, dynamic>? content,
    bool? hasChildren,
    List<NotionBlock>? children,
  }) {
    return NotionBlock(
      id: id ?? this.id,
      type: type ?? this.type,
      content: content ?? this.content,
      hasChildren: hasChildren ?? this.hasChildren,
      children: children ?? this.children,
    );
  }

  /// 텍스트 업데이트
  NotionBlock updateText(String newText) {
    final newContent = Map<String, dynamic>.from(content);
    newContent['rich_text'] = [
      {
        'type': 'text',
        'text': {'content': newText},
        'plain_text': newText,
      }
    ];
    return copyWith(content: newContent);
  }

  /// 체크 상태 토글 (to_do용)
  NotionBlock toggleChecked() {
    if (type != 'to_do') return this;

    final newContent = Map<String, dynamic>.from(content);
    newContent['checked'] = !(content['checked'] as bool? ?? false);
    return copyWith(content: newContent);
  }
}
