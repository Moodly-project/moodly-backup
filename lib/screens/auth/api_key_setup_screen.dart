import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:moodyr/screens/auth/login_screen.dart';
import 'package:url_launcher/url_launcher.dart';

class ApiKeySetupScreen extends StatefulWidget {
  const ApiKeySetupScreen({super.key});

  @override
  State<ApiKeySetupScreen> createState() => _ApiKeySetupScreenState();
}

class _ApiKeySetupScreenState extends State<ApiKeySetupScreen> {
  final _apiKeyController = TextEditingController();
  final _storage = const FlutterSecureStorage();
  final _formKey = GlobalKey<FormState>();

  Future<void> _saveApiKey() async {
    if (_formKey.currentState!.validate()) {
      await _storage.write(key: 'api_key', value: _apiKeyController.text.trim());
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }
  }

  // Função para abrir links
  Future<void> _launchURL(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Não foi possível abrir o link: $urlString')),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configurar Chave de API da IA'),
         automaticallyImplyLeading: false, // Impede de voltar
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Conecte sua IA Favorita!',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Text(
                'Para habilitar os recursos de análise e sugestões personalizadas do Moodly AI, você precisa fornecer sua própria chave de API de um serviço compatível (como Google Gemini).',
                style: TextStyle(fontSize: 16, color: Colors.grey.shade700),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _apiKeyController,
                decoration: InputDecoration(
                  labelText: 'Sua Chave de API',
                  hintText: 'Cole sua chave aqui (ex: sk-...) ',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                enableInteractiveSelection: true,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Por favor, insira sua chave de API.';
                  }
                  
                  return null;
                },
              ),
              const SizedBox(height: 32),
              const Text(
                'Como obter uma chave de API?',
                 style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              _buildInstructionTile(
                title: 'Google Gemini (Recomendado - Gratuito):',
                url: 'https://aistudio.google.com/app/apikey',
                instructions: '1. Acesse o Google AI Studio.\n2. Faça login com sua conta Google.\n3. Clique em "Get API key".\n4. Copie a chave gerada e cole acima.',
                icon: Icons.android,
              ),
               const SizedBox(height: 16),

              const SizedBox(height: 40),
              Center(
                child: ElevatedButton(
                  onPressed: _saveApiKey,
                  style: ElevatedButton.styleFrom(
                     minimumSize: const Size(double.infinity, 50),
                     backgroundColor: Theme.of(context).primaryColor,
                     foregroundColor: Colors.white
                  ),
                  child: const Text('Salvar Chave e Continuar'),
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: TextButton(
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => const LoginScreen()),
                    );
                  },
                  child: Text(
                    'Pular por agora',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

   Widget _buildInstructionTile({required String title, required String url, required String instructions, required IconData icon}) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Theme.of(context).primaryColor, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(instructions, style: TextStyle(color: Colors.grey.shade700)),
            const SizedBox(height: 8),
            TextButton.icon(
              icon: const Icon(Icons.link, size: 18),
              label: const Text('Obter Chave Aqui'),
              onPressed: () => _launchURL(url),
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ],
        ),
      ),
    );
  }
}