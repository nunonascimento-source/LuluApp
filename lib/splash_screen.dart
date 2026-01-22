import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'measurement_form.dart';
import 'measurements_list.dart';
import 'db/database_helper.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToHome();
  }

  Future<void> _navigateToHome() async {
    await Future.delayed(const Duration(seconds: 3), () {});
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => const MyHomePage(title: 'Medição de Insulina'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.red,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.medical_services, size: 100, color: Colors.white),
            const SizedBox(height: 20),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Lulu',
                  style: TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: 30,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'App',
                  style: GoogleFonts.dancingScript(
                    fontSize: 24,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;

  void _incrementCounter() {
    setState(() {
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              widget.title,
              style: const TextStyle(
                fontFamily: 'Roboto',
                fontSize: 34,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
            const SizedBox(height: 60),
            // Two buttons section
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Nova Medição button
                Column(
                  children: [
                    FloatingActionButton(
                      onPressed: () async {
                        final saved = await Navigator.push<bool?>(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const MeasurementForm(),
                          ),
                        );
                        if (!mounted) return;
                        if (saved == true) {
                          final messenger = ScaffoldMessenger.of(context);
                          messenger.removeCurrentSnackBar();
                          messenger.showSnackBar(
                            const SnackBar(content: Text('Dados guardados')),
                          );
                          // Refresh the state
                          setState(() {});
                        }
                      },
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      child: const Icon(Icons.add),
                    ),
                    const SizedBox(height: 8),
                    const Text('Nova medição'),
                  ],
                ),
                const SizedBox(width: 60),
                // Medições realizadas button
                Column(
                  children: [
                    FloatingActionButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const MeasurementsListPage(),
                          ),
                        );
                      },
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      child: const Icon(Icons.list),
                    ),
                    const SizedBox(height: 8),
                    const Text('Medições realizadas'),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 40),
            // Exit button
            ElevatedButton.icon(
              onPressed: () {
                // Close the app (works in mobile, on web closes the tab)
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
              icon: const Icon(Icons.exit_to_app),
              label: const Text('Sair'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey[700],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
