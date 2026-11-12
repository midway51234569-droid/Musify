import 'dart:ui';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:material/material.dart';
import 'package:musify/constants/app.constants.dart';
import 'package:musify/extensions/l10n.dart';
import 'package:musify/main.dart';
import 'package:musify/services/settings_manager.dart';
import 'package:musify/utilities/flutter_bottom_sheet.dart';
import 'package:musify/widgets/mini_player.dart';

class BottomNavigationPage extends StatefulWidget {
  const BottomNavigationPage({required this.child, super.key});
  final StatefulNavigationShell child;
  @override
  State<BottomNavigationPage> createState() => _BottomNavigationPageState();
}

class _BottomNavigationPageState extends State<BottomNavigationPage> {
  late final _miniPlayerVisibilityStream = audioHandler.mediaItem
      .map((mediaItem) => mediaItem != null)
      .distinct();

  bool? _previousOfflineMode;
  int? _previousShellIndex;

  void _onTap(int index, bool isOfflineMode) {
    if (index == widget.child.currentIndex) {
      if (index == 0) {
        homeKey.currentState?.scrollToTop();
      } else if (index == (isOfflineMode ? 1 : 2)) {
        libraryKey.currentState?.scrollToTop();
      } else if (index == 1 && !isOfflineMode) {
        searchKey.currentState?.scrollToTop();
      }
      return;
    }
    _previousShellIndex = index;
    widget.child.goBranch(index, initialLocation: index == widget.child.currentIndex);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: widget.child.currentIndex == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        if (widget.child.currentIndex != 0) {
          widget.child.goBranch(0);
        } else {
          SystemNavigator.pop();
        }
      },
      child: ValueListenableBuilder<bool>(
        valueListenable: offlineMode,
        builder: (context, isOfflineMode, _) {
          if (_previousOfflineMode != null && _previousOfflineMode != isOfflineMode) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (isOfflineMode && widget.child.currentIndex == 1) {
                widget.child.goBranch(0);
              } else if (!isOfflineMode && widget.child.currentIndex == 0) {
                widget.child.goBranch(1);
              }
            });
          }
          _previousOfflineMode = isOfflineMode;
          return Scaffold(
            body: widget.child,
            // --- NEW MORDAN FAB ---
            floatingActionButton: Container(
              height: 64,
              width: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [Color(0xFF8A2BE2), Color(0xFFDA70D6)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF8A2BE2).withOpacity(0.45),
                    blurRadius: 22,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: () {
                    if (audioHandler.playbackState.value.playing) {
                      audioHandler.pause();
                    } else {
                      audioHandler.play();
                    }
                  },
                  child: const Icon(
                    Icons.play_arrow_rounded,
                    color: Colors.white,
                    size: 36,
                  ),
                ),
              ),
            ),
            floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
            bottomNavigationBar: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                StreamBuilder<bool>(
                  stream: _miniPlayerVisibilityStream,
                  builder: (context, snapshot) {
                    final isVisible = snapshot.data ?? false;
                    if (!isVisible) return const SizedBox.shrink();
                    return const MiniPlayer();
                  },
                ),
                _MordanGlassBar(
                  currentIndex: widget.child.currentIndex,
                  isOffline: isOfflineMode,
                  onTap: (index) => _onTap(index, isOfflineMode),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _MordanGlassBar extends StatelessWidget {
  final int currentIndex;
  final bool isOffline;
  final Function(int) onTap;
  const _MordanGlassBar({required this.currentIndex, required this.isOffline, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final items = isOffline
        ? const [
            (FluentIcons.home_24_filled, FluentIcons.home_24_regular, 'Home'),
            (FluentIcons.library_24_filled, FluentIcons.library_24_regular, 'Library'),
            (FluentIcons.settings_24_filled, FluentIcons.settings_24_regular, 'Settings'),
          ]
        : const [
            (FluentIcons.home_24_filled, FluentIcons.home_24_regular, 'Home'),
            (FluentIcons.search_24_filled, FluentIcons.search_24_regular, 'Search'),
            (FluentIcons.library_24_filled, FluentIcons.library_24_regular, 'Library'),
            (FluentIcons.settings_24_filled, FluentIcons.settings_24_regular, 'Settings'),
          ];

    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
        child: Container(
          height: 78,
          decoration: BoxDecoration(
            color: isDark ? Colors.black.withOpacity(0.65) : Colors.white.withOpacity(0.85),
            border: Border(
              top: BorderSide(
                color: isDark ? Colors.white10 : Colors.black12,
                width: 0.5,
              ),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              if (!isOffline) ...[
                _buildItem(0, items[0]),
                _buildItem(1, items[1]),
                const SizedBox(width: 64), // FAB GAP
                _buildItem(2, items[2]),
                _buildItem(3, items[3]),
              ] else ...[
                _buildItem(0, items[0]),
                const SizedBox(width: 64), // FAB GAP
                _buildItem(1, items[1]),
                _buildItem(2, items[2]),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildItem(int index, dynamic item) {
    final isSelected = currentIndex == index;
    return InkWell(
      onTap: () => onTap(index),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isSelected ? item.$1 : item.$2,
            color: isSelected ? const Color(0xFF8A2BE2) : Colors.grey,
            size: 26,
          ),
          const SizedBox(height: 4),
          Text(
            item.$3,
            style: TextStyle(
              fontSize: 10,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
              color: isSelected ? const Color(0xFF8A2BE2) : Colors.grey,
            ),
          ),
          if (isSelected)
            Container(
              margin: const EdgeInsets.only(top: 4),
              height: 3,
              width: 16,
              decoration: BoxDecoration(
                color: const Color(0xFF8A2BE2),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
        ],
      ),
    );
  }
}
