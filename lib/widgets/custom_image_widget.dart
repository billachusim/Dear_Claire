import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class CustomImageWidget extends StatelessWidget {
  final String imageUrl;

  const CustomImageWidget({
    Key? key, required this.imageUrl,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {

    return CachedNetworkImage(
        imageUrl: imageUrl,
        imageBuilder: (context, imageProvider) => Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(25),
            image: DecorationImage(
              image: imageProvider,
              //fit: BoxFit.fill,
            ),
          ),
        ),
        placeholder: (context, url) =>
            Center(child: CircularProgressIndicator()),
        errorWidget: (context, url, error) => Image.asset(
          "assets/images/brown_boy_mask.png",
          width: 48,
          height: 48,
        ) //Icon(Icons.error),
    );
  }

}