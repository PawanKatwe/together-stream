import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/theme.dart';
import 'ui/screens/room_screen.dart';
import 'ui/screens/setup_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Allow both portrait and landscape orientation
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  // Set dark system navigation bar & status bar
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: AppTheme.background,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  final prefs = await SharedPreferences.getInstance();
  final savedIdentity = prefs.getString('my_identity');
  final savedServerUrl = prefs.getString('token_server_url');

  runApp(TogetherStreamApp(
    initialIdentity: savedIdentity,
    savedServerUrl: savedServerUrl,
  ));
}

class TogetherStreamApp extends StatelessWidget {
  final String? initialIdentity;
  final String? savedServerUrl;

  const TogetherStreamApp({
    super.key,
    this.initialIdentity,
    this.savedServerUrl,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TogetherStream',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const SetupScreen(),
    );
  }
}
