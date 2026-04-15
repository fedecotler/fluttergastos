class Categoria {
  final String nombre;
  final int icono; // IconData codePoint
  final int color; // Color value

  const Categoria({
    required this.nombre,
    required this.icono,
    required this.color,
  });
}

const List<Categoria> categorias = [
  Categoria(nombre: 'Comida',    icono: 0xe56c, color: 0xFFFF7043), // restaurant
  Categoria(nombre: 'Transporte', icono: 0xe531, color: 0xFF42A5F5), // directions_car
  Categoria(nombre: 'Hogar',     icono: 0xe318, color: 0xFF66BB6A), // home
  Categoria(nombre: 'Salud',     icono: 0xe3f1, color: 0xFFEC407A), // favorite
  Categoria(nombre: 'Ocio',      icono: 0xe415, color: 0xFFAB47BC), // movie
  Categoria(nombre: 'Otros',     icono: 0xe8b8, color: 0xFF78909C), // more_horiz
];

class Gasto {
  final String descripcion;
  final double monto;
  final Categoria categoria;
  final DateTime fecha;

  Gasto({
    required this.descripcion,
    required this.monto,
    required this.categoria,
    DateTime? fecha,
  }) : fecha = fecha ?? DateTime.now();
}
