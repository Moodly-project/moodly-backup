import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:moodyr/models/diary_entry_model.dart';

class ChatScreen extends StatefulWidget {
  

  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController(); 
  final List<Map<String, dynamic>> _messages = [];
  List<DiaryEntry> _diaryEntries = []; 
  bool _isLoading = false;
  bool _isFetchingEntries = false;
  String? _errorMessage;
  String? _apiKey;
  GenerativeModel? _model;

  final _storage = const FlutterSecureStorage();
  final String _apiBaseUrl = 'http://10.0.2.2:3000/api'; // URL da DiaryScreen

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
      _fetchEntries();

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

    // Lista de humores válidos para detecção
    const List<String> validMoods = ['Feliz', 'Ansioso', 'Calmo', 'Triste', 'Animado', 'Grato', 'Com Raiva'];
    
    // Verificar se o usuário está respondendo apenas com um humor
    bool isMoodResponse = false;
    String? detectedMood;
    
    // Verificar se o texto do usuário corresponde exatamente a um humor (ignorando caso)
    for (var mood in validMoods) {
      if (userMessage.toLowerCase().trim() == mood.toLowerCase()) {
        detectedMood = mood;
        isMoodResponse = true;
        break;
      }
    }
    
    // Verificar se alguma mensagem anterior da IA estava perguntando sobre humor
    bool previousMessageAskedForMood = false;
    for (var msg in _messages) {
      if (msg['askingMood'] == true) {
        previousMessageAskedForMood = true;
        
        // Marcar a mensagem como processada
        setState(() {
          msg['askingMood'] = false;
        });
        break;
      }
    }
    
    // Se foi uma resposta de humor para uma pergunta da IA
    if (isMoodResponse && previousMessageAskedForMood && detectedMood != null) {
      setState(() {
        _messages.insert(0, {'role': 'user', 'text': userMessage});
        _isLoading = false; // Não vamos fazer uma consulta à IA neste caso
      });
      _scrollToBottom();
      
      // Solicitar ao usuário a descrição da entrada
      setState(() {
        _messages.insert(0, {
          'role': 'model',
          'text': 'Por favor, escreva o que deseja adicionar na descrição desta entrada. Se quiser adicionar uma entrada para uma data anterior (até um mês atrás), mencione a data no formato "dia/mês/ano" no início da sua mensagem.',
          'isConfirmation': false,
          'awaitingDescription': true,
          'pendingMood': detectedMood,
        });
      });
      _scrollToBottom();
      return;
    }

    // Verificar se estamos aguardando uma descrição para uma entrada
    bool awaitingDescription = false;
    String? pendingMood;
    
    for (var msg in _messages) {
      if (msg['awaitingDescription'] == true) {
        awaitingDescription = true;
        pendingMood = msg['pendingMood'];
        
        // Marcar a mensagem como processada
        setState(() {
          msg['awaitingDescription'] = false;
        });
        break;
      }
    }

    setState(() {
      _messages.insert(0, {'role': 'user', 'text': userMessage});
      _isLoading = true;
      _errorMessage = null;
    });
    _scrollToBottom();

    // Se estamos aguardando descrição, processar diretamente
    if (awaitingDescription && pendingMood != null) {
      setState(() {
        _isLoading = false;
      });
      
      // Verificar se contém data retroativa no formato dia/mês/ano
      DateTime? customDate;
      
      // Primeira expressão: dia/mês/ano ou dia-mês-ano
      final dateRegexFormal = RegExp(r'(\d{1,2})[/\-](\d{1,2})[/\-](\d{4})');
      final dateMatchFormal = dateRegexFormal.firstMatch(userMessage);
      
      // Segunda expressão: "dia X de mês"
      final months = {
        'janeiro': 1, 'fevereiro': 2, 'março': 3, 'abril': 4, 'maio': 5, 
        'junho': 6, 'julho': 7, 'agosto': 8, 'setembro': 9, 'outubro': 10, 
        'novembro': 11, 'dezembro': 12
      };
      
      final dateRegexNatural = RegExp(r'dia\s+(\d{1,2})\s+(?:de\s+)?([a-zç]+)');
      final dateMatchNatural = dateRegexNatural.firstMatch(userMessage.toLowerCase());
      
      // Terceira expressão: "ontem" ou "ontem dia X"
      final dateRegexYesterday = RegExp(r'ontem(?:\s+dia\s+(\d{1,2}))?');
      final dateMatchYesterday = dateRegexYesterday.firstMatch(userMessage.toLowerCase());
      
      // Quarta expressão: apenas "dia X" (contexto amplo)
      final dateRegexDayOnly = RegExp(r'dia\s+(\d{1,2})');
      final dateMatchDayOnly = dateRegexDayOnly.firstMatch(userMessage.toLowerCase());
      
      if (dateMatchFormal != null) {
        try {
          final day = int.parse(dateMatchFormal.group(1)!);
          final month = int.parse(dateMatchFormal.group(2)!);
          final year = int.parse(dateMatchFormal.group(3)!);
          
          customDate = DateTime(year, month, day);
        } catch (e) {
          customDate = null;
        }
      } else if (dateMatchNatural != null) {
        try {
          final day = int.parse(dateMatchNatural.group(1)!);
          final monthText = dateMatchNatural.group(2)!;
          int? month;
          
          for (var entry in months.entries) {
            if (monthText.contains(entry.key)) {
              month = entry.value;
              break;
            }
          }
          
          if (month != null) {
            final year = DateTime.now().year;  // Assumir ano atual
            customDate = DateTime(year, month, day);
          }
        } catch (e) {
          customDate = null;
        }
      } else if (dateMatchYesterday != null) {
        final yesterday = DateTime.now().subtract(const Duration(days: 1));
        if (dateMatchYesterday.group(1) != null) {
          try {
            // "ontem dia X" - usar o dia especificado no mês/ano atual
            final day = int.parse(dateMatchYesterday.group(1)!);
            customDate = DateTime(yesterday.year, yesterday.month, day);
          } catch (e) {
            customDate = yesterday;  // Fallback para ontem
          }
        } else {
          customDate = yesterday;  // Apenas "ontem"
        }
      } else if (dateMatchDayOnly != null) {
        try {
          final day = int.parse(dateMatchDayOnly.group(1)!);
          final now = DateTime.now();
          
          // Usar o mês e ano atuais
          customDate = DateTime(now.year, now.month, day);
          
          // Se a data calculada estiver no futuro, assumir mês anterior
          if (customDate.isAfter(now)) {
            if (now.month > 1) {
              customDate = DateTime(now.year, now.month - 1, day);
            } else {
              customDate = DateTime(now.year - 1, 12, day);
            }
          }
        } catch (e) {
          customDate = null;
        }
      }
      
      // Verificar se a data está dentro do limite de 1 mês
      if (customDate != null) {
        final oneMonthAgo = DateTime.now().subtract(const Duration(days: 30));
        if (customDate.isBefore(oneMonthAgo)) {
          // Data muito antiga, informar ao usuário
          setState(() {
            _messages.insert(0, {
              'role': 'model',
              'text': 'Desculpe, só posso adicionar entradas retroativas de até 1 mês atrás. Vou adicionar a entrada com a data de hoje.',
              'isConfirmation': false
            });
          });
          customDate = null; // Resetar para usar a data atual
        }
      }
      
      // Extrair o conteúdo sem a data (se houver uma data no início)
      String content = userMessage;
      
      // Tentativa de limpeza de menções explícitas à data
      if (dateMatchFormal != null) {
        content = userMessage.replaceFirst(dateMatchFormal.group(0)!, '').trim();
      }
      if (dateMatchNatural != null) {
        // Remove "dia X de mês" da mensagem
        String pattern = dateMatchNatural.group(0)!;
        content = content.replaceAll(RegExp(pattern, caseSensitive: false), '').trim();
      }
      if (dateMatchYesterday != null) {
        // Remove "ontem" ou "ontem dia X" da mensagem
        String pattern = dateMatchYesterday.group(0)!;
        content = content.replaceAll(RegExp(pattern, caseSensitive: false), '').trim();
      }
      if (dateMatchDayOnly != null && customDate != null) {
        // Tentar remover a menção ao dia se temos certeza sobre a data
        String pattern = dateMatchDayOnly.group(0)!;
        content = content.replaceAll(RegExp(pattern, caseSensitive: false), '').trim();
      }
      
      // Limpar múltiplos espaços e possíveis vírgulas/pontos iniciais após a limpeza
      content = content.replaceAll(RegExp(r'\s+'), ' ').trim();
      content = content.replaceAll(RegExp(r'^[,\.\s]+'), '').trim();
      
      if (content.isEmpty) {
        content = 'Entrada adicionada via chat IA.';
      }
      
      // Adicionar a entrada com o conteúdo fornecido pelo usuário
      _addDiaryEntryFromChat(pendingMood, content, customDate);
      return;
    }

    try {
      // Construir o histórico da conversa para o prompt
      final reversedHistory = _messages.reversed.toList();
      List<Content> chatHistoryForAPI = reversedHistory
          .where((m) => m['role'] != 'error')
          .map((m) => Content(m['role']!, [TextPart(m['text']!)]))
          .toList();

      // **** INSTRUÇÕES PARA A IA ****
      String contextInstructions = """
Seja um assistente de diário amigável e empático.

Contexto recente do diário do usuário (use se relevante para a conversa):
""";
      if (_diaryEntries.isNotEmpty) {
        final recentEntries = _diaryEntries.take(3).toList();
        for (var entry in recentEntries) {
          String formattedDate = DateFormat('dd/MM/yyyy').format(entry.date);
          String safeContent = entry.content.replaceAll('\\n', ' ');
          contextInstructions += "- $formattedDate: Humor ${entry.mood}, Notas: $safeContent\\n";
        }
      } else {
        contextInstructions += "(Nenhuma entrada recente encontrada)\\n";
      }
      contextInstructions += """
-----
INSTRUÇÕES IMPORTANTES:

1. Se, na ÚLTIMA mensagem do usuário, ele expressar CLARAMENTE um dos seguintes humores como seu sentimento ATUAL:
[Feliz, Ansioso, Calmo, Triste, Animado, Grato, Com Raiva]
Então, RESPONDA à mensagem do usuário E, em seguida, pergunte EXPLICITAMENTE se ele gostaria de registrar essa emoção no diário.
Use OBRIGATORIAMENTE a frase: "Gostaria de adicionar uma entrada no diário sobre estar [Humor Detectado]?" substituindo [Humor Detectado] pelo nome exato do humor.

2. Se o usuário EXPLICITAMENTE solicitar adicionar uma entrada no diário com frases como:
   - "adicione isso ao meu diário"
   - "registre no diário"
   - "anote no diário"
   - "salve isso no diário"
   - "adicionar entrada no diário"
   - "quero adicionar no diário"
   - "coloque isso no meu diário"
   - ou variações semelhantes,
   
considere o seguinte formato ESPECIAL para responder:
[ADICIONAR_DIARIO]
Humor: [APENAS UM DESTES: Feliz, Ansioso, Calmo, Triste, Animado, Grato, Com Raiva]
Conteúdo: [Breve descrição do que o usuário relatou, baseado na conversa atual]
[/ADICIONAR_DIARIO]

Não use o formato ADICIONAR_DIARIO a menos que o usuário tenha pedido EXPLICITAMENTE para adicionar ao diário.
Não faça suposições sobre o humor do usuário sem que ele tenha expressado claramente. 
Se o usuário não especificar o humor, pergunte qual humor ele está sentindo antes de adicionar a entrada.

Responda à última mensagem do usuário abaixo:
-----
""";
      // **** FIM DAS INSTRUÇÕES ****


      // Prepend context instructions to the *last* user message text
      if (chatHistoryForAPI.isNotEmpty && chatHistoryForAPI.last.role == 'user') {
          final lastUserContent = chatHistoryForAPI.removeLast();
          // Garantir que parts não esteja vazio e seja TextPart
          final originalUserText = (lastUserContent.parts.isNotEmpty && lastUserContent.parts.first is TextPart)
                                   ? (lastUserContent.parts.first as TextPart).text ?? ''
                                   : '';
          // Cria um novo Content com o contexto + texto original
          chatHistoryForAPI.add(Content('user', [TextPart(contextInstructions + originalUserText)]));
      } else {
         // Fallback improvável, mas seguro
          chatHistoryForAPI.add(Content('user', [TextPart(userMessage)]));
      }

      // Usando generateContent apenas com o histórico modificado
      final response = await _model!.generateContent(chatHistoryForAPI);

      final botResponse = response.text;
      if (botResponse == null || botResponse.isEmpty) {
        throw Exception('Recebi uma resposta vazia da IA.');
      }

      // ---- DETECÇÃO DA PERGUNTA DE CONFIRMAÇÃO E ADIÇÃO AUTOMÁTICA ----
      String? detectedMood;
      String? autoAddContent;
      String confirmationQuestionPrefix = "Gostaria de adicionar uma entrada no diário sobre estar ";
      String confirmationQuestionSuffix = "?";
      // Lista de humores válidos para extração
      const List<String> validMoods = ['Feliz', 'Ansioso', 'Calmo', 'Triste', 'Animado', 'Grato', 'Com Raiva'];

      String messageTextToShow = botResponse; // Texto padrão a ser exibido

      // Verificar se a IA quer adicionar automaticamente uma entrada
      final addDiaryRegex = RegExp(r'\[ADICIONAR_DIARIO\](.*?)\[/ADICIONAR_DIARIO\]', dotAll: true);
      final addDiaryMatch = addDiaryRegex.firstMatch(botResponse);
      
      if (addDiaryMatch != null && addDiaryMatch.groupCount >= 1) {
        final diaryContent = addDiaryMatch.group(1)!.trim();
        
        // Extrair humor e conteúdo
        final humorRegex = RegExp(r'Humor:\s*(Feliz|Ansioso|Calmo|Triste|Animado|Grato|Com Raiva)', caseSensitive: false);
        final contentRegex = RegExp(r'Conteúdo:\s*(.*?)($|\n)', dotAll: true);
        
        final humorMatch = humorRegex.firstMatch(diaryContent);
        final contentMatch = contentRegex.firstMatch(diaryContent);
        
        if (humorMatch != null && contentMatch != null) {
          detectedMood = humorMatch.group(1);
          autoAddContent = contentMatch.group(1)?.trim();
          
          // Remover o bloco [ADICIONAR_DIARIO] do texto a ser exibido
          messageTextToShow = botResponse.replaceAll(addDiaryMatch.group(0)!, '').trim();
          
          // Se o texto estiver vazio após a remoção, adicionar uma mensagem padrão
          if (messageTextToShow.isEmpty) {
            messageTextToShow = "Vou adicionar essa entrada no seu diário.";
          }
          
          // Adicionar a entrada automaticamente
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _addDiaryEntryFromChat(detectedMood!, autoAddContent, null);
          });
        }
      } else {
        // Verificar se é uma pergunta de confirmação (comportamento anterior)
        final regex = RegExp(r"Gostaria de adicionar uma entrada no diário sobre estar (\w+)\?");
        final match = regex.firstMatch(botResponse);

        if (match != null && match.groupCount >= 1) {
          String potentialMood = match.group(1)!;
          // Verificar se o humor extraído está na lista válida
          if (validMoods.contains(potentialMood)) {
            detectedMood = potentialMood;
          }
        }
      }

      // Adicionar a mensagem à lista
      setState(() {
          Map<String, dynamic> newMessageData = {
              'role': 'model',
              'text': messageTextToShow, // Texto principal da IA
              'isConfirmation': detectedMood != null && autoAddContent == null, // É uma pergunta de confirmação?
              'mood': detectedMood, // Humor detectado (null se não for confirmação)
              'pendingConfirmation': detectedMood != null && autoAddContent == null, // Ainda aguarda clique Sim/Não?
              'awaitingDescription': detectedMood != null && autoAddContent == null, // Aguardando descrição?
              'pendingMood': detectedMood, // Humor aguardado para adição
          };
          
          // Verificar se é uma resposta onde a IA está perguntando sobre o humor
          bool isAskingMood = messageTextToShow.contains("Qual humor você está sentindo?") || 
                              messageTextToShow.contains("Que humor você está sentindo?") ||
                              messageTextToShow.contains("Como você se sente?") || 
                              messageTextToShow.contains("Qual é o seu humor?");
                              
          if (isAskingMood) {
            // Marcar a mensagem para processamento especial na resposta do usuário
            newMessageData['askingMood'] = true;
          }
          
          _messages.insert(0, newMessageData);
      });
      // ---- FIM DA DETECÇÃO ----

    } catch (e) {
      final errorText = 'Erro ao obter resposta: ${e.toString()}';
      setState(() {
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

  // Função para adicionar a entrada no diário
  Future<void> _addDiaryEntryFromChat(String mood, String? userContext, [DateTime? customDate]) async {
       // Mostrar um indicador de loading específico para esta ação
       setState(() {
         // Adiciona mensagem de feedback
          _messages.insert(0, {'role': 'model', 'text': 'Adicionando entrada...', 'isConfirmation': false});
          _scrollToBottom();
       });

      try {
         final headers = await _getHeaders();
         
         // Usar data personalizada ou data atual
         final DateTime entryDate = customDate ?? DateTime.now();
         final formattedDate = DateFormat('yyyy-MM-dd').format(entryDate);
         
         // Determinar o conteúdo da entrada
         final content = userContext != null && userContext.isNotEmpty
             ? userContext
             : 'Registrado via chat IA.';

         final response = await http.post(
           Uri.parse('$_apiBaseUrl/diary'),
           headers: headers,
           body: jsonEncode({
             'conteudo': content,
             'humor': mood,
             'data_entrada': formattedDate,
           }),
         );

         if (!mounted) return;

         if (response.statusCode == 201) {
             // Remover mensagem "Adicionando..." e adicionar sucesso
             setState(() {
                 _messages.removeAt(0); // Remove "Adicionando..."
                 _messages.insert(0, {'role': 'model', 'text': 'Entrada de humor "$mood" adicionada com sucesso!', 'isConfirmation': false});
             });
             
             // Recarregar entradas do diário para manter o contexto atualizado
             _fetchEntries();
         } else {
            final responseBody = jsonDecode(response.body);
            final errorMsg = responseBody['message'] ?? 'Falha ao adicionar entrada via chat.';
             setState(() {
                _messages.removeAt(0); // Remove "Adicionando..."
               _messages.insert(0, {'role': 'error', 'text': 'Erro ao adicionar: $errorMsg', 'isConfirmation': false});
             });
         }
      } catch (e) {
         if (!mounted) return;
         setState(() {
              _messages.removeAt(0); // Remove "Adicionando..."
             _messages.insert(0, {'role': 'error', 'text': 'Erro de conexão ao adicionar: ${e.toString()}', 'isConfirmation': false});
         });
      } finally {
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

  Widget _buildMessageBubble(Map<String, dynamic> message) {
    bool isUser = message['role'] == 'user';
    bool isError = message['role'] == 'error';
    bool isConfirmation = message['isConfirmation'] == true && message['pendingConfirmation'] == true;
    bool isAwaitingDescription = message['awaitingDescription'] == true;
    String? mood = message['mood'];
    
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message['text']!,
              style: TextStyle(color: textColor),
            ),
            // Se for uma mensagem de confirmação, mostrar botões
            if (isConfirmation)
              Padding(
                padding: const EdgeInsets.only(top: 10.0),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        // Marcar esta mensagem como não pendente de confirmação
                        setState(() {
                          message['pendingConfirmation'] = false;
                        });
                        
                        // Solicitar ao usuário que escreva a descrição
                        _messages.insert(0, {
                          'role': 'model', 
                          'text': 'Por favor, escreva o que deseja adicionar na descrição desta entrada. Se quiser adicionar uma entrada para uma data anterior (até um mês atrás), mencione a data no formato "dia/mês/ano" no início da sua mensagem.',
                          'isConfirmation': false,
                          'awaitingDescription': true,
                          'pendingMood': mood,
                        });
                        _scrollToBottom();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Theme.of(context).colorScheme.onPrimary,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        textStyle: const TextStyle(fontSize: 12),
                      ),
                      child: const Text('Sim'),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton(
                      onPressed: () {
                        // Apenas marcar como não pendente de confirmação
                        setState(() {
                          message['pendingConfirmation'] = false;
                        });
                        
                        // Resposta opcional da IA
                        _messages.insert(0, {
                          'role': 'model', 
                          'text': 'Ok, não vou adicionar uma entrada sobre isto. Em que mais posso ajudar?',
                          'isConfirmation': false
                        });
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Theme.of(context).colorScheme.primary,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        textStyle: const TextStyle(fontSize: 12),
                      ),
                      child: const Text('Não'),
                    ),
                  ],
                ),
              ),
          ],
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