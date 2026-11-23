
class Mood {
  int? id;
  String? name = "";
  Mood(this.id, this.name);


  static final MOODS = [
    Mood(-1, ""),
    Mood(0, ""),
    Mood(1, "is happy \uD83D\uDE0A"),
    Mood(2, "is sad \uD83D\uDE14"),
    Mood(3, "is excited \uD83D\uDE01"),
    Mood(4, "is in love ♥"),
    Mood(5, "is out of love \uD83D\uDC94"),
    Mood(6, "is depressed \uD83D\uDE22"),
    Mood(7, "is motivated \uD83D\uDC83"),
    Mood(8, "is anxious \uD83D\uDE1F"),
    Mood(9, "is sick \uD83E\uDD22"),
    Mood(10, "is afraid \uD83D\uDE28"),
    Mood(11, "is surprised \uD83D\uDE32"),
    Mood(12, "is jealous \uD83D\uDE44"),
    Mood(13, "is upside-down \uD83D\uDE43"),
    Mood(14, "is embarrassed \uD83D\uDE33"),
    Mood(15, "is gingered \uD83D\uDCAA"),
    Mood(16, "is fly \uD83D\uDC7C"),
    Mood(17, "so Claire 🌺")
  ];

  static String? getMood(int? moodId) {

    for (var mood in MOODS) {
      if (mood.id == moodId) {
        return mood.name;
      }
    }
    return null;
  }

  static int? getMoodId(int? moodId) {

    for (var mood in MOODS) {
      if (mood.id == moodId) {
        return mood.id;
      }
    }
    return null;
  }

}

