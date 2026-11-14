class Registro {
  final int? id;
  final String titulo;
  final String caminhoImagem;
  final String dataHora;
  final double latitude;
  final double longitude;

  Registro({
    this.id,
    required this.titulo,
    required this.caminhoImagem,
    required this.dataHora,
    required this.latitude,
    required this.longitude,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'titulo': titulo,
      'caminhoImagem': caminhoImagem,
      'dataHora': dataHora,
      'latitude': latitude,
      'longitude': longitude,
    };
  }

  factory Registro.fromMap(Map<String, dynamic> map) {
    return Registro(
      id: map['id'] as int?,
      titulo: map['titulo'] as String,
      caminhoImagem: map['caminhoImagem'] as String,
      dataHora: map['dataHora'] as String,
      latitude: (map['latitude'] as num).toDouble(),
      longitude: (map['longitude'] as num).toDouble(),
    );
  }
}