import 'dart:io';

import 'package:material_ui/material_ui.dart';

import '../db/database_helper.dart';
import '../models/registro.dart';

class DetalhesRegistroScreen extends StatefulWidget {
  const DetalhesRegistroScreen({
    super.key,
    required this.registro,
  });

  final Registro registro;

  @override
  State<DetalhesRegistroScreen> createState() =>
      _DetalhesRegistroScreenState();
}

class _DetalhesRegistroScreenState
    extends State<DetalhesRegistroScreen> {
  bool _excluindo = false;

  String _formatarData(String valor) {
    try {
      final data = DateTime.parse(valor);
      String dois(int numero) => numero.toString().padLeft(2, '0');

      return '${dois(data.day)}/${dois(data.month)}/${data.year} '
          'às ${dois(data.hour)}:${dois(data.minute)}';
    } on FormatException {
      return valor;
    }
  }

  Future<void> _confirmarExclusao() async {
    final cores = Theme.of(context).colorScheme;

    final confirmou = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          icon: Icon(
            Icons.delete_outline_rounded,
            color: cores.error,
            size: 34,
          ),
          title: const Text('Excluir esta memória?'),
          content: const Text(
            'O registro e sua foto serão excluídos permanentemente. '
            'Essa ação não pode ser desfeita.',
          ),
          actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: cores.error,
                foregroundColor: cores.onError,
              ),
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Excluir'),
            ),
          ],
        );
      },
    );

    if (!mounted || confirmou != true) return;

    await _excluirRegistro();
  }

  Future<void> _excluirRegistro() async {
    final id = widget.registro.id;

    if (id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Não foi possível identificar o registro.'),
        ),
      );
      return;
    }

    setState(() {
      _excluindo = true;
    });

    try {
      final foto = File(widget.registro.caminhoImagem);

      if (foto.existsSync()) {
        foto.deleteSync();
      }

      final quantidade =
          await DatabaseHelper.instance.deletarRegistro(id);

      if (quantidade != 1) {
        throw StateError('O registro não foi encontrado no banco.');
      }

      debugPrint('Foto e registro de ID $id excluídos.');

      if (!mounted) return;

      Navigator.pop(context, true);
    } catch (erro) {
      debugPrint('Erro ao excluir registro: $erro');

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Não foi possível concluir a exclusão. '
            'A foto pode já ter sido removida; tente novamente.',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _excluindo = false;
        });
      }
    }
  }

  Widget _cartaoInformacao({
    required IconData icone,
    required String rotulo,
    required String valor,
  }) {
    final cores = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFE2E8F0),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: cores.primaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icone,
              color: cores.primary,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  rotulo,
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  valor,
                  style: const TextStyle(
                    color: Color(0xFF0F172A),
                    fontSize: 16,
                    height: 1.4,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final registro = widget.registro;
    final cores = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8FAFC),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text(
          'Sua memória',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            onPressed: _excluindo ? null : _confirmarExclusao,
            tooltip: 'Excluir registro',
            icon: Icon(
              Icons.delete_outline_rounded,
              color: _excluindo ? Colors.grey : cores.error,
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Hero(
              tag: 'registro-foto-${registro.id}',
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(28),
                ),
                child: Image.file(
                  File(registro.caminhoImagem),
                  width: double.infinity,
                  height: 340,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      height: 260,
                      color: const Color(0xFFE2E8F0),
                      child: const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.broken_image_outlined,
                            size: 48,
                            color: Color(0xFF94A3B8),
                          ),
                          SizedBox(height: 12),
                          Text(
                            'Imagem não encontrada',
                            style: TextStyle(
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: const Color(0xFFE2E8F0),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'MOMENTO REGISTRADO',
                          style: TextStyle(
                            color: cores.primary,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.5,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          registro.titulo,
                          style: const TextStyle(
                            fontSize: 27,
                            height: 1.2,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  _cartaoInformacao(
                    icone: Icons.calendar_month_outlined,
                    rotulo: 'DATA E HORA',
                    valor: _formatarData(registro.dataHora),
                  ),
                  const SizedBox(height: 16),
                  _cartaoInformacao(
                    icone: Icons.location_on_outlined,
                    rotulo: 'LATITUDE',
                    valor: registro.latitude.toStringAsFixed(6),
                  ),
                  const SizedBox(height: 16),
                  _cartaoInformacao(
                    icone: Icons.explore_outlined,
                    rotulo: 'LONGITUDE',
                    valor: registro.longitude.toStringAsFixed(6),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Registro #${registro.id}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Color(0xFF94A3B8),
                      fontSize: 12,
                    ),
                  ),
                  if (_excluindo) ...[
                    const SizedBox(height: 24),
                    const Center(
                      child: CircularProgressIndicator(),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Excluindo registro...',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}