import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:moodyr/models/diary_entry_model.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:moodyr/screens/report/report_screen.dart';
import 'package:moodyr/screens/auth/login_screen.dart';
import 'package:moodyr/screens/ai/ai_screen.dart';
import 'package:moodyr/screens/ai/chat_screen.dart';
import 'package:moodyr/services/api_config_service.dart';

class DiaryScreen extends StatefulWidget {
  const DiaryScreen({super.key});

  @override
  State<DiaryScreen> createState() => _DiaryScreenState();
}

class _DiaryScreenState extends State<DiaryScreen> {
  List<DiaryEntry> _diaryEntries = []; // Começa vazia
  bool _isLoading = true; // Estado para carregamento inicial
  String? _errorMessage; // Estado para mensagens de erro
  final _storage = const FlutterSecureStorage(); // Instância do secure storage
  final _apiConfigService = ApiConfigService();

  // URL Base da API (ajuste conforme necessário)
  // 10.0.2.2 emulador Android
  final String _apiBaseUrl = 'http://10.0.2.2:3000/api';

  // ícones para humores
  final Map<String, IconData> _moodIcons = {
    'Feliz': Icons.emoji_emotions,
    'Ansioso': Icons.upcoming,
    'Calmo': Icons.nightlight,
    'Triste': Icons.sentiment_very_dissatisfied,
    'Animado': Icons.celebration,
    'Grato': Icons.favorite,
    'Com Raiva': Icons.flash_on,
  };

  // cores para humores
  final Map<String, Color> _moodColors = {
    'Feliz': Colors.amber.shade500,
    'Ansioso': Colors.orange.shade600,
    'Calmo': Colors.blue.shade500,
    'Triste': Colors.indigo.shade500,
    'Animado': Colors.pink.shade500,
    'Grato': Colors.green.shade600,
    'Com Raiva': Colors.red.shade600,
  };

  @override
  void initState() {
    super.initState();
    _fetchEntries(); // Busca as entradas ao iniciar a tela
  }

  // Função auxiliar para obter o token JWT
  Future<String?> _getToken() async {
    return await _storage.read(key: 'jwt_token');
  }

  // Função auxiliar para criar headers com o token
  Future<Map<String, String>> _getHeaders() async {
    String? token = await _getToken();
    return {
      'Content-Type': 'application/json; charset=UTF-8',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // Buscar entradas da API
  Future<void> _fetchEntries() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final headers = await _getHeaders();
      final apiUrl = await _apiConfigService.getBaseUrl();
      final response = await http.get(
        Uri.parse('$apiUrl/diary'),
        headers: headers,
      );

      if (!mounted) return; // Verifica widget montado

      if (response.statusCode == 200) {
        List<dynamic> data = jsonDecode(response.body);
        setState(() {
          _diaryEntries = data.map((item) {
            // O backend retorna o ID como número, convertemos para String
            // A data vem como String 'YYYY-MM-DD', convertemos para DateTime
            return DiaryEntry(
              id: item['id'].toString(),
              content: item['conteudo'],
              date: DateTime.parse(item['data_entrada']),
              mood: item['humor'],
            );
          }).toList();
          _isLoading = false;
        });
      } else if (response.statusCode == 401 || response.statusCode == 403) {
         // logout ou redirecionamento para login se token inválido/expirado
        setState(() {
           _errorMessage = 'Sessão inválida. Por favor, faça login novamente.';
           _isLoading = false;
        });
        _logout();
      } else {
        final responseBody = jsonDecode(response.body);
        setState(() {
          _errorMessage = responseBody['message'] ?? 'Erro ao buscar entradas.';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Erro de conexão ou ao processar dados: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  // Logout e navegação para tela de login
  Future<void> _logout() async {
    await _storage.delete(key: 'jwt_token');
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const LoginScreen())
    );
  }

  // Adicionar entrada via API
  Future<void> _addEntry(DiaryEntry entry) async {
    try {
      final headers = await _getHeaders();
      final apiUrl = await _apiConfigService.getBaseUrl();
      final formattedDate = DateFormat('yyyy-MM-dd').format(entry.date);
      
      final response = await http.post(
        Uri.parse('$apiUrl/diary'),
        headers: headers,
        body: jsonEncode({
          'conteudo': entry.content,
          'data_entrada': formattedDate,
          'humor': entry.mood,
        }),
      );

      if (!mounted) return;

       if (response.statusCode == 201) {
          _fetchEntries(); // Recarrega as entradas após adicionar
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Entrada adicionada com sucesso!'), backgroundColor: Colors.green)
          );
      } else {
         final responseBody = jsonDecode(response.body);
         _showErrorSnackbar(responseBody['message'] ?? 'Falha ao adicionar entrada.');
      }
    } catch (e) {
       if (!mounted) return;
       _showErrorSnackbar('Erro ao conectar com o servidor: ${e.toString()}');
    }
  }

  // Atualizar entrada via API
  Future<void> _updateEntry(DiaryEntry updatedEntry) async {
     try {
       final headers = await _getHeaders();
       final formattedDate = DateFormat('yyyy-MM-dd').format(updatedEntry.date);

       final response = await http.put(
         Uri.parse('$_apiBaseUrl/diary/${updatedEntry.id}'), // Passa o ID na URL
         headers: headers,
         body: jsonEncode({
           'conteudo': updatedEntry.content,
           'humor': updatedEntry.mood,
           'data_entrada': formattedDate,
         }),
       );
        if (!mounted) return;

       if (response.statusCode == 200) {
          _fetchEntries(); // Recarrega as entradas após atualizar
           ScaffoldMessenger.of(context).showSnackBar(
               const SnackBar(content: Text('Entrada atualizada com sucesso!'), backgroundColor: Colors.green)
           );
       } else {
          final responseBody = jsonDecode(response.body);
           _showErrorSnackbar(responseBody['message'] ?? 'Falha ao atualizar entrada.');
       }
    } catch (e) {
        if (!mounted) return;
       _showErrorSnackbar('Erro ao conectar com o servidor: ${e.toString()}');
    }
  }

  // Deletar entrada via API
  Future<void> _deleteEntry(String id) async {
     // Mostrar diálogo de confirmação PRIMEIRO
     bool? confirmDelete = await showDialog<bool>(
       context: context,
       builder: (BuildContext ctx) {
         return AlertDialog(
           title: const Text('Confirmar Exclusão'),
           content: const Text('Tem certeza que deseja excluir esta entrada?'),
           actions: <Widget>[
             TextButton(
               child: const Text('Cancelar'),
               onPressed: () {
                 Navigator.of(ctx).pop(false);
               },
             ),
             TextButton(
               style: TextButton.styleFrom(foregroundColor: Colors.red),
               child: const Text('Excluir'),
               onPressed: () {
                 Navigator.of(ctx).pop(true);
               },
             ),
           ],
         );
       },
     );

      // não confirmou, não fazer nada
     if (confirmDelete != true) {
       return;
     }

     // confirmou, prosseguir
     try {
        final headers = await _getHeaders();
        final apiUrl = await _apiConfigService.getBaseUrl();
        final response = await http.delete(
         Uri.parse('$apiUrl/diary/$id'), // Passa o ID na URL
         headers: headers,
       );

        if (!mounted) return;

       if (response.statusCode == 200) {
         _fetchEntries(); // Recarrega as entradas após deletar
          ScaffoldMessenger.of(context).showSnackBar(
             const SnackBar(content: Text('Entrada excluída com sucesso!'), backgroundColor: Colors.orange)
          );
       } else {
          final responseBody = jsonDecode(response.body);
          _showErrorSnackbar(responseBody['message'] ?? 'Falha ao excluir entrada.');
       }
     } catch (e) {
         if (!mounted) return;
        _showErrorSnackbar('Erro ao conectar com o servidor: ${e.toString()}');
     }
  }

  // Função auxiliar para mostrar SnackBar de erro
  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showAddEditEntrySheet({DiaryEntry? entry}) {
    final _contentController = TextEditingController(text: entry?.content ?? '');
    DateTime _selectedDate = entry?.date ?? DateTime.now();
    String? _selectedMood = entry?.mood;
    final _formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25.0)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Container(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                top: 20,
                left: 20,
                right: 20,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).colorScheme.primaryContainer,
                    Theme.of(context).colorScheme.secondaryContainer,
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: Form( // Envolve com um Form
                key: _formKey, // Associa a chave
                child: SingleChildScrollView(
                   child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Center(
                        child: Container(
                          height: 4,
                          width: 60,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade400,
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Center(
                        child: Text(
                          entry == null ? 'Como você está hoje?' : 'Revisando seu dia',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary
                          ),
                        ),
                      ),
                      const SizedBox(height: 30),
                      Text('Data:', style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary.withOpacity(0.8)
                      )),
                      Card(
                        elevation: 0,
                        color: Colors.white70,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: ListTile(
                            leading: Icon(Icons.calendar_today, color: Theme.of(context).colorScheme.primary),
                            title: Text(
                              DateFormat('EEEE, dd MMMM yyyy', 'pt_BR').format(_selectedDate),
                              style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color)
                            ),
                            onTap: () async {
                              final DateTime? picked = await showDatePicker(
                                context: context,
                                initialDate: _selectedDate,
                                firstDate: DateTime(2000),
                                lastDate: DateTime.now(),
                                builder: (context, child) {
                                  return Theme(
                                    data: Theme.of(context).copyWith(
                                      colorScheme: ColorScheme.light(
                                        primary: Theme.of(context).colorScheme.primary,
                                        onPrimary: Colors.white,
                                        surface: Theme.of(context).colorScheme.surface,
                                        onSurface: Theme.of(context).colorScheme.onSurface,
                                      ),
                                      textButtonTheme: TextButtonThemeData(
                                        style: TextButton.styleFrom(
                                          foregroundColor: Theme.of(context).colorScheme.primary,
                                        ),
                                      ),
                                    ),
                                    child: child!,
                                  );
                                },
                              );
                              if (picked != null && picked != _selectedDate) {
                                setModalState(() {
                                  _selectedDate = picked;
                                });
                              }
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text('Humor:', style: Theme.of(context).textTheme.titleMedium?.copyWith(
                         fontWeight: FontWeight.bold,
                         color: Theme.of(context).colorScheme.primary.withOpacity(0.8)
                      )),
                      Card(
                         elevation: 0,
                         color: Colors.white70,
                         shape: RoundedRectangleBorder(
                           borderRadius: BorderRadius.circular(15),
                         ),
                         child: Padding(
                           padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                           child: DropdownButtonFormField<String>(
                              value: _selectedMood,
                              items: _moodIcons.keys.map((String mood) {
                                 return DropdownMenuItem<String>(
                                   value: mood,
                                   child: Row(
                                     children: [
                                       Icon(_moodIcons[mood], color: _moodColors[mood], size: 20),
                                       const SizedBox(width: 10),
                                       Text(mood),
                                     ],
                                   ),
                                 );
                              }).toList(),
                              onChanged: (String? newValue) {
                                if (newValue != null) {
                                  setModalState(() {
                                    _selectedMood = newValue;
                                  });
                                }
                              },
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.zero,
                              ),
                              validator: (value) => value == null ? 'Por favor, selecione um humor' : null,
                              icon: Icon(Icons.arrow_drop_down, color: Theme.of(context).colorScheme.primary),
                           ),
                         ),
                       ),
                      const SizedBox(height: 20),
                      Text('Diário:', style: Theme.of(context).textTheme.titleMedium?.copyWith(
                         fontWeight: FontWeight.bold,
                         color: Theme.of(context).colorScheme.primary.withOpacity(0.8)
                      )),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(15),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 3,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                        child: TextFormField(
                          controller: _contentController,
                          maxLines: 5,
                          decoration: InputDecoration(
                            hintText: 'Escreva sobre seus sentimentos e experiências...',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(15),
                              borderSide: BorderSide.none,
                            ),
                            filled: true,
                            fillColor: Colors.transparent,
                            contentPadding: const EdgeInsets.all(16),
                          ),
                          validator: (value) => value == null || value.isEmpty ? 'Por favor, compartilhe seus pensamentos' : null,
                          style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
                        ),
                      ),
                      const SizedBox(height: 30),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Cancelar'),
                            style: TextButton.styleFrom(
                              foregroundColor: Theme.of(context).colorScheme.secondary,
                            ),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton(
                            onPressed: () {
                              if (_formKey.currentState!.validate()) {
                                final newEntry = DiaryEntry(
                                  id: entry?.id ?? '',
                                  content: _contentController.text,
                                  date: _selectedDate,
                                  mood: _selectedMood!,
                                );
                                if (entry == null) {
                                  _addEntry(newEntry);
                                } else {
                                  _updateEntry(newEntry);
                                }
                                Navigator.pop(context);
                              }
                            },
                             style: ElevatedButton.styleFrom(
                              backgroundColor: Theme.of(context).colorScheme.primary,
                              foregroundColor: Colors.white,
                            ),
                            child: Text(entry == null ? 'Salvar Entrada' : 'Atualizar Entrada'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          }
        );
      },
    );
  }

  // Navegar para a tela de relatórios
  void _navigateToReportScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ReportScreen()),
    );
  }

  // Navegar para a tela da IA
  void _navigateToAIScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AIScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Meu Diário de Emoções', style: TextStyle(fontWeight: FontWeight.bold)),
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
         elevation: 0,
         actions: [
           // Botão para tela da IA
           IconButton(
             icon: const Icon(Icons.psychology_outlined),
             tooltip: 'Assistente IA',
             onPressed: _navigateToAIScreen,
           ),
           // Botão para tela de relatórios
           IconButton(
             icon: const Icon(Icons.bar_chart),
             tooltip: 'Ver relatórios',
             onPressed: _navigateToReportScreen,
           ),
           // NOVO Ícone para Chat IA
           IconButton(
             icon: const Icon(Icons.chat_bubble_outline),
             tooltip: 'Chat com IA',
             onPressed: () {
               Navigator.of(context).push(
                 MaterialPageRoute(builder: (_) => const ChatScreen()),
               );
             },
           ),
           // Botão de logout
           IconButton(
             icon: const Icon(Icons.logout),
             tooltip: 'Sair',
             onPressed: _logout,
           ),
         ],
      ),
      body: RefreshIndicator(
         onRefresh: _fetchEntries,
         child: Container(
           decoration: BoxDecoration(
             gradient: LinearGradient(
                colors: [
                 Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
                 Theme.of(context).colorScheme.secondaryContainer.withOpacity(0.3),
               ],
               begin: Alignment.topCenter,
               end: Alignment.bottomCenter,
              ),
           ),
           child: _buildBody(),
         ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddEditEntrySheet(),
        tooltip: 'Adicionar Entrada',
        backgroundColor: Theme.of(context).colorScheme.primary,
        child: const Icon(Icons.add, color: Colors.white),
        elevation: 4,
      ),
    );
  }

  // Método para construir o corpo da tela baseado no estado
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
                 Icon(Icons.error_outline, color: Colors.red.shade400, size: 60),
                 const SizedBox(height: 16),
                 Text(_errorMessage!, textAlign: TextAlign.center, style: TextStyle(color: Colors.red.shade700, fontSize: 16)),
                 const SizedBox(height: 16),
                 ElevatedButton.icon(
                   icon: const Icon(Icons.refresh),
                   label: const Text('Tentar Novamente'),
                   onPressed: _fetchEntries,
                   style: ElevatedButton.styleFrom(
                     backgroundColor: Theme.of(context).colorScheme.primary,
                     foregroundColor: Colors.white,
                     padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                   ),
                 )
             ]
          ),
        )
      );
    } else if (_diaryEntries.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.book_outlined, size: 80, color: Theme.of(context).colorScheme.secondary.withOpacity(0.5)),
              const SizedBox(height: 24),
              Text(
                'Seu diário está vazio',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary),
              ),
              const SizedBox(height: 12),
              Text(
                'Registre como você se sente hoje tocando no botão abaixo',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Theme.of(context).colorScheme.secondary),
              ),
              const SizedBox(height: 40),
              ElevatedButton.icon(
                icon: const Icon(Icons.add),
                label: const Text('Nova entrada'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                ),
                onPressed: () => _showAddEditEntrySheet(),
              ),
            ],
          ),
        ),
      );
    } else {
      // Lista de entradas
      return Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12.0),
            margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 5.0),
            decoration: BoxDecoration(
              color: Colors.orange.shade100,
              borderRadius: BorderRadius.circular(10.0),
            ),
            child: Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: Colors.orange.shade700),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    "Lembre-se: as análises de humor são geradas por IA e podem não ser precisas. Não as leve ao pé da letra.",
                    style: TextStyle(color: Color(0xFFE65100)), // Colors.orange.shade900
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(12.0),
              itemCount: _diaryEntries.length,
              itemBuilder: (context, index) {
          final entry = _diaryEntries[index];
          final moodColor = _moodColors[entry.mood] ?? Colors.grey;
          
          return Card(
             margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 5.0),
             elevation: 2,
             shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18.0)),
             child: Container(
               decoration: BoxDecoration(
                 borderRadius: BorderRadius.circular(18.0),
                 gradient: LinearGradient(
                   colors: [
                     Colors.white,
                     moodColor.withOpacity(0.1),
                   ],
                   begin: Alignment.topLeft,
                   end: Alignment.bottomRight,
                 ),
               ),
               child: Column(
                 crossAxisAlignment: CrossAxisAlignment.start,
                 children: [
                   Container(
                     padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                     decoration: BoxDecoration(
                       color: moodColor.withOpacity(0.15),
                       borderRadius: const BorderRadius.only(
                         topLeft: Radius.circular(18),
                         topRight: Radius.circular(18),
                       ),
                     ),
                     child: Row(
                       children: [
                         CircleAvatar(
                           backgroundColor: Colors.white,
                           radius: 20,
                           child: Icon(
                             _moodIcons[entry.mood] ?? Icons.sentiment_neutral,
                             size: 26,
                             color: moodColor,
                           ),
                         ),
                         const SizedBox(width: 12),
                         Expanded(
                           child: Column(
                             crossAxisAlignment: CrossAxisAlignment.start,
                             children: [
                               Text(
                                 DateFormat('EEEE, dd MMMM yyyy', 'pt_BR').format(entry.date),
                                 style: TextStyle(
                                   fontWeight: FontWeight.bold, 
                                   fontSize: 16, 
                                   color: Colors.grey.shade900
                                 ),
                               ),
                               const SizedBox(height: 4),
                               Row(
                                 children: [
                                   Text(
                                     entry.mood,
                                     style: TextStyle(
                                       color: moodColor,
                                       fontWeight: FontWeight.w600,
                                     ),
                                   ),
                                 ],
                               ),
                             ],
                           ),
                         ),
                         Row(
                           mainAxisSize: MainAxisSize.min,
                           children: [
                             IconButton(
                               icon: Icon(Icons.edit, color: Colors.blue.shade600),
                               tooltip: 'Editar',
                               onPressed: () => _showAddEditEntrySheet(entry: entry),
                             ),
                             IconButton(
                               icon: Icon(Icons.delete_outline, color: Colors.red.shade600),
                               tooltip: 'Excluir',
                               onPressed: () => _deleteEntry(entry.id),
                             ),
                           ],
                         ),
                       ],
                     ),
                   ),
                   if (entry.content.isNotEmpty)
                     Padding(
                       padding: const EdgeInsets.all(16.0),
                       child: Text(
                         entry.content,
                         style: TextStyle(
                           fontSize: 15, 
                           color: Colors.grey.shade800,
                           height: 1.5,
                         ),
                       ),
                     ),
                 ],
               ),
             ),
          );
        },
            ),
          ),
        ],
      );
    }
  }
}