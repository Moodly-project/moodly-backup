import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Para formatação de data
import 'package:moodyr/models/diary_entry_model.dart'; // Importa o modelo

class DiaryScreen extends StatefulWidget {
  const DiaryScreen({super.key});

  @override
  State<DiaryScreen> createState() => _DiaryScreenState();
}

class _DiaryScreenState extends State<DiaryScreen> {
  // Lista temporária para armazenar as entradas
  final List<DiaryEntry> _diaryEntries = [
    // Dados de exemplo iniciais (remover depois)
    DiaryEntry(id: '1', content: 'Tive uma reunião produtiva e consegui resolver um problema complexo. Me senti realizado.', date: DateTime.now().subtract(Duration(days: 1)), mood: 'Feliz'),
    DiaryEntry(id: '2', content: 'Estava me sentindo um pouco sobrecarregado com as tarefas.', date: DateTime.now().subtract(Duration(days: 2)), mood: 'Ansioso'),
    DiaryEntry(id: '3', content: 'Passei um tempo relaxando e lendo um livro. Foi bom desacelerar.', date: DateTime.now().subtract(Duration(days: 3)), mood: 'Calmo'),
  ];

  // Mapa de ícones para humores (adicione mais conforme necessário)
  final Map<String, IconData> _moodIcons = {
    'Feliz': Icons.sentiment_very_satisfied,
    'Ansioso': Icons.sentiment_neutral,
    'Calmo': Icons.sentiment_satisfied,
    'Triste': Icons.sentiment_very_dissatisfied,
    'Animado': Icons.sentiment_satisfied_alt,
    'Grato': Icons.favorite,
    'Com Raiva': Icons.sentiment_dissatisfied, 
    // Adicione outros humores e seus ícones
  };

  void _showAddEditEntrySheet({DiaryEntry? entry}) {
    final _contentController = TextEditingController(text: entry?.content ?? '');
    DateTime _selectedDate = entry?.date ?? DateTime.now();
    String? _selectedMood = entry?.mood;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Permite que o sheet seja mais alto
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.0)),
      ),
      builder: (context) {
        return StatefulBuilder(
          // Usamos StatefulBuilder para atualizar o estado dentro do BottomSheet
          builder: (BuildContext context, StateSetter setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom, // Ajusta pelo teclado
                top: 20,
                left: 20,
                right: 20,
              ),
              child: SingleChildScrollView(
                 child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(entry == null ? 'Nova Entrada' : 'Editar Entrada', style: Theme.of(context).textTheme.headlineSmall),
                    const SizedBox(height: 20),
                    
                    // Seletor de Data
                    Text('Data:', style: Theme.of(context).textTheme.titleMedium),
                    TextButton.icon(
                       icon: const Icon(Icons.calendar_today),
                       label: Text(DateFormat('dd/MM/yyyy').format(_selectedDate)),
                       onPressed: () async {
                         final DateTime? picked = await showDatePicker(
                           context: context,
                           initialDate: _selectedDate,
                           firstDate: DateTime(2000),
                           lastDate: DateTime.now(),
                         );
                         if (picked != null && picked != _selectedDate) {
                           setModalState(() { // Atualiza o estado do BottomSheet
                             _selectedDate = picked;
                           });
                         }
                       },
                     ),
                    const SizedBox(height: 15),

                    // Seletor de Humor
                    Text('Como você está se sentindo?', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _selectedMood,
                      hint: const Text('Selecione seu humor'),
                      items: _moodIcons.keys.map((String mood) {
                        return DropdownMenuItem<String>(
                          value: mood,
                          child: Row(
                            children: [
                              Icon(_moodIcons[mood], color: Colors.grey.shade700),
                              const SizedBox(width: 8),
                              Text(mood),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                         setModalState(() {
                           _selectedMood = newValue;
                         });
                      },
                       validator: (value) => value == null ? 'Selecione um humor' : null,
                       decoration: InputDecoration(
                         border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                         filled: true,
                         fillColor: Colors.grey.shade100,
                       ),
                    ),
                    const SizedBox(height: 15),

                    // Campo de Observações
                     Text('Observações:', style: Theme.of(context).textTheme.titleMedium),
                     const SizedBox(height: 8),
                     TextFormField(
                      controller: _contentController,
                      maxLines: 4,
                      decoration: InputDecoration(
                        hintText: 'Escreva sobre o seu dia...',
                         border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                         filled: true,
                         fillColor: Colors.grey.shade100,
                      ),
                       validator: (value) => value == null || value.isEmpty ? 'Escreva algo' : null,
                    ),
                    const SizedBox(height: 20),

                    // Botão Salvar
                    Center(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.save),
                        label: Text(entry == null ? 'Salvar Entrada' : 'Atualizar Entrada'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepPurple.shade300,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                          shape: RoundedRectangleBorder(
                             borderRadius: BorderRadius.circular(12),
                           )
                        ),
                        onPressed: () {
                          if (_selectedMood != null && _contentController.text.isNotEmpty) {
                            if (entry == null) {
                              _addEntry(DiaryEntry(
                                id: DateTime.now().millisecondsSinceEpoch.toString(), // ID temporário
                                content: _contentController.text,
                                date: _selectedDate,
                                mood: _selectedMood!,
                              ));
                            } else {
                              _updateEntry(entry.copyWith(
                                content: _contentController.text,
                                date: _selectedDate,
                                mood: _selectedMood!,
                              ));
                            }
                            Navigator.pop(context); // Fecha o BottomSheet
                          }
                           // Adicionar validação se necessário
                        },
                      ),
                    ),
                     const SizedBox(height: 20),
                  ],
                ),
              ),
            );
          }
        );
      },
    );
  }

   // Funções CRUD temporárias (manipulando a lista local)
  void _addEntry(DiaryEntry entry) {
    setState(() {
      _diaryEntries.insert(0, entry); // Adiciona no início da lista
    });
     // TODO: Chamar API para adicionar no backend
  }

  void _updateEntry(DiaryEntry updatedEntry) {
    setState(() {
      final index = _diaryEntries.indexWhere((e) => e.id == updatedEntry.id);
      if (index != -1) {
        _diaryEntries[index] = updatedEntry;
      }
    });
     // TODO: Chamar API para atualizar no backend
  }

  void _deleteEntry(String id) {
     // Mostrar diálogo de confirmação
     showDialog(
       context: context,
       builder: (BuildContext ctx) {
         return AlertDialog(
           title: const Text('Confirmar Exclusão'),
           content: const Text('Tem certeza que deseja excluir esta entrada?'),
           actions: <Widget>[
             TextButton(
               child: const Text('Cancelar'),
               onPressed: () {
                 Navigator.of(ctx).pop(); // Fecha o diálogo
               },
             ),
             TextButton(
               style: TextButton.styleFrom(foregroundColor: Colors.red),
               child: const Text('Excluir'),
               onPressed: () {
                  setState(() {
                    _diaryEntries.removeWhere((e) => e.id == id);
                  });
                   Navigator.of(ctx).pop(); // Fecha o diálogo
                 // TODO: Chamar API para deletar no backend (soft delete)
               },
             ),
           ],
         );
       },
     );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Meu Diário'),
        flexibleSpace: Container(
           decoration: BoxDecoration(
             gradient: LinearGradient(
                colors: [
                 Colors.blue.shade100,
                 Colors.purple.shade100,
               ],
               begin: Alignment.topLeft,
               end: Alignment.bottomRight,
              ),
           ),
         ),
         actions: [
           // Adicionar botão de logout ou configurações aqui se necessário
         ],
      ),
      body: Container(
        // Gradiente de fundo para consistência
         decoration: BoxDecoration(
           gradient: LinearGradient(
              colors: [
               Colors.purple.shade50,
               Colors.blue.shade50,
             ],
             begin: Alignment.topCenter,
             end: Alignment.bottomCenter,
            ),
         ),
         child: _diaryEntries.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                     Icon(Icons.book_outlined, size: 80, color: Colors.grey.shade400),
                     const SizedBox(height: 16),
                     Text(
                      'Nenhuma entrada ainda.',
                      style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
                    ),
                    const SizedBox(height: 8),
                     Text(
                      'Toque no botão + para adicionar sua primeira entrada!',
                       textAlign: TextAlign.center,
                       style: TextStyle(color: Colors.grey.shade500),
                    ),
                  ],
                )
              )
            : ListView.builder(
                padding: const EdgeInsets.all(8.0),
                itemCount: _diaryEntries.length,
                itemBuilder: (context, index) {
                  final entry = _diaryEntries[index];
                  return Card(
                     margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 5.0),
                     elevation: 3,
                     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0)),
                     child: ListTile(
                      contentPadding: const EdgeInsets.all(15.0),
                       leading: Icon(
                         _moodIcons[entry.mood] ?? Icons.sentiment_neutral, // Ícone do humor
                         size: 40,
                         color: Colors.deepPurple.shade300,
                       ),
                       title: Text(
                         DateFormat('EEEE, dd MMMM yyyy', 'pt_BR').format(entry.date), // Data formatada
                         style: const TextStyle(fontWeight: FontWeight.bold),
                       ),
                       subtitle: Padding(
                         padding: const EdgeInsets.only(top: 8.0),
                         child: Text(
                           entry.content,
                           maxLines: 2,
                           overflow: TextOverflow.ellipsis, // Mostra '...' se for muito longo
                         ),
                       ),
                       trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                         children: [
                           IconButton(
                             icon: Icon(Icons.edit, color: Colors.blueGrey.shade400),
                             tooltip: 'Editar',
                             onPressed: () => _showAddEditEntrySheet(entry: entry),
                           ),
                           IconButton(
                             icon: Icon(Icons.delete_outline, color: Colors.red.shade300),
                             tooltip: 'Excluir',
                             onPressed: () => _deleteEntry(entry.id),
                           ),
                         ],
                       ),
                       onTap: () { 
                          // Opcional: Abrir uma visualização detalhada da entrada
                          _showAddEditEntrySheet(entry: entry);
                       },
                     ),
                  );
                },
              ),
        ),

      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddEditEntrySheet(),
        tooltip: 'Adicionar Entrada',
        backgroundColor: Colors.deepPurple.shade400,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

// Adicionar extensão para facilitar a atualização parcial do DiaryEntry
// (Isso é útil pois nosso modelo tem campos final)
extension DiaryEntryCopyWith on DiaryEntry {
  DiaryEntry copyWith({
    String? id,
    String? content,
    DateTime? date,
    String? mood,
  }) {
    return DiaryEntry(
      id: id ?? this.id,
      content: content ?? this.content,
      date: date ?? this.date,
      mood: mood ?? this.mood,
    );
  }
} 