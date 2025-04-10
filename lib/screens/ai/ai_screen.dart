import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:moodyr/models/diary_entry_model.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:intl/intl.dart'; // Necessário para formatar datas no prompt

// REMOVIDO: Mock data não é mais necessário para exibição principal
// final Map<String, dynamic> _mockAiData = { ... };

class AIScreen extends StatefulWidget {
  const AIScreen({super.key});

  @override
  State<AIScreen> createState() => _AIScreenState();
}

class _AIScreenState extends State<AIScreen> {

  bool _isLoading = true;
  String? _errorMessage;
  List<DiaryEntry> _diaryEntries = [];
  String? _apiKey;

  // Novas variáveis de estado para armazenar a resposta da IA
  String? _aiSummary;
  List<String> _aiInsights = [];
  List<String> _aiSuggestions = [];

  final _storage = const FlutterSecureStorage();
  final String _apiBaseUrl = 'http://10.0.2.2:3000/api';

  @override
  void initState() {
    super.initState();
    _loadInitialDataAndGenerateAIContent();
  }

  Future<void> _loadInitialDataAndGenerateAIContent() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      // Limpar resultados anteriores da IA
      _aiSummary = null;
      _aiInsights = [];
      _aiSuggestions = [];
    });
    try {
      // Carregar a chave da API
      _apiKey = await _storage.read(key: 'api_key');
      if (_apiKey == null || _apiKey!.isEmpty) {
        throw Exception('Chave de API não encontrada. Configure-a primeiro.');
      }

      // Carregar entradas do diário
      await _fetchEntries();

      // Chamar a API da IA após carregar os dados
      await _callGenerativeAI();

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }

    } catch (e) {
      if (mounted) {
        String errorMsg = e.toString();
        // Simplificar a mensagem de erro comum da API
        if (e is GenerativeAIException) {
            errorMsg = 'Erro na API da IA: ${e.message}';
        } else if (e.toString().contains('Connection refused')) {
           errorMsg = 'Erro de conexão ao buscar dados do diário. Verifique o backend.';
        } else if (e.toString().contains('Falha ao buscar')){
            errorMsg = 'Falha ao buscar entradas do diário. Verifique o login.';
        }
        setState(() {
          _errorMessage = 'Erro ao gerar conteúdo da IA: $errorMsg';
          _isLoading = false;
        });
      }
    }
  }

  // Função para chamar a API Generative AI (Gemini)
  Future<void> _callGenerativeAI() async {
    if (_apiKey == null || _diaryEntries.isEmpty) {
      // Não fazer nada se não houver chave ou entradas
      _aiSummary = "Sem dados suficientes para análise.";
      return;
    }

    // 1. Inicializar o modelo
    // Use gemini-1.5-flash-latest ou outro modelo disponível
    final model = GenerativeModel(model: 'gemini-1.5-flash-latest', apiKey: _apiKey!);

    // 2. Criar o Prompt - CORRIGIDO
    final StringBuffer promptBuffer = StringBuffer();
    promptBuffer.writeln("Analise as seguintes entradas do meu diário de humor:");
    promptBuffer.writeln(); // Linha em branco
    for (var entry in _diaryEntries) {
      String formattedDate = DateFormat('dd/MM/yyyy').format(entry.date);
      // Escapar quebras de linha no conteúdo para não quebrar o prompt
      String safeContent = entry.content.replaceAll('\n', ' '); 
      promptBuffer.writeln("- Data: $formattedDate, Humor: ${entry.mood}, Notas: $safeContent");
    }
    promptBuffer.writeln(); // Linha em branco
    promptBuffer.writeln("Com base nessas entradas, forneça:");
    promptBuffer.writeln("1. SUMMARY: Um resumo conciso do humor predominante ou tendência geral em uma frase.");
    promptBuffer.writeln("2. INSIGHTS: Liste 2 ou 3 insights ou padrões interessantes que você observa (cada um começando com 'INSIGHT:').");
    promptBuffer.writeln("3. SUGGESTIONS: Liste 2 ou 3 sugestões acionáveis baseadas nos insights (cada uma começando com 'SUGGESTION:').");
    promptBuffer.writeln(); // Linha em branco
    promptBuffer.writeln("Responda APENAS no formato solicitado, usando os prefixos SUMMARY:, INSIGHT:, SUGGESTION:.");

    final content = [Content.text(promptBuffer.toString())];

    // 3. Gerar conteúdo
    setState(() { 
      // Poderia mostrar um indicador secundário aqui se a chamada demorar
    });

    GenerateContentResponse response;
    try {
       response = await model.generateContent(content);
    } on GenerativeAIException catch (e) {
        // Tratar erros específicos da API aqui, talvez com mais detalhes
        throw Exception('Erro na API Generativa: ${e.message}');
    } catch (e) {
       // Outros erros gerais
       throw Exception('Erro ao gerar conteúdo: ${e.toString()}');
    }
    
    // 4. Processar a resposta
    if (response.text != null) {
      _parseAIResponse(response.text!);
    } else {
      throw Exception('A API da IA retornou uma resposta vazia ou inválida.');
    }
  }

  // 5. Analisar (Parse) a resposta da IA
  void _parseAIResponse(String text) {
    final lines = text.split('\n');
    List<String> insights = [];
    List<String> suggestions = [];
    String? summary;

    for (var line in lines) {
      line = line.trim();
      if (line.startsWith('SUMMARY:')) {
        summary = line.substring('SUMMARY:'.length).trim();
      } else if (line.startsWith('INSIGHT:')) {
        insights.add(line.substring('INSIGHT:'.length).trim());
      } else if (line.startsWith('SUGGESTION:')) {
        suggestions.add(line.substring('SUGGESTION:'.length).trim());
      } else if (summary == null && insights.isEmpty && suggestions.isEmpty && line.isNotEmpty) {
         // Caso a IA não siga o formato e retorne um texto direto
         summary = line; 
      }
    }

    // Atualizar estado com os dados parseados
    setState(() {
      _aiSummary = summary ?? "Não foi possível gerar um resumo.";
      _aiInsights = insights.isNotEmpty ? insights : ["Nenhum insight específico gerado."];
      _aiSuggestions = suggestions.isNotEmpty ? suggestions : ["Nenhuma sugestão específica gerada."];
    });
  }

  // Função auxiliar para obter o token JWT de autenticação
  Future<String?> _getAuthToken() async {
    return await _storage.read(key: 'jwt_token');
  }

  // Função auxiliar para criar headers com o token de autenticação
  Future<Map<String, String>> _getAuthHeaders() async {
    String? token = await _getAuthToken();
    return {
      'Content-Type': 'application/json; charset=UTF-8',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // Buscar entradas da API do diário (adaptado de ReportScreen)
  Future<void> _fetchEntries() async {
    final headers = await _getAuthHeaders();
    final response = await http.get(
      Uri.parse('$_apiBaseUrl/diary'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      List<dynamic> data = jsonDecode(response.body);
      _diaryEntries = data.map((item) {
        return DiaryEntry(
          id: item['id'].toString(),
          content: item['conteudo'],
          date: DateTime.parse(item['data_entrada']),
          mood: item['humor'],
        );
      }).toList();
      _diaryEntries.sort((a, b) => a.date.compareTo(b.date)); // Ordenar
    } else {
      // Lançar uma exceção mais específica
      throw Exception('Falha ao buscar entradas do diário (${response.statusCode})');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Moodly AI Assistant', style: TextStyle(fontWeight: FontWeight.bold)),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.teal.shade300,
                Colors.cyan.shade300,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.cyan.shade50,
              Colors.teal.shade50,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    } else if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 60, color: Colors.red.shade400),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.red.shade700, fontSize: 16),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                icon: const Icon(Icons.refresh),
                label: const Text('Tentar Novamente'),
                onPressed: _loadInitialDataAndGenerateAIContent,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal.shade400,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      );
    } else {
      // Exibir os dados REAIS retornados pela IA
      return ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildSectionTitle('Resumo da IA', Icons.lightbulb_outline),
          _buildInfoCard(_aiSummary ?? 'Análise indisponível.', Colors.blueAccent.shade400),
          const SizedBox(height: 20),
          
          _buildSectionTitle('Insights da IA', Icons.insights),
          if (_aiInsights.isEmpty) 
             _buildInfoCard("Nenhum insight gerado.", Colors.grey) 
          else 
             ..._aiInsights
                .map((insight) => _buildInfoCard(insight, Colors.deepPurpleAccent.shade100))
                .toList(),
          const SizedBox(height: 20),

          _buildSectionTitle('Sugestões da IA', Icons.spa),
          if (_aiSuggestions.isEmpty) 
             _buildInfoCard("Nenhuma sugestão gerada.", Colors.grey) 
          else 
            ..._aiSuggestions
              .map((suggestion) => _buildInfoCard(suggestion, Colors.greenAccent.shade400))
              .toList(),
          const SizedBox(height: 20),
        ],
      );
    }
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0, top: 8.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.teal.shade600, size: 24),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.teal.shade800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(String text, Color accentColor) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15)
      ),
      clipBehavior: Clip.antiAlias,
      child: Container(
        decoration: BoxDecoration(
          border: Border(left: BorderSide(color: accentColor, width: 5)),
          color: Colors.white.withOpacity(0.8)
        ),
        padding: const EdgeInsets.all(16.0),
        child: Text(
          text,
          style: TextStyle(fontSize: 15, color: Colors.grey.shade900, height: 1.4),
        ),
      ),
    );
  }
} 