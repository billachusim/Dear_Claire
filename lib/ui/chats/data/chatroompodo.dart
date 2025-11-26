
class ChatRoomPodo {
  final String? image;
  final String? title;
  final String? font;final String? hex;
  final String? text;
  final int? numberOfParticipants;
  final bool? isOpen;
  final int? id;

  ChatRoomPodo(
      {required this.image,
        required this.id,
        this.title,
        this.font,
        this.hex,
        this.text,
        this.numberOfParticipants,
        this.isOpen = true});

  // Add this factory constructor to create an object from a Firestore map.
  factory ChatRoomPodo.fromJson(Map<String, dynamic> json) {
    return ChatRoomPodo(
      image: json['image'],
      id: json['id'],
      title: json['title'],
      font: json['font'],
      hex: json['hex'],
      text: json['text'],
      numberOfParticipants: json['numberOfParticipants'],
      isOpen: json['isOpen'] ?? true, // Provide a default value
    );
  }
}
