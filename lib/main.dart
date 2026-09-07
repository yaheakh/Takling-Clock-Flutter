import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'app_state.dart';
import 'clock_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Loads locale data (month/day names, etc.) for both English and
  // Arabic so DateFormat(..., 'ar') doesn't throw at runtime — by
  // default intl only ships 'en_US' data until this is called.
  await initializeDateFormatting();
  await initializeDateFormatting('ar');
  runApp(const TalkingClockApp());
}

class TalkingClockApp extends StatefulWidget {
  const TalkingClockApp({super.key});

  @override
  State<TalkingClockApp> createState() => _TalkingClockAppState();
}

class _TalkingClockAppState extends State<TalkingClockApp> {
  final AppState _app = AppState();

  @override
  void initState() {
    super.initState();
    _app.init().then((_) => setState(() {}));
  }

  @override
  void dispose() {
    _app.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Talking Clock',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(useMaterial3: true),
      home: _app.loaded
          ? ClockScreen(app: _app)
          : const Scaffold(
              backgroundColor: Color(0xFF0A0612),
              body: Center(child: CircularProgressIndicator()),
            ),
    );
  }
}
