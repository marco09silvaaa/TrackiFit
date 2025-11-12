import 'package:flutter/cupertino.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';

import 'pages/root_shell.dart'; // página principal da app
import 'pages/login_page.dart'; // página de login

import 'populate_exercises.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializa o Firebase antes de rodar a app
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const TrackiFitApp());
}

class TrackiFitApp extends StatelessWidget {
  const TrackiFitApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const CupertinoApp(
      debugShowCheckedModeBanner: false,
      title: 'TrackiFit',
      home: AuthGate(), // Verifica o login antes de ir ao RootShell
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Mostra um loading enquanto verifica o estado
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CupertinoPageScaffold(
            child: Center(child: CupertinoActivityIndicator()),
          );
        }

        // Se o user estiver logado → vai para o RootShell (a tua app principal)
        if (snapshot.hasData) {
          return const RootShell();
        }

        // Se não estiver logado → vai para o Login
        return const LoginPage();
      },
    );
  }
}


/*Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // 🚀 Executa o populate uma vez
  await populateExercises();

  runApp(const CupertinoApp(
    debugShowCheckedModeBanner: false,
    home: CupertinoPageScaffold(
      backgroundColor: CupertinoColors.black,
      child: Center(
        child: Text(
          '✅ Exercises populated successfully!',
          style: TextStyle(color: CupertinoColors.white, fontSize: 18),
        ),
      ),
    ),
  ));
}*/