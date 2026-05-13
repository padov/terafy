import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:intl/intl.dart';
import 'package:terafy/common/app_colors.dart';
import 'package:terafy/core/dependencies/dependency_container.dart';
import 'package:terafy/features/patients/models/ai_analysis.dart';

class AiAnalysisDetailPage extends StatefulWidget {
  final AiAnalysis analysis;

  const AiAnalysisDetailPage({super.key, required this.analysis});

  @override
  State<AiAnalysisDetailPage> createState() => _AiAnalysisDetailPageState();
}

class _AiAnalysisDetailPageState extends State<AiAnalysisDetailPage> {
  bool _showPrompt = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Análise IA'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.offBlack,
        elevation: 0.5,
        actions: [
          IconButton(
            icon: Icon(Icons.share),
            onPressed: () {
              // Future: Share functionality
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Compartilhamento em breve')));
            },
          ),
        ],
      ),
      backgroundColor: Colors.grey[50],
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildMetadataCard(),
            // SizedBox(height: 20),
            // _buildPromptCard(context),
            SizedBox(height: 20),
            _buildResponseCard(context),
            SizedBox(height: 30),
            widget.analysis.archived ? _buildUnarchiveButton(context) : _buildArchiveButton(context),
          ],
        ),
      ),
    );
  }

  Widget _buildMetadataCard() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.psychology, color: AppColors.primary, size: 24),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  widget.analysis.title ?? widget.analysis.typeLabel,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          _buildMetadataRow(
            Icons.calendar_today,
            'Data',
            DateFormat('dd/MM/yyyy HH:mm').format(widget.analysis.createdAt),
          ),
          SizedBox(height: 8),
          _buildMetadataRow(Icons.category, 'Tipo', widget.analysis.typeLabel),
          SizedBox(height: 8),
          _buildMetadataRow(Icons.check_circle, 'Status', widget.analysis.statusLabel, statusColor: _getStatusColor()),
          if (widget.analysis.sessionId != null) ...[
            SizedBox(height: 8),
            _buildMetadataRow(Icons.event_note, 'Sessão', '#${widget.analysis.sessionId}'),
          ],
        ],
      ),
    );
  }

  Widget _buildMetadataRow(IconData icon, String label, String value, {Color? statusColor}) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        SizedBox(width: 8),
        Text(
          '$label: ',
          style: TextStyle(fontSize: 14, color: Colors.grey[600], fontWeight: FontWeight.w500),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 14,
              color: statusColor ?? Colors.black87,
              fontWeight: statusColor != null ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ],
    );
  }

  Color _getStatusColor() {
    switch (widget.analysis.status) {
      case 'completed':
        return Colors.green;
      case 'processing':
        return Colors.orange;
      case 'error':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Widget _buildPromptCard(BuildContext context) {
    final promptText = widget.analysis.prompt.trim();
    final hasPrompt = promptText.isNotEmpty;

    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Prompt Enviado', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (hasPrompt)
                    IconButton(
                      icon: Icon(_showPrompt ? Icons.visibility_off : Icons.visibility, size: 20),
                      onPressed: () {
                        setState(() {
                          _showPrompt = !_showPrompt;
                        });
                      },
                      tooltip: _showPrompt ? 'Ocultar prompt' : 'Ver prompt',
                    ),
                  if (hasPrompt)
                    IconButton(
                      icon: Icon(Icons.copy, size: 20),
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: promptText));
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Prompt copiado!')));
                      },
                      tooltip: 'Copiar prompt',
                    ),
                ],
              ),
            ],
          ),
          if (_showPrompt && hasPrompt) ...[
            SizedBox(height: 12),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: SelectableText(
                promptText,
                style: TextStyle(fontFamily: 'monospace', fontSize: 13, color: Colors.black87, height: 1.5),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildResponseCard(BuildContext context) {
    final responseText = widget.analysis.response.trim();
    final hasResponse = responseText.isNotEmpty;

    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF667eea).withOpacity(0.05), Color(0xFF764ba2).withOpacity(0.05)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.auto_awesome, color: AppColors.primary, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Resposta da IA',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primary),
                  ),
                ],
              ),
              if (hasResponse)
                IconButton(
                  icon: Icon(Icons.copy, size: 20, color: AppColors.primary),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: responseText));
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Resposta copiada!')));
                  },
                ),
            ],
          ),
          SizedBox(height: 12),
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
            child: hasResponse
                ? MarkdownBody(
                    data: responseText,
                    selectable: true,
                    styleSheet: MarkdownStyleSheet(
                      p: TextStyle(fontSize: 14, color: Colors.black87, height: 1.6),
                      h1: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.offBlack),
                      h2: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.offBlack),
                      h3: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.offBlack),
                      strong: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
                      em: TextStyle(fontStyle: FontStyle.italic, color: Colors.black87),
                      blockquoteDecoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.05),
                        border: Border(left: BorderSide(color: AppColors.primary, width: 3)),
                      ),
                      blockquotePadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      code: TextStyle(fontFamily: 'monospace', fontSize: 13, backgroundColor: Colors.grey[100]),
                      codeblockDecoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(6),
                      ),
                      listBullet: TextStyle(fontSize: 14, color: AppColors.primary),
                    ),
                  )
                : Text(
                    'Resposta ainda não disponível',
                    style: TextStyle(fontSize: 14, color: Colors.grey[500], fontStyle: FontStyle.italic),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildArchiveButton(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: () async {
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Arquivar Análise'),
            content: Text(
              'Tem certeza que deseja arquivar esta análise? Ela não aparecerá mais no histórico principal.',
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: Text('Cancelar')),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                child: Text('Arquivar'),
              ),
            ],
          ),
        );

        if (confirmed == true && mounted) {
          try {
            await DependencyContainer().aiAnalysisRepository.archiveAnalysis(widget.analysis.id);

            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Análise arquivada com sucesso')));
              Navigator.pop(context, true); // Return to previous screen with refresh signal
            }
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Erro ao arquivar: ${e.toString().replaceAll("Exception: ", "")}'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        }
      },
      icon: Icon(Icons.archive_outlined),
      label: Text('Arquivar'),
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.orange,
        side: BorderSide(color: Colors.orange),
        padding: EdgeInsets.symmetric(vertical: 16),
      ),
    );
  }

  Widget _buildUnarchiveButton(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: () async {
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Desarquivar Análise'),
            content: Text('Deseja desarquivar esta análise? Ela voltará a aparecer no histórico principal.'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: Text('Cancelar')),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
                child: Text('Desarquivar'),
              ),
            ],
          ),
        );

        if (confirmed == true && mounted) {
          try {
            await DependencyContainer().aiAnalysisRepository.unarchiveAnalysis(widget.analysis.id);

            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Análise desarquivada com sucesso')));
              Navigator.pop(context, true); // Return to previous screen with refresh signal
            }
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Erro ao desarquivar: ${e.toString().replaceAll("Exception: ", "")}'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        }
      },
      icon: Icon(Icons.unarchive),
      label: Text('Desarquivar'),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primary,
        side: BorderSide(color: AppColors.primary),
        padding: EdgeInsets.symmetric(vertical: 16),
      ),
    );
  }
}
