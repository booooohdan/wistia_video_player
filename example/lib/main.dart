import 'package:flutter/material.dart';
import 'package:wistia_video_player/wistia_video_player.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Wistia Video Player Example',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const VideoPlayerPage(videoId: 'e4a27b971d'),
    );
  }
}

class VideoPlayerPage extends StatefulWidget {
  final String videoId;

  const VideoPlayerPage({Key? key, required this.videoId}) : super(key: key);

  @override
  State<VideoPlayerPage> createState() => _VideoPlayerPageState();
}

class _VideoPlayerPageState extends State<VideoPlayerPage> {
  late WistiaPlayerController wistiaController;

  @override
  void initState() {
    super.initState();
    wistiaController = WistiaPlayerController(videoId: widget.videoId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      body: WistiaPlayer(controller: wistiaController),
    );
  }

  @override
  void dispose() {
    wistiaController.dispose();
    super.dispose();
  }
}
