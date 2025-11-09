import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_fonts/google_fonts.dart';
import 'firebase_options.dart';
import 'package:provider/provider.dart';
import 'services/auth_service.dart';
import 'providers/book_provider.dart';
import 'providers/chat_provider.dart';
import 'providers/notification_provider.dart';
import 'widgets/notification_badge.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/signup_screen.dart';
import 'screens/auth/verify_email_screen.dart';

import 'screens/home/browse_listings.dart';
import 'screens/home/my_listings.dart';
import 'screens/chat/threads_screen.dart';
import 'screens/settings/settings_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const PageTurnerApp());
}

class PageTurnerApp extends StatelessWidget {
  const PageTurnerApp({super.key});

  // New vibrant color palette
  static const _teal = Color(0xFF004D40); // Deep Teal
  static const _brown = Color.fromARGB(255, 221, 148, 12); // Hot Pink

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<AuthService>(create: (_) => AuthService()),
        ChangeNotifierProvider(create: (_) => BookProvider()),
        ChangeNotifierProvider(create: (_) => ChatProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Page Turner',
        theme: ThemeData(
          // Using Google Fonts for a fresh look
          textTheme: GoogleFonts.poppinsTextTheme(Theme.of(context).textTheme),
          colorScheme: const ColorScheme.light(
            primary: _brown, // Use our exact pink as the primary color
            secondary: _teal, // Use our exact teal as the secondary color
            surface: Color(0xFFFDF7F9), // Light pinkish-white surface
            background: Color(0xFFFDF7F9), // And as the background
            onPrimary: Colors.white, // Text on pink buttons will be white
            onSecondary: Colors.white, // Text on teal elements will be white
          ),
          useMaterial3: true,
          scaffoldBackgroundColor: const Color(
            0xFFFDF7F9,
          ), // Light pinkish-white
          appBarTheme: AppBarTheme(
            backgroundColor: _teal,
            foregroundColor: Colors.white,
            elevation: 2,
            centerTitle: true,
            titleTextStyle: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          bottomNavigationBarTheme: const BottomNavigationBarThemeData(
            backgroundColor: _teal,
            selectedItemColor: _brown,
            unselectedItemColor: Colors.white60,
            selectedLabelStyle: TextStyle(fontWeight: FontWeight.bold),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: _brown,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
          ),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            floatingLabelStyle: const TextStyle(color: _brown),
          ),
          cardTheme: CardThemeData(
            elevation: 1,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
        home: const _AuthGate(),
        routes: {
          LoginScreen.route: (_) => const LoginScreen(),
          SignupScreen.route: (_) => const SignupScreen(),
        },
      ),
    );
  }
}

class _AuthGate extends StatelessWidget {
  const _AuthGate();

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthService>();
    return StreamBuilder(
      stream: auth.authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (!snapshot.hasData) return const LoginScreen();
        final user = auth.currentUser!;
        if (!user.emailVerified) return const VerifyEmailScreen();
        return const MainNav();
      },
    );
  }
}

class MainNav extends StatefulWidget {
  const MainNav({super.key});

  @override
  State<MainNav> createState() => _MainNavState();
}

class _MainNavState extends State<MainNav> {
  int idx = 0;
  final pages = const [
    BrowseListings(),
    MyListings(),
    ThreadsScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final notifications = context.watch<NotificationProvider>();

    return Scaffold(
      body: pages[idx],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: idx,
        onTap: (i) {
          setState(() => idx = i);
          if (i == 1) {
            notifications.markIncomingAsRead();
            notifications.markMyOffersAsRead();
          }
        },
        items: [
          // Fun new titles for the navbar items
          const BottomNavigationBarItem(
            icon: Icon(Icons.auto_stories_outlined),
            label: 'Discover',
          ),
          BottomNavigationBarItem(
            icon: NotificationBadge(
              count: notifications.totalUnread,
              child: const Icon(Icons.inventory_2_outlined),
            ),
            label: 'My Shelf',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.forum_outlined),
            label: 'Chats',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.face_retouching_natural),
            label: 'Me',
          ),
        ],
      ),
    );
  }
}
