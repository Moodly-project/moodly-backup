import 'dart:convert'; // Para jsonEncode
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http; // Importa o pacote http
import 'package:moodyr/validators/email_register_validator.dart';
import 'package:moodyr/validators/password_register_validator.dart';
import 'package:moodyr/validators/username_register_validator.dart';
import 'package:moodyr/widgets/custom_button.dart';
import 'package:moodyr/services/api_config_service.dart';

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
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false; // Estado para indicar carregamento
  bool _showPassword = false; // Controla a visibilidade da senha
  bool _showConfirmPassword = false; // Controla a visibilidade da confirmação de senha
  final _apiConfigService = ApiConfigService();

  // Configuração padrão para os inputs do formulário
  InputDecoration _getInputDecoration({
    required String labelText,
    required Icon prefixIcon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: labelText,
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      filled: true,
      fillColor: Colors.white70,
      // Configuração para garantir que as mensagens de erro tenham espaço suficiente
      errorMaxLines: 3, // Permite até 3 linhas para mensagens de erro
      helperMaxLines: 1,
      alignLabelWithHint: true,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (_formKey.currentState!.validate() && !_isLoading) {
      setState(() {
        _isLoading = true; // Inicia o carregamento
      });

      try {
        final apiUrl = await _apiConfigService.getBaseUrl();
        final response = await http.post(
          Uri.parse('${apiUrl}/auth/register'),
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

  // Função para alternar a visibilidade da senha com animação
  void _togglePasswordVisibility() {
    setState(() {
      _showPassword = !_showPassword;
    });
  }

  // Função para alternar a visibilidade da confirmação de senha com animação
  void _toggleConfirmPasswordVisibility() {
    setState(() {
      _showConfirmPassword = !_showConfirmPassword;
    });
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
                    decoration: _getInputDecoration(
                      labelText: 'Nome',
                      prefixIcon: const Icon(Icons.person_outline),
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
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: _emailController,
                    decoration: _getInputDecoration(
                      labelText: 'Email',
                      prefixIcon: const Icon(Icons.email_outlined),
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
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: _passwordController,
                    decoration: _getInputDecoration(
                      labelText: 'Senha',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        transitionBuilder: (Widget child, Animation<double> animation) {
                          return ScaleTransition(scale: animation, child: child);
                        },
                        child: IconButton(
                          key: ValueKey<bool>(_showPassword),
                          icon: Icon(
                            _showPassword ? Icons.visibility : Icons.visibility_off,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          onPressed: _togglePasswordVisibility,
                        ),
                      ),
                    ),
                    obscureText: !_showPassword,
                    validator: (value) {
                      if (value == null ||
                          !PasswordRegisterValidator.isSecurePassWordRegister(
                              value)) {
                        return 'A senha deve ter pelo menos 6 caracteres, incluir letra maiúscula, número e caractere especial';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: _confirmPasswordController,
                    decoration: _getInputDecoration(
                      labelText: 'Confirmar Senha',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        transitionBuilder: (Widget child, Animation<double> animation) {
                          return ScaleTransition(scale: animation, child: child);
                        },
                        child: IconButton(
                          key: ValueKey<bool>(_showConfirmPassword),
                          icon: Icon(
                            _showConfirmPassword ? Icons.visibility : Icons.visibility_off,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          onPressed: _toggleConfirmPasswordVisibility,
                        ),
                      ),
                    ),
                    obscureText: !_showConfirmPassword,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Por favor, confirme sua senha';
                      }
                      if (value != _passwordController.text) {
                        return 'As senhas não coincidem';
                      }
                      return null;
                    },
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0, left: 12.0),
                    child: Row(
                      children: [
                        InkWell(
                          onTap: () => _showPasswordRequirements(context),
                          child: Icon(
                            Icons.help_outline,
                            size: 18,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text('Requisitos de senha',
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(context).colorScheme.primary,
                            )),
                      ],
                    ),
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

  void _showPasswordRequirements(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Requisitos de Senha'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text('• Mínimo de 6 caracteres'),
              Text('• Pelo menos uma letra maiúscula'),
              Text('• Pelo menos um número'),
              Text('• Pelo menos um caractere especial (ex: !@#\$%^&*)'),
            ],
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Entendi'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _showPasswordConfirmationInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Por que confirmar a senha?'),
          content: const Text(
              'Confirmar a senha ajuda a garantir que você digitou a senha desejada corretamente, evitando erros de digitação que poderiam impedir seu acesso futuro à conta.'),
          actions: <Widget>[
            TextButton(
              child: const Text('Entendi'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}
