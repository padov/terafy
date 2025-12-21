import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:terafy/common/app_colors.dart';
import 'package:terafy/core/dependencies/dependency_container.dart';
import 'package:terafy/features/patients/models/ai_analysis.dart';
import 'package:terafy/features/patients/models/patient.dart';
import 'package:terafy/features/patients/pages/ai_analysis_detail_page.dart';

class AiAnalysisHistoryPage extends StatefulWidget {
  final Patient patient;

  const AiAnalysisHistoryPage({super.key, required this.patient});

  @override
  State<AiAnalysisHistoryPage> createState() => _AiAnalysisHistoryPageState();
}

class _AiAnalysisHistoryPageState extends State<AiAnalysisHistoryPage> {
  String _filterMode = 'active'; // 'active', 'all', 'archived'
  int _refreshKey = 0; // Key to force rebuild

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Histórico de Análises IA'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.offBlack,
        elevation: 0.5,
        actions: [
          PopupMenuButton<String>(
            icon: Icon(Icons.filter_list),
            onSelected: (value) {
              setState(() {
                _filterMode = value;
              });
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'active',
                child: Row(
                  children: [
                    Icon(
                      Icons.check_circle,
                      size: 20,
                      color: _filterMode == 'active' ? AppColors.primary : Colors.grey,
                    ),
                    SizedBox(width: 8),
                    Text('Ativas'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'all',
                child: Row(
                  children: [
                    Icon(Icons.list, size: 20, color: _filterMode == 'all' ? AppColors.primary : Colors.grey),
                    SizedBox(width: 8),
                    Text('Todas'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'archived',
                child: Row(
                  children: [
                    Icon(Icons.archive, size: 20, color: _filterMode == 'archived' ? AppColors.primary : Colors.grey),
                    SizedBox(width: 8),
                    Text('Arquivadas'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      backgroundColor: Colors.grey[50],
      body: FutureBuilder<List<Map<String, dynamic>>>(
        key: ValueKey(_refreshKey), // Force rebuild when key changes
        future: DependencyContainer().aiAnalysisRepository.fetchAnalyses(int.parse(widget.patient.id)),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                  SizedBox(height: 16),
                  Text('Erro ao carregar análises', style: TextStyle(fontSize: 16, color: Colors.grey[600])),
                  SizedBox(height: 8),
                  Text(snapshot.error.toString(), style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                ],
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.psychology_outlined, size: 64, color: Colors.grey[300]),
                  SizedBox(height: 16),
                  Text('Nenhuma análise encontrada', style: TextStyle(fontSize: 16, color: Colors.grey[600])),
                  SizedBox(height: 8),
                  Text('As análises geradas aparecerão aqui', style: TextStyle(fontSize: 14, color: Colors.grey[500])),
                ],
              ),
            );
          }

          // Parse and filter analyses
          var analyses = snapshot.data!.map((data) => AiAnalysis.fromJson(data)).toList();

          // Apply filters based on mode
          if (_filterMode == 'active') {
            analyses = analyses.where((a) => !a.archived && a.status == 'completed').toList();
          } else if (_filterMode == 'archived') {
            analyses = analyses.where((a) => a.archived).toList();
          }
          // 'all' mode shows everything, no filter needed

          if (analyses.isEmpty) {
            String emptyMessage = 'Nenhuma análise encontrada';
            if (_filterMode == 'active') {
              emptyMessage = 'Nenhuma análise ativa';
            } else if (_filterMode == 'archived') {
              emptyMessage = 'Nenhuma análise arquivada';
            }

            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.filter_list_off, size: 64, color: Colors.grey[300]),
                  SizedBox(height: 16),
                  Text(emptyMessage, style: TextStyle(fontSize: 16, color: Colors.grey[600])),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: EdgeInsets.all(16),
            itemCount: analyses.length,
            itemBuilder: (context, index) {
              final analysis = analyses[index];
              return _buildAnalysisCard(context, analysis);
            },
          );
        },
      ),
    );
  }

  Widget _buildAnalysisCard(BuildContext context, AiAnalysis analysis) {
    return Card(
      margin: EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () async {
          final shouldRefresh = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AiAnalysisDetailPage(analysis: analysis)),
          );

          // Refresh list if analysis was archived/unarchived
          if (shouldRefresh == true && mounted) {
            setState(() {
              _refreshKey++; // Increment key to force rebuild
            });
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.psychology, color: AppColors.primary, size: 20),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          analysis.title ?? analysis.typeLabel,
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 4),
                        Text(
                          DateFormat('dd/MM/yyyy HH:mm').format(analysis.createdAt),
                          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                  _buildStatusBadge(analysis.status),
                  if (analysis.archived) ...[
                    SizedBox(width: 8),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(8)),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.archive, size: 12, color: Colors.grey[700]),
                          SizedBox(width: 4),
                          Text('Arquivada', style: TextStyle(fontSize: 10, color: Colors.grey[700])),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
              SizedBox(height: 12),
              Text(analysis.typeLabel, style: TextStyle(fontSize: 14, color: Colors.grey[700])),
              if (analysis.response.isNotEmpty) ...[
                SizedBox(height: 8),
                Text(
                  analysis.response,
                  style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    String label;
    IconData icon;

    switch (status) {
      case 'completed':
        color = Colors.green;
        label = 'Concluída';
        icon = Icons.check_circle;
        break;
      case 'pending':
        color = Colors.orange;
        label = 'Pendente';
        icon = Icons.pending;
        break;
      case 'failed':
        color = Colors.red;
        label = 'Erro';
        icon = Icons.error;
        break;
      default:
        color = Colors.grey;
        label = 'Desconhecido';
        icon = Icons.help;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
