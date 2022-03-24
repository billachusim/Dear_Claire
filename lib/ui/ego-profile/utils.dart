

var kToday = DateTime.now();
var kFirstDay = DateTime(kToday.year-2, DateTime.january, kToday.day);
var kLastDay = DateTime(kToday.year, kToday.month, kToday.day);

int getHashCode(DateTime key) {
  return key.day * 1000000 + key.month * 10000 + key.year;
}

