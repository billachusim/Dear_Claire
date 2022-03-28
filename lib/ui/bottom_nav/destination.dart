import 'package:flutter/material.dart';

class Destination {
  const Destination(
      this.title, this.icon, this.activeIcon, this.color, this.index);
  final String title;
  final String icon;
  final String activeIcon;
  final Color color;
  final int index;
}

const List<Destination> allDestinations = <Destination>[
  Destination('Featured', "assets/images/new_feature.svg",
      "assets/images/new_featured_select.svg", Color(0xFF131418), 0),
  Destination('Followed', "assets/images/ic_follow.svg",
      "assets/images/ic_followed_select.svg", Color(0xFF131418), 1),
  Destination('Dairy', "assets/images/ic_dairy.svg",
      "assets/images/ic_diary_selected.svg", Color(0xFF131418), 2),
  Destination('Chatrooms', "assets/images/ic_chat_rooms.svg",
      "assets/images/ic_rooms_select.svg", Color(0xFF131418), 3),
  Destination('Ego', "assets/images/ic_ego.svg",
      "assets/images/new_ego_select.svg", Color(0xFF131418), 4),
];
