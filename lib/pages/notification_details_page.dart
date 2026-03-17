import 'package:flutter/material.dart';

import '../controllers/app_controller.dart';
import '../models/offline_notification.dart';
import '../services/text_formatter.dart';

class NotificationDetailsPage extends StatefulWidget {
  const NotificationDetailsPage({
    super.key,
    required this.controller,
    required this.notification,
  });

  final AppController controller;
  final OfflineNotification notification;

  @override
  State<NotificationDetailsPage> createState() =>
      _NotificationDetailsPageState();
}

class _NotificationDetailsPageState extends State<NotificationDetailsPage> {
  late OfflineNotification _notification = widget.notification;
  bool _isRetrying = false;

  Future<void> _retry() async {
    setState(() {
      _isRetrying = true;
    });

    try {
      final result = await widget.controller.retryOfflineNotification(
        _notification.id,
      );

      if (!mounted) {
        return;
      }

      if (result.success) {
        Navigator.of(context).pop(true);
        return;
      }

      if (result.record != null) {
        setState(() {
          _notification = result.record!;
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isRetrying = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final response = _notification.response;

    return Scaffold(
      appBar: AppBar(title: const Text('Falha de envio')),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFF4F7FB), Color(0xFFF8FAFC), Color(0xFFFFF7ED)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: [
              _HeroSummaryCard(notification: _notification),
              const SizedBox(height: 16),
              _SectionCard(
                title: 'Requisição',
                accentColor: colorScheme.primary,
                child: _CodePanel(
                  lines: [
                    'Método: ${_notification.request.method}',
                    'URL: ${_notification.request.url}',
                    'Tentativa: ${formatTimestamp(_notification.request.attemptedAt)}',
                    '',
                    prettyJsonIfPossible(_notification.request.body),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _SectionCard(
                title: 'Resposta',
                accentColor: colorScheme.secondary,
                child: _CodePanel(
                  lines: [
                    'Status: ${response.statusCode?.toString() ?? 'sem status'}',
                    'Recebido em: ${formatTimestamp(response.receivedAt)}',
                    if (response.errorMessage != null &&
                        response.errorMessage!.trim().isNotEmpty)
                      'Erro: ${response.errorMessage}',
                    '',
                    if (response.body != null &&
                        response.body!.trim().isNotEmpty)
                      prettyJsonIfPossible(response.body!)
                    else
                      'Sem corpo de resposta.',
                  ],
                ),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: _isRetrying ? null : _retry,
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(56),
                  backgroundColor: const Color(0xFF0F766E),
                ),
                icon: _isRetrying
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.refresh_rounded),
                label: Text(_isRetrying ? 'Reenviando...' : 'Enviar de novo'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeroSummaryCard extends StatelessWidget {
  const _HeroSummaryCard({required this.notification});

  final OfflineNotification notification;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          colors: [Color(0xFF082F49), Color(0xFF0F766E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x22082F49),
            blurRadius: 24,
            offset: Offset(0, 16),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0x1FFFFFFF),
              borderRadius: BorderRadius.circular(999),
            ),
            child: const Text(
              'Offline aguardando backend',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 18),
          SelectableText(
            notification.app,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          SelectableText(
            notification.text,
            style: const TextStyle(color: Color(0xFFE2E8F0), height: 1.45),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.accentColor,
    required this.child,
  });

  final String title;
  final Color accentColor;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x110F172A),
            blurRadius: 16,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: accentColor,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            child,
          ],
        ),
      ),
    );
  }
}

class _CodePanel extends StatelessWidget {
  const _CodePanel({required this.lines});

  final List<String> lines;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF111827),
        borderRadius: BorderRadius.circular(18),
      ),
      child: SelectableText(
        lines.join('\n'),
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: const Color(0xFFE5E7EB),
          height: 1.5,
        ),
      ),
    );
  }
}
