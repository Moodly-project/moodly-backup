import 'dart:convert'; // Para jsonEncode
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http; // Importa o pacote http
import 'package:moodyr/validators/email_register_validator.dart';
import 'package:moodyr/validators/password_register_validator.dart';
import 'package:moodyr/validators/username_register_validator.dart';
import 'package:moodyr/widgets/custom_button.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false; // Estado para indicar carregamento

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (_formKey.currentState!.validate() && !_isLoading) {
      setState(() {
        _isLoading = true; // Inicia o carregamento
      });

      // Emulador Android: 'http://10.0.2.2:3000/api/auth/register'
      const String apiUrl = 'http://10.0.2.2:3000/api/auth/register';

      try {
        final response = await http.post(
          Uri.parse(apiUrl),
          headers: <String, String>{
            'Content-Type': 'application/json; charset=UTF-8',
          },
          body: jsonEncode(<String, String>{
            'nome': _nameController.text,
            'email': _emailController.text,
            'senha': _passwordController.text,
          }),
        );

        if (mounted) {
          // Verifica se o widget ainda está na árvore
          final responseBody = jsonDecode(response.body);
          final message = responseBody['message'] ?? 'Erro desconhecido';

          if (response.statusCode == 201) {
            // Sucesso
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(message)),
            );
            Navigator.pop(context); // Volta para a tela de login
          } else {
            // Erro
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text('Falha no registro: $message'),
                  backgroundColor: Colors.red),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          // Erro de conexão ou outr
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text('Erro ao conectar: ${e.toString()}'),
                backgroundColor: Colors.red),
          );
        }
        print('Erro na requisição HTTP: $e');
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false; // Finaliza o carregamento
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Criar Conta'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Theme.of(context).colorScheme.primary,
      ),
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Theme.of(context).colorScheme.primaryContainer.withOpacity(0.6),
              Theme.of(context).colorScheme.secondaryContainer.withOpacity(0.6),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(32.0, 100.0, 32.0, 32.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Junte-se ao Moodly',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 40),
                  TextFormField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: 'Nome',
                      prefixIcon: const Icon(Icons.person_outline),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.white70,
                    ),
                    validator: (value) {
                      if (value == null ||
                          !UsernameRegisterValidator.isValidUsernameRegister(
                              value)) {
                        return 'Nome Inválido';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _emailController,
                    decoration: InputDecoration(
                      labelText: 'Email',
                      prefixIcon: const Icon(Icons.email_outlined),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.white70,
                    ),
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null ||
                          !EmailRegisterValidator.isValidEmailRegister(value)) {
                        return 'E-mail Inválido';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _passwordController,
                    decoration: InputDecoration(
                      labelText: 'Senha',
                      prefixIcon: const Icon(Icons.lock_outline),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.white70,
                    ),
                    obscureText: true,
                    validator: (value) {
                      if (value == null ||
                          !PasswordRegisterValidator.isSecurePassWordRegister(
                              value)) {
                        return 'A senha deve ter pelo menos 6 caracteres';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 30),
                  _isLoading
                      ? CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                              Theme.of(context).colorScheme.primary),
                        )
                      : CustomButton(
                          text: 'Registrar',
                          onPressed: _register,
                        ),
                  const SizedBox(height: 20),
                  TextButton(
                    onPressed: () => Navigator.pop(context), // tela de login
                    child: Text(
                      'Já tem uma conta? Faça login',
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.primary),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
