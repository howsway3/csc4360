import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'dart:math';

void main() {
  runApp(const HalloweenStorybookApp());
}

class HalloweenStorybookApp extends StatelessWidget {
  const HalloweenStorybookApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Spooky Halloween Storybook',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF1a0033),
        primaryColor: const Color(0xFFff6b00),
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/home': (context) => const HomeScreen(),
        '/story': (context) => const StoryScreen(),
        '/game': (context) => const GameScreen(),
      },
    );
  }
}

// Splash Screen with animated entrance
class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );

    _controller.forward();

    Future.delayed(const Duration(seconds: 3), () {
      Navigator.pushReplacementNamed(context, '/home');
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1a0033), Color(0xFF330066), Color(0xFF1a0033)],
          ),
        ),
        child: Center(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Opacity(
                opacity: _fadeAnimation.value,
                child: Transform.scale(
                  scale: _scaleAnimation.value,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.auto_stories,
                        size: 100,
                        color: Color(0xFFff6b00),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        '🎃 Spooktacular 🎃',
                        style: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange[700],
                          shadows: [
                            Shadow(
                              color: Colors.black.withOpacity(0.5),
                              offset: const Offset(2, 2),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Halloween Storybook',
                        style: TextStyle(
                          fontSize: 24,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

// Home Screen with navigation options
class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with TickerProviderStateMixin {
  final AudioPlayer _bgMusicPlayer = AudioPlayer();
  late List<AnimationController> _floatingControllers;

  @override
  void initState() {
    super.initState();
    _floatingControllers = List.generate(
      5,
      (index) => AnimationController(
        duration: Duration(seconds: 3 + index),
        vsync: this,
      )..repeat(reverse: true),
    );
    _playBackgroundMusic();
  }

  void _playBackgroundMusic() async {
    // In production, add your Halloween background music file
    // await _bgMusicPlayer.play(AssetSource('sounds/bg_music.mp3'));
    // await _bgMusicPlayer.setReleaseMode(ReleaseMode.loop);
  }

  @override
  void dispose() {
    for (var controller in _floatingControllers) {
      controller.dispose();
    }
    _bgMusicPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0d001a), Color(0xFF1a0033), Color(0xFF2d0052)],
          ),
        ),
        child: Stack(
          children: [
            // Floating decorative elements
            ...List.generate(5, (index) {
              return AnimatedBuilder(
                animation: _floatingControllers[index],
                builder: (context, child) {
                  return Positioned(
                    left: 50.0 + (index * 60),
                    top: 100 + (_floatingControllers[index].value * 50),
                    child: Opacity(
                      opacity: 0.3,
                      child: Text(
                        ['👻', '🎃', '🦇', '🕷️', '💀'][index],
                        style: const TextStyle(fontSize: 40),
                      ),
                    ),
                  );
                },
              );
            }),
            SafeArea(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      '🎃 Welcome to the 🎃',
                      style: TextStyle(
                        fontSize: 28,
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Haunted Storybook',
                      style: TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange[700],
                        shadows: [
                          Shadow(
                            color: Colors.black.withOpacity(0.7),
                            offset: const Offset(3, 3),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 60),
                    _buildMenuButton(
                      context,
                      'Read the Story',
                      Icons.menu_book,
                      '/story',
                    ),
                    const SizedBox(height: 20),
                    _buildMenuButton(
                      context,
                      'Play the Game',
                      Icons.games,
                      '/game',
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuButton(
    BuildContext context,
    String text,
    IconData icon,
    String route,
  ) {
    return Hero(
      tag: text,
      child: ElevatedButton.icon(
        onPressed: () => Navigator.pushNamed(context, route),
        icon: Icon(icon, size: 28),
        label: Text(
          text,
          style: const TextStyle(fontSize: 22),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFff6b00),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          elevation: 8,
        ),
      ),
    );
  }
}

// Story Screen with animated pages
class StoryScreen extends StatefulWidget {
  const StoryScreen({Key? key}) : super(key: key);

  @override
  State<StoryScreen> createState() => _StoryScreenState();
}

class _StoryScreenState extends State<StoryScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<StoryPage> _storyPages = [
    StoryPage(
      text: 'Once upon a midnight dreary, in a town where shadows creep...',
      emoji: '🌙',
      backgroundColor: Color(0xFF1a0033),
    ),
    StoryPage(
      text: 'A haunted mansion stood alone, where ghostly spirits sleep.',
      emoji: '🏚️',
      backgroundColor: Color(0xFF0d1a33),
    ),
    StoryPage(
      text: 'The pumpkins grinned with wicked smiles, the bats began to fly...',
      emoji: '🎃',
      backgroundColor: Color(0xFF331a00),
    ),
    StoryPage(
      text: 'The witches brewed their potions dark beneath the starless sky.',
      emoji: '🧙‍♀️',
      backgroundColor: Color(0xFF1a331a),
    ),
    StoryPage(
      text: 'But one brave soul would dare to seek the treasure hidden there...',
      emoji: '🗝️',
      backgroundColor: Color(0xFF331a1a),
    ),
    StoryPage(
      text: 'Now it\'s YOUR turn to find it... if you dare!',
      emoji: '🎮',
      backgroundColor: Color(0xFF2d0052),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('The Haunted Tale'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() => _currentPage = index);
            },
            itemCount: _storyPages.length,
            itemBuilder: (context, index) {
              return _buildStoryPage(_storyPages[index]);
            },
          ),
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _storyPages.length,
                (index) => AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: _currentPage == index ? 24 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _currentPage == index
                        ? Colors.orange
                        : Colors.white38,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
          ),
          if (_currentPage == _storyPages.length - 1)
            Positioned(
              bottom: 80,
              left: 0,
              right: 0,
              child: Center(
                child: ElevatedButton(
                  onPressed: () => Navigator.pushReplacementNamed(context, '/game'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 40,
                      vertical: 15,
                    ),
                  ),
                  child: const Text(
                    'Start the Game!',
                    style: TextStyle(fontSize: 20),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStoryPage(StoryPage page) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 500),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            page.backgroundColor,
            page.backgroundColor.withOpacity(0.7),
          ],
        ),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 800),
                builder: (context, value, child) {
                  return Transform.scale(
                    scale: value,
                    child: Text(
                      page.emoji,
                      style: const TextStyle(fontSize: 120),
                    ),
                  );
                },
              ),
              const SizedBox(height: 40),
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 1000),
                builder: (context, value, child) {
                  return Opacity(
                    opacity: value,
                    child: Text(
                      page.text,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 24,
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                        height: 1.5,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class StoryPage {
  final String text;
  final String emoji;
  final Color backgroundColor;

  StoryPage({
    required this.text,
    required this.emoji,
    required this.backgroundColor,
  });
}

// Game Screen - Find the correct item!
class GameScreen extends StatefulWidget {
  const GameScreen({Key? key}) : super(key: key);

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen>
    with TickerProviderStateMixin {
  final AudioPlayer _audioPlayer = AudioPlayer();
  final Random _random = Random();
  late List<AnimationController> _controllers;
  late List<Animation<Offset>> _animations;
  bool _gameWon = false;

  final List<GameItem> _items = [
    GameItem(emoji: '👻', isTrap: true),
    GameItem(emoji: '🎃', isTrap: true),
    GameItem(emoji: '🦇', isTrap: true),
    GameItem(emoji: '🕷️', isTrap: true),
    GameItem(emoji: '💀', isTrap: true),
    GameItem(emoji: '🍬', isCorrect: true), // The winning item!
    GameItem(emoji: '🧟', isTrap: true),
    GameItem(emoji: '🕸️', isTrap: true),
  ];

  @override
  void initState() {
    super.initState();
    _items.shuffle();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _controllers = List.generate(
      _items.length,
      (index) => AnimationController(
        duration: Duration(seconds: 2 + _random.nextInt(3)),
        vsync: this,
      )..repeat(reverse: true),
    );

    _animations = List.generate(_items.length, (index) {
      double startX = _random.nextDouble() * 2 - 1;
      double startY = _random.nextDouble() * 2 - 1;
      double endX = _random.nextDouble() * 2 - 1;
      double endY = _random.nextDouble() * 2 - 1;

      return Tween<Offset>(
        begin: Offset(startX, startY),
        end: Offset(endX, endY),
      ).animate(CurvedAnimation(
        parent: _controllers[index],
        curve: Curves.easeInOut,
      ));
    });
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    _audioPlayer.dispose();
    super.dispose();
  }

  void _onItemTapped(GameItem item, int index) async {
    if (_gameWon) return;

    if (item.isCorrect) {
      setState(() => _gameWon = true);
      // Play success sound
      // await _audioPlayer.play(AssetSource('sounds/success.mp3'));
      _showWinDialog();
    } else if (item.isTrap) {
      // Play jump scare sound
      // await _audioPlayer.play(AssetSource('sounds/jumpscare.mp3'));
      _showTrapDialog();
    }
  }

  void _showWinDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1a0033),
        title: const Text(
          '🎉 You Found It! 🎉',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.orange, fontSize: 28),
        ),
        content: const Text(
          'Congratulations! You found the magical candy!\n\n🍬✨',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white, fontSize: 18),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushReplacementNamed(context, '/home');
            },
            child: const Text('Play Again'),
          ),
        ],
      ),
    );
  }

  void _showTrapDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1a0033),
        title: const Text(
          '👻 BOO! 👻',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.red, fontSize: 32),
        ),
        content: const Text(
          'That was a trap!\nKeep searching...',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white, fontSize: 18),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Find the Magical Candy! 🍬'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0d001a), Color(0xFF1a0033), Color(0xFF2d0052)],
          ),
        ),
        child: Stack(
          children: List.generate(_items.length, (index) {
            return AnimatedBuilder(
              animation: _animations[index],
              builder: (context, child) {
                return Positioned(
                  left: (MediaQuery.of(context).size.width / 2) +
                      (_animations[index].value.dx * 120),
                  top: (MediaQuery.of(context).size.height / 2) +
                      (_animations[index].value.dy * 200),
                  child: GestureDetector(
                    onTap: () => _onItemTapped(_items[index], index),
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.8, end: 1.2),
                      duration: Duration(milliseconds: 500 + _random.nextInt(500)),
                      curve: Curves.easeInOut,
                      onEnd: () {
                        // This creates a pulsing effect
                      },
                      builder: (context, scale, child) {
                        return Transform.scale(
                          scale: scale,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: _items[index].isCorrect
                                      ? Colors.yellow.withOpacity(0.5)
                                      : Colors.purple.withOpacity(0.3),
                                  blurRadius: 20,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: Text(
                              _items[index].emoji,
                              style: const TextStyle(fontSize: 48),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                );
              },
            );
          }),
        ),
      ),
    );
  }
}

class GameItem {
  final String emoji;
  final bool isTrap;
  final bool isCorrect;

  GameItem({
    required this.emoji,
    this.isTrap = false,
    this.isCorrect = false,
  });
}
