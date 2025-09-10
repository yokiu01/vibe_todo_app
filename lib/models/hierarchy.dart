enum RelationshipType {
  areaGoal,
  goalProject,
  projectTask,
  areaNote,
  resourceNote,
}

class Hierarchy {
  final String id;
  final String parentId;
  final String childId;
  final RelationshipType relationshipType;
  final DateTime createdAt;

  Hierarchy({
    required this.id,
    required this.parentId,
    required this.childId,
    required this.relationshipType,
    required this.createdAt,
  });

  Hierarchy copyWith({
    String? id,
    String? parentId,
    String? childId,
    RelationshipType? relationshipType,
    DateTime? createdAt,
  }) {
    return Hierarchy(
      id: id ?? this.id,
      parentId: parentId ?? this.parentId,
      childId: childId ?? this.childId,
      relationshipType: relationshipType ?? this.relationshipType,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'parent_id': parentId,
      'child_id': childId,
      'relationship_type': relationshipType.name,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory Hierarchy.fromMap(Map<String, dynamic> map) {
    return Hierarchy(
      id: map['id'],
      parentId: map['parent_id'],
      childId: map['child_id'],
      relationshipType: RelationshipType.values.firstWhere(
        (e) => e.name == map['relationship_type'],
      ),
      createdAt: DateTime.parse(map['created_at']),
    );
  }
}

