import 'package:anki_backend_models/anki_backend_models.dart';
import 'package:fixnum/fixnum.dart';

void main() {
  final card = Card(id: Int64(1));
  final note = Note(id: Int64(2));
  if (card.id.toInt() + note.id.toInt() != 3) {
    throw StateError('model package JS smoke compilation failed');
  }
}
