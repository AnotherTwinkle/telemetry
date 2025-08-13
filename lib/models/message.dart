class Message {
  final int? id;
  final String sender;
  final String content;
  final bool isEncrypted;
  final bool isFromMe;
  final DateTime timestamp;
  final MessageType type;

  Message({
    this.id,
    required this.sender,
    required this.content,
    required this.isEncrypted,
    required this.isFromMe,
    required this.timestamp,
    required this.type,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'sender': sender,
      'content': content,
      'isEncrypted': isEncrypted ? 1 : 0,
      'isFromMe': isFromMe ? 1 : 0,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'type': type.index,
    };
  }

  factory Message.fromMap(Map<String, dynamic> map) {
    return Message(
      id: map['id'],
      sender: map['sender'],
      content: map['content'],
      isEncrypted: map['isEncrypted'] == 1,
      isFromMe: map['isFromMe'] == 1,
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp']),
      type: MessageType.values[map['type']],
    );
  }
}

enum MessageType {
  userMessage,
  command,
  update,
} 