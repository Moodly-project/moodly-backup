import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http; // Necessário para buscar entradas
import 'dart:convert'; // Necessário para jsonDecode
import 'package:intl/intl.dart'; // Necessário para formatar datas no prompt (se usarmos)
import 'package:moodyr/models/diary_entry_model.dart'; // Importar modelo da entrada
// Importar outros pacotes necessários, como http, se precisar buscar dados

class ChatScreen extends StatefulWidget {
  // Poderíamos passar dados iniciais aqui, como a última entrada do diário
  // final DiaryEntry? initialContext;
  // const ChatScreen({super.key, this.initialContext});

  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController(); // Para rolar a lista
  final List<Map<String, String>> _messages = []; // Lista de mensagens
  List<DiaryEntry> _diaryEntries = []; // Para armazenar entradas do diário
  bool _isLoading = false;
  bool _isFetchingEntries = false; // Estado para busca de entradas
  String? _errorMessage;
  String? _apiKey;
  GenerativeModel? _model;

  final _storage = const FlutterSecureStorage();
  final String _apiBaseUrl = 'http://10.0.2.2:3000/api'; // Mesma URL da DiaryScreen

  @override
  void initState() {
    super.initState();
    _initializeChat();
  }

  // Renomeado para incluir busca de entradas
  Future<void> _initializeChat() async {
    setState(() {
      _isLoading = true; // Loading geral inicial
      _errorMessage = null;
    });
    try {
      // Carregar chave API
      _apiKey = await _storage.read(key: 'api_key');
      if (_apiKey == null || _apiKey!.isEmpty) {
        throw Exception('Chave de API não encontrada.');
      }
      _model = GenerativeModel(model: 'gemini-1.5-flash-latest', apiKey: _apiKey!);

      // Buscar entradas do diário em paralelo (sem bloquear a UI inicial)
      _fetchEntries(); // Não aguarda aqui, mas atualiza _isFetchingEntries

      // Adiciona a mensagem inicial do bot APÓS carregar a chave
      if (mounted) {
          setState(() {
             _messages.add({'role': 'model', 'text': 'Olá! Sobre qual emoção ou evento do seu dia você gostaria de conversar?'});
          });
          _scrollToBottom();
      }

    } catch (e) {
      if (mounted) {
         setState(() {
           _errorMessage = 'Erro ao inicializar o chat: ${e.toString()}';
         });
      }
    } finally {
       if (mounted) {
         setState(() {
           _isLoading = false; // Termina o loading geral
         });
       }
    }
  }

  // ---- Funções copiadas/adaptadas da DiaryScreen para buscar entradas ----
  Future<String?> _getToken() async {
    return await _storage.read(key: 'jwt_token');
  }

  Future<Map<String, String>> _getHeaders() async {
    String? token = await _getToken();
    return {
      'Content-Type': 'application/json; charset=UTF-8',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<void> _fetchEntries() async {
    if (_isFetchingEntries) return; // Evita buscas múltiplas
    setState(() {
      _isFetchingEntries = true;
      // Não mostrar erro na UI principal ainda, talvez um indicador sutil?
    });
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$_apiBaseUrl/diary'),
        headers: headers,
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        List<dynamic> data = jsonDecode(response.body);
        setState(() {
          _diaryEntries = data.map((item) {
            return DiaryEntry(
              id: item['id'].toString(),
              content: item['conteudo'],
              date: DateTime.parse(item['data_entrada']),
              mood: item['humor'],
            );
          }).toList();
          _diaryEntries.sort((a, b) => b.date.compareTo(a.date)); // Ordenar recentes primeiro
        });
      } else {
        // Tratar erro silenciosamente ou com log, não quebrar o chat
        print('Erro ao buscar entradas do diário: ${response.statusCode}');
        // Poderia adicionar uma mensagem de erro sutil no chat se necessário
      }
    } catch (e) {
       print('Erro de conexão ao buscar entradas: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() {
          _isFetchingEntries = false;
        });
      }
    }
  }
  // ---- Fim das funções de busca ----

  // Função para rolar para o fim da lista
  void _scrollToBottom() {
     WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
           _scrollController.animateTo(
             _scrollController.position.maxScrollExtent,
             duration: const Duration(milliseconds: 300),
             curve: Curves.easeOut,
           );
         }
     });
  }

  // ---- Limpar Chat ----
  Future<void> _clearChat() async {
    // Mostrar diálogo de confirmação
    bool? confirmClear = await showDialog<bool>(
      context: context,
      builder: (BuildContext ctx) {
        return AlertDialog(
          title: const Text('Limpar Conversa'),
          content: const Text('Tem certeza que deseja apagar todas as mensagens desta conversa?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () {
                Navigator.of(ctx).pop(false); // Não confirmar
              },
            ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Limpar'),
              onPressed: () {
                Navigator.of(ctx).pop(true); // Confirmar
              },
            ),
          ],
        );
      },
    );

    // Se o usuário confirmou
    if (confirmClear == true && mounted) {
      setState(() {
        _messages.clear(); // Limpa a lista de mensagens
        // Opcional: Adiciona a mensagem inicial do bot novamente
        _messages.add({
            'role': 'model',
            'text': 'Olá! Sobre qual emoção ou evento do seu dia você gostaria de conversar?'
        });
        _errorMessage = null; // Limpa qualquer erro residual
        _isLoading = false; // Garante que não está em estado de loading
      });
      _scrollToBottom(); // Rola para o topo (ou fim, com reverse: true)
    }
  }
  // ---- Fim Limpar Chat ----

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty || _isLoading || _model == null) return;

    final userMessage = text.trim();
    _textController.clear();

    setState(() {
      _messages.insert(0, {'role': 'user', 'text': userMessage});
      _isLoading = true;
      _errorMessage = null;
    });
    _scrollToBottom();

    try {
        // ... (construção do histórico e chamada da API)
         final reversedHistory = _messages.reversed.toList();
         List<Content> chatHistoryForAPI = reversedHistory
             .where((m) => m['role'] != 'error')
             .map((m) => Content(m['role']!, [TextPart(m['text']!)]))
             .toList();

         String contextInstructions = "Seja um assistente de diário amigável e empático.\n";
         if (_diaryEntries.isNotEmpty) {
             final recentEntries = _diaryEntries.take(3).toList();
             contextInstructions += "\nContexto recente do diário do usuário (use se relevante para a conversa):\n";
             for (var entry in recentEntries) {
                 String formattedDate = DateFormat('dd/MM/yyyy').format(entry.date);
                 String safeContent = entry.content.replaceAll('\n', ' ');
                 contextInstructions += "- $formattedDate: Humor ${entry.mood}, Notas: $safeContent\n";
             }
             contextInstructions += "\n-----\n";
         }

         if (chatHistoryForAPI.isNotEmpty && chatHistoryForAPI.last.role == 'user') {
             final lastUserContent = chatHistoryForAPI.removeLast();
             final originalUserText = (lastUserContent.parts.first as TextPart).text;
             chatHistoryForAPI.add(Content('user', [TextPart(contextInstructions + originalUserText)]));
         } else {
              chatHistoryForAPI.add(Content('user', [TextPart(userMessage)]));
         }

         final response = await _model!.generateContent(chatHistoryForAPI);

         final botResponse = response.text;
         if (botResponse == null || botResponse.isEmpty) {
             throw Exception('Recebi uma resposta vazia da IA.');
         }

         setState(() {
            // Garante inserção no início
            _messages.insert(0, {'role': 'model', 'text': botResponse});
         });
    } catch (e) {
         final errorText = 'Erro ao obter resposta: ${e.toString()}';
         setState(() {
             // Garante inserção no início
            _messages.insert(0, {'role': 'error', 'text': errorText});
             _errorMessage = errorText;
         });
    } finally {
         setState(() {
             _isLoading = false;
         });
         _scrollToBottom();
    }
  }

  @override
  Widget build(BuildContext context) {
    // ---- Persistência: Chamar super.build ----
    // super.build(context); // <-- REMOVIDO

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat com IA'),
          flexibleSpace: Container(
           decoration: BoxDecoration(
             gradient: LinearGradient(
              colors: [
                Theme.of(context).colorScheme.primaryContainer,
                Theme.of(context).colorScheme.secondaryContainer,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        actions: [
          // ---- Botão Limpar Chat ----
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Limpar Conversa',
            onPressed: _clearChat, // Chama a nova função
          ),
          // ---- Fim Botão Limpar Chat ----
        ],
      ),
      body: Column(
        children: [
          // Mensagem de erro ou de busca de entradas no topo?
          if (_errorMessage != null && _messages.length <= 1) // Só mostra erro inicial grave
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(_errorMessage!, style: TextStyle(color: Colors.red)),
            ),
          if (_isFetchingEntries && _diaryEntries.isEmpty)
             Padding(
               padding: const EdgeInsets.all(8.0),
               child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  SizedBox(height: 12, width: 12, child: CircularProgressIndicator(strokeWidth: 2)),
                  SizedBox(width: 8), Text('Buscando contexto do diário...')
               ]),
             ),

          Expanded(
            child: _buildMessagesList(),
          ),
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildMessagesList() {
     // Não precisa mais checar _errorMessage aqui, pois é mostrado acima ou como bolha

     return ListView.builder(
       controller: _scrollController,
       reverse: true, // <-- Inverte a lista, comum em chats
       padding: const EdgeInsets.symmetric(vertical: 10.0), // Add padding
       itemCount: _messages.length,
       itemBuilder: (context, index) {
          final message = _messages[index];
          // Adiciona indicador de carregamento ACIMA da caixa de texto (index 0)
          // quando _isLoading é true e a última mensagem NÃO é um erro.
          bool isLastMessage = index == 0;
          bool lastMessageIsError = _messages.isNotEmpty && _messages.first['role'] == 'error';

          if (_isLoading && isLastMessage && !lastMessageIsError) {
              // Mostra a bolha da mensagem do usuário E o indicador abaixo dela
              return Column(
                 crossAxisAlignment: message['role'] == 'user' ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                 children: [
                    _buildMessageBubble(message),
                    const Align(
                        alignment: Alignment.centerLeft,
                        child: Padding(
                          padding: EdgeInsets.only(left: 15.0, top: 5.0),
                          child: SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                       )
                    )
                 ]
              );
          }
          return _buildMessageBubble(message);
       },
     );
  }

  Widget _buildMessageBubble(Map<String, String> message) {
    bool isUser = message['role'] == 'user';
    bool isError = message['role'] == 'error';
    // Usar cores dos containers do tema
    Color bubbleColor = isError
        ? Colors.red.shade100
        : isUser
            ? Theme.of(context).colorScheme.primaryContainer
            : Theme.of(context).colorScheme.secondaryContainer;
    Color textColor = isError
        ? Colors.red.shade900
        : isUser
            ? Theme.of(context).colorScheme.onPrimaryContainer
            : Theme.of(context).colorScheme.onSecondaryContainer;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 5.0, horizontal: 10.0),
        padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 15.0),
        decoration: BoxDecoration(
          color: bubbleColor,
          borderRadius: BorderRadius.circular(15.0),
        ),
        child: Text(
          message['text']!,
          style: TextStyle(color: textColor),
        ),
      ),
    );
  }

  Widget _buildInputArea() {
    // Mostrar input mesmo se _apiKey for null inicialmente, pois _initializeChat trata o erro
    // Apenas desabilitar se _isLoading geral (inicialização)
    bool canSend = !_isLoading && !_isFetchingEntries; // Pode enviar se não estiver carregando nem buscando entradas

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _textController,
              enabled: canSend, // Habilita/desabilita
              decoration: InputDecoration(
                hintText: _isLoading ? 'Aguarde...' : 'Digite sua mensagem...', // Feedback no hint
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25.0),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey[200],
                contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
              ),
              onSubmitted: canSend ? _sendMessage : null,
            ),
          ),
          const SizedBox(width: 8.0),
          IconButton(
            icon: _isLoading
                 ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) // Icone de loading no botão
                 : const Icon(Icons.send),
            onPressed: canSend ? () => _sendMessage(_textController.text) : null,
            style: IconButton.styleFrom(
               backgroundColor: canSend ? Theme.of(context).colorScheme.primary : Colors.grey,
               foregroundColor: Colors.white,
               padding: const EdgeInsets.all(12),
               shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)) // Botão redondo
            ),
            tooltip: 'Enviar Mensagem',
          ),
        ],
      ),
    );
  }

 @override
 void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
 }
} 