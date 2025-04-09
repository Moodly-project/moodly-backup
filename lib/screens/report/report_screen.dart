import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:moodyr/models/diary_entry_model.dart';

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
  final String _apiBaseUrl = 'http://10.0.2.2:3000/api';

  // Mapa de cores para humores
  final Map<String, Color> _moodColors = {
    'Feliz': Colors.amber.shade500,
    'Ansioso': Colors.orange.shade600,
    'Calmo': Colors.blue.shade500,
    'Triste': Colors.indigo.shade500,
    'Animado': Colors.pink.shade500,
    'Grato': Colors.green.shade600,
    'Com Raiva': Colors.red.shade600,
  };
  
  // Mapa de ícones para humores (adicionado para corrigir o erro)
  final Map<String, IconData> _moodIcons = {
    'Feliz': Icons.emoji_emotions,
    'Ansioso': Icons.upcoming,
    'Calmo': Icons.nightlight,
    'Triste': Icons.sentiment_very_dissatisfied,
    'Animado': Icons.celebration,
    'Grato': Icons.favorite,
    'Com Raiva': Icons.flash_on,
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _fetchEntries();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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
          
          // Ordenar por data
          _diaryEntries.sort((a, b) => a.date.compareTo(b.date));
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Erro ao buscar dados. Tente novamente.';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Erro de conexão: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Insights de Humor', style: TextStyle(fontWeight: FontWeight.bold)),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.deepPurple.shade300,
                Colors.blue.shade300,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'Geral'),
            Tab(text: 'Tendências'),
            Tab(text: 'Resumo'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 60, color: Colors.red.shade400),
                      const SizedBox(height: 16),
                      Text(_errorMessage!, style: TextStyle(color: Colors.red.shade700)),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _fetchEntries,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepPurple.shade400,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Tentar Novamente'),
                      ),
                    ],
                  ),
                )
              : _diaryEntries.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.bar_chart, size: 80, color: Colors.grey.shade300),
                          const SizedBox(height: 16),
                          Text(
                            'Sem dados suficientes',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade700,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 40),
                            child: Text(
                              'Adicione mais entradas no seu diário para gerar relatórios e insights',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.grey.shade600),
                            ),
                          ),
                        ],
                      ),
                    )
                  : Container(
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
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          _buildOverviewTab(),
                          _buildTrendsTab(),
                          _buildSummaryTab(),
                        ],
                      ),
                    ),
    );
  }

  Widget _buildOverviewTab() {
    // Contagem de emoções
    Map<String, int> moodCounts = {};
    for (var entry in _diaryEntries) {
      moodCounts[entry.mood] = (moodCounts[entry.mood] ?? 0) + 1;
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionCard(
            title: 'Distribuição de Emoções',
            child: SizedBox(
              height: 300,
              child: PieChart(
                PieChartData(
                  sectionsSpace: 2,
                  centerSpaceRadius: 40,
                  sections: moodCounts.entries.map((entry) {
                    return PieChartSectionData(
                      color: _moodColors[entry.key] ?? Colors.grey,
                      value: entry.value.toDouble(),
                      title: '${entry.key}: ${entry.value}',
                      radius: 100,
                      titleStyle: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          _buildSectionCard(
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
                  icon: Icons.emoji_emotions,
                  title: 'Humor Mais Comum',
                  value: moodCounts.entries.isEmpty 
                      ? '-' 
                      : moodCounts.entries
                          .reduce((a, b) => a.value > b.value ? a : b)
                          .key,
                  color: moodCounts.entries.isEmpty 
                      ? null 
                      : _moodColors[moodCounts.entries
                          .reduce((a, b) => a.value > b.value ? a : b)
                          .key],
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

  Widget _buildTrendsTab() {
    // Agrupar por mês para tendências
    Map<String, Map<String, int>> monthlyMoods = {};
    
    for (var entry in _diaryEntries) {
      String month = DateFormat('MMM/yy', 'pt_BR').format(entry.date);
      monthlyMoods.putIfAbsent(month, () => {});
      monthlyMoods[month]![entry.mood] = (monthlyMoods[month]![entry.mood] ?? 0) + 1;
    }

    // Gerar dados para o gráfico de linha
    final List<String> months = monthlyMoods.keys.toList();
    final List<Color> gradientColors = [
      Colors.deepPurple.shade400,
      Colors.blue.shade400,
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionCard(
            title: 'Evolução de Emoções',
            child: AspectRatio(
              aspectRatio: 1.5,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(show: false),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            value.toInt().toString(),
                            style: TextStyle(
                              color: Colors.grey.shade700,
                              fontSize: 10,
                            ),
                          );
                        },
                        reservedSize: 30,
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          if (value >= 0 && value < months.length) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(
                                months[value.toInt()],
                                style: TextStyle(
                                  color: Colors.grey.shade700,
                                  fontSize: 10,
                                ),
                              ),
                            );
                          }
                          return const Text('');
                        },
                        reservedSize: 30,
                      ),
                    ),
                    rightTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  borderData: FlBorderData(
                    show: true,
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      spots: months.asMap().entries.map((entry) {
                        int total = 0;
                        monthlyMoods[entry.value]?.forEach((_, count) {
                          total += count;
                        });
                        return FlSpot(entry.key.toDouble(), total.toDouble());
                      }).toList(),
                      isCurved: true,
                      gradient: LinearGradient(colors: gradientColors),
                      barWidth: 4,
                      isStrokeCapRound: true,
                      dotData: FlDotData(show: true),
                      belowBarData: BarAreaData(
                        show: true,
                        gradient: LinearGradient(
                          colors: gradientColors
                              .map((color) => color.withOpacity(0.2))
                              .toList(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          _buildSectionCard(
            title: 'Insights',
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInsightItem(
                    'Tendência geral',
                    _generateTrendText(),
                    Icons.trending_up,
                  ),
                  const Divider(),
                  _buildInsightItem(
                    'Consistência',
                    _generateConsistencyText(),
                    Icons.repeat,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryTab() {
    // Frequência por dia da semana
    Map<int, int> dayOfWeekFrequency = {};
    Map<int, Map<String, int>> dayOfWeekMoods = {};
    
    for (var entry in _diaryEntries) {
      int dayOfWeek = entry.date.weekday;
      dayOfWeekFrequency[dayOfWeek] = (dayOfWeekFrequency[dayOfWeek] ?? 0) + 1;
      
      dayOfWeekMoods.putIfAbsent(dayOfWeek, () => {});
      dayOfWeekMoods[dayOfWeek]![entry.mood] = (dayOfWeekMoods[dayOfWeek]![entry.mood] ?? 0) + 1;
    }

    final List<String> weekdays = ['Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb', 'Dom'];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionCard(
            title: 'Frequência por Dia da Semana',
            child: AspectRatio(
              aspectRatio: 1.5,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: (dayOfWeekFrequency.isEmpty ? 1 : dayOfWeekFrequency.values.reduce(max) + 1).toDouble(),
                  barTouchData: BarTouchData(enabled: false),
                  titlesData: FlTitlesData(
                    show: true,
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          if (value % 1 == 0) {
                            return Text(
                              value.toInt().toString(),
                              style: TextStyle(
                                color: Colors.grey.shade700,
                                fontSize: 10,
                              ),
                            );
                          }
                          return const Text('');
                        },
                        reservedSize: 30,
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          if (value >= 0 && value < weekdays.length) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(
                                weekdays[value.toInt()],
                                style: TextStyle(
                                  color: Colors.grey.shade700,
                                  fontSize: 10,
                                ),
                              ),
                            );
                          }
                          return const Text('');
                        },
                        reservedSize: 30,
                      ),
                    ),
                    rightTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  gridData: FlGridData(show: false),
                  barGroups: List.generate(7, (index) {
                    final int dayIndex = index + 1; // 1-7 para segunda-domingo
                    final int count = dayOfWeekFrequency[dayIndex] ?? 0;
                    
                    return BarChartGroupData(
                      x: index,
                      barRods: [
                        BarChartRodData(
                          toY: count.toDouble(),
                          gradient: LinearGradient(
                            colors: [
                              Colors.deepPurple.shade300,
                              Colors.blue.shade300,
                            ],
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                          ),
                          width: 20,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(6),
                            topRight: Radius.circular(6),
                          ),
                        ),
                      ],
                    );
                  }),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          _buildSectionCard(
            title: 'Palavras Mais Usadas',
            child: _generateWordCloud(),
          ),
          const SizedBox(height: 20),
          _buildSectionCard(
            title: 'Resumo Mensal',
            child: _buildMonthlyMoodSummary(),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({required String title, required Widget child}) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
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
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: (color ?? Colors.deepPurple.shade400).withOpacity(0.1),
            child: Icon(icon, color: color ?? Colors.deepPurple.shade400),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: Colors.grey.shade700,
                  fontSize: 14,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInsightItem(String title, String content, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.deepPurple.shade400, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  content,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade800,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _generateTrendText() {
    if (_diaryEntries.length < 3) {
      return "Registre mais entradas para análise de tendências.";
    }
    
    // Análise de tendência simples - positivo vs negativo
    List<String> positiveEmotions = ['Feliz', 'Calmo', 'Grato', 'Animado'];
    
    // Contar emoções positivas na primeira e segunda metade
    int halfPoint = _diaryEntries.length ~/ 2;
    
    int firstHalfPositive = 0;
    for (int i = 0; i < halfPoint; i++) {
      if (positiveEmotions.contains(_diaryEntries[i].mood)) {
        firstHalfPositive++;
      }
    }
    
    int secondHalfPositive = 0;
    for (int i = halfPoint; i < _diaryEntries.length; i++) {
      if (positiveEmotions.contains(_diaryEntries[i].mood)) {
        secondHalfPositive++;
      }
    }
    
    double firstHalfRatio = firstHalfPositive / halfPoint;
    double secondHalfRatio = secondHalfPositive / (_diaryEntries.length - halfPoint);
    
    if (secondHalfRatio > firstHalfRatio * 1.2) {
      return "Sua tendência emocional está melhorando com o tempo, com mais emoções positivas recentemente.";
    } else if (firstHalfRatio > secondHalfRatio * 1.2) {
      return "Você tem registrado mais emoções desafiadoras recentemente, comparado ao período anterior.";
    } else {
      return "Seu padrão emocional tem se mantido relativamente estável ao longo do tempo.";
    }
  }

  String _generateConsistencyText() {
    if (_diaryEntries.length < 5) {
      return "Continue registrando suas emoções para análise de consistência.";
    }
    
    // Calcular consistência por intervalos entre registros
    List<int> intervals = [];
    for (int i = 1; i < _diaryEntries.length; i++) {
      intervals.add(
        _diaryEntries[i].date.difference(_diaryEntries[i-1].date).inDays
      );
    }
    
    double avgInterval = intervals.reduce((a, b) => a + b) / intervals.length;
    
    if (avgInterval <= 2) {
      return "Excelente consistência! Você tem registrado suas emoções regularmente, quase diariamente.";
    } else if (avgInterval <= 5) {
      return "Boa consistência. Você tem registrado suas emoções com frequência, aproximadamente a cada ${avgInterval.toStringAsFixed(1)} dias.";
    } else {
      return "Considere registrar suas emoções com mais frequência para um acompanhamento mais preciso. Atualmente, a média é de um registro a cada ${avgInterval.toStringAsFixed(1)} dias.";
    }
  }

  Widget _generateWordCloud() {
    // Em uma aplicação real, isso usaria um algoritmo de processamento de linguagem natural
    // para extrair palavras-chave dos textos das entradas.
    // Aqui, simulamos algumas palavras comuns com frequências aleatórias
    
    List<Map<String, dynamic>> wordFrequency = [
      {'word': 'Tranquilidade', 'size': 22.0, 'color': Colors.blue.shade400},
      {'word': 'Família', 'size': 20.0, 'color': Colors.green.shade400},
      {'word': 'Trabalho', 'size': 18.0, 'color': Colors.red.shade400},
      {'word': 'Amigos', 'size': 17.0, 'color': Colors.orange.shade400},
      {'word': 'Descanso', 'size': 16.0, 'color': Colors.purple.shade300},
      {'word': 'Música', 'size': 15.0, 'color': Colors.teal.shade400},
      {'word': 'Esporte', 'size': 14.0, 'color': Colors.indigo.shade300},
      {'word': 'Leitura', 'size': 13.0, 'color': Colors.amber.shade700},
    ];
    
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 12,
      runSpacing: 12,
      children: wordFrequency.map((word) {
        return Chip(
          label: Text(
            word['word'],
            style: TextStyle(
              fontSize: word['size'],
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
          backgroundColor: word['color'],
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        );
      }).toList(),
    );
  }

  Widget _buildMonthlyMoodSummary() {
    // Agrupar por mês
    Map<String, Map<String, int>> monthlyMoods = {};
    
    for (var entry in _diaryEntries) {
      String month = DateFormat('MMM/yy', 'pt_BR').format(entry.date);
      monthlyMoods.putIfAbsent(month, () => {});
      monthlyMoods[month]![entry.mood] = (monthlyMoods[month]![entry.mood] ?? 0) + 1;
    }
    
    // Limitar aos últimos 3 meses
    List<String> months = monthlyMoods.keys.toList();
    months.sort(); // Ordenar cronologicamente
    
    if (months.length > 3) {
      months = months.sublist(months.length - 3);
    }
    
    return Column(
      children: months.map((month) {
        // Encontrar o humor predominante do mês
        String? dominantMood;
        int maxCount = 0;
        
        monthlyMoods[month]!.forEach((mood, count) {
          if (count > maxCount) {
            maxCount = count;
            dominantMood = mood;
          }
        });
        
        return Padding(
          padding: const EdgeInsets.only(bottom: 12.0),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: _moodColors[dominantMood]?.withOpacity(0.2),
              child: Text(
                month.substring(0, 3),
                style: TextStyle(
                  color: _moodColors[dominantMood],
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            title: Text(
              'Humor predominante: $dominantMood',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text('Total de entradas: ${monthlyMoods[month]!.values.reduce((a, b) => a + b)}'),
            trailing: Icon(_moodIcons[dominantMood], color: _moodColors[dominantMood]),
          ),
        );
      }).toList(),
    );
  }
} 