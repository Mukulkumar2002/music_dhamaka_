import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // await InAppWebViewController.setWebContentsDebuggingEnabled(true);
  runApp(const MusicDhamakaApp());
}

class MusicDhamakaApp extends StatelessWidget {
  const MusicDhamakaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Music Dhamaka',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.system,
      theme: ThemeData(
        brightness: Brightness.light,
        primarySwatch: Colors.red,
      ),
      darkTheme: ThemeData.dark().copyWith(
        colorScheme: const ColorScheme.dark(
          primary: Colors.red,
          secondary: Colors.redAccent,
        ),
      ),
      home: const SplashScreen(),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Timer(const Duration(seconds: 2), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.black, Colors.red],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.music_note, size: 80, color: Colors.white),
                SizedBox(height: 16),
                Text(
                  "Music Dhamaka",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          )),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  InAppWebViewController? _webViewController;
  late PullToRefreshController _pullToRefreshController;
  late StreamSubscription _connectivitySub;

  double _progress = 0;
  bool _isOffline = false;
  int _currentIndex = 0;

  final List<String> _titles = [
    'MUSIC DHAMAKA',
    'Trending',
    'Subscriptions',
    'Library',
  ];

  final List<String> _urls = [
    'https://m.youtube.com/',
    'https://m.youtube.com/feed/explore',
    'https://m.youtube.com/feed/subscriptions',
    'https://m.youtube.com/feed/library',
  ];

  @override
  void initState() {
    super.initState();

    _pullToRefreshController = PullToRefreshController(
      settings: PullToRefreshSettings(color: Colors.red),
      onRefresh: () async {
        if (_webViewController != null) {
          await _webViewController!.reload();
        }
      },
    );

    /// Latest Compatibility Listener
    _connectivitySub =
        Connectivity().onConnectivityChanged.listen((result) async {
      bool offline;

      if (result is ConnectivityResult) {
        offline = result == ConnectivityResult.none;
      } else if (result is List<ConnectivityResult>) {
        offline = result.contains(ConnectivityResult.none);
      } else {
        offline = true;
      }

      if (!mounted) return;
      setState(() => _isOffline = offline);

      if (!offline && _webViewController != null) {
        _webViewController!.reload();
      }
    });

    _checkInitialConnection();
  }

  Future<void> _checkInitialConnection() async {
    final connectivity = await Connectivity().checkConnectivity();
    setState(() {
      _isOffline = connectivity == ConnectivityResult.none;
    });
  }

  @override
  void dispose() {
    _connectivitySub.cancel();
    super.dispose();
  }

  Future<bool> _onWillPop() async {
    if (_webViewController != null && await _webViewController!.canGoBack()) {
      await _webViewController!.goBack();
      return false;
    }
    return true;
  }

  void _onTabTapped(int index) {
    setState(() => _currentIndex = index);
    if (_webViewController != null && !_isOffline) {
      _webViewController!.loadUrl(
        urlRequest: URLRequest(url: WebUri(_urls[index])),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUrl = _urls[_currentIndex];

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: AppBar(
            title: Text(
          _titles[_currentIndex],
          style: const TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.bold, // 🔥 Bold active section
          ),
        )),
        body: SafeArea(
          child: _isOffline
              ? _buildOfflineView()
              : Stack(children: [
                  InAppWebView(
                    initialUrlRequest: URLRequest(url: WebUri(currentUrl)),
                    pullToRefreshController: _pullToRefreshController,
                    initialSettings: InAppWebViewSettings(
                      javaScriptEnabled: true,
                      supportZoom: false,
                      useWideViewPort: true,
                      loadWithOverviewMode: true,
                      preferredContentMode: UserPreferredContentMode.MOBILE,
                    ),
                    onWebViewCreated: (controller) {
                      _webViewController = controller;
                    },
                    onProgressChanged: (_, progress) {
                      setState(() => _progress = progress / 100);
                    },
                  ),
                  if (_progress < 1.0)
                    LinearProgressIndicator(value: _progress),
                ]),
        ),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: _onTabTapped,
          selectedItemColor: Colors.red,
          unselectedItemColor: Colors.grey,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
            BottomNavigationBarItem(
                icon: Icon(Icons.local_fire_department), label: "Trending"),
            BottomNavigationBarItem(
                icon: Icon(Icons.subscriptions), label: "Subs"),
            BottomNavigationBarItem(
                icon: Icon(Icons.video_library), label: "Library"),
          ],
        ),
      ),
    );
  }

  Widget _buildOfflineView() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.wifi_off, size: 80),
          const SizedBox(height: 16),
          const Text("You are offline"),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => _checkInitialConnection(),
            child: const Text("Retry"),
          ),
        ],
      ),
    );
  }
}
