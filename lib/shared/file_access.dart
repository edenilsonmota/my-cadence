import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

typedef PickedFile = ({String name, Uint8List bytes});

/// Escolhe arquivos para importar (Markdown, texto, zip ou JSON). Os testes
/// trocam por uma lista fixa.
final importFilesPickerProvider = Provider<Future<List<PickedFile>> Function()>(
  (ref) => () async {
    // FileType.any: no Android, ".md" e ".json" nem sempre têm tipo MIME
    // conhecido.
    final files = await FilePicker.pickFiles();
    return [
      for (final f in files) (name: f.name, bytes: await f.xFile.readAsBytes()),
    ];
  },
);

/// Salva um arquivo onde o usuário escolher. Devolve se salvou.
final fileSaverProvider =
    Provider<Future<bool> Function(String fileName, Uint8List bytes)>(
      (ref) =>
          (fileName, bytes) async =>
              await FilePicker.saveFile(fileName: fileName, bytes: bytes) !=
              null,
    );
