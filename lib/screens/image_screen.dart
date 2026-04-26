import 'package:flutter/material.dart';

class ImageScreen extends StatelessWidget {
  const ImageScreen({super.key, required this.imagePath});

  final String imagePath;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      extendBodyBehindAppBar: true,
      body: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            InteractiveViewer(
              panEnabled: true,
              minScale: 0.5,
              maxScale: 4.0,
              child: Hero(
                tag: imagePath,
                child: imagePath.startsWith('http')
                    ? Image.network(imagePath, fit: BoxFit.contain)
                    : Image.asset(imagePath, fit: BoxFit.contain),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                imagePath,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontSize: 10),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: const Text(
                'Unless otherwise stated, all images used in this application are sourced from Wikimedia Commons and are used under their respective Creative Commons or Public Domain licenses. For specific author information and license details for any individual image, please visit the original source on the Wikimedia Commons repository',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontSize: 10),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
