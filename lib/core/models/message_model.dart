class ChatMessage {
  final String id;
  final String itemId;
  final String claimId;
  final String senderId;
  final String senderName;
  final String text;
  final DateTime createdAt;

  const ChatMessage({
    required this.id,
    required this.itemId,
    required this.claimId,
    required this.senderId,
    required this.senderName,
    required this.text,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'itemId': itemId,
      'claimId': claimId,
      'senderId': senderId,
      'senderName': senderName,
      'text': text,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory ChatMessage.fromMap(Map<String, dynamic> map) {
    return ChatMessage(
      id: map['id'] ?? '',
      itemId: map['itemId'] ?? '',
      claimId: map['claimId'] ?? '',
      senderId: map['senderId'] ?? '',
      senderName: map['senderName'] ?? '',
      text: map['text'] ?? '',
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'])
          : DateTime.now(),
    );
  }
}
