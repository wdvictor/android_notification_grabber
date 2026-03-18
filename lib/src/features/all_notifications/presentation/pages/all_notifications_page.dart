import 'package:flutter/material.dart';

import '../../../../app/dependency_container.dart';
import '../../domain/entities/all_notification.dart';
import '../controllers/all_notifications_controller.dart';

class AllNotificationsPage extends StatefulWidget {
  const AllNotificationsPage({super.key, AllNotificationsController? controller})
    : _controller = controller;

  final AllNotificationsController? _controller;

  @override
  State<AllNotificationsPage> createState() => _AllNotificationsPageState();
}

class _AllNotificationsPageState extends State<AllNotificationsPage> {
  late final AllNotificationsController _controller =
      widget._controller ?? DependencyContainer.createAllNotificationsController();
  late final bool _ownsController = widget._controller == null;
  late final TextEditingController _queryController = TextEditingController(
    text: _controller.currentSearchText,
  );

  @override
  void initState() {
    super.initState();
    _controller.initialize();
  }

  @override
  void dispose() {
    _queryController.dispose();
    if (_ownsController) {
      _controller.dispose();
    }
    super.dispose();
  }

  Future<void> _applyFilters() async {
    FocusScope.of(context).unfocus();
    await _controller.applyFilters(
      searchText: _queryController.text,
      filter: _controller.selectedFilter,
    );
  }

  Future<void> _clearFilters() async {
    _queryController.clear();
    await _controller.applyFilters(searchText: '', filter: FinancialTransactionFilterOption.any);
  }

  void _showUpdatePlaceholder({required AllNotification notification, required bool value}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Atualização para $value de ${notification.app} será implementada depois.'),
        backgroundColor: const Color(0xFF334155),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Todas as notificações'),
            backgroundColor: Colors.transparent,
            foregroundColor: const Color(0xFF0F172A),
          ),
          body: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFE0F2FE), Color(0xFFF8FAFC), Color(0xFFFFF7ED)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: SafeArea(
              top: false,
              child: RefreshIndicator(
                color: const Color(0xFF0E7490),
                onRefresh: _controller.refresh,
                child: CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                        child: _SummaryCard(
                          currentPage: _controller.currentPage,
                          itemCount: _controller.notifications.length,
                          filter: _controller.selectedFilter,
                          searchText: _controller.currentSearchText,
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                        child: _FilterCard(
                          queryController: _queryController,
                          selectedFilter: _controller.selectedFilter,
                          isLoading: _controller.isLoading,
                          onFilterChanged: (value) async {
                            if (value == null) {
                              return;
                            }

                            await _controller.applyFilters(
                              searchText: _queryController.text,
                              filter: value,
                            );
                          },
                          onApply: _applyFilters,
                          onClear: _clearFilters,
                        ),
                      ),
                    ),
                    if (_controller.errorMessage != null)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                          child: _ErrorCard(
                            message: _controller.errorMessage!,
                            onRetry: _controller.refresh,
                          ),
                        ),
                      ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 18, 16, 8),
                        child: Text(
                          'Resultados da API',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF0F172A),
                          ),
                        ),
                      ),
                    ),
                    if (_controller.isLoading)
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                        sliver: SliverList.separated(
                          itemCount: 6,
                          itemBuilder: (_, _) => const _NotificationSkeleton(),
                          separatorBuilder: (_, _) => const SizedBox(height: 14),
                        ),
                      )
                    else if (_controller.notifications.isEmpty)
                      const SliverFillRemaining(hasScrollBody: false, child: _EmptyState())
                    else
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                        sliver: SliverList.separated(
                          itemCount: _controller.notifications.length,
                          itemBuilder: (context, index) {
                            final notification = _controller.notifications[index];
                            return _NotificationCard(
                              notification: notification,
                              onMarkTrue: () =>
                                  _showUpdatePlaceholder(notification: notification, value: true),
                              onMarkFalse: () =>
                                  _showUpdatePlaceholder(notification: notification, value: false),
                            );
                          },
                          separatorBuilder: (_, _) => const SizedBox(height: 14),
                        ),
                      ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                        child: _PaginationCard(
                          currentPage: _controller.currentPage,
                          hasPreviousPage: _controller.hasPreviousPage,
                          hasNextPage: _controller.hasNextPage,
                          isLoading: _controller.isLoading,
                          onPrevious: _controller.goToPreviousPage,
                          onNext: _controller.goToNextPage,
                        ),
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

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.currentPage,
    required this.itemCount,
    required this.filter,
    required this.searchText,
  });

  final int currentPage;
  final int itemCount;
  final FinancialTransactionFilterOption filter;
  final String searchText;

  @override
  Widget build(BuildContext context) {
    final searchDescription = searchText.isEmpty ? 'Sem busca textual' : searchText;
    final filterDescription = switch (filter) {
      FinancialTransactionFilterOption.any => 'Sem filtro de transação',
      FinancialTransactionFilterOption.onlyTrue => 'Somente true',
      FinancialTransactionFilterOption.onlyFalse => 'Somente false',
    };

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
          BoxShadow(color: Color(0x1F082F49), blurRadius: 28, offset: Offset(0, 18)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Página $currentPage',
            style: Theme.of(
              context,
            ).textTheme.headlineMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          Text(
            '$itemCount registros carregados nesta página.',
            style: const TextStyle(color: Color(0xFFE2E8F0), fontSize: 16, height: 1.4),
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _SummaryPill(label: filterDescription),
              _SummaryPill(label: searchDescription),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryPill extends StatelessWidget {
  const _SummaryPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0x1AFFFFFF),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0x33FFFFFF)),
      ),
      child: Text(
        label,
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _FilterCard extends StatelessWidget {
  const _FilterCard({
    required this.queryController,
    required this.selectedFilter,
    required this.isLoading,
    required this.onFilterChanged,
    required this.onApply,
    required this.onClear,
  });

  final TextEditingController queryController;
  final FinancialTransactionFilterOption selectedFilter;
  final bool isLoading;
  final ValueChanged<FinancialTransactionFilterOption?> onFilterChanged;
  final Future<void> Function() onApply;
  final Future<void> Function() onClear;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFBAE6FD)),
        boxShadow: const [
          BoxShadow(color: Color(0x140F172A), blurRadius: 24, offset: Offset(0, 12)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Filtros',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
              color: const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'O campo p sempre é enviado. q e isft só são enviados quando existirem.',
            style: TextStyle(color: Color(0xFF475569), fontSize: 14, height: 1.4),
          ),
          const SizedBox(height: 18),
          TextField(
            controller: queryController,
            enabled: !isLoading,
            textInputAction: TextInputAction.search,
            onSubmitted: (_) => onApply(),
            decoration: InputDecoration(
              labelText: 'Buscar em q',
              hintText: 'Ex.: pix recebido',
              prefixIcon: const Icon(Icons.search_rounded),
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<FinancialTransactionFilterOption>(
            key: ValueKey<FinancialTransactionFilterOption>(selectedFilter),
            initialValue: selectedFilter,
            items: FinancialTransactionFilterOption.values
                .map((option) => DropdownMenuItem(value: option, child: Text(option.label)))
                .toList(growable: false),
            onChanged: isLoading ? null : onFilterChanged,
            decoration: InputDecoration(
              labelText: 'Filtro isft',
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              FilledButton.icon(
                onPressed: isLoading ? null : () => onApply(),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF0E7490),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                ),
                icon: const Icon(Icons.filter_alt_rounded),
                label: const Text('Aplicar filtros'),
              ),
              OutlinedButton.icon(
                onPressed: isLoading ? null : () => onClear(),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF0F172A),
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                ),
                icon: const Icon(Icons.cleaning_services_outlined),
                label: const Text('Limpar'),
              ),
            ],
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
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7ED),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFF97316)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.error_outline_rounded, color: Color(0xFFEA580C)),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Falha ao carregar a API',
                  style: TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF9A3412)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(message, style: const TextStyle(color: Color(0xFF7C2D12), height: 1.5)),
          const SizedBox(height: 14),
          FilledButton(
            onPressed: () => onRetry(),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFEA580C),
              foregroundColor: Colors.white,
            ),
            child: const Text('Tentar novamente'),
          ),
        ],
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({
    required this.notification,
    required this.onMarkTrue,
    required this.onMarkFalse,
  });

  final AllNotification notification;
  final VoidCallback onMarkTrue;
  final VoidCallback onMarkFalse;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(color: Color(0x120F172A), blurRadius: 20, offset: Offset(0, 12)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 10,
            runSpacing: 10,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFE0F2FE),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  notification.app,
                  style: const TextStyle(color: Color(0xFF0C4A6E), fontWeight: FontWeight.w800),
                ),
              ),
              _FinancialStatusChip(isFinancialTransaction: notification.isFinancialTransaction),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            notification.preview,
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(color: const Color(0xFF0F172A), height: 1.55),
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              FilledButton.icon(
                onPressed: onMarkTrue,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF15803D),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                ),
                icon: const Icon(Icons.check_circle_outline_rounded),
                label: const Text('Atualizar para true'),
              ),
              OutlinedButton.icon(
                onPressed: onMarkFalse,
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFB91C1C),
                  side: const BorderSide(color: Color(0xFFFECACA)),
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                ),
                icon: const Icon(Icons.remove_circle_outline_rounded),
                label: const Text('Atualizar para false'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FinancialStatusChip extends StatelessWidget {
  const _FinancialStatusChip({required this.isFinancialTransaction});

  final bool? isFinancialTransaction;

  @override
  Widget build(BuildContext context) {
    final (label, foregroundColor, backgroundColor) = switch (isFinancialTransaction) {
      true => ('Transação financeira', const Color(0xFF166534), const Color(0xFFDCFCE7)),
      false => ('Não é transação financeira', const Color(0xFF991B1B), const Color(0xFFFEE2E2)),
      null => ('Classificar', const Color(0xFF475569), const Color(0xFFE2E8F0)),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(color: backgroundColor, borderRadius: BorderRadius.circular(999)),
      child: Text(
        label,
        style: TextStyle(color: foregroundColor, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _NotificationSkeleton extends StatelessWidget {
  const _NotificationSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SkeletonLine(width: 150, height: 18),
          SizedBox(height: 12),
          _SkeletonLine(width: double.infinity, height: 14),
          SizedBox(height: 8),
          _SkeletonLine(width: double.infinity, height: 14),
          SizedBox(height: 8),
          _SkeletonLine(width: 220, height: 14),
          SizedBox(height: 18),
          Row(
            children: [
              Expanded(child: _SkeletonLine(width: double.infinity, height: 44)),
              SizedBox(width: 12),
              Expanded(child: _SkeletonLine(width: double.infinity, height: 44)),
            ],
          ),
        ],
      ),
    );
  }
}

class _SkeletonLine extends StatelessWidget {
  const _SkeletonLine({required this.width, required this.height});

  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFFE2E8F0),
        borderRadius: BorderRadius.circular(999),
      ),
    );
  }
}

class _PaginationCard extends StatelessWidget {
  const _PaginationCard({
    required this.currentPage,
    required this.hasPreviousPage,
    required this.hasNextPage,
    required this.isLoading,
    required this.onPrevious,
    required this.onNext,
  });

  final int currentPage;
  final bool hasPreviousPage;
  final bool hasNextPage;
  final bool isLoading;
  final Future<void> Function() onPrevious;
  final Future<void> Function() onNext;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        runAlignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 12,
        runSpacing: 12,
        children: [
          Text(
            'Página atual: $currentPage',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: const Color(0xFF0F172A),
            ),
          ),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              OutlinedButton.icon(
                onPressed: !hasPreviousPage || isLoading ? null : () => onPrevious(),
                icon: const Icon(Icons.chevron_left_rounded),
                label: const Text('Anterior'),
              ),
              FilledButton.icon(
                onPressed: !hasNextPage || isLoading ? null : () => onNext(),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF0E7490),
                  foregroundColor: Colors.white,
                ),
                icon: const Icon(Icons.chevron_right_rounded),
                label: const Text('Próxima'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.92),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  color: const Color(0xFFE0F2FE),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Icon(Icons.dataset_outlined, size: 38, color: Color(0xFF0E7490)),
              ),
              const SizedBox(height: 18),
              Text(
                'Nenhum dado retornado',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'A API não retornou registros para os filtros aplicados nesta página.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Color(0xFF475569), fontSize: 15, height: 1.5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
