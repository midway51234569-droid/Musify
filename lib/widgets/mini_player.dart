import 'dart:math' as math;
import 'dart:ui';
import 'package:audio_service/audio_service.dart';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:material/material.dart' as material;
import 'package:material_ui/material_ui.dart';
import 'package:musify/main.dart';
import 'package:musify/models/full_player_state.dart';
import 'package:musify/models/position_data.dart';
import 'package:musify/screens/now_playing_page.dart';
import 'package:musify/widgets/marquee.dart';
import 'package:musify/widgets/song_artwork.dart';
import 'package:rxdart/rxdart.dart';

final Stream<FullPlayerState> _fullPlayerStateStream =
    Rx.combineLatest3(
      audioHandler.playbackStateStream,
      audioHandler.queue.distinct(),
      audioHandler.positionDataStream,
      (PlaybackState state, List<MediaItem> queue, PositionData pos) =>
          FullPlayerState(
        playbackState: state,
        queue: queue,
        position: pos,
      ),
    ).throttleTime(const Duration(milliseconds: 120), trailing: true).asBroadcastStream();

class MiniPlayer extends StatelessWidget {
  const MiniPlayer({super.key});
  static const double playerHeight = 72;
  static const double _borderRadius = 20;
  static const double _artworkSize = 52;
  static const double _artworkRadius = 14;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return AnimatedSize(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      child: StreamBuilder<MediaItem?>(
        stream: audioHandler.mediaItem,
        builder: (context, mediaSnapshot) {
          final metadata = mediaSnapshot.data;
          if (metadata == null) return const SizedBox.shrink();
          return StreamBuilder<FullPlayerState>(
            stream: _fullPlayerStateStream,
            builder: (context, stateSnapshot) {
              final state = stateSnapshot.data;
              if (state == null) return const SizedBox.shrink();
              return _MordanMiniPlayerContent(
                metadata: metadata,
                state: state,
                colorScheme: colorScheme,
              );
            },
          );
        },
      ),
    );
  }
}

class _MordanMiniPlayerContent extends StatelessWidget {
  final MediaItem metadata;
  final FullPlayerState state;
  final ColorScheme colorScheme;
  const _MordanMiniPlayerContent({required this.metadata, required this.state, required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isPlaying = state.playbackState.playing;

    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 0, 18, 10),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(MiniPlayer._borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: GestureDetector(
            onTap: () => showCupertinoSheet(context: context, builder: (ctx) => const NowPlayingPage()),
            child: Container(
              height: MiniPlayer.playerHeight,
              decoration: BoxDecoration(
                color: isDark ? Colors.black.withOpacity(0.70) : Colors.white.withOpacity(0.85),
                borderRadius: BorderRadius.circular(MiniPlayer._borderRadius),
                border: Border.all(color: isDark ? Colors.white.withOpacity(0.10) : Colors.black.withOpacity(0.07), width: 1),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(isDark ? 0.35 : 0.12), blurRadius: 20, offset: Offset(0, 8))],
              ),
              child: Stack(
                children: [
                  // Progress line at bottom - MORDAN STYLE
                  Positioned(
                    bottom: 0, left: 0, right: 0,
                    child: ClipRRect(
                      borderRadius: BorderRadius.only(bottomLeft: Radius.circular(20), bottomRight: Radius.circular(20)),
                      child: LinearProgressIndicator(
                        value: state.positionData.duration.inMilliseconds == 0 ? 0 : state.positionData.position.inMilliseconds / state.positionData.duration.inMilliseconds,
                        minHeight: 2.5,
                        backgroundColor: Colors.transparent,
                        valueColor: AlwaysStoppedAnimation(Color(0xFF9C4DFF)),
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    child: Row(
                      children: [
                        // Artwork with glow
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(MiniPlayer._artworkRadius),
                            boxShadow: [BoxShadow(color: Color(0xFF9C4DFF).withOpacity(0.25), blurRadius: 12, offset: Offset(0, 4))],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(MiniPlayer._artworkRadius),
                            child: SongArtwork(size: MiniPlayer._artworkSize, metadata: metadata),
                          ),
                        ),
                        SizedBox(width: 12),
                        // Title
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Marquee(
                                child: Text(metadata.title, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, letterSpacing: 0.2), maxLines: 1, overflow: TextOverflow.ellipsis),
                              ),
                              SizedBox(height: 2),
                              Text(metadata.artist ?? '', style: TextStyle(fontSize: 12.5, color: isDark ? Colors.white60 : Colors.black54, fontWeight: FontWeight.w500), maxLines: 1, overflow: TextOverflow.ellipsis),
                            ],
                          ),
                        ),
                        // Play Pause MORDAN Button
                        _MordanPlayButton(isPlaying: isPlaying),
                        SizedBox(width: 4),
                        IconButton(
                          icon: Icon(FluentIcons.skip_forward_24_filled, size: 24),
                          onPressed: audioHandler.skipToNext,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MordanPlayButton extends StatelessWidget {
  final bool isPlaying;
  const _MordanPlayButton({required this.isPlaying});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => isPlaying ? audioHandler.pause() : audioHandler.play(),
      child: Container(
        width: 42, height: 42,
        decoration: BoxDecoration(
          color: Color(0xFF9C4DFF),
          shape: BoxShape.circle,
          boxShadow: [BoxShadow(color: Color(0xFF9C4DFF).withOpacity(0.45), blurRadius: 14, offset: Offset(0, 5))],
        ),
        child: Icon(isPlaying ? FluentIcons.pause_24_filled : FluentIcons.play_24_filled, color: Colors.white, size: 20),
      ),
    );
  }
}
