import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/gasto.dart';

// ─────────────────────────────────────────────
// Animated counter widget
// ─────────────────────────────────────────────
class _AnimatedTotal extends StatefulWidget {
  final double value;
  final String Function(double) format;
  const _AnimatedTotal({required this.value, required this.format});

  @override
  State<_AnimatedTotal> createState() => _AnimatedTotalState();
}

class _AnimatedTotalState extends State<_AnimatedTotal>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;
  double _prev = 0;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        duration: const Duration(milliseconds: 600), vsync: this);
    _anim = Tween<double>(begin: 0, end: widget.value).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    _ctrl.forward();
  }

  @override
  void didUpdateWidget(_AnimatedTotal old) {
    super.didUpdateWidget(old);
    if (old.value != widget.value) {
      _prev = old.value;
      _anim = Tween<double>(begin: _prev, end: widget.value).animate(
          CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
      _ctrl
        ..reset()
        ..forward();
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (ctx2, child2) => Text(
        widget.format(_anim.value),
        style: const TextStyle(
          fontSize: 36,
          fontWeight: FontWeight.w800,
          letterSpacing: -1.5,
          color: Colors.white,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// Slide-fade item wrapper
// ─────────────────────────────────────────────
class _SlideFadeItem extends StatefulWidget {
  final Widget child;
  final int index;
  const _SlideFadeItem({required this.child, required this.index});

  @override
  State<_SlideFadeItem> createState() => _SlideFadeItemState();
}

class _SlideFadeItemState extends State<_SlideFadeItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fade;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      duration: Duration(milliseconds: 300 + widget.index * 40),
      vsync: this,
    );
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(position: _slide, child: widget.child),
    );
  }
}

// ─────────────────────────────────────────────
// Shake animation for validation feedback
// ─────────────────────────────────────────────
class _ShakeWidget extends StatefulWidget {
  final Widget child;
  final GlobalKey<_ShakeWidgetState> shakeKey;
  const _ShakeWidget({required this.child, required this.shakeKey})
      : super(key: shakeKey);

  @override
  State<_ShakeWidget> createState() => _ShakeWidgetState();
}

class _ShakeWidgetState extends State<_ShakeWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        duration: const Duration(milliseconds: 400), vsync: this);
    _anim = Tween<double>(begin: 0, end: 1).animate(_ctrl);
  }

  void shake() {
    _ctrl.reset();
    _ctrl.forward();
    HapticFeedback.heavyImpact();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, child) {
        final dx = _ctrl.isAnimating
            ? 6 * (0.5 - (_anim.value - (_anim.value).floor())).abs() *
                ((_anim.value * 8).floor().isEven ? 1 : -1)
            : 0.0;
        return Transform.translate(offset: Offset(dx, 0), child: child);
      },
      child: widget.child,
    );
  }
}

// ─────────────────────────────────────────────
// Main Screen
// ─────────────────────────────────────────────
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Gasto> gastos = [];
  Categoria? _filtroCategoria;

  // ── Helpers ─────────────────────────────────
  List<Gasto> get gastosFiltrados {
    if (_filtroCategoria == null) return gastos;
    return gastos
        .where((g) => g.categoria.nombre == _filtroCategoria!.nombre)
        .toList();
  }

  double get _total => gastos.fold(0, (s, g) => s + g.monto);
  double get _totalFiltrado => gastosFiltrados.fold(0, (s, g) => s + g.monto);

  Gasto? get _gastoMayor =>
      gastos.isEmpty ? null : gastos.reduce((a, b) => a.monto > b.monto ? a : b);

  String formatMonto(double monto) {
    final s = monto.toStringAsFixed(2).replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},');
    return '\$ $s';
  }

  // ── Grouping ────────────────────────────────
  /// Returns a list where each element is either a String (date header)
  /// or a Gasto (item).
  List<dynamic> _buildGroupedList() {
    final lista = gastosFiltrados;
    if (lista.isEmpty) return [];

    final ahora = DateTime.now();
    final hoy = DateTime(ahora.year, ahora.month, ahora.day);
    final ayer = hoy.subtract(const Duration(days: 1));

    String lastHeader = '';
    final result = <dynamic>[];

    for (final g in lista) {
      final d = DateTime(g.fecha.year, g.fecha.month, g.fecha.day);
      String header;
      if (d == hoy) {
        header = 'Hoy';
      } else if (d == ayer) {
        header = 'Ayer';
      } else {
        header = '${d.day}/${d.month}/${d.year}';
      }
      if (header != lastHeader) {
        result.add(header);
        lastHeader = header;
      }
      result.add(g);
    }
    return result;
  }

  // ── Add / Edit dialog ───────────────────────
  void _mostrarFormulario({Gasto? editar}) {
    final descripcionController =
        TextEditingController(text: editar?.descripcion ?? '');
    final montoController =
        TextEditingController(text: editar != null ? editar.monto.toString() : '');
    Categoria selectedCategoria = editar?.categoria ?? categorias.first;

    final descShakeKey = GlobalKey<_ShakeWidgetState>();
    final montoShakeKey = GlobalKey<_ShakeWidgetState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            void guardar() {
              final desc = descripcionController.text.trim();
              final monto = double.tryParse(montoController.text) ?? 0;

              bool valid = true;
              if (desc.isEmpty) {
                descShakeKey.currentState?.shake();
                valid = false;
              }
              if (monto <= 0) {
                montoShakeKey.currentState?.shake();
                valid = false;
              }
              if (!valid) return;

              HapticFeedback.mediumImpact();
              setState(() {
                if (editar != null) {
                  final idx = gastos.indexOf(editar);
                  gastos[idx] = Gasto(
                    descripcion: desc,
                    monto: monto,
                    categoria: selectedCategoria,
                    fecha: editar.fecha,
                  );
                } else {
                  gastos.insert(
                      0,
                      Gasto(
                        descripcion: desc,
                        monto: monto,
                        categoria: selectedCategoria,
                      ));
                }
              });
              Navigator.pop(ctx);
            }

            return Container(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
                top: 8,
                left: 24,
                right: 24,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1B2E),
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(28)),
                border: Border(
                  top: BorderSide(color: Colors.white.withAlpha(20)),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Handle bar
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(51),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),

                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF9C7EE8).withAlpha(25),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          editar != null
                              ? Icons.edit_outlined
                              : Icons.add_rounded,
                          color: const Color(0xFF9C7EE8),
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        editar != null ? 'Editar gasto' : 'Nuevo gasto',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),

                  // ── Categorías ──────────────
                  const _Label('Categoría'),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 44,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: categorias.length,
                      separatorBuilder: (context2, index2) => const SizedBox(width: 8),
                      itemBuilder: (context2, i) {
                        final cat = categorias[i];
                        final sel = cat.nombre == selectedCategoria.nombre;
                        return GestureDetector(
                          onTap: () =>
                              setModalState(() => selectedCategoria = cat),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: sel
                                  ? Color(cat.color).withAlpha(40)
                                  : const Color(0xFF2A2640),
                              borderRadius: BorderRadius.circular(22),
                              border: Border.all(
                                color: sel
                                    ? Color(cat.color)
                                    : Colors.transparent,
                                width: 1.5,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  IconData(cat.icono,
                                      fontFamily: 'MaterialIcons'),
                                  size: 16,
                                  color: sel
                                      ? Color(cat.color)
                                      : Colors.white54,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  cat.nombre,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: sel
                                        ? FontWeight.w600
                                        : FontWeight.w400,
                                    color: sel
                                        ? Color(cat.color)
                                        : Colors.white54,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 18),

                  // ── Descripción ─────────────
                  const _Label('Descripción'),
                  const SizedBox(height: 8),
                  _ShakeWidget(
                    shakeKey: descShakeKey,
                    child: TextField(
                      controller: descripcionController,
                      textCapitalization: TextCapitalization.sentences,
                      onSubmitted: (_) => guardar(),
                      decoration: const InputDecoration(
                        hintText: 'Ej: Almuerzo, Netflix, metro…',
                        prefixIcon:
                            Icon(Icons.short_text_rounded, size: 20),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // ── Monto ────────────────────
                  const _Label('Monto'),
                  const SizedBox(height: 8),
                  _ShakeWidget(
                    shakeKey: montoShakeKey,
                    child: TextField(
                      controller: montoController,
                      keyboardType: const TextInputType.numberWithOptions(
                          decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                      ],
                      onSubmitted: (_) => guardar(),
                      decoration: const InputDecoration(
                        hintText: '0.00',
                        prefixText: '\$ ',
                        prefixStyle: TextStyle(
                            color: Color(0xFF9C7EE8),
                            fontWeight: FontWeight.w700),
                        prefixIcon: Icon(Icons.attach_money_rounded, size: 20),
                      ),
                    ),
                  ),
                  const SizedBox(height: 22),

                  // ── Botones ─────────────────
                  Row(
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('Cancelar'),
                      ),
                      const Spacer(),
                      FilledButton.icon(
                        onPressed: guardar,
                        icon: Icon(
                            editar != null ? Icons.check : Icons.add_rounded,
                            size: 18),
                        label: Text(editar != null
                            ? 'Guardar cambios'
                            : 'Agregar gasto'),
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF9C7EE8),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                          textStyle: const TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // ── Delete ───────────────────────────────────
  void _eliminarGasto(Gasto gasto) {
    final realIndex = gastos.indexOf(gasto);
    setState(() => gastos.removeAt(realIndex));
    HapticFeedback.mediumImpact();

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              IconData(gasto.categoria.icono, fontFamily: 'MaterialIcons'),
              color: Color(gasto.categoria.color),
              size: 18,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                '${gasto.descripcion} eliminado',
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF2A2640),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        action: SnackBarAction(
          label: 'Deshacer',
          textColor: const Color(0xFF9C7EE8),
          onPressed: () {
            setState(() => gastos.insert(realIndex, gasto));
          },
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // Build
  // ─────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final grouped = _buildGroupedList();

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _buildHeader()),
          SliverToBoxAdapter(child: _buildStats()),
          SliverToBoxAdapter(child: _buildFiltros()),

          if (grouped.isEmpty)
            SliverFillRemaining(child: _buildEmptyState()),

          if (grouped.isNotEmpty)
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 110),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (_, i) {
                    final item = grouped[i];
                    if (item is String) return _buildDateHeader(item);

                    final gasto = item as Gasto;
                    // Index for animation: count only Gasto items before this
                    final animIdx =
                        grouped.sublist(0, i).whereType<Gasto>().length;
                    return _SlideFadeItem(
                      index: animIdx,
                      child: _buildGastoItem(gasto),
                    );
                  },
                  childCount: grouped.length,
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _mostrarFormulario(),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Nuevo gasto',
            style: TextStyle(fontWeight: FontWeight.w600)),
      ),
    );
  }

  // ── Header ───────────────────────────────────
  Widget _buildHeader() {
    final displayTotal =
        _filtroCategoria != null ? _totalFiltrado : _total;

    return Container(
      padding: EdgeInsets.fromLTRB(
          20, MediaQuery.of(context).padding.top + 16, 20, 24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2D1F5E), Color(0xFF13111F)],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top row
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF9C7EE8).withAlpha(38),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.account_balance_wallet_outlined,
                    color: Color(0xFF9C7EE8), size: 20),
              ),
              const SizedBox(width: 10),
              const Text(
                'Mis Gastos',
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.5),
              ),
              const Spacer(),
              if (gastos.isNotEmpty)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${gastos.length} gasto${gastos.length == 1 ? '' : 's'}',
                    style: TextStyle(
                        color: Colors.white.withAlpha(160), fontSize: 12),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 20),

          // Total card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF7C5CBF), Color(0xFF5135A0)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(22),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x667C5CBF),
                  blurRadius: 24,
                  offset: Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _filtroCategoria != null
                      ? 'Total · ${_filtroCategoria!.nombre}'
                      : 'Balance total',
                  style: TextStyle(
                      color: Colors.white.withAlpha(178),
                      fontSize: 13,
                      fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 4),
                _AnimatedTotal(value: displayTotal, format: formatMonto),

                if (gastos.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _buildCategoryBar(),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryBar() {
    final total = _total;
    final Map<String, double> porCat = {};
    for (final g in gastos) {
      porCat[g.categoria.nombre] = (porCat[g.categoria.nombre] ?? 0) + g.monto;
    }
    final entries = porCat.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: SizedBox(
            height: 5,
            child: Row(
              children: entries.map((e) {
                final cat = categorias.firstWhere((c) => c.nombre == e.key,
                    orElse: () => categorias.last);
                return Expanded(
                  flex: (e.value / total * 100).round().clamp(1, 100),
                  child: Container(color: Color(cat.color)),
                );
              }).toList(),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 14,
          runSpacing: 4,
          children: entries.take(4).map((e) {
            final cat = categorias.firstWhere((c) => c.nombre == e.key,
                orElse: () => categorias.last);
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 7,
                  height: 7,
                  decoration:
                      BoxDecoration(color: Color(cat.color), shape: BoxShape.circle),
                ),
                const SizedBox(width: 4),
                Text(
                  '${cat.nombre} ${(e.value / total * 100).toStringAsFixed(0)}%',
                  style: TextStyle(
                      fontSize: 11,
                      color: Colors.white.withAlpha(178),
                      fontWeight: FontWeight.w500),
                ),
              ],
            );
          }).toList(),
        ),
      ],
    );
  }

  // ── Stats row ────────────────────────────────
  Widget _buildStats() {
    if (gastos.isEmpty) return const SizedBox.shrink();

    final mayor = _gastoMayor!;
    final promedio = _total / gastos.length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Row(
        children: [
          Expanded(
            child: _StatCard(
              icon: Icons.trending_up_rounded,
              iconColor: const Color(0xFF64FFDA),
              label: 'Promedio',
              value: formatMonto(promedio),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _StatCard(
              icon: Icons.arrow_upward_rounded,
              iconColor: const Color(0xFFFF7043),
              label: 'Mayor gasto',
              value: mayor.descripcion,
              subvalue: formatMonto(mayor.monto),
            ),
          ),
        ],
      ),
    );
  }

  // ── Filtros ──────────────────────────────────
  Widget _buildFiltros() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                _filtroCategoria == null
                    ? 'Todos los gastos'
                    : _filtroCategoria!.nombre,
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w700),
              ),
              const Spacer(),
              if (_filtroCategoria != null)
                GestureDetector(
                  onTap: () => setState(() => _filtroCategoria = null),
                  child: const Text(
                    'Ver todos',
                    style: TextStyle(
                        color: Color(0xFF9C7EE8),
                        fontSize: 13,
                        fontWeight: FontWeight.w500),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 34,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _FilterChip(
                  label: 'Todos',
                  selected: _filtroCategoria == null,
                  color: const Color(0xFF9C7EE8),
                  onTap: () => setState(() => _filtroCategoria = null),
                ),
                const SizedBox(width: 8),
                ...categorias.map((cat) {
                  final sel = _filtroCategoria?.nombre == cat.nombre;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: _FilterChip(
                      label: cat.nombre,
                      icon: IconData(cat.icono, fontFamily: 'MaterialIcons'),
                      selected: sel,
                      color: Color(cat.color),
                      onTap: () => setState(() => _filtroCategoria = cat),
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Date header ─────────────────────────────
  Widget _buildDateHeader(String label) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 14, 4, 6),
      child: Row(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.white.withAlpha(102),
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
              child: Divider(color: Colors.white.withAlpha(20), height: 1)),
        ],
      ),
    );
  }

  // ── Empty state ──────────────────────────────
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              color: const Color(0xFF9C7EE8).withAlpha(20),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.receipt_long_outlined,
                size: 44, color: Color(0xFF9C7EE8)),
          ),
          const SizedBox(height: 20),
          Text(
            _filtroCategoria != null
                ? 'Sin gastos en ${_filtroCategoria!.nombre}'
                : 'Sin gastos aún',
            style: const TextStyle(
                fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white),
          ),
          const SizedBox(height: 8),
          Text(
            _filtroCategoria != null
                ? 'Probá con otra categoría o agregá uno nuevo'
                : 'Tocá "Nuevo gasto" para empezar\na registrar tus gastos',
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 14,
                color: Colors.white.withAlpha(102),
                height: 1.5),
          ),
          if (_filtroCategoria != null) ...[
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: () => setState(() => _filtroCategoria = null),
              icon: const Icon(Icons.clear_rounded, size: 16),
              label: const Text('Limpiar filtro'),
            ),
          ],
        ],
      ),
    );
  }

  // ── Gasto item ───────────────────────────────
  Widget _buildGastoItem(Gasto gasto) {
    return Dismissible(
      key: Key('${gasto.descripcion}_${gasto.fecha.millisecondsSinceEpoch}'),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFFB71C1C),
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.delete_outline_rounded,
                color: Colors.white, size: 22),
            const SizedBox(height: 3),
            Text('Eliminar',
                style:
                    TextStyle(color: Colors.white.withAlpha(204), fontSize: 11)),
          ],
        ),
      ),
      confirmDismiss: (_) async => true,
      onDismissed: (_) => _eliminarGasto(gasto),
      child: GestureDetector(
        onLongPress: () {
          HapticFeedback.selectionClick();
          _mostrarFormulario(editar: gasto);
        },
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1B2E),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withAlpha(13)),
          ),
          child: ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Color(gasto.categoria.color).withAlpha(30),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                IconData(gasto.categoria.icono, fontFamily: 'MaterialIcons'),
                color: Color(gasto.categoria.color),
                size: 22,
              ),
            ),
            title: Text(
              gasto.descripcion,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Color(gasto.categoria.color).withAlpha(20),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      gasto.categoria.nombre,
                      style: TextStyle(
                          fontSize: 11,
                          color: Color(gasto.categoria.color),
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _formatFecha(gasto.fecha),
                    style: TextStyle(
                        color: Colors.white.withAlpha(102), fontSize: 11),
                  ),
                ],
              ),
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  formatMonto(gasto.monto),
                  style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: Color(0xFF64FFDA)),
                ),
                const SizedBox(height: 2),
                Text(
                  'Mantené para editar',
                  style: TextStyle(
                      fontSize: 9, color: Colors.white.withAlpha(70)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatFecha(DateTime fecha) {
    final diff = DateTime.now().difference(fecha);
    if (diff.inMinutes < 1) return 'Ahora mismo';
    if (diff.inHours < 1) return 'Hace ${diff.inMinutes}m';
    if (diff.inDays < 1) return 'Hace ${diff.inHours}h';
    return '${fecha.hour.toString().padLeft(2, '0')}:${fecha.minute.toString().padLeft(2, '0')}';
  }
}

// ─────────────────────────────────────────────
// Reusable small widgets
// ─────────────────────────────────────────────

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: Color(0xFF9C7EE8),
        letterSpacing: 0.8,
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final String? subvalue;
  const _StatCard({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    this.subvalue,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1B2E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withAlpha(13)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: iconColor.withAlpha(25),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 16),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(
                        fontSize: 11,
                        color: Colors.white.withAlpha(102),
                        fontWeight: FontWeight.w500)),
                const SizedBox(height: 2),
                Text(
                  subvalue ?? value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Colors.white),
                ),
                if (subvalue != null)
                  Text(
                    value,
                    style: TextStyle(
                        fontSize: 11, color: Colors.white.withAlpha(102)),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final IconData? icon;
  final bool selected;
  final Color color;
  final VoidCallback onTap;
  const _FilterChip({
    required this.label,
    this.icon,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? color.withAlpha(40) : const Color(0xFF2A2640),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? color : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 13, color: selected ? color : Colors.white54),
              const SizedBox(width: 5),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight:
                    selected ? FontWeight.w600 : FontWeight.w400,
                color: selected ? color : Colors.white54,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
