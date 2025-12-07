import 'package:clairediary/ui/create_session/session_model.dart';

class SessionCategorizer {
  // A map to associate keywords with their categories.
  // This makes the logic much easier to manage and extend.
  static final Map<String, List<String>> _keywordCategoryMap = {
    // Love & Relationship
    'love': ['love and relationship', 'sex and dating', 'boyfriend and girlfriend', 'birthdays and anniversary'],
    'relationship': ['love and relationship', 'sex and dating', 'boyfriend and girlfriend', 'birthdays and anniversary'],
    'boyfriend': ['love and relationship', 'sex and dating', 'birthdays and anniversary', 'boyfriend and girlfriend'],
    'girlfriend': ['love and relationship', 'sex and dating', 'birthdays and anniversary', 'boyfriend and girlfriend'],
    'bf': ['love and relationship', 'sex and dating', 'birthdays and anniversary', 'boyfriend and girlfriend'],
    'gf': ['love and relationship', 'sex and dating', 'birthdays and anniversary', 'boyfriend and girlfriend'],
    'dating': ['sex and dating', 'love and relationship', 'boyfriend and girlfriend'],
    'sex': ['sex and dating', 'love and relationship', 'boyfriend and girlfriend'],

    // Marriage & Family
    'marriage': ['marriage and family', 'husband and wife', 'birthdays and anniversary'],
    'family': ['marriage and family', 'husband and wife', 'birthdays and anniversary'],
    'husband': ['husband and wife', 'marriage and family', 'life and living', 'birthdays and anniversary'],
    'wife': ['husband and wife', 'marriage and family', 'life and living', 'birthdays and anniversary'],
    'married': ['husband and wife', 'marriage and family', 'life and living', 'birthdays and anniversary'],
    'inlaw': ['husband and wife', 'marriage and family', 'life and living', 'birthdays and anniversary'],
    'parents': ['parents and children', 'marriage and family', 'husband and wife', 'childhood and memory'],
    'children': ['parents and children', 'marriage and family', 'husband and wife', 'childhood and memory'],
    'father': ['parents and children', 'marriage and family', 'husband and wife', 'childhood and memory'],
    'mother': ['parents and children', 'marriage and family', 'husband and wife', 'childhood and memory'],
    'dad': ['parents and children', 'marriage and family', 'husband and wife', 'childhood and memory'],
    'mom': ['parents and children', 'marriage and family', 'husband and wife', 'childhood and memory'],
    'stepmom': ['parents and children', 'marriage and family', 'husband and wife', 'childhood and memory'],
    'stepdad': ['parents and children', 'marriage and family', 'husband and wife', 'childhood and memory'],
    'brother': ['brothers and sisters', 'marriage and family', 'husband and wife'],
    'sister': ['brothers and sisters', 'marriage and family', 'husband and wife'],
    'my bro': ['brothers and sisters', 'marriage and family', 'husband and wife'],
    'my sis': ['brothers and sisters', 'marriage and family', 'husband and wife'],

    // Work & Career
    'school': ['school and education', 'work and career'],
    'education': ['school and education', 'work and career'],
    'work': ['work and career', 'business and entrepreneur'],
    'career': ['work and career', 'business and entrepreneur'],
    'office': ['work and career', 'business and entrepreneur'],
    'job': ['work and career', 'business and entrepreneur'],
    'boss': ['work and career', 'business and entrepreneur'],
    'madam': ['work and career', 'business and entrepreneur'],

    // Business & Entrepreneurship
    'business': ['business and entrepreneur', 'work and career', 'school and education'],
    'entrepreneur': ['business and entrepreneur', 'work and career', 'school and education'],
    'startup': ['business and entrepreneur', 'work and career', 'school and education'],
    'sales': ['business and entrepreneur', 'work and career', 'school and education'],

    // Negative Emotions
    'hate': ['hate and abuse', 'depression and anxiety', 'sad and depressed'],
    'abuse': ['hate and abuse', 'depression and anxiety', 'sad and depressed'],
    'pain': ['hate and abuse', 'depression and anxiety', 'sad and depressed'],
    'trauma': ['hate and abuse', 'depression and anxiety', 'sad and depressed'],
    'slap': ['hate and abuse', 'depression and anxiety', 'sad and depressed'],
    'punch': ['hate and abuse', 'depression and anxiety', 'sad and depressed'],
    'depression': ['depression and anxiety', 'sad and depressed', 'single and lonely'],
    'anxiety': ['depression and anxiety', 'sad and depressed', 'single and lonely'],
    'sad': ['sad and depressed', 'single and lonely', 'life and living'],
    'depressed': ['sad and depressed', 'single and lonely', 'life and living'],
    'suicide': ['sad and depressed', 'single and lonely', 'life and living'],
    'die': ['sad and depressed', 'single and lonely', 'life and living'],

    // Positive Emotions & Life
    'friends': ['friends and fun', 'life and living'],
    'fun': ['friends and fun', 'life and living'],
    'happy': ['happy and blessed', 'life and living', 'love and relationship', 'marriage and family'],
    'blessed': ['happy and blessed', 'life and living', 'love and relationship', 'marriage and family'],
    'excited': ['happy and blessed', 'life and living', 'love and relationship', 'marriage and family'],
    'grateful': ['happy and blessed', 'life and living', 'love and relationship', 'marriage and family'],
    'joyful': ['happy and blessed', 'life and living', 'love and relationship', 'marriage and family'],
    'dance': ['happy and blessed', 'life and living', 'love and relationship', 'marriage and family'],
    'dancing': ['happy and blessed', 'life and living', 'love and relationship', 'marriage and family'],
    'beach': ['happy and blessed', 'life and living', 'love and relationship', 'marriage and family'],
    'life': ['life and living', 'happy and blessed', 'childhood and memory', 'work and career'],
    'living': ['life and living', 'happy and blessed', 'childhood and memory', 'work and career'],
    'house': ['life and living', 'happy and blessed', 'childhood and memory', 'work and career'],
    'bedroom': ['life and living', 'happy and blessed', 'childhood and memory', 'work and career'],

    // Single & Lonely
    'single': ['single and lonely', 'sad and depressed', 'love and relationship'],
    'lonely': ['single and lonely', 'sad and depressed', 'love and relationship'],
    'alone': ['single and lonely', 'sad and depressed', 'love and relationship'],
    'mingle': ['single and lonely', 'sad and depressed', 'love and relationship'],

    // Health & Misc
    'help': ['help and charity', 'life and living'],
    'charity': ['help and charity', 'life and living'],
    'sick': ['health and fitness', 'life and living', 'food and drink'],
    'health': ['health and fitness', 'life and living', 'food and drink'],
    'fitness': ['health and fitness', 'life and living', 'food and drink'],
    'food': ['food and drink', 'health and fitness', 'friends and fun'],
    'drink': ['food and drink', 'health and fitness', 'friends and fun'],

    // Events & Memories
    'birthday': ['birthdays and anniversary', 'love and relationship', 'marriage and family', 'friends and fun'],
    'anniversary': ['birthdays and anniversary', 'love and relationship', 'marriage and family', 'friends and fun'],
    'childhood': ['childhood and memory', 'life and living', 'marriage and family', 'parents and children'],
    'memory': ['childhood and memory', 'life and living', 'marriage and family', 'parents and children'],
    'old': ['childhood and memory', 'life and living', 'marriage and family', 'parents and children'],

    // Spirituality
    'pray': ['prayer and thanksgiving', 'life and living'],
    'God': ['prayer and thanksgiving', 'life and living'],
    'church': ['prayer and thanksgiving', 'life and living'],
    'prayer': ['prayer and thanksgiving', 'life and living'],
    'praises': ['prayer and thanksgiving', 'life and living'],

    // Arts & Entertainment
    'art': ['arts and photography', 'work and career', 'business and entrepreneur'],
    'photography': ['arts and photography', 'work and career', 'business and entrepreneur'],
    'studio': ['arts and photography', 'work and career', 'business and entrepreneur'],
    'camera': ['arts and photography', 'work and career', 'business and entrepreneur'],
    'music': ['music and videos', 'arts and photography', 'work and career', 'comedy and entertainment'],
    'video': ['music and videos', 'arts and photography', 'work and career', 'comedy and entertainment'],
    'riddles': ['riddles and jokes', 'friends and fun', 'comedy and entertainment'],
    'joke': ['riddles and jokes', 'friends and fun', 'comedy and entertainment'],
    'comedy': ['comedy and entertainment', 'music and videos', 'riddles and jokes'],
    'entertainment': ['comedy and entertainment', 'music and videos', 'riddles and jokes'],
    'laugh': ['riddles and jokes', 'friends and fun', 'comedy and entertainment'],
    'television': ['television and movies', 'music and videos', 'arts and photography', 'comedy and entertainment'],
    'movie': ['television and movies', 'music and videos', 'arts and photography', 'comedy and entertainment'],
    'cinema': ['television and movies', 'music and videos', 'arts and photography', 'comedy and entertainment'],
    'puzzle': ['puzzles and games', 'riddles and jokes', 'comedy and entertainment'],
    'games': ['puzzles and games', 'riddles and jokes', 'comedy and entertainment'],
  };

  /// Takes a session object and its text, assigns categories to the object,
  /// and returns a list of all unique categories found.
  static List<String> assignCategories(CreateSessionModel sessionObject, String sessionText) {
    final lowerCaseText = sessionText.toLowerCase();

  // A set to avoid duplicate categories.
  final Set<String> foundCategories = {};

  _keywordCategoryMap.forEach((keyword, categories) {
    if (lowerCaseText.contains(keyword)) {
      foundCategories.addAll(categories);
    }
  });

  // Convert the set to a list to assign to the model.
  final List<String> finalList = foundCategories.toList();

  // Assign to the model fields for storage in the main session document.
  if (finalList.isNotEmpty) sessionObject.category1 = finalList[0];
  if (finalList.length > 1) sessionObject.category2 = finalList[1];
  if (finalList.length > 2) sessionObject.category3 = finalList[2];
  if (finalList.length > 3) sessionObject.category4 = finalList[3];

  // Return the complete list so it can be used for other purposes (like sorting).
  return finalList;
  }

}
