import 'package:flutter/material.dart';

// Placeholder para dados - Em uma implementação real, viria de outro lugar
final Map<String, dynamic> _mockAiData = {
  'summary': 'Humor predominante na última semana: Calmo.',
  'insights': [
    'Padrão identificado: Entradas com humor \'Ansioso\' são mais frequentes em dias de semana.',
    'Correlação observada: O humor \'Grato\' aparece frequentemente após registros de atividades relaxantes.',
  ],
  'suggestions': [
    'Para dias mais \'Ansiosos\', experimente uma pausa curta para respiração profunda.',
    'Continue registrando atividades que te trazem calma, como ouvir música ou ler.',
  ],
  'chat_history': [
    {'sender': 'ai', 'text': 'Olá! Como posso ajudar a analisar seus padrões de humor hoje?'},
  ]
};

class AIScreen extends StatefulWidget {
  const AIScreen({super.key});

  @override
  State<AIScreen> createState() => _AIScreenState();
}

class _AIScreenState extends State<AIScreen> {
  final TextEditingController _chatController = TextEditingController();
  final List<Map<String, String>> _chatMessages = List.from(_mockAiData['chat_history']);

  void _sendMessage() {
    final text = _chatController.text.trim();
    if (text.isNotEmpty) {
      setState(() {
        _chatMessages.add({'sender': 'user', 'text': text});
        // Simulação de resposta da IA
        _chatMessages.add({'sender': 'ai', 'text': 'Entendido. Analisando sua pergunta... (resposta simulada)'});
        _chatController.clear();
      });
      // TODO: Implementar lógica real de envio e recebimento de chat com IA
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
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16.0),
                children: [
                  _buildSectionTitle('Resumo Rápido', Icons.lightbulb_outline),
                  _buildInfoCard(_mockAiData['summary'] ?? 'Sem resumo disponível.', Colors.blueAccent),
                  const SizedBox(height: 20),
                  
                  _buildSectionTitle('Insights da IA', Icons.insights),
                  ...(_mockAiData['insights'] as List<String>)
                      .map((insight) => _buildInfoCard(insight, Colors.deepPurpleAccent))
                      .toList(),
                  const SizedBox(height: 20),

                  _buildSectionTitle('Sugestões Personalizadas', Icons.spa),
                   ...(_mockAiData['suggestions'] as List<String>)
                      .map((suggestion) => _buildInfoCard(suggestion, Colors.greenAccent))
                      .toList(),
                  const SizedBox(height: 20),
                  
                  _buildSectionTitle('Conversar com a IA', Icons.chat_bubble_outline),
                  _buildChatArea(),
                ],
              ),
            ),
            _buildChatInput(),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Container(
        decoration: BoxDecoration(
          border: Border(left: BorderSide(color: accentColor, width: 5)),
          borderRadius: BorderRadius.circular(15),
        ),
        padding: const EdgeInsets.all(16.0),
        child: Text(
          text,
          style: TextStyle(fontSize: 15, color: Colors.grey.shade800, height: 1.4),
        ),
      ),
    );
  }

  Widget _buildChatArea() {
    return Container(
      height: 200, // Altura fixa para a área de chat, pode ser ajustada
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.5),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.teal.shade100),
      ),
      child: ListView.builder(
        padding: const EdgeInsets.all(8.0),
        itemCount: _chatMessages.length,
        itemBuilder: (context, index) {
          final message = _chatMessages[index];
          final isUser = message['sender'] == 'user';
          return Align(
            alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 4.0),
              padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
              decoration: BoxDecoration(
                color: isUser ? Colors.cyan.shade300 : Colors.teal.shade300,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                message['text'] ?? '',
                style: const TextStyle(color: Colors.white),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildChatInput() {
    return Container(
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 5,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _chatController,
              decoration: InputDecoration(
                hintText: 'Digite sua pergunta aqui...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey.shade100,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
              ),
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: Icon(Icons.send, color: Colors.teal.shade400),
            onPressed: _sendMessage,
          ),
        ],
      ),
    );
  }
} 