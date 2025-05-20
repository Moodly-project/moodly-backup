import 'package:flutter/material.dart';
import 'package:moodyr/services/api_config_service.dart';

class ApiSettingsScreen extends StatefulWidget {
  const ApiSettingsScreen({super.key});

  @override
  State<ApiSettingsScreen> createState() => _ApiSettingsScreenState();
}

class _ApiSettingsScreenState extends State<ApiSettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _urlController = TextEditingController();
  final _apiConfigService = ApiConfigService();
  bool _isLoading = false;
  String? _currentUrl;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadCurrentUrl();
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentUrl() async {
    setState(() => _isLoading = true);
    try {
      final url = await _apiConfigService.getBaseUrl();
      setState(() {
        _currentUrl = url;
        _urlController.text = url.replaceAll('/api', ''); // Remove /api para exibição
      });
    } catch (e) {
      setState(() => _errorMessage = 'Erro ao carregar URL atual: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveUrl() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      try {
        await _apiConfigService.setBaseUrl(_urlController.text);
        await _loadCurrentUrl(); // Recarrega a URL atual
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('URL da API atualizada com sucesso!')),
          );
        }
      } catch (e) {
        setState(() => _errorMessage = 'Erro ao salvar URL: $e');
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _resetToDefault() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await _apiConfigService.resetToDefault();
      await _loadCurrentUrl();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('URL resetada para o padrão!')),
        );
      }
    } catch (e) {
      setState(() => _errorMessage = 'Erro ao resetar URL: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configurações da API'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Configuração da URL da API',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Configure o endereço do servidor da API. Use o IP do seu computador quando estiver rodando no celular.',
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (_errorMessage != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16.0),
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(color: Colors.red),
                          ),
                        ),
                      TextFormField(
                        controller: _urlController,
                        decoration: InputDecoration(
                          labelText: 'URL do Servidor',
                          hintText: 'Ex: http://192.168.1.100:3000',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          prefixIcon: const Icon(Icons.link),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Por favor, insira a URL do servidor';
                          }
                          if (!value.startsWith('http://') && !value.startsWith('https://')) {
                            return 'URL deve começar com http:// ou https://';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _isLoading ? null : _saveUrl,
                              icon: const Icon(Icons.save),
                              label: const Text('Salvar'),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _isLoading ? null : _resetToDefault,
                              icon: const Icon(Icons.restore),
                              label: const Text('Resetar'),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'URL Atual',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (_isLoading)
                        const Center(child: CircularProgressIndicator())
                      else if (_currentUrl != null)
                        SelectableText(
                          _currentUrl!,
                          style: TextStyle(
                            color: Colors.grey.shade700,
                            fontFamily: 'monospace',
                          ),
                        )
                      else
                        const Text('Nenhuma URL configurada'),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 