library generate_translations;

import 'package:equatable/equatable.dart';

///Class to store the id, the english and spanish word.
///
/// Extends Equatable to compare the objects and overriding toString
class StringsApp extends Equatable {
  final String id;
  final String english;
  final String spanish;

  StringsApp({this.id, this.english, this.spanish});

  //Add only id and english as parameters to compare objects
  @override
  List<Object> get props => [id, english];

  //override to String and display the class name with the two properties
  @override
  bool get stringify => true;
}
