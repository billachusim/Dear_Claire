import 'package:algolia/algolia.dart';

class AlgoliaApplication{
  static final Algolia algolia = Algolia.init(
    applicationId: "NPY7FTFI3M", //ApplicationID
    apiKey: "e4ae5cbbda53d14cc65875463dec05df", //search-only api key in flutter code
  );
}