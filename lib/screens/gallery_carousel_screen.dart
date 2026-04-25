import 'package:flutter/material.dart';
import 'image_screen.dart';

class GalleryCarouselScreen extends StatelessWidget {
  final List<String> galleryImages;

  const GalleryCarouselScreen({super.key, required this.galleryImages});

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(),
      body: Directionality(
        textDirection: TextDirection.ltr,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height,
          ),
          child: CarouselView(
            scrollDirection: Axis.vertical,
            itemExtent: double.infinity,
            padding: const EdgeInsets.all(10.0),
            onTap: (int index) {
              final image = galleryImages[index];
              Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (context) =>
                      ImageScreen(imagePath: image),
                ),
              );
            },
            children: List.generate(galleryImages.length, (index) {
              final image = galleryImages[index];
              final isNetwork = image.startsWith('http');
              return InkWell(
                child: Ink.image(
                  fit: BoxFit.cover,
                  image: isNetwork
                      ? NetworkImage(image) as ImageProvider
                      : AssetImage(image),
                  ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
