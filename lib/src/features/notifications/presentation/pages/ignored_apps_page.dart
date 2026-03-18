import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../domain/entities/installed_app.dart';
import '../controllers/app_controller.dart';

class IgnoredAppsPage extends StatefulWidget {
  const IgnoredAppsPage({super.key, required this.controller});

  final AppController controller;

  @override
  State<IgnoredAppsPage> createState() => _IgnoredAppsPageState();
}

class _IgnoredAppsPageState extends State<IgnoredAppsPage> {
  String _query = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(widget.controller.ensureInstalledAppsLoaded());
    });
  }

  Future<void> _setIgnoredApp(InstalledApp app, bool isIgnored) async {
    try {
      await widget.controller.setAppIgnored(
        packageName: app.packageName,
        isIgnored: isIgnored,
      );
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isIgnored
                ? '${app.name} foi adicionado aos apps ignorados'
                : '${app.name} foi removido dos apps ignorados',
          ),
          backgroundColor: const Color(0xFF0F766E),
        ),
      );
    } on PlatformException catch (error) {
      _showError(error.message ?? error.code);
    } on MissingPluginException {
      _showError('Integração Android indisponível nesta plataforma.');
    } catch (error) {
      _showError(error.toString());
    }
  }

  void _showError(String message) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFFB91C1C),
      ),
    );
  }

  List<InstalledApp> _filterApps(List<InstalledApp> apps) {
    final normalizedQuery = _query.trim().toLowerCase();
    if (normalizedQuery.isEmpty) {
      return apps;
    }

    return apps
        .where((app) {
          return app.name.toLowerCase().contains(normalizedQuery) ||
              app.packageName.toLowerCase().contains(normalizedQuery);
        })
        .toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, _) {
        final filteredApps = _filterApps(widget.controller.installedApps);
        final ignoredApps = filteredApps
            .where((app) => app.isIgnored)
            .toList(growable: false);
        final availableApps = filteredApps
            .where((app) => !app.isIgnored)
            .toList(growable: false);

        return Scaffold(
          appBar: AppBar(
            title: const Text('Apps ignorados'),
            backgroundColor: Colors.transparent,
            foregroundColor: const Color(0xFF0F172A),
            elevation: 0,
          ),
          body: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFFFFF7ED),
                  Color(0xFFF8FAFC),
                  Color(0xFFE0F2FE),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: SafeArea(
              top: false,
              child: RefreshIndicator(
                color: const Color(0xFF0E7490),
                onRefresh: widget.controller.refreshInstalledApps,
                child: CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                        child: _SummaryPanel(
                          ignoredCount: widget.controller.ignoredApps.length,
                          totalCount: widget.controller.installedApps.length,
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                        child: TextField(
                          onChanged: (value) {
                            setState(() {
                              _query = value;
                            });
                          },
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: Colors.white,
                            hintText: 'Buscar por nome ou package name',
                            prefixIcon: const Icon(Icons.search_rounded),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 16,
                            ),
                          ),
                        ),
                      ),
                    ),
                    if (widget.controller.installedAppsErrorMessage != null)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                          child: _ErrorCard(
                            message:
                                widget.controller.installedAppsErrorMessage!,
                            onRetry: widget.controller.refreshInstalledApps,
                          ),
                        ),
                      ),
                    if (widget.controller.isLoadingInstalledApps &&
                        widget.controller.installedApps.isEmpty)
                      const SliverFillRemaining(
                        hasScrollBody: false,
                        child: Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFF0E7490),
                          ),
                        ),
                      )
                    else if (filteredApps.isEmpty)
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: _EmptyAppsState(
                          hasQuery: _query.trim().isNotEmpty,
                        ),
                      )
                    else
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
                        sliver: SliverList(
                          delegate: SliverChildListDelegate.fixed([
                            if (ignoredApps.isNotEmpty) ...[
                              _SectionHeader(
                                title: 'Ignorados',
                                count: ignoredApps.length,
                              ),
                              const SizedBox(height: 12),
                              ...ignoredApps.map(
                                (app) => Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: _InstalledAppTile(
                                    app: app,
                                    isUpdating: widget.controller
                                        .isUpdatingIgnoredApp(app.packageName),
                                    onChanged: (value) =>
                                        _setIgnoredApp(app, value),
                                  ),
                                ),
                              ),
                            ],
                            if (availableApps.isNotEmpty) ...[
                              _SectionHeader(
                                title: 'Demais apps',
                                count: availableApps.length,
                              ),
                              const SizedBox(height: 12),
                              ...availableApps.map(
                                (app) => Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: _InstalledAppTile(
                                    app: app,
                                    isUpdating: widget.controller
                                        .isUpdatingIgnoredApp(app.packageName),
                                    onChanged: (value) =>
                                        _setIgnoredApp(app, value),
                                  ),
                                ),
                              ),
                            ],
                          ]),
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

class _SummaryPanel extends StatelessWidget {
  const _SummaryPanel({required this.ignoredCount, required this.totalCount});

  final int ignoredCount;
  final int totalCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(28),
        boxShadow: const [
          BoxShadow(
            color: Color(0x220F172A),
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
              color: const Color(0xFF164E63),
              borderRadius: BorderRadius.circular(999),
            ),
            child: const Text(
              'Blacklist de envio',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Escolha os apps que nunca devem enviar notificações para a API.',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w900,
              height: 1.15,
            ),
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _SummaryChip(
                label: 'Ignorados',
                value: ignoredCount.toString(),
                backgroundColor: const Color(0xFF1D4ED8),
              ),
              _SummaryChip(
                label: 'Apps listados',
                value: totalCount.toString(),
                backgroundColor: const Color(0xFF9A3412),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryChip extends StatelessWidget {
  const _SummaryChip({
    required this.label,
    required this.value,
    required this.backgroundColor,
  });

  final String label;
  final String value;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFFE2E8F0),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFFFE4E6),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFFDA4AF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Falha ao carregar os apps',
            style: TextStyle(
              color: Color(0xFF881337),
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: const TextStyle(color: Color(0xFF9F1239), height: 1.4),
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: () => onRetry(),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFBE123C),
              foregroundColor: Colors.white,
            ),
            child: const Text('Tentar novamente'),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.count});

  final String title;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w900,
            color: const Color(0xFF0F172A),
          ),
        ),
        const SizedBox(width: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFFE2E8F0),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            '$count',
            style: const TextStyle(
              color: Color(0xFF334155),
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _InstalledAppTile extends StatelessWidget {
  const _InstalledAppTile({
    required this.app,
    required this.isUpdating,
    required this.onChanged,
  });

  final InstalledApp app;
  final bool isUpdating;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x120F172A),
            blurRadius: 18,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 10,
        ),
        leading: _AppIcon(app: app),
        title: Text(
          app.name,
          style: const TextStyle(
            color: Color(0xFF0F172A),
            fontWeight: FontWeight.w800,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                app.packageName,
                style: const TextStyle(
                  color: Color(0xFF475569),
                  fontSize: 12,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: app.isIgnored
                      ? const Color(0xFFFFEDD5)
                      : const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  app.isIgnored ? 'Ignorado' : 'Enviado normalmente',
                  style: TextStyle(
                    color: app.isIgnored
                        ? const Color(0xFF9A3412)
                        : const Color(0xFF166534),
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ),
        trailing: SizedBox(
          width: 58,
          child: Center(
            child: isUpdating
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      color: Color(0xFF0E7490),
                    ),
                  )
                : Switch.adaptive(
                    value: app.isIgnored,
                    onChanged: onChanged,
                    activeTrackColor: const Color(0xFF67E8F9),
                    activeThumbColor: const Color(0xFF0E7490),
                  ),
          ),
        ),
      ),
    );
  }
}

class _AppIcon extends StatelessWidget {
  const _AppIcon({required this.app});

  final InstalledApp app;

  @override
  Widget build(BuildContext context) {
    final iconBytes = app.iconBytes;
    if (iconBytes != null && iconBytes.isNotEmpty) {
      return CircleAvatar(
        radius: 24,
        backgroundColor: const Color(0xFFF8FAFC),
        backgroundImage: MemoryImage(iconBytes),
      );
    }

    return const CircleAvatar(
      radius: 24,
      backgroundColor: Color(0xFFE2E8F0),
      foregroundColor: Color(0xFF334155),
      child: Icon(Icons.android_rounded),
    );
  }
}

class _EmptyAppsState extends StatelessWidget {
  const _EmptyAppsState({required this.hasQuery});

  final bool hasQuery;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              color: const Color(0xFFE0F2FE),
              borderRadius: BorderRadius.circular(28),
            ),
            child: const Icon(
              Icons.search_off_rounded,
              size: 42,
              color: Color(0xFF0369A1),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            hasQuery
                ? 'Nenhum app encontrado para essa busca.'
                : 'Nenhum app disponível para configurar.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w900,
              color: const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            hasQuery
                ? 'Ajuste o filtro para encontrar apps ignorados ou ativos.'
                : 'Puxe a lista para baixo para tentar carregar novamente.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Color(0xFF475569), height: 1.5),
          ),
        ],
      ),
    );
  }
}
