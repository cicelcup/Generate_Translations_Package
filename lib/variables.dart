library generate_translations;

import 'strings_app.dart';

///Variables of control.
///
/// [isDivided] define if the line was divided in the file
/// [temp] store temporary the line that is being read
/// [listOfLines] store the new list of lines
/// [option] if it is [option_1] write the file, if it is [option_2] compare
/// with the translations.txt and generate the json
/// [listOfStringsI18N] Store the objects from the app strings i18n
/// [listOfTranslations] Store the objects from the translation file
/// [newSeparator] used to create and read files
///
bool isDivided = false;
String temp = '';
List<String> listOfLines = [];
String option;
List<StringsApp> listOfStringsI18N;
List<StringsApp> listOfTranslations = [];
final newSeparator = '///';
const option_1 = '1';
const option_2 = '2';
