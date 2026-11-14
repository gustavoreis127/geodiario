import 'dart:io';

import 'package:material_ui/material_ui.dart';

import '../db/database_helper.dart';
import '../models/registro.dart';
import 'detalhes_registro_screen.dart';
import 'novo_registro_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<List<Registro>> _registrosFuture;

  @override
  void initState() {
    super.initState();
    _registrosFuture = DatabaseHelper.instance.listarRegistros();
  }

  void _atualizarLista() {
    setState(() {
      _registrosFuture = DatabaseHelper.instance.listarRegistros();
    });
  }

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

  Future<void> _abrirCadastro() async {
    final salvou = await Navigator.push<bool>(
      context,
      MaterialPageRoute<bool>(
        builder: (context) => const NovoRegistroScreen(),
      ),
    );

    if (!mounted) return;

    if (salvou == true) {
      _atualizarLista();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Registro salvo com sucesso!'),
        ),
      );
    }
  }

  Future<void> _abrirDetalhes(Registro registro) async {
    final excluiu = await Navigator.push<bool>(
      context,
      MaterialPageRoute<bool>(
        builder: (context) => DetalhesRegistroScreen(
          registro: registro,
        ),
      ),
    );

    if (!mounted) return;

    if (excluiu == true) {
      _atualizarLista();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Registro excluído com sucesso!'),
        ),
      );
    }
  }

  Widget _estadoVazio() {
    final cores = Theme.of(context).colorScheme;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 112,
              height: 112,
              decoration: BoxDecoration(
                color: cores.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.explore_outlined,
                size: 56,
                color: cores.primary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Sua história começa aqui',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF0F172A),
                  ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Transforme seus passeios em memórias.\n'
              'Adicione uma foto, um título e a localização '
              'do seu primeiro registro.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF64748B),
                height: 1.6,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _abrirCadastro,
              icon: const Icon(Icons.add),
              label: const Text('Criar primeiro registro'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _cardRegistro(Registro registro) {
    final cores = Theme.of(context).colorScheme;

    return Card(
      elevation: 2,
      shadowColor: const Color(0x180F172A),
      color: Colors.white,
      surfaceTintColor: Colors.transparent,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _abrirDetalhes(registro),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Hero(
                tag: 'registro-foto-${registro.id}',
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(
                    File(registro.caminhoImagem),
                    width: 92,
                    height: 112,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 92,
                        height: 112,
                        color: const Color(0xFFF1F5F9),
                        child: const Icon(
                          Icons.broken_image_outlined,
                          color: Color(0xFF94A3B8),
                        ),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      registro.titulo,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.schedule_outlined,
                          size: 15,
                          color: Color(0xFF64748B),
                        ),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Text(
                            _formatarData(registro.dataHora),
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.location_on_outlined,
                          size: 16,
                          color: cores.primary,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            '${registro.latitude.toStringAsFixed(5)}, '
                            '${registro.longitude.toStringAsFixed(5)}',
                            style: TextStyle(
                              fontSize: 12,
                              color: cores.primary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              const Padding(
                padding: EdgeInsets.only(top: 4),
                child: Icon(
                  Icons.chevron_right,
                  color: Color(0xFF94A3B8),
                  size: 20,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8FAFC),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text(
          'Geodiário',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: Color(0xFF0F172A),
          ),
        ),
        actions: [
          IconButton(
            onPressed: _atualizarLista,
            tooltip: 'Atualizar lista',
            icon: const Icon(Icons.refresh_rounded),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: FutureBuilder<List<Registro>>(
        future: _registrosFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.cloud_off_outlined,
                      size: 48,
                      color: Color(0xFF94A3B8),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Não foi possível carregar os registros.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _atualizarLista,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Tentar novamente'),
                    ),
                  ],
                ),
              ),
            );
          }

          final registros = snapshot.data ?? <Registro>[];

          if (registros.isEmpty) {
            return _estadoVazio();
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Lugares que viraram memórias',
                      style:
                          Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF0F172A),
                              ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${registros.length} '
                      '${registros.length == 1 ? 'registro salvo' : 'registros salvos'}',
                      style: const TextStyle(
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                  itemCount: registros.length,
                  itemBuilder: (context, index) {
                    return _cardRegistro(registros[index]);
                  },
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _abrirCadastro,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Novo registro'),
      ),
    );
  }
}