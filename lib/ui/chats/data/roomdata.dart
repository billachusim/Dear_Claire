import 'chatroompodo.dart';

class RoomData {
  static List<ChatRoomPodo> room() {
    List<ChatRoomPodo> chatRoomPojoList = [];

    var
    chatRoomPojo = ChatRoomPodo(
        image: "assets/images/loveGif.gif",
        id: -1,
        title: "One On One With Claire AI",
        font: "Default",
        hex: "#68034D",
        text: "Hello Gen Z,\n" +
            "Want to have some fun and expand your horizons? Come chat with me, ChatGPT! Whether it's about your favorite hobbies, current events, or just random musings, I'm here to listen and chat. Let's connect and see where the conversation takes us! #ChatWithChatGPT #GenZ #Let'sChat");
    chatRoomPojoList.add(chatRoomPojo);

    chatRoomPojo = ChatRoomPodo(
        image: "assets/images/loveGif.gif",
        id: 0,
        title: "Love and Relationship Garden",
        font: "Default",
        hex: "#88050B",
        text: "Hello, Lovers,\n" +
            "For all of us that believe that falling in love and building good relationships is not far from the only reason of our existence; Welcome to the Love and Relationship Diary Room.");
    chatRoomPojoList.add(chatRoomPojo);

    chatRoomPojo = ChatRoomPodo(
        image: "assets/images/EntCom.jpeg",
        id: 1,
        title: "Entertainment and Comedy Hall",
        font: "Default",
        hex: "#0407ED",
        text: "Knock, Knock.\n" +
            "What's cooking in the streets? Which celebrity took everyone's attention yesterday and who is taking it this weekend? But, for today, please, who can make us laugh? Welcome to the Entertainment and Comedy Diary Room.");
    chatRoomPojoList.add(chatRoomPojo);

    chatRoomPojo = ChatRoomPodo(
        image: "assets/images/greenGuyFashion.gif",
        id: 2,
        title: "The Fashion Walkway",
        font: "Default",
        hex: "#d50000",
        text: "Hello, Nistas,\n" +
            "Do you have a date or meeting tomorrow and don't know what to wear? And by \"don't know what to wear?\" I mean maybe you have different shades of sunrise yellow crop jackets and can't decide which of them works for your cobalt blue sneakers or oxblood stilettos or just maybe you don't even have a nice shoe anymore. Welcome to the Fashion Diary Room where we can all help each other slay.");
    chatRoomPojoList.add(chatRoomPojo);

    chatRoomPojo = ChatRoomPodo(
        image: "assets/images/youngPolitics.gif",
        id: 3,
        title: "Political and Social Issues",
        font: "Default",
        hex: "#3E2723",
        text: "Hello, Darlings,\n" +
            "Our generation has been famously tagged as the most politically and socially \"woke\" generation ever. Using the power of tech and social media to stand against bad political leadership and speak up against social inequalities and abuse. Welcome to the Political and Social Issues Diary Room.");
    chatRoomPojoList.add(chatRoomPojo);

    chatRoomPojo = ChatRoomPodo(
        image: "assets/images/sports.gif",
        id: 4,
        title: "Sports Analysis Centre",
        font: "Default",
        hex: "#096D0E",
        text: "Pundits, you are live!\n" +
            "Share scores, statistics and banter. Rep your favourite teams and players. Analyse the latest games and predict coming games with other fans from all over the world. Welcome to the Sports Analysis Diary Room.");
    chatRoomPojoList.add(chatRoomPojo);

    chatRoomPojo = ChatRoomPodo(
        image: "assets/images/DearDiary.jpg",
        id: 5,
        title: "Education Classroom",
        font: "Default",
        hex: "#000003",
        text: "Hello, Class,\n" +
            "This classroom has no teacher. Technically, we are all learners and teachers because to teach you will have to learn and to learn you'll have to teach. Welcome to the Education Diary Room.");
    chatRoomPojoList.add(chatRoomPojo);

    chatRoomPojo = ChatRoomPodo(
        image: "assets/images/bikeGirl.gif",
        id: 6,
        title: "Health Care Ward",
        font: "Default",
        hex: "#239B56",
        text: "Hello, Darlings,\n" +
            "Welcome to the Healthcare Chat Room. Discuss symptoms, diagnosis and share healthertaining information about common sicknesses. If you are sick, we'll wish you well or even sing you \"Soft Kitty\" but remember to visit a doctor because we really love to have you around.");
    chatRoomPojoList.add(chatRoomPojo);

    chatRoomPojo = ChatRoomPodo(
        image: "assets/images/makeMoreArt.gif",
        id: 7,
        title: "Arts and Creativity Studio",
        font: "Default",
        hex: "#880E4F",
        text: "Hello World!\n" +
            "Weirdos, Geeks, Jacks, Queers, Freaks, Worms and Nerds all have something in common; Spending more time doing something no one else can do and only few can understand. Welcome to the Arts and Creativity Diary Room. Share.");
    chatRoomPojoList.add(chatRoomPojo);

    chatRoomPojo = ChatRoomPodo(
        image: "assets/images/tooShy.gif",
        id: 8,
        numberOfParticipants: 2,
        isOpen: false,
        title: "One On One Room",
        font: "Default",
        hex: "#4A148C",
        text: "Shhhhhhhhh,\n" +
            "Here, you can start or enter a heart to heart room with just one unknown and anonymous darling to chat about a topic of mutual interest, offload some burdens or exchange secrets. DO NOT REQUEST OR SHARE PERSONAL INFORMATION. YOU WILL BE BANNED.");
    chatRoomPojoList.add(chatRoomPojo);

    chatRoomPojo = ChatRoomPodo(
        image: "assets/images/hiFive.gif",
        numberOfParticipants: 5,
        id: 9,
        isOpen: false,
        title: "Five Aside Room",
        font: "Default",
        hex: "#0D47A1",
        text: "Hi, Group,\n" +
            "Here, you can start a small room of closed chat between you and just four other anonymous users online. Positive vibes only. DO NOT REQUEST OR SHARE PERSONAL INFORMATION. YOU WILL BE BANNED.");
    chatRoomPojoList.add(chatRoomPojo);

    chatRoomPojo = ChatRoomPodo(
        image: "assets/images/elevenAside.png",
        id: 10,
        isOpen: false,
        numberOfParticipants: 11,
        title: "Eleven Aside Room",
        font: "Default",
        hex: "#1B5E20",
        text: "Hello, Room,\n" +
            "Here, you can start a small room of closed chat between you and ten other anonymous users online. Positive vibes only. DO NOT REQUEST OR SHARE PERSONAL INFORMATION. YOU WILL BE BANNED.");
    chatRoomPojoList.add(chatRoomPojo);

    return chatRoomPojoList;
  }
}
