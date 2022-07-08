class ChatRoomPodo {
  final String? image;
  final String? title;
  final String? font;
  final String? hex;
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
}
