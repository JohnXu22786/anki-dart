//
//  Generated code. Do not modify.
//  source: anki/notes.proto
//
// @dart = 2.12

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, prefer_final_fields
// ignore_for_file: unnecessary_import, unnecessary_this, unused_import

import 'dart:async' as $async;
import 'dart:core' as $core;

import 'package:protobuf/protobuf.dart' as $pb;

import 'cards.pb.dart' as $3;
import 'collection.pb.dart' as $2;
import 'decks.pb.dart' as $4;
import 'notes.pb.dart' as $13;
import 'notes.pbjson.dart';
import 'notetypes.pb.dart' as $12;

export 'notes.pb.dart';

abstract class NotesServiceBase extends $pb.GeneratedService {
  $async.Future<$13.Note> newNote($pb.ServerContext ctx, $12.NotetypeId request);
  $async.Future<$13.AddNoteResponse> addNote($pb.ServerContext ctx, $13.AddNoteRequest request);
  $async.Future<$13.AddNotesResponse> addNotes($pb.ServerContext ctx, $13.AddNotesRequest request);
  $async.Future<$13.DeckAndNotetype> defaultsForAdding($pb.ServerContext ctx, $13.DefaultsForAddingRequest request);
  $async.Future<$4.DeckId> defaultDeckForNotetype($pb.ServerContext ctx, $12.NotetypeId request);
  $async.Future<$2.OpChanges> updateNotes($pb.ServerContext ctx, $13.UpdateNotesRequest request);
  $async.Future<$13.Note> getNote($pb.ServerContext ctx, $13.NoteId request);
  $async.Future<$2.OpChangesWithCount> removeNotes($pb.ServerContext ctx, $13.RemoveNotesRequest request);
  $async.Future<$13.ClozeNumbersInNoteResponse> clozeNumbersInNote($pb.ServerContext ctx, $13.Note request);
  $async.Future<$2.OpChangesWithCount> afterNoteUpdates($pb.ServerContext ctx, $13.AfterNoteUpdatesRequest request);
  $async.Future<$13.FieldNamesForNotesResponse> fieldNamesForNotes($pb.ServerContext ctx, $13.FieldNamesForNotesRequest request);
  $async.Future<$13.NoteFieldsCheckResponse> noteFieldsCheck($pb.ServerContext ctx, $13.Note request);
  $async.Future<$3.CardIds> cardsOfNote($pb.ServerContext ctx, $13.NoteId request);
  $async.Future<$12.NotetypeId> getSingleNotetypeOfNotes($pb.ServerContext ctx, $13.NoteIds request);

  $pb.GeneratedMessage createRequest($core.String methodName) {
    switch (methodName) {
      case 'NewNote': return $12.NotetypeId();
      case 'AddNote': return $13.AddNoteRequest();
      case 'AddNotes': return $13.AddNotesRequest();
      case 'DefaultsForAdding': return $13.DefaultsForAddingRequest();
      case 'DefaultDeckForNotetype': return $12.NotetypeId();
      case 'UpdateNotes': return $13.UpdateNotesRequest();
      case 'GetNote': return $13.NoteId();
      case 'RemoveNotes': return $13.RemoveNotesRequest();
      case 'ClozeNumbersInNote': return $13.Note();
      case 'AfterNoteUpdates': return $13.AfterNoteUpdatesRequest();
      case 'FieldNamesForNotes': return $13.FieldNamesForNotesRequest();
      case 'NoteFieldsCheck': return $13.Note();
      case 'CardsOfNote': return $13.NoteId();
      case 'GetSingleNotetypeOfNotes': return $13.NoteIds();
      default: throw $core.ArgumentError('Unknown method: $methodName');
    }
  }

  $async.Future<$pb.GeneratedMessage> handleCall($pb.ServerContext ctx, $core.String methodName, $pb.GeneratedMessage request) {
    switch (methodName) {
      case 'NewNote': return this.newNote(ctx, request as $12.NotetypeId);
      case 'AddNote': return this.addNote(ctx, request as $13.AddNoteRequest);
      case 'AddNotes': return this.addNotes(ctx, request as $13.AddNotesRequest);
      case 'DefaultsForAdding': return this.defaultsForAdding(ctx, request as $13.DefaultsForAddingRequest);
      case 'DefaultDeckForNotetype': return this.defaultDeckForNotetype(ctx, request as $12.NotetypeId);
      case 'UpdateNotes': return this.updateNotes(ctx, request as $13.UpdateNotesRequest);
      case 'GetNote': return this.getNote(ctx, request as $13.NoteId);
      case 'RemoveNotes': return this.removeNotes(ctx, request as $13.RemoveNotesRequest);
      case 'ClozeNumbersInNote': return this.clozeNumbersInNote(ctx, request as $13.Note);
      case 'AfterNoteUpdates': return this.afterNoteUpdates(ctx, request as $13.AfterNoteUpdatesRequest);
      case 'FieldNamesForNotes': return this.fieldNamesForNotes(ctx, request as $13.FieldNamesForNotesRequest);
      case 'NoteFieldsCheck': return this.noteFieldsCheck(ctx, request as $13.Note);
      case 'CardsOfNote': return this.cardsOfNote(ctx, request as $13.NoteId);
      case 'GetSingleNotetypeOfNotes': return this.getSingleNotetypeOfNotes(ctx, request as $13.NoteIds);
      default: throw $core.ArgumentError('Unknown method: $methodName');
    }
  }

  $core.Map<$core.String, $core.dynamic> get $json => NotesServiceBase$json;
  $core.Map<$core.String, $core.Map<$core.String, $core.dynamic>> get $messageJson => NotesServiceBase$messageJson;
}

abstract class BackendNotesServiceBase extends $pb.GeneratedService {

  $pb.GeneratedMessage createRequest($core.String methodName) {
    switch (methodName) {
      default: throw $core.ArgumentError('Unknown method: $methodName');
    }
  }

  $async.Future<$pb.GeneratedMessage> handleCall($pb.ServerContext ctx, $core.String methodName, $pb.GeneratedMessage request) {
    switch (methodName) {
      default: throw $core.ArgumentError('Unknown method: $methodName');
    }
  }

  $core.Map<$core.String, $core.dynamic> get $json => BackendNotesServiceBase$json;
  $core.Map<$core.String, $core.Map<$core.String, $core.dynamic>> get $messageJson => BackendNotesServiceBase$messageJson;
}
