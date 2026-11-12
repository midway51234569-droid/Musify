import 'dart:ui';
import 'package:fluentui_system_icons/fluentui_system_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:material/material.dart';
import 'package:musify/constants/app_constants.dart';
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

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: widget.child.currentIndex == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        final currentIndex = widget.child.currentIndex;
        if (currentIndex != 0) {
          widget.child.goBranch(0);
        } else {
          SystemNavigator.pop();
        }
      },
      child: ValueListenableBuilder<bool>(
        valueListenable: offlineMode,
        builder: (context, isOfflineMode, _) {
          final previousOfflineMode = _previousOfflineMode;
          _previousOfflineMode = isOfflineMode;
          if (previousOfflineMode != null && previousOfflineMode != isOfflineMode) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (isOfflineMode && widget.child.currentIndex == 1) {
                widget.child.goBranch(0);
              } else if (!isOfflineMode && widget.child.currentIndex == 0) {
                widget.child.goBranch(1);
              }
            });
          }

          return Scaffold(
            body: widget.child,
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

  void _onTap(int index, bool isOffline) {
    final previousIndex = _previousShellIndex;
    _previousShellIndex = widget.child.currentIndex;

    if (widget.child.currentIndex == index && previousIndex == index) {
      if (index == 0) {
        if (isOffline) {
          homeOfflineKey.currentState?.scrollToTop();
        } else {
          homeKey.currentState?.scrollToTop();
        }
      } else if (index == 1 && !isOffline) {
        searchKey.currentState?.scrollToTop();
      } else if (index == (isOffline ? 1 : 2)) {
        libraryKey.currentState?.scrollToTop();
      }
      return;
    }
    _previousShellIndex = index;
    widget.child.goBranch(index, initialLocation: index == widget.child.currentIndex);
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
    
    // Online: Home, Search, Library, Settings - Offline: Home, Library, Settings
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

    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 22),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            height: 72,
            decoration: BoxDecoration(
              color: isDark ? Colors.black.withOpacity(0.72) : Colors.white.withOpacity(0.82),
              borderRadius: BorderRadius.circular(32),
              border: Border.all(
                color: isDark ? Colors.white.withOpacity(0.10) : Colors.black.withOpacity(0.08),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.4 : 0.15),
                  blurRadius: 25,
                  offset: Offset(0, 10),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(items.length, (i) {
                final isActive = currentIndex == i;
                return GestureDetector(
                  onTap: () => onTap(i),
                  behavior: HitTestBehavior.opaque,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 350),
                    curve: Curves.easeOutBack,
                    padding: EdgeInsets.symmetric(
                      horizontal: isActive ? 22 : 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: isActive ? const Color(0xFF9C4DFF) : Colors.transparent,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: isActive
                          ? [
                              BoxShadow(
                                color: const Color(0xFF9C4DFF).withOpacity(0.45),
                                blurRadius: 18,
                                offset: Offset(0, 6),
                              )
                            ]
                          : [],
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isActive ? items[i].$1 : items[i].$2,
                          size: isActive ? 24 : 22,
                          color: isActive ? Colors.white : (isDark ? Colors.white70 : Colors.black54),
                        ),
                        if (isActive) ...[
                          const SizedBox(width: 8),
                          Text(
                            items[i].$3,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 13.5,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}
