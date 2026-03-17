import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/formatters/text_formatter.dart';
import '../../domain/entities/offline_notification.dart';
import '../controllers/app_controller.dart';
import 'notification_details_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.controller});

  final AppController controller;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool _isNavigatingToDetails = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_handleControllerChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _handleControllerChanged();
    });
  }

  @override
  void dispose() {
    widget.controller.removeListener(_handleControllerChanged);
    super.dispose();
  }

  Future<void> _handleControllerChanged() async {
    if (_isNavigatingToDetails || !mounted) {
      return;
    }

    final targetId = widget.controller.takePendingNavigationTarget();
    if (targetId == null) {
      return;
    }

    var notification = widget.controller.findNotificationById(targetId);
    if (notification == null) {
      await widget.controller.refresh();
      notification = widget.controller.findNotificationById(targetId);
    }

    if (!mounted || notification == null) {
      return;
    }

    _isNavigatingToDetails = true;
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => NotificationDetailsPage(
          controller: widget.controller,
          notification: notification!,
        ),
      ),
    );
    _isNavigatingToDetails = false;

    if (!mounted) {
      return;
    }

    if (result == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Notificação enviada com sucesso'),
          backgroundColor: Color(0xFF15803D),
        ),
      );
    }
  }

  Future<void> _retryAll() async {
    final result = await widget.controller.retryAllOfflineNotifications();
    if (!mounted) {
      return;
    }

    final messenger = ScaffoldMessenger.of(context);
    if (result.failureCount == 0 && result.successCount > 0) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            '${result.successCount} notificações enviadas com sucesso',
          ),
          backgroundColor: const Color(0xFF15803D),
        ),
      );
      return;
    }

    if (result.successCount == 0 && result.failureCount == 0) {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Não existem notificações offline para reenviar'),
          backgroundColor: Color(0xFF334155),
        ),
      );
      return;
    }

    messenger.showSnackBar(
      SnackBar(
        content: Text(
          'Reenvio concluído: ${result.successCount} sucesso, ${result.failureCount} falha',
        ),
        backgroundColor: const Color(0xFFB45309),
      ),
    );
  }

  Future<void> _openDetails(OfflineNotification notification) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => NotificationDetailsPage(
          controller: widget.controller,
          notification: notification,
        ),
      ),
    );

    if (!mounted || result != true) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Notificação enviada com sucesso'),
        backgroundColor: Color(0xFF15803D),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, _) {
        return Scaffold(
          body: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFFE0F2FE),
                  Color(0xFFF8FAFC),
                  Color(0xFFFFF7ED),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: SafeArea(
              child: RefreshIndicator(
                color: const Color(0xFF0E7490),
                onRefresh: widget.controller.refresh,
                child: CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                        child: _HeroPanel(
                          total: widget.controller.offlineNotifications.length,
                          isRetryingAll: widget.controller.isRetryingAll,
                          onRetryAll: _retryAll,
                        ),
                      ),
                    ),
                    if (widget.controller.errorMessage != null)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                          child: _WarningBanner(
                            icon: Icons.error_outline_rounded,
                            title: 'Falha ao carregar dados do Android',
                            description: widget.controller.errorMessage!,
                            actionLabel: 'Tentar de novo',
                            onTap: widget.controller.refresh,
                          ),
                        ),
                      ),
                    if (!widget.controller.notificationAccessGranted)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                          child: _WarningBanner(
                            icon: Icons.notifications_active_outlined,
                            title: 'Acesso às notificações desativado',
                            description:
                                'Sem essa permissão o app não consegue capturar notificações em background.',
                            actionLabel: 'Abrir ajustes',
                            onTap: widget
                                .controller
                                .openNotificationAccessSettings,
                          ),
                        ),
                      ),
                    if (!widget.controller.notificationPermissionGranted)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                          child: _WarningBanner(
                            icon: Icons.campaign_outlined,
                            title: 'Permissão de push pendente',
                            description:
                                'Sem essa permissão o Android pode bloquear o alerta local quando o backend falhar.',
                            actionLabel: 'Permitir',
                            onTap:
                                widget.controller.requestNotificationPermission,
                          ),
                        ),
                      ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 18, 16, 8),
                        child: Text(
                          'Fila offline',
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF0F172A),
                              ),
                        ),
                      ),
                    ),
                    if (widget.controller.isLoading &&
                        widget.controller.offlineNotifications.isEmpty)
                      const SliverFillRemaining(
                        hasScrollBody: false,
                        child: Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFF0E7490),
                          ),
                        ),
                      )
                    else if (widget.controller.offlineNotifications.isEmpty)
                      const SliverFillRemaining(
                        hasScrollBody: false,
                        child: _EmptyState(),
                      )
                    else
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                        sliver: SliverList.separated(
                          itemCount:
                              widget.controller.offlineNotifications.length,
                          itemBuilder: (context, index) {
                            final notification =
                                widget.controller.offlineNotifications[index];
                            return _OfflineNotificationTile(
                              notification: notification,
                              onTap: () => _openDetails(notification),
                            );
                          },
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: 14),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _HeroPanel extends StatelessWidget {
  const _HeroPanel({
    required this.total,
    required this.isRetryingAll,
    required this.onRetryAll,
  });

  final int total;
  final bool isRetryingAll;
  final Future<void> Function() onRetryAll;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          colors: [Color(0xFF082F49), Color(0xFF0E7490), Color(0xFF14B8A6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1F082F49),
            blurRadius: 28,
            offset: Offset(0, 18),
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
              'Monitor Android em background',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Notification Grabber',
            style: TextStyle(
              color: Colors.white,
              fontSize: 30,
              fontWeight: FontWeight.w900,
              height: 1.05,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            total == 0
                ? 'Nenhuma notificação está offline neste momento.'
                : '$total notificações aguardando envio ao endpoint.',
            style: const TextStyle(
              color: Color(0xFFE2E8F0),
              fontSize: 16,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: isRetryingAll ? null : onRetryAll,
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFFFF7ED),
              foregroundColor: const Color(0xFF9A3412),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            ),
            icon: isRetryingAll
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Color(0xFF9A3412),
                    ),
                  )
                : const Icon(Icons.sync_rounded),
            label: Text(
              isRetryingAll ? 'Reenviando...' : 'Tentar de novo tudo',
            ),
          ),
        ],
      ),
    );
  }
}

class _WarningBanner extends StatelessWidget {
  const _WarningBanner({
    required this.icon,
    required this.title,
    required this.description,
    required this.actionLabel,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String description;
  final String actionLabel;
  final Future<void> Function() onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFF59E0B)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14F59E0B),
            blurRadius: 12,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF7ED),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(icon, color: const Color(0xFFB45309)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  description,
                  style: const TextStyle(
                    height: 1.45,
                    color: Color(0xFF475569),
                  ),
                ),
                const SizedBox(height: 10),
                TextButton.icon(
                  onPressed: onTap,
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    foregroundColor: const Color(0xFF9A3412),
                  ),
                  icon: const Icon(Icons.arrow_forward_rounded),
                  label: Text(actionLabel),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OfflineNotificationTile extends StatelessWidget {
  const _OfflineNotificationTile({
    required this.notification,
    required this.onTap,
  });

  final OfflineNotification notification;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final statusCode = notification.response.statusCode;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Ink(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: const [
              BoxShadow(
                color: Color(0x110F172A),
                blurRadius: 18,
                offset: Offset(0, 12),
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
                    Expanded(
                      child: SelectableText(
                        notification.app,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    _StatusChip(statusCode: statusCode),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  notification.preview,
                  style: const TextStyle(
                    color: Color(0xFF334155),
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Última tentativa: ${formatTimestamp(notification.request.attemptedAt)}',
                        style: const TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 16,
                      color: Color(0xFF94A3B8),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.statusCode});

  final int? statusCode;

  @override
  Widget build(BuildContext context) {
    final backgroundColor = switch (statusCode) {
      201 => const Color(0xFFDCFCE7),
      null => const Color(0xFFFFEDD5),
      _ => const Color(0xFFFEE2E2),
    };
    final foregroundColor = switch (statusCode) {
      201 => const Color(0xFF166534),
      null => const Color(0xFF9A3412),
      _ => const Color(0xFFB91C1C),
    };
    final label = statusCode?.toString() ?? 'sem status';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(color: foregroundColor, fontWeight: FontWeight.w800),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 82,
              height: 82,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x110F172A),
                    blurRadius: 18,
                    offset: Offset(0, 12),
                  ),
                ],
              ),
              child: const Icon(
                Icons.cloud_done_outlined,
                size: 40,
                color: Color(0xFF0E7490),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'Nenhuma falha pendente',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
                color: const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Quando o backend falhar, as notificações ficarão disponíveis aqui para reenvio manual.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFF475569), height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}
