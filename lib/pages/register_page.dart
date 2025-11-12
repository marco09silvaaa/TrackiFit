import 'package:flutter/cupertino.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  bool isLoading = false;

  Future<void> _register() async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();
    final confirmPassword = confirmPasswordController.text.trim();

    if (password != confirmPassword) {
      _showError('As passwords não coincidem.');
      return;
    }

    if (password.length < 6) {
      _showError('A password deve ter pelo menos 6 caracteres.');
      return;
    }

    setState(() => isLoading = true);
    try {
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      Navigator.pop(context); // volta ao login automaticamente
    } on FirebaseAuthException catch (e) {
      _showError(e.message ?? 'Erro no registo');
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
        middle: Text('Criar Conta'),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(CupertinoIcons.person_crop_circle_badge_plus, size: 80, color: CupertinoColors.activeGreen),
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
              const SizedBox(height: 12),
              CupertinoTextField(
                controller: confirmPasswordController,
                placeholder: 'Confirmar Password',
                obscureText: true,
              ),
              const SizedBox(height: 20),
              isLoading
                  ? const CupertinoActivityIndicator()
                  : CupertinoButton.filled(
                      onPressed: _register,
                      child: const Text('Criar Conta'),
                    ),
              const SizedBox(height: 8),
              CupertinoButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Já tenho conta'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
