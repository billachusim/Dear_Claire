
class Mood {
  int? id;
  String? name = "";
  Mood(this.id, this.name);


  static final MOODS = [
    Mood(-1, "💕"),
    Mood(0, "💕"),
    Mood(1, "is feeling happy \uD83D\uDE0A"),
    Mood(2, "is feeling sad \uD83D\uDE14"),
    Mood(3, "is feeling excited \uD83D\uDE01"),
    Mood(4, "is falling in love ♥"),
    Mood(5, "is falling out of love \uD83D\uDC94"),
    Mood(6, "is feeling depressed \uD83D\uDE22"),
    Mood(7, "is feeling motivated \uD83D\uDC83"),
    Mood(8, "is feeling anxious \uD83D\uDE1F"),
    Mood(9, "is feeling sick \uD83E\uDD22"),
    Mood(10, "is feeling afraid \uD83D\uDE28"),
    Mood(11, "is feeling surprised \uD83D\uDE32"),
    Mood(12, "is feeling jealous \uD83D\uDE44"),
    Mood(13, "is feeling upside-down \uD83D\uDE43"),
    Mood(14, "is feeling embarrassed \uD83D\uDE33"),
    Mood(15, "is feeling gingered \uD83D\uDCAA"),
    Mood(16, "is feeling fly \uD83D\uDC7C"),
    Mood(17, "is feeling Claire 🌺")
  ];

  static String? getMood(int? moodId) {

    for (var mood in MOODS) {
      if (mood.id == moodId) {
        return mood.name;
      }
    }
  }

  static int? getMoodId(int? moodId) {

    for (var mood in MOODS) {
      if (mood.id == moodId) {
        return mood.id;
      }
    }
  }

}

