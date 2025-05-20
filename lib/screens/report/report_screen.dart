// --- START OF REFACTORED FILE report_screen.dart ---
import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:moodyr/models/diary_entry_model.dart';
import 'package:moodyr/services/api_config_service.dart';

// --- Constantes para Humores ---
class Mood {
  static const String feliz = 'Feliz';
  static const String ansioso = 'Ansioso';
  static const String calmo = 'Calmo';
  static const String triste = 'Triste';
  static const String animado = 'Animado';
  static const String grato = 'Grato';
  static const String comRaiva = 'Com Raiva';

  static final Map<String, Color> colors = {
    feliz: Colors.amber.shade500,
    ansioso: Colors.orange.shade600,
    calmo: Colors.blue.shade500,
    triste: Colors.indigo.shade500,
    animado: Colors.pink.shade500,
    grato: Colors.green.shade600,
    comRaiva: Colors.red.shade600,
  };

  static final Map<String, IconData> icons = {
    feliz: Icons.emoji_emotions,
    ansioso: Icons.upcoming,
    calmo: Icons.nightlight,
    triste: Icons.sentiment_very_dissatisfied,
    animado: Icons.celebration,
    grato: Icons.favorite,
    comRaiva: Icons.flash_on,
  };

  static Color getColor(String? mood) => colors[mood] ?? Colors.grey;
  static IconData getIcon(String? mood) => icons[mood] ?? Icons.question_mark;
}
// --- Fim das Constantes ---


class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<DiaryEntry> _diaryEntries = [];
  bool _isLoading = true;
  String? _errorMessage;
  final _storage = const FlutterSecureStorage();
  final _apiConfigService = ApiConfigService();
  // TODO: Considere mover a URL base para um arquivo de configuração ou variáveis de ambiente
  final String _apiBaseUrl = 'http://10.0.2.2:3000/api';

  // Dados calculados que serão preenchidos após buscar as entradas
  Map<String, int> _moodCounts = {};
  Map<int, int> _dayOfWeekFrequency = {};
  Map<String, Map<String, int>> _monthlyMoods = {};

  final List<String> _weekdays = const ['Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb', 'Dom'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchEntries();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // --- Funções de Acesso à API ---

  Future<String?> _getToken() async {
    return await _storage.read(key: 'jwt_token');
  }

  Future<Map<String, String>> _getHeaders() async {
    final String? token = await _getToken();
    return {
      'Content-Type': 'application/json; charset=UTF-8',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<void> _fetchEntries() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _diaryEntries = []; // Limpa dados antigos antes de buscar novos
    });

    try {
      final headers = await _getHeaders();
      final apiUrl = await _apiConfigService.getBaseUrl();
      final response = await http.get(
        Uri.parse('$apiUrl/diary'),
        headers: headers,
      );

      if (!mounted) return; // Check if the widget is still in the tree before proceeding

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        final List<DiaryEntry> entries = data.map((item) {
          return DiaryEntry(
            id: item['id']?.toString() ?? '', // Add null check and default value
            content: item['conteudo'] ?? '',
            date: DateTime.tryParse(item['data_entrada'] ?? '') ?? DateTime.now(), // Handle potential parsing error
            mood: item['humor'] ?? Mood.calmo, // Provide a default mood if null
          );
        }).toList();

        // Ordena as entradas por data para garantir a ordem cronológica
        entries.sort((a, b) => a.date.compareTo(b.date));

        setState(() {
          _diaryEntries = entries;
          _calculateStatistics(); // Calcula estatísticas após buscar os dados
          _isLoading = false;
        });
      } else {
         // Tenta decodificar a mensagem de erro do corpo da resposta
        String serverMessage = 'Erro ${response.statusCode}. Tente novamente.';
        try {
          final decodedBody = jsonDecode(response.body);
          if (decodedBody is Map && decodedBody.containsKey('message')) {
            serverMessage = decodedBody['message'];
          }
        } catch (_) {
          // Ignora erro de decodificação do corpo da resposta, usa mensagem padrão
        }
        setState(() {
          _errorMessage = serverMessage;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Erro de conexão: Verifique sua rede.'; // Mensagem de erro mais genérica para o usuário
        print("Erro fetchEntries: $e"); // Log do erro para debug interno
        _isLoading = false;
      });
    }
  }

  // --- Funções de Cálculo de Dados ---

  void _calculateStatistics() {
    _moodCounts = _calculateMoodCounts(_diaryEntries);
    _dayOfWeekFrequency = _calculateDayOfWeekFrequency(_diaryEntries);
    _monthlyMoods = _calculateMonthlyMoods(_diaryEntries);
  }

  Map<String, int> _calculateMoodCounts(List<DiaryEntry> entries) {
    final Map<String, int> counts = {};
    for (final entry in entries) {
      counts[entry.mood] = (counts[entry.mood] ?? 0) + 1;
    }
    return counts;
  }

  Map<int, int> _calculateDayOfWeekFrequency(List<DiaryEntry> entries) {
    final Map<int, int> frequency = {};
    for (final entry in entries) {
      final int dayOfWeek = entry.date.weekday; // Em Dart: 1 (Segunda) a 7 (Domingo)
      frequency[dayOfWeek] = (frequency[dayOfWeek] ?? 0) + 1;
    }
    return frequency;
  }

   Map<String, Map<String, int>> _calculateMonthlyMoods(List<DiaryEntry> entries) {
      final Map<String, Map<String, int>> monthlyData = {};
      // Usar um locale consistente (pt_BR) para formatação de mês ('MMM/yy')
      final DateFormat monthFormatter = DateFormat('MMM/yy', 'pt_BR');

      for (final entry in entries) {
        final String monthKey = monthFormatter.format(entry.date);
        // Inicializa o mapa para o mês se ainda não existir
        monthlyData.putIfAbsent(monthKey, () => {});
        // Incrementa a contagem do humor para aquele mês
        final monthMap = monthlyData[monthKey]!;
        monthMap[entry.mood] = (monthMap[entry.mood] ?? 0) + 1;
      }
      return monthlyData;
    }

  // --- Widgets de Construção da UI ---

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Insights de Humor', style: TextStyle(fontWeight: FontWeight.bold)),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [colorScheme.primaryContainer, colorScheme.secondaryContainer],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: colorScheme.primary,
          labelColor: colorScheme.primary,
          unselectedLabelColor: colorScheme.onSurface.withOpacity(0.7),
          tabs: const [
            Tab(text: 'Geral'),
            Tab(text: 'Resumo'),
          ],
        ),
      ),
      body: _buildBody(context, colorScheme),
    );
  }

  Widget _buildBody(BuildContext context, ColorScheme colorScheme) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return _buildErrorState(context, colorScheme);
    }

    if (_diaryEntries.isEmpty) {
      return _buildEmptyState(context, colorScheme);
    }

    // Se chegou aqui, temos dados e podemos construir a UI principal
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colorScheme.primaryContainer.withOpacity(0.3),
            colorScheme.secondaryContainer.withOpacity(0.3),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: TabBarView(
        controller: _tabController,
        children: [
          _buildOverviewTab(context, colorScheme),
          _buildSummaryTab(context, colorScheme),
        ],
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, ColorScheme colorScheme) {
     return Center(
       child: Padding(
         padding: const EdgeInsets.all(20.0),
         child: Column(
           mainAxisAlignment: MainAxisAlignment.center,
           children: [
             Icon(Icons.error_outline, size: 60, color: colorScheme.error),
             const SizedBox(height: 16),
             Text(
                _errorMessage!,
                style: TextStyle(color: colorScheme.error, fontSize: 16),
                textAlign: TextAlign.center,
              ),
             const SizedBox(height: 24),
             ElevatedButton.icon(
               icon: const Icon(Icons.refresh),
               onPressed: _fetchEntries,
               style: ElevatedButton.styleFrom(
                 backgroundColor: colorScheme.primary,
                 foregroundColor: colorScheme.onError,
               ),
               label: const Text('Tentar Novamente'),
             ),
           ],
         ),
       ),
     );
   }

  Widget _buildEmptyState(BuildContext context, ColorScheme colorScheme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.bar_chart, size: 80, color: colorScheme.secondary.withOpacity(0.4)),
          const SizedBox(height: 16),
          Text(
            'Sem dados suficientes',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'Adicione mais entradas no seu diário para gerar relatórios e insights',
              textAlign: TextAlign.center,
              style: TextStyle(color: colorScheme.secondary),
            ),
          ),
        ],
      ),
    );
  }

  // --- Widgets das Tabs ---

  Widget _buildOverviewTab(BuildContext context, ColorScheme colorScheme) {
    final String mostCommonMood = _moodCounts.entries.isEmpty
        ? '-'
        : _moodCounts.entries.reduce((a, b) => a.value > b.value ? a : b).key;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionCard(
            context: context,
            colorScheme: colorScheme,
            title: 'Distribuição de Emoções',
            child: SizedBox(
              height: 300, // Altura fixa para o gráfico de pizza
              child: _buildPieChart(_moodCounts, _diaryEntries.length),
            ),
          ),
          const SizedBox(height: 20),
          _buildSectionCard(
            context: context,
            colorScheme: colorScheme,
            title: 'Estatísticas Rápidas',
            child: Column(
              children: [
                _buildStatisticTile(
                  icon: Icons.note_alt,
                  title: 'Total de Entradas',
                  value: _diaryEntries.length.toString(),
                ),
                const Divider(),
                _buildStatisticTile(
                  icon: Mood.getIcon(mostCommonMood),
                  title: 'Humor Mais Comum',
                  value: mostCommonMood,
                  color: Mood.getColor(mostCommonMood),
                ),
                const Divider(),
                _buildStatisticTile(
                  icon: Icons.calendar_today,
                  title: 'Período Analisado',
                  value: _diaryEntries.isEmpty
                      ? '-'
                      : '${DateFormat('dd/MM/yy').format(_diaryEntries.first.date)} até ${DateFormat('dd/MM/yy').format(_diaryEntries.last.date)}',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryTab(BuildContext context, ColorScheme colorScheme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionCard(
            context: context,
            colorScheme: colorScheme,
            title: 'Frequência por Dia da Semana',
            child: AspectRatio(
              aspectRatio: 1.5, // Proporção para o gráfico de barras
              child: _buildDayOfWeekBarChart(_dayOfWeekFrequency, colorScheme),
            ),
          ),
          const SizedBox(height: 20),
          _buildSectionCard(
            context: context,
            colorScheme: colorScheme,
            title: 'Resumo Mensal',
            child: _buildMonthlyMoodSummary(_monthlyMoods, colorScheme),
          ),
        ],
      ),
    );
  }

  // --- Widgets Reutilizáveis ---

  Widget _buildSectionCard({
    required BuildContext context,
    required ColorScheme colorScheme,
    required String title,
    required Widget child,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      // Usa a cor do card do tema com alguma transparência
      color: Theme.of(context).cardColor.withOpacity(0.85),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildStatisticTile({
    required IconData icon,
    required String title,
    required String value,
    Color? color,
  }) {
    final Color effectiveColor = color ?? Colors.deepPurple.shade400;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: effectiveColor.withOpacity(0.1),
            child: Icon(icon, color: effectiveColor),
          ),
          const SizedBox(width: 16),
          Expanded( // Usa Expanded para garantir que o texto não cause overflow
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontSize: 14,
                  ),
                  overflow: TextOverflow.ellipsis, // Evita quebra de linha se o título for muito longo
                ),
                Text(
                  value,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                   overflow: TextOverflow.ellipsis, // Evita quebra de linha se o valor for muito longo
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

   Widget _buildMonthlyMoodSummary(Map<String, Map<String, int>> monthlyMoods, ColorScheme colorScheme) {
     if (monthlyMoods.isEmpty) {
       return const Padding(
         padding: EdgeInsets.symmetric(vertical: 16.0),
         child: Center(child: Text("Sem dados mensais para exibir.")),
       );
     }

     // Ordena os meses cronologicamente (assumindo o formato 'MMM/yy' definido em _calculateMonthlyMoods)
     final DateFormat monthParser = DateFormat('MMM/yy', 'pt_BR');
     final List<String> sortedMonths = monthlyMoods.keys.toList()
       ..sort((a, b) {
         try {
           final dateA = monthParser.parse(a);
           final dateB = monthParser.parse(b);
           return dateA.compareTo(dateB);
         } catch (e) {
           // Fallback para ordenação de string normal se o parse falhar por algum motivo
           return a.compareTo(b);
         }
       });

     // Pega os últimos 3 meses (ou menos se não houver dados suficientes) para exibir no resumo
     final List<String> recentMonths = sortedMonths.length > 3
         ? sortedMonths.sublist(sortedMonths.length - 3)
         : sortedMonths;

     return Column(
       children: recentMonths.map((month) {
         final Map<String, int> moodsInMonth = monthlyMoods[month]!;
         if (moodsInMonth.isEmpty) return const SizedBox.shrink(); // Não mostra mês sem nenhuma entrada

         // Encontra o humor predominante do mês (o que teve mais ocorrências)
         final String dominantMood = moodsInMonth.entries
             .reduce((a, b) => a.value > b.value ? a : b)
             .key;
         final int totalEntries = moodsInMonth.values.fold(0, (sum, count) => sum + count);

         final Color moodColor = Mood.getColor(dominantMood);
         final IconData moodIcon = Mood.getIcon(dominantMood);

         return Padding(
           padding: const EdgeInsets.only(bottom: 12.0),
           child: ListTile(
             leading: CircleAvatar(
               backgroundColor: moodColor.withOpacity(0.2),
               child: Text(
                 month.substring(0, 3), // Ex: 'Jan', 'Fev'
                 style: TextStyle(
                   color: moodColor,
                   fontWeight: FontWeight.bold,
                   fontSize: 12, // Tamanho de fonte menor para caber 'Jan', 'Fev', etc.
                 ),
               ),
             ),
             title: Text(
               'Humor predominante: $dominantMood',
               style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
             ),
             subtitle: Text('Total de entradas: $totalEntries', style: const TextStyle(fontSize: 12)),
             trailing: Icon(moodIcon, color: moodColor),
             dense: true, // Torna o ListTile mais compacto verticalmente
           ),
         );
       }).toList(),
     );
   }

  Widget _buildMoodIconBadge(String mood, Color color, {bool isTouched = false}) {
      final double size = isTouched ? 40 : 32;
      return AnimatedContainer(
        duration: PieChart.defaultDuration,
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: color, width: 2),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: Colors.black.withOpacity(.5),
              offset: const Offset(3, 3),
              blurRadius: 3,
            ),
          ],
        ),
        child: Center(
          child: Icon(
            Mood.getIcon(mood),
            color: color,
            size: isTouched ? 20 : 16,
          ),
        ),
      );
    }

  // --- Widgets de Gráficos ---

  Widget _buildPieChart(Map<String, int> moodCounts, int totalEntries) {
     if (moodCounts.isEmpty) {
       return const Center(child: Text("Sem dados para o gráfico de pizza."));
     }

     return PieChart(
       PieChartData(
         sectionsSpace: 2,
         centerSpaceRadius: 40,
         sections: moodCounts.entries.map((entry) {
           final double percentage = totalEntries > 0 ? (entry.value / totalEntries * 100) : 0;
           final String title = '${percentage.toStringAsFixed(0)}%\n${entry.key}';
           final Color color = Mood.getColor(entry.key);

           return PieChartSectionData(
             color: color,
             value: entry.value.toDouble(),
             title: title,
             radius: 100.0, // Raio fixo para simplicidade
             titleStyle: TextStyle(
               fontSize: 11.0, // Tamanho fixo
               fontWeight: FontWeight.bold,
               color: color.computeLuminance() > 0.5 ? Colors.black87 : Colors.white,
               shadows: const [Shadow(color: Colors.black26, blurRadius: 2)],
             ),
             badgeWidget: _buildMoodIconBadge(entry.key, color),
             badgePositionPercentageOffset: .98,
           );
         }).toList(),
       ),
       // options: PieChartOptions( // Se precisar de interatividade
       //   pieTouchData: PieTouchData(touchCallback: (event, pieTouchResponse) {
       //      // Lógica de toque aqui
       //   }),
       // ),
     );
   }

  Widget _buildDayOfWeekBarChart(Map<int, int> frequency, ColorScheme colorScheme) {
     if (frequency.isEmpty) {
       return const Center(child: Text("Sem dados para o gráfico de barras."));
     }

     final double maxY = (frequency.isEmpty ? 0 : frequency.values.reduce(max)).toDouble() + 1;

     return BarChart(
       BarChartData(
         alignment: BarChartAlignment.spaceAround,
         maxY: maxY <= 1 ? 5 : maxY, // Garante um maxY mínimo de 5 para melhor visualização quando há poucas entradas
         barTouchData: BarTouchData(enabled: false), // Desabilitar interatividade por toque no gráfico de barras
         titlesData: FlTitlesData(
           show: true,
           // Títulos da Esquerda (Eixo Y - Contagem)
           leftTitles: AxisTitles(
             sideTitles: SideTitles(
               showTitles: true,
               getTitlesWidget: (value, meta) {
                 // Mostra apenas números inteiros no eixo Y e evita o 0 se não houver dados (maxY <= 1)
                  if (value == 0 && maxY <= 1) return const Text('');
                 if (value % 1 == 0 && value < maxY) {
                    return Text(
                      value.toInt().toString(),
                      style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 10),
                    );
                 }
                 return const Text('');
               },
               reservedSize: 30,
               interval: max(1, (maxY / 5).floorToDouble()), // Ajusta o intervalo do eixo Y dinamicamente baseado no maxY
             ),
           ),
           // Títulos de Baixo (Eixo X - Dias da Semana)
           bottomTitles: AxisTitles(
             sideTitles: SideTitles(
               showTitles: true,
               getTitlesWidget: (value, meta) {
                 final int index = value.toInt();
                 if (index >= 0 && index < _weekdays.length) {
                   return Padding(
                     padding: const EdgeInsets.only(top: 8.0),
                     child: Text(
                       _weekdays[index],
                       style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 10),
                     ),
                   );
                 }
                 return const Text('');
               },
               reservedSize: 30,
             ),
           ),
            // Remover títulos do topo e da direita para um visual mais limpo
           topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
           rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
         ),
         borderData: FlBorderData(show: false), // Sem borda ao redor do gráfico
         gridData: FlGridData( // Linhas de grade horizontais sutis para referência
            show: true,
            drawVerticalLine: false, // Não desenha linhas de grade verticais
            horizontalInterval: max(1, (maxY / 5).floorToDouble()), // Intervalo das linhas de grade igual ao do eixo Y
             getDrawingHorizontalLine: (value) => FlLine(
                  color: colorScheme.outline.withOpacity(0.2), // Cor sutil para as linhas
                  strokeWidth: 1,
                ),
          ),
         barGroups: List.generate(7, (index) {
           final int dayIndex = index + 1; // Mapeia índice 0-6 para dia da semana 1-7
           final int count = frequency[dayIndex] ?? 0;
           return BarChartGroupData(
             x: index, // Posição no eixo X (0 a 6)
             barRods: [
               BarChartRodData(
                 toY: count.toDouble(),
                 gradient: LinearGradient( // Aplica um gradiente suave às barras
                   colors: [
                     colorScheme.primary.withOpacity(0.8),
                     colorScheme.tertiary.withOpacity(0.8),
                   ],
                   begin: Alignment.bottomCenter,
                   end: Alignment.topCenter,
                 ),
                 width: 20, // Largura das barras
                 borderRadius: const BorderRadius.only( // Bordas arredondadas no topo
                   topLeft: Radius.circular(6),
                   topRight: Radius.circular(6),
                 ),
               ),
             ],
           );
         }),
       ),
     );
   }
}