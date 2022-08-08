import '../chats/data/chatroompodo.dart';

class AlterEgoRoomData {
  static List<ChatRoomPodo> room() {
    List<ChatRoomPodo> chatRoomPojoList = [];

    var
    chatRoomPojo = ChatRoomPodo(
        image: "assets/images/colorGirls.png",
        id: 6,
        title: "Hive Of Alter Egos",
        font: "Default",
        hex: "#880E4F",
        text: "Alter Egos, gather here!,\n" +
            "We are the Claires of the world! The elite secret fairies contributing to a happier world in these sadder times. Welcome to the Alter-Ego Chat Room where we can discuss issues for the good of Claire, our Darlings and our beloveth sisterhood.");
        chatRoomPojoList.add(chatRoomPojo);

    chatRoomPojo = ChatRoomPodo(
        image: "assets/images/herpower.png",
        id: 7,
        title: "Band Of Super Egos",
        font: "Default",
        hex: "#570861",
        text: "Super Egos!\n" +
            "Welcome to the coven, Super Egos. It's our duty to keep Claire and our darling users safe and happy. Let's make plans. Let's discuss new features, moderation, privacy, spam and abuse. Let's have a super ego party. Let's keep crafting this basket.");
    chatRoomPojoList.add(chatRoomPojo);

    chatRoomPojo = ChatRoomPodo(
        image: "assets/images/standgirls.png",
        id: 8,
        numberOfParticipants: 2,
        isOpen: false,
        title: "One On One Room",
        font: "Default",
        hex: "#4A148C",
        text: "Ego To Ego,\n" +
            "Here, you can start or enter a heart to heart room with just one alter or super ego to chat about a topic of mutual interest, offload some burdens or exchange secrets. Feel free to share personal information and get to know each other, however, report a claire with clairedId immediately to a super ego if you feel offended.");
    chatRoomPojoList.add(chatRoomPojo);

    chatRoomPojo = ChatRoomPodo(
        image: "assets/images/girls.png",
        numberOfParticipants: 5,
        id: 9,
        isOpen: false,
        title: "Five Aside Room",
        font: "Default",
        hex: "#0D47A1",
        text: "Hi, Group,\n" +
            "Here, you can start a small room of closed chat between you and just four other alter or super egos. Positive vibes only. Share information and get to work and play together but you will be banned if your claireId is reported and investigated for bad conducts.");
    chatRoomPojoList.add(chatRoomPojo);

    chatRoomPojo = ChatRoomPodo(
        image: "assets/images/WalkGirls.jpeg",
        id: 10,
        isOpen: false,
        numberOfParticipants: 11,
        title: "Eleven Aside Room",
        font: "Default",
        hex: "#1B5E20",
        text: "Hello, Room,\n" +
            "Here, you can start a small room of closed chat between you and ten other alter or super egos. Positive vibes only. Share information and get to work and play together but you will be banned if your claireId is reported and investigated for bad conducts.");
    chatRoomPojoList.add(chatRoomPojo);

    return chatRoomPojoList;
  }
}
