import 'package:fixnum/fixnum.dart';

typedef CardId = Int64;
typedef NoteId = Int64;
typedef TimestampSecs = Int64;

extension CardIdTimestamp on CardId {
  /// Converts the millisecond card ID to seconds, truncating toward zero.
  TimestampSecs asSecs() => this ~/ Int64(1000);
}
