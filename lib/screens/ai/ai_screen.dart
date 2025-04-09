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
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            _buildSectionTitle('Resumo Rápido', Icons.lightbulb_outline),
            _buildInfoCard(_mockAiData['summary'] ?? 'Sem resumo disponível.', Colors.blueAccent.shade400),
            const SizedBox(height: 20),
            
            _buildSectionTitle('Insights da IA', Icons.insights),
            ...(_mockAiData['insights'] as List<String>)
                .map((insight) => _buildInfoCard(insight, Colors.deepPurpleAccent.shade100))
                .toList(),
            const SizedBox(height: 20),

            _buildSectionTitle('Sugestões Personalizadas', Icons.spa),
             ...(_mockAiData['suggestions'] as List<String>)
                .map((suggestion) => _buildInfoCard(suggestion, Colors.greenAccent.shade400))
                .toList(),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
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