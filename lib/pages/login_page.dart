import 'package:flutter/cupertino.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'register_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  bool isLoading = false;

  Future<void> _login() async {
    setState(() => isLoading = true);
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );
      // AuthGate redireciona automaticamente
    } on FirebaseAuthException catch (e) {
      _showError(e.message ?? 'Erro no login');
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _showError(String message) {
    showCupertinoDialog(
      context: context,
      builder: (_) => CupertinoAlertDialog(
        title: const Text('Erro'),
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            child: const Text('OK'),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: const CupertinoNavigationBar(
        middle: Text('Login'),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(CupertinoIcons.person_alt_circle, size: 80, color: CupertinoColors.activeBlue),
              const SizedBox(height: 24),
              CupertinoTextField(
                controller: emailController,
                placeholder: 'Email',
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 12),
              CupertinoTextField(
                controller: passwordController,
                placeholder: 'Password',
                obscureText: true,
              ),
              const SizedBox(height: 20),
              isLoading
                  ? const CupertinoActivityIndicator()
                  : Column(
                      children: [
                        CupertinoButton.filled(
                          onPressed: _login,
                          child: const Text('Entrar'),
                        ),
                        const SizedBox(height: 8),
                        CupertinoButton(
                          child: const Text('Criar Conta'),
                          onPressed: () {
                            Navigator.push(
                              context,
                              CupertinoPageRoute(builder: (_) => const RegisterPage()),
                            );
                          },
                        ),
                      ],
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
