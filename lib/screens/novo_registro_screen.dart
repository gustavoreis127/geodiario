import 'dart:io';

import 'package:material_ui/material_ui.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../db/database_helper.dart';
import '../models/registro.dart';

class NovoRegistroScreen extends StatefulWidget {
  const NovoRegistroScreen({super.key});

  @override
  State<NovoRegistroScreen> createState() => _NovoRegistroScreenState();
}

class _NovoRegistroScreenState extends State<NovoRegistroScreen> {
  final TextEditingController _tituloController = TextEditingController();

  String? _caminhoImagem;
  double? _latitude;
  double? _longitude;

  bool _obtendoLocalizacao = false;
  bool _tirandoFoto = false;
  bool _salvando = false;

  bool get _ocupado =>
      _obtendoLocalizacao || _tirandoFoto || _salvando;

  void _mostrarMensagem(String mensagem) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensagem)),
    );
  }

  Future<void> _obterLocalizacao() async {
    setState(() {
      _obtendoLocalizacao = true;
    });

    try {
      final servicoAtivo = await Geolocator.isLocationServiceEnabled();

      if (!servicoAtivo) {
        _mostrarMensagem(
          'Ative a localização do celular e tente novamente.',
        );
        return;
      }

      var permissao = await Geolocator.checkPermission();

      if (permissao == LocationPermission.denied) {
        permissao = await Geolocator.requestPermission();
      }

      if (permissao == LocationPermission.denied) {
        _mostrarMensagem('A permissão de localização foi negada.');
        return;
      }

      if (permissao == LocationPermission.deniedForever) {
        _mostrarMensagem(
          'Libere a localização nas configurações de permissões do aplicativo.',
        );
        return;
      }

      final posicao = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 30),
        ),
      );

      if (!mounted) return;

      setState(() {
        _latitude = posicao.latitude;
        _longitude = posicao.longitude;
      });

      _mostrarMensagem('Localização obtida!');
    } catch (erro) {
      _mostrarMensagem(
        'Não foi possível obter a localização. Tente novamente.',
      );
      debugPrint('Erro ao obter localização: $erro');
    } finally {
      if (mounted) {
        setState(() {
          _obtendoLocalizacao = false;
        });
      }
    }
  }

  Future<void> _tirarFoto() async {
    setState(() {
      _tirandoFoto = true;
    });

    try {
      final foto = await ImagePicker().pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
      );

      if (foto == null) return;

      final diretorio = await getApplicationDocumentsDirectory();

      final extensao = p.extension(foto.path);
      final nomeArquivo =
          'foto_${DateTime.now().microsecondsSinceEpoch}'
          '${extensao.isEmpty ? '.jpg' : extensao}';

      final caminhoDestino = p.join(
        diretorio.path,
        nomeArquivo,
      );

      final fotoSalva = await File(foto.path).copy(caminhoDestino);

      if (!mounted) return;

      setState(() {
        _caminhoImagem = fotoSalva.path;
      });

      _mostrarMensagem('Foto salva no diretório do aplicativo!');
    } catch (erro) {
      _mostrarMensagem(
        'Não foi possível tirar ou salvar a foto. '
        'Verifique a permissão da câmera.',
      );
      debugPrint('Erro ao tirar foto: $erro');
    } finally {
      if (mounted) {
        setState(() {
          _tirandoFoto = false;
        });
      }
    }
  }

  Future<void> _salvarRegistro() async {
    final titulo = _tituloController.text.trim();

    if (titulo.isEmpty) {
      _mostrarMensagem('Digite um título.');
      return;
    }

    final caminhoImagem = _caminhoImagem;
    final latitude = _latitude;
    final longitude = _longitude;

    if (caminhoImagem == null) {
      _mostrarMensagem('Tire uma foto antes de salvar.');
      return;
    }

    if (latitude == null || longitude == null) {
      _mostrarMensagem('Obtenha a localização antes de salvar.');
      return;
    }

    setState(() {
      _salvando = true;
    });

    try {
      final registro = Registro(
        titulo: titulo,
        caminhoImagem: caminhoImagem,
        dataHora: DateTime.now().toIso8601String(),
        latitude: latitude,
        longitude: longitude,
      );

      final id = await DatabaseHelper.instance.inserirRegistro(registro);

      debugPrint('Registro salvo no SQLite com ID: $id');

      if (!mounted) return;

      Navigator.pop(context, true);
    } catch (erro) {
      _mostrarMensagem('Não foi possível salvar o registro.');
      debugPrint('Erro ao salvar registro: $erro');
    } finally {
      if (mounted) {
        setState(() {
          _salvando = false;
        });
      }
    }
  }

  Widget _previewFoto() {
    final cores = Theme.of(context).colorScheme;

    return Container(
      height: 280,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: cores.outlineVariant,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: _caminhoImagem != null
          ? Image.file(
              File(_caminhoImagem!),
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.broken_image_outlined,
                        size: 44,
                        color: Color(0xFF94A3B8),
                      ),
                      SizedBox(height: 12),
                      Text('Não foi possível exibir a foto.'),
                    ],
                  ),
                );
              },
            )
          : Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: cores.primaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.add_a_photo_outlined,
                    size: 38,
                    color: cores.primary,
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  'Capture este momento',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Sua foto aparecerá aqui',
                  style: TextStyle(
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _statusGps() {
    final capturou = _latitude != null && _longitude != null;
    final sucesso = capturou && !_obtendoLocalizacao;

    final cor = sucesso
        ? const Color(0xFF15803D)
        : Theme.of(context).colorScheme.primary;

    final fundo = sucesso
        ? const Color(0xFFF0FDF4)
        : const Color(0xFFEFF6F7);

    String titulo;
    String descricao;

    if (_obtendoLocalizacao) {
      titulo = 'Buscando sua localização';
      descricao = 'Aguarde enquanto obtemos as coordenadas.';
    } else if (capturou) {
      titulo = 'Localização capturada';
      descricao =
          'Latitude: ${_latitude!.toStringAsFixed(6)}\n'
          'Longitude: ${_longitude!.toStringAsFixed(6)}';
    } else {
      titulo = 'Localização pendente';
      descricao = 'Obtenha as coordenadas para marcar este momento.';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: fundo,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: sucesso
              ? const Color(0xFFBBF7D0)
              : const Color(0xFFCCE3E5),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_obtendoLocalizacao)
            SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: cor,
              ),
            )
          else
            Icon(
              sucesso
                  ? Icons.check_circle_outline
                  : Icons.location_on_outlined,
              color: cor,
            ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: TextStyle(
                    color: cor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  descricao,
                  style: const TextStyle(
                    color: Color(0xFF475569),
                    height: 1.5,
                    fontSize: 13,
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
  void dispose() {
    _tituloController.dispose();
    super.dispose();
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
          'Novo registro',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Guarde uma nova memória',
              style: TextStyle(
                fontSize: 23,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Uma foto, um lugar e uma história para lembrar.',
              style: TextStyle(
                color: Color(0xFF64748B),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            _previewFoto(),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _ocupado ? null : _tirarFoto,
              icon: const Icon(Icons.camera_alt_outlined),
              label: Text(
                _tirandoFoto
                    ? 'Abrindo câmera...'
                    : _caminhoImagem == null
                        ? 'Tirar foto'
                        : 'Tirar outra foto',
              ),
            ),
            const SizedBox(height: 28),
            const Text(
              'Sobre este momento',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _tituloController,
              enabled: !_ocupado,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Título do registro',
                hintText: 'Ex.: Fim de tarde no parque',
                prefixIcon: Icon(Icons.edit_outlined),
              ),
            ),
            const SizedBox(height: 28),
            const Text(
              'Onde aconteceu',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 12),
            _statusGps(),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _ocupado ? null : _obterLocalizacao,
              icon: const Icon(Icons.my_location_outlined),
              label: Text(
                _obtendoLocalizacao
                    ? 'Obtendo localização...'
                    : _latitude == null || _longitude == null
                        ? 'Obter localização'
                        : 'Atualizar localização',
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
          decoration: const BoxDecoration(
            color: Color(0xFFF8FAFC),
            border: Border(
              top: BorderSide(color: Color(0xFFE2E8F0)),
            ),
          ),
          child: SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: _ocupado ? null : _salvarRegistro,
              icon: _salvando
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(Icons.save_outlined),
              label: Text(
                _salvando ? 'Salvando...' : 'Salvar registro',
              ),
            ),
          ),
        ),
      ),
    );
  }
}