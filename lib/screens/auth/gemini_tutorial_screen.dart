import 'package:flutter/material.dart';

class GeminiTutorialScreen extends StatelessWidget {
  const GeminiTutorialScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tutorial: Obter Chave Gemini'),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor, // Maintain consistency
        elevation: 1,
        iconTheme: IconThemeData(color: Theme.of(context).primaryColor),
        titleTextStyle: TextStyle(
          color: Theme.of(context).textTheme.titleLarge?.color,
          fontSize: 20,
          fontWeight: FontWeight.w500,
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Passo a Passo para Gerar sua Chave:',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            _buildStep(
              context,
              stepNumber: 1,
              title: 'Acesse o Google AI Studio',
              description: 'Vá para a página inicial do Google AI Studio e faça login com sua conta Google.',
              
            ),
            const SizedBox(height: 16),
             _buildStep(
              context,
              stepNumber: 2,
              title: 'Encontre "Get API key"',
              description: 'Na página principal do AI Studio, procure e clique no botão "Get API key", geralmente localizado no canto superior direito.',
               
            ),
             const SizedBox(height: 16),
            _buildStep(
              context,
              stepNumber: 3,
              title: 'Crie sua Chave',
              description: 'Na tela de "API Keys", clique no botão "Criar chave de API."',

            ),
            const SizedBox(height: 16),
            _buildStep(
              context,
              stepNumber: 4,
              title: 'Copie a Chave',
              description: 'Uma nova chave será gerada. Clique no botão para copiar a chave para sua área de transferência.',

            ),
             const SizedBox(height: 16),
             _buildStep(
              context,
              stepNumber: 5,
              title: 'Cole no Moodly',
              description: 'Volte para a tela "Configurar Chave de API da IA" no Moodly, cole a chave no campo indicado e clique em "Salvar Chave e Continuar".',
            ),
            const SizedBox(height: 30),
            Center(
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                 style: ElevatedButton.styleFrom(
                   padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                   backgroundColor: Theme.of(context).primaryColor,
                   foregroundColor: Colors.white
                 ),
                child: const Text('Entendi, voltar'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep(BuildContext context, {required int stepNumber, required String title, required String description}) {
    return Card(
       elevation: 1,
       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
       margin: const EdgeInsets.symmetric(vertical: 8.0),
       child: Padding(
         padding: const EdgeInsets.all(16.0),
         child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
           children: [
             CircleAvatar(
               radius: 14,
               backgroundColor: Theme.of(context).primaryColor,
               child: Text(
                 '$stepNumber',
                 style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
               ),
             ),
             const SizedBox(width: 16),
             Expanded(
               child: Column(
                 crossAxisAlignment: CrossAxisAlignment.start,
                 children: [
                   Text(
                     title,
                     style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                   ),
                   const SizedBox(height: 6),
                   Text(
                     description,
                     style: TextStyle(color: Colors.grey.shade700, fontSize: 14),
                   ),
                 ],
               ),
             ),
           ],
         ),
       ),
    );
  }
} 