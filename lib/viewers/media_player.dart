import 'dart:io';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:audioplayers/audioplayers.dart';
import '../utils/file_type_utils.dart';

class MediaPlayer extends StatefulWidget {
  final String filePath;
  final String title;
  final FileTypeCategory fileType;

  const MediaPlayer({
    Key? key,
    required this.filePath,
    required this.title,
    required this.fileType,
  }) : super(key: key);

  @override
  _MediaPlayerState createState() => _MediaPlayerState();
}

class _MediaPlayerState extends State<MediaPlayer> {
  VideoPlayerController? _videoController;
  AudioPlayer? _audioPlayer;
  bool _isPlaying = false;
  bool _isLoading = true;
  bool _showControls = true;
  bool _isFullScreen = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  double _volume = 1.0;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  Future<void> _initializePlayer() async {
    try {
      final file = File(widget.filePath);
      if (!file.existsSync()) {
        setState(() {
          _isLoading = false;
        });
        return;
      }

      if (widget.fileType == FileTypeCategory.video) {
        _videoController = VideoPlayerController.file(file);
        try {
          await _videoController!.initialize();
          if (_videoController!.value.isInitialized) {
            // Add listener for video player state changes
            _videoController!.addListener(() {
              if (mounted) {
                setState(() {
                  _isPlaying = _videoController!.value.isPlaying;
                  _duration = _videoController!.value.duration;
                  _position = _videoController!.value.position;
                });
              }
            });
            setState(() {
              _isLoading = false;
              _isPlaying = _videoController!.value.isPlaying;
              _duration = _videoController!.value.duration;
              _position = _videoController!.value.position;
              _volume = _videoController!.value.volume;
            });

            // Auto-hide controls after 3 seconds
            _hideControlsAfterDelay();
          } else {
            setState(() {
              _isLoading = false;
            });
          }
        } catch (e) {
          print('Video initialization error: $e');
          setState(() {
            _isLoading = false;
          });
        }
      } else if (widget.fileType == FileTypeCategory.audio) {
        _audioPlayer = AudioPlayer();
        await _audioPlayer!.setSourceDeviceFile(widget.filePath);
        _audioPlayer!.onDurationChanged.listen((duration) {
          if (mounted) {
            setState(() {
              _duration = duration;
            });
          }
        });
        _audioPlayer!.onPositionChanged.listen((position) {
          if (mounted) {
            setState(() {
              _position = position;
            });
          }
        });
        _audioPlayer!.onPlayerComplete.listen((_) {
          if (mounted) {
            setState(() {
              _isPlaying = false;
              _position = Duration.zero;
            });
          }
        });
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error initializing media player: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _togglePlayPause() {
    if (widget.fileType == FileTypeCategory.video) {
      if (_videoController!.value.isPlaying) {
        _videoController!.pause();
      } else {
        _videoController!.play();
      }
      setState(() {
        _isPlaying = _videoController!.value.isPlaying;
        _showControls = true;
      });
      _hideControlsAfterDelay();
    } else if (widget.fileType == FileTypeCategory.audio) {
      if (_isPlaying) {
        _audioPlayer!.pause();
      } else {
        _audioPlayer!.resume();
      }
      setState(() {
        _isPlaying = !_isPlaying;
      });
    }
  }

  void _seekTo(Duration position) {
    if (widget.fileType == FileTypeCategory.video && _videoController != null) {
      _videoController!.seekTo(position);
    }
  }

  void _setVolume(double volume) {
    if (widget.fileType == FileTypeCategory.video && _videoController != null) {
      _videoController!.setVolume(volume);
      setState(() {
        _volume = volume;
      });
    }
  }

  void _toggleFullScreen() {
    setState(() {
      _isFullScreen = !_isFullScreen;
    });
  }

  void _toggleControls() {
    setState(() {
      _showControls = !_showControls;
    });
    if (_showControls) {
      _hideControlsAfterDelay();
    }
  }

  void _hideControlsAfterDelay() {
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted && _isPlaying && widget.fileType == FileTypeCategory.video) {
        setState(() {
          _showControls = false;
        });
      }
    });
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '${twoDigits(hours)}:${twoDigits(minutes)}:${twoDigits(seconds)}';
    }
    return '${twoDigits(minutes)}:${twoDigits(seconds)}';
  }

  @override
  void dispose() {
    _videoController?.dispose();
    _audioPlayer?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final file = File(widget.filePath);

    if (!file.existsSync()) {
      return Scaffold(
        appBar: AppBar(
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
              ),
            ),
          ),
          title: const Text('Media Player'),
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: const Center(child: Text('File not found')),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
            ),
          ),
        ),
        title: Text(widget.title, style: const TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
          : widget.fileType == FileTypeCategory.video
          ? _buildVideoPlayer()
          : _buildAudioPlayer(),
    );
  }

  Widget _buildVideoPlayer() {
    if (_videoController == null || !_videoController!.value.isInitialized) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            const Text(
              'Error initializing video player',
              style: TextStyle(color: Colors.white),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Please try opening with an external video player',
              style: TextStyle(color: Colors.white70, fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return GestureDetector(
      onTap: _toggleControls,
      child: Stack(
        children: [
          Center(
            child: AspectRatio(
              aspectRatio: _videoController!.value.aspectRatio,
              child: VideoPlayer(_videoController!),
            ),
          ),
          if (_showControls)
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.7),
                    Colors.transparent,
                    Colors.transparent,
                    Colors.black.withOpacity(0.7),
                  ],
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Top controls
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.arrow_back_rounded,
                            color: Colors.white,
                          ),
                          onPressed: () => Navigator.pop(context),
                        ),
                        Row(
                          children: [
                            IconButton(
                              icon: Icon(
                                _volume > 0
                                    ? Icons.volume_up_rounded
                                    : Icons.volume_off_rounded,
                                color: Colors.white,
                              ),
                              onPressed: () {
                                _setVolume(_volume > 0 ? 0.0 : 1.0);
                              },
                            ),
                            SizedBox(
                              width: 100,
                              child: Slider(
                                value: _volume,
                                min: 0.0,
                                max: 1.0,
                                activeColor: Colors.white,
                                inactiveColor: Colors.white.withOpacity(0.3),
                                onChanged: _setVolume,
                              ),
                            ),
                            IconButton(
                              icon: Icon(
                                _isFullScreen
                                    ? Icons.fullscreen_exit_rounded
                                    : Icons.fullscreen_rounded,
                                color: Colors.white,
                              ),
                              onPressed: _toggleFullScreen,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Center play button
                  if (!_isPlaying)
                    Center(
                      child: GestureDetector(
                        onTap: _togglePlayPause,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.6),
                            shape: BoxShape.circle,
                          ),
                          padding: const EdgeInsets.all(24),
                          child: const Icon(
                            Icons.play_arrow_rounded,
                            color: Colors.white,
                            size: 64,
                          ),
                        ),
                      ),
                    ),

                  // Bottom controls
                  Container(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        // Progress bar
                        Row(
                          children: [
                            Text(
                              _formatDuration(_position),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                            ),
                            Expanded(
                              child: Slider(
                                value: _position.inMilliseconds.toDouble(),
                                min: 0.0,
                                max: _duration.inMilliseconds > 0
                                    ? _duration.inMilliseconds.toDouble()
                                    : 1.0,
                                activeColor: Colors.white,
                                inactiveColor: Colors.white.withOpacity(0.3),
                                onChanged: (value) {
                                  _seekTo(
                                    Duration(milliseconds: value.toInt()),
                                  );
                                },
                              ),
                            ),
                            Text(
                              _formatDuration(_duration),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        // Control buttons
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            IconButton(
                              icon: const Icon(
                                Icons.replay_10_rounded,
                                color: Colors.white,
                                size: 32,
                              ),
                              onPressed: () {
                                final newPosition =
                                    _position - const Duration(seconds: 10);
                                _seekTo(
                                  newPosition < Duration.zero
                                      ? Duration.zero
                                      : newPosition,
                                );
                              },
                            ),
                            const SizedBox(width: 20),
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                              child: IconButton(
                                icon: Icon(
                                  _isPlaying
                                      ? Icons.pause_rounded
                                      : Icons.play_arrow_rounded,
                                  color: const Color(0xFF667EEA),
                                  size: 36,
                                ),
                                onPressed: _togglePlayPause,
                              ),
                            ),
                            const SizedBox(width: 20),
                            IconButton(
                              icon: const Icon(
                                Icons.forward_10_rounded,
                                color: Colors.white,
                                size: 32,
                              ),
                              onPressed: () {
                                final newPosition =
                                    _position + const Duration(seconds: 10);
                                if (newPosition <= _duration) {
                                  _seekTo(newPosition);
                                } else {
                                  _seekTo(_duration);
                                }
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAudioPlayer() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(40),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.music_note_rounded,
              size: 80,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 40),
          Text(
            widget.title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 40),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                Slider(
                  value: _duration.inSeconds > 0
                      ? _position.inSeconds.toDouble()
                      : 0.0,
                  max: _duration.inSeconds > 0
                      ? _duration.inSeconds.toDouble()
                      : 1.0,
                  onChanged: (value) {
                    _audioPlayer!.seek(Duration(seconds: value.toInt()));
                  },
                  activeColor: Colors.white,
                  inactiveColor: Colors.white.withOpacity(0.3),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _formatDuration(_position),
                      style: const TextStyle(color: Colors.white70),
                    ),
                    Text(
                      _formatDuration(_duration),
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 30),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(
                  Icons.replay_10_rounded,
                  color: Colors.white,
                  size: 32,
                ),
                onPressed: () {
                  final newPosition = _position - const Duration(seconds: 10);
                  _audioPlayer!.seek(
                    newPosition < Duration.zero ? Duration.zero : newPosition,
                  );
                },
              ),
              const SizedBox(width: 20),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: Icon(
                    _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                    color: const Color(0xFF667EEA),
                    size: 48,
                  ),
                  onPressed: _togglePlayPause,
                ),
              ),
              const SizedBox(width: 20),
              IconButton(
                icon: const Icon(
                  Icons.forward_10_rounded,
                  color: Colors.white,
                  size: 32,
                ),
                onPressed: () {
                  final newPosition = _position + const Duration(seconds: 10);
                  if (newPosition <= _duration) {
                    _audioPlayer!.seek(newPosition);
                  }
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
