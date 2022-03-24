extension TextFormatter on String{
  String get inCaps => '${this[0].toUpperCase()}${this.substring(1)}';
  String capitalize(String s) => s[0].toUpperCase() + s.substring(1);
  String get allInCaps => this.toUpperCase();
  String toLowerCase(String s) => s[0].toLowerCase() + s.substring(1);
}