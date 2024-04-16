import 'package:fluent_ui/fluent_ui.dart';
import 'package:parc_oto/theme.dart';
import 'package:video_player/video_player.dart';

class PaOVideoPlayer extends StatefulWidget {
  final String link;
  const PaOVideoPlayer({super.key, required this.link});

  @override
  State<PaOVideoPlayer> createState() => _PaOVideoPlayerState();
}

class _PaOVideoPlayerState extends State<PaOVideoPlayer> {
  late VideoPlayerController _controller;
  late Future<void> _initializeVideoPlayerFuture;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.link));
    _initializeVideoPlayerFuture = _controller.initialize();
  }

  bool currentlyWaiting = false;
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: FutureBuilder(
            future: _initializeVideoPlayerFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.done) {
                // If the VideoPlayerController has finished initialization, use
                // the data it provides to limit the aspect ratio of the video.
                return AspectRatio(
                  aspectRatio: _controller.value.aspectRatio,
                  // Use the VideoPlayer widget to display the video.
                  child: GestureDetector(
                    onTap: () {
                      if (_controller.value.isPlaying) {
                        _controller.pause();
                      } else {
                        _controller.play();
                        setCurretlyWaiting();
                      }
                      setState(() {});
                    },
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Positioned.fill(child: VideoPlayer(_controller)),
                        if (!_controller.value.isPlaying)
                          Positioned(
                              child: FilledButton(
                            child: const Icon(FluentIcons.play),
                            onPressed: () {
                              _controller.play();
                              setCurretlyWaiting();
                            },
                          )),
                        if (_controller.value.isPlaying && currentlyWaiting)
                          Positioned(
                              child: Button(
                            child: const Icon(FluentIcons.pause),
                            onPressed: () {
                              _controller.pause();
                            },
                          )),
                      ],
                    ),
                  ),
                );
              } else {
                // If the VideoPlayerController is still initializing, show a
                // loading spinner.
                return const Center(
                  child: ProgressRing(),
                );
              }
            },
          ),
        ),
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          height: 30,
          child: Row(
            children: [
              if (!_controller.value.isPlaying)
                FilledButton(
                    onPressed: () {
                      _controller.play();
                      setState(() {});
                    },
                    child: const Icon(FluentIcons.play)),
              if (_controller.value.isPlaying)
                Button(
                    onPressed: () {
                      _controller.pause();
                      setState(() {});
                    },
                    child: const Icon(FluentIcons.pause)),
              smallSpace,
              Flexible(
                child: VideoProgressIndicator(
                  _controller,
                  allowScrubbing: true,
                  colors: VideoProgressColors(
                      backgroundColor: Colors.red,
                      bufferedColor: Colors.black,
                      playedColor: Colors.blue),
                ),
              ),
            ],
          ),
        )
      ],
    );
  }

  void setCurretlyWaiting() {
    setState(() {
      currentlyWaiting = true;
    });
    Future.delayed(const Duration(seconds: 3)).then((value) => {
          setState(() {
            currentlyWaiting = false;
          })
        });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
