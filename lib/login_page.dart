import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'register_page.dart';
import 'package:task_app/home_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  void _login() async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomePage()),
      );
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Erro: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email')),
            TextField(
                controller: _passwordController,
                decoration: const InputDecoration(labelText: 'Senha'),
                obscureText: true),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: _login, child: const Text('Entrar')),
            TextButton(
              onPressed: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const RegisterPage())),
              child: const Text('Criar conta'),
            )
          ],
        ),
      ),
    );
  }
}
