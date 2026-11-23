

class SessionService {
  //final _databaseRef = FirebaseDatabase.instance.reference();

  SessionService();

  List<PostResponse> postList = <PostResponse>[];

  Future<void> getPost() async {
    print("==> getPost in session service called");
    // await _databaseRef.child("posts").once().then((DataSnapshot e) {

    //   print(e.value['title'].toString());
    //   var data = e.value;
    //   print(data);
    //   var keys = e.value.keys;
    //   for (var item in keys) {
    //     postList.add(PostResponse(
    //         title: data[item]['title'],
    //         archived: data[item]['archived'],
    //         author: data[item]['author'],
    //         body: data[item]['body'],
    //         firebaseId: data[item]['firebaseId'],
    //         flagged: data[item]['flagged'],
    //         lastResponse: data[item]['lastResponse'],
    //         respondentId: data[item]['respondentId'],
    //         featured: data[item]['featured'],
    //         uid: data[item]['uid']));
    //         print('done');
    //         print(postList.length.toString());
    //   }
    // });


//    final jsonn = data.then((value) {
// print('start');
//      var result = value!.value;
//      result.forEach((e){
//        print(e);
//        postList.add(PostResponse.fromJson(e));
//      });
    // List<dynamic> resultList = value!.value;
    // print(resultList.length);
    // for(var i = 0; i < resultList.length; i++) {
    //   Map<String, dynamic> map = Map.from(resultList[i]);
    //   postList.add(PostResponse.fromJson(map));
    // }
    // return postList;

    // final obj= value!.value as List<PostResponse>;
    //  // print(obj[0].lastResponse);
    //   print(value.value);
    //   print('test');
    //   print(value.value);
    //   json.encode(value);
    // });
  }
}

class PostResponse {
  bool? archived;
  String? author;
  String? body;
  String? firebaseId;
  bool? flagged;
  int? lastResponse;
  String? respondentId;
  String? title;
  bool? featured;
  String? uid;

  PostResponse(
      {this.uid,
      this.archived,
      this.author,
      this.title,
      this.body,
      this.firebaseId,
      this.flagged,
      this.lastResponse,
      this.respondentId,
      this.featured});

  PostResponse.fromJson(Map<String, dynamic> json) {
    author = json['author'];
    body = json['body'];
    firebaseId = json['firebaseId'];
    flagged = json['flagged'];
    lastResponse = json['lastResponse'];
    respondentId = json['respondentId'];
    title = json['title'];
    archived = json['archived'];
    uid = json['uid'];
    featured = json['featured'];
  }

  PostResponse.fromMap(Map<String, dynamic> json) {
    author = json['author'];
    body = json['body'];
    firebaseId = json['firebaseId'];
    flagged = json['flagged'];
    lastResponse = json['lastResponse'];
    respondentId = json['respondentId'];
    title = json['title'];
    archived = json['archived'];
    uid = json['uid'];
    featured = json['featured'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();

    return data;
  }
}
