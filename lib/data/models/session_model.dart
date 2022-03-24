class SessionModel{

  final String? name;
  final String? time;
  final String? date;
  final int? index;
  final String? title;
  final String? sub;
  final bool? hasImages;
  final String? commentTitle;
  final String? commentSub;
  final String? imageUrl;
  final String? location;
  final String? mood;

  SessionModel(
      {this.name,
      this.time,
      this.date,
        this.index,
      this.title,
      this.sub,
      this.hasImages=false,
      this.commentTitle,
      this.commentSub,
      this.imageUrl,
      this.location,
      this.mood});

}