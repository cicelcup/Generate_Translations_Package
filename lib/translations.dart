library generate_translations;

import 'dart:convert';
import 'dart:io';

import 'package:collection/collection.dart';
import 'package:path/path.dart';

import 'strings_app.dart';
import 'variables.dart';

///Script to get strings from AppStringsI18n or converting translations to json
///
///Script is executed in the root of the app as:
///flutter pub run translations.dart and the argument [option_1] or [option_2]
///[option_1] generate the file to send to the client
///[option_2] generate the json file
///Translations are indicated in the argument and store in [stringsPath]
///arg translation should be similar as translations/app_strings_i18n.dart
///
Future<void> start(List args) async {
  if (args.isNotEmpty) {
    if (args.length == 2) {
      option = args[0]; //read the first argument
      stringsPath = args[1]; //read the path of the file
      await readSheetsFile();
    } else {
      print(
          'Its necessary to provide two arguments, first the option and second '
          'the path');
    }
  } else {
    print('Not arguments passed to the script');
  }
}

///Read the file with the translations [translations.txt] and store in a list.
///
/// If the file is not found it, check the option to display error message
/// or create the new file to send to the client without any translations
Future<void> readSheetsFile() async {
  var scriptPath = dirname(Platform.script.toFilePath());
  var filePath = join(scriptPath, 'translations.txt');
  var file = File(filePath);

  //Verify if the file exists.
  if (await file.exists()) {
    var contentStream = file.openRead(); //Open the file.

    //Read each line of the file and create one list of objects
    contentStream.transform(Utf8Decoder()).transform(LineSplitter()).listen(
      (String line) {
        var array = line.split(newSeparator);
        listOfTranslations.add(StringsApp(
          id: array[0],
          english: array[1],
          spanish: array[2],
        ));
      },
      onDone: () => readAppStringsI18N(),
    );
  } else {
    if (option == option_1) {
      await readAppStringsI18N();
    }
    if (option == option_2) {
      print('translations.txt does not exist in the path defined');
    }
  }
}

///Read the file from flutter package app.
///
/// If the file doesn't exist, display error message
Future<void> readAppStringsI18N() async {
  var translationFile = '../lib/$stringsPath';
  var filePath = Platform.script.resolve(translationFile);
  var file = File.fromUri(filePath);

  //Verify if the file exists.
  if (await file.exists()) {
    var contentStream = file.openRead(); //Open the file.

    //Read each line of the file.
    contentStream.transform(Utf8Decoder()).transform(LineSplitter()).listen(
      (String line) => checkLine(line), //check each line of the file
      onDone: () {
        if (isDivided) {
          throw Exception(
              "There's one string at the end of the file without i18n");
        }
        onDoneReadingAppStringsI18N();
      }, //execute after the file is read
    );
  } else {
    print('AppStrings_i18n does not exist in the path defined');
  }
}

///C heck each line of the file.
///
/// if it's no divided, check it contains static
/// if contain static check if contains .i18n to add in the list.
/// else store it in the temp variable and set divided to true
/// If it's divided store the line in the temp variable
/// check if contains i18n to store it in the list and set divided to false
///
void checkLine(String line) {
  if (!isDivided) {
    if (line.contains('static')) {
      if (line.contains('.i18n;')) {
        listOfLines.add(line.trim());
      }
      if (!line.contains('.i18n;')) {
        temp = line.trim();
        isDivided = true;
      }
    }
  } else {
    temp = temp + line.trim();
    if (line.contains('.i18n;')) {
      listOfLines.add(temp);
      isDivided = false;
    }
    if (line.contains('static')) {
      throw Exception(
          "There's one string without i18n. Last static line found: $line");
    }
  }
}

///Function to manipulate the list
///
/// For each element, remove the strings "static String " and ".i18n"
/// Split the map and join to form a new string
/// when finds "=" then replace for [newSeparator]
/// In the others, remove the spaces around it and delete " or ' accordingly
///
/// If the [option_1] is found it, add the spanish word in those cases that
/// is not empty to add it to the file to send to the client
///
void onDoneReadingAppStringsI18N() {
  var newList = listOfLines.map((element) {
    var newElement = element
        .replaceAll('static String ', '')
        .replaceAll('.i18n;', '')
        .splitMapJoin(
          '=',
          onMatch: (m) => newSeparator, //add the new separator
          //remove the ' or " according the case
          onNonMatch: (n) {
            if (n.contains('\"')) return n.replaceAll('\"', '').trim();
            if (n.contains("\'")) return n.replaceAll("\'", '').trim();
            return n.trim();
          },
        );

    ///if [option_1] is passed to the function, add the spanish translations
    ///in those case where appears (first check if the list translations is
    ///not empty to avoid errors.
    if (option == option_1 && listOfTranslations.isNotEmpty) {
      //get the id to search
      var idToSearch =
          newElement.substring(0, newElement.indexOf(newSeparator));
      //search the item in the list if it's not found it return null
      var item = listOfTranslations.firstWhere(
        (element) => element.id == idToSearch,
        orElse: () => null,
      );
      //if item is not null and spanish is not empty added to the file
      if (item != null && item.spanish.isNotEmpty) {
        newElement = newElement + newSeparator + item.spanish;
      }
    }

    return newElement;
  });

  ///Write the file with the data if option is [option_1]
  if (option == option_1) {
    //reduce the list to a variable adding the line separation
    var info = newList.reduce((curr, next) => curr + '\n' + next);
    checkStringsDuplicated(newList);
    writeCleanFile(info);
  }

  ///Map the list taking in consideration the new separator and compare lists
  ///
  if (option == option_2) {
    listOfStringsI18N = newList.map((e) {
      var array = e.split(newSeparator);
      return StringsApp(
        id: array[0],
        english: array[1],
      );
    }).toList();
    compareLists();
  }
}

///Check if there's strings duplicated in the list.
///
///Map the items only to get the English Strings.
///Then iterate this list to create a set where those items that are repeated
///would be added in duplicates
///Print the result and the duplicated list
///
void checkStringsDuplicated(list) {
  List onlyEnglish = list.map((e) {
    return e.split(newSeparator)[1];
  }).toList();

  var set = <String>{};
  var duplicates = [];

  onlyEnglish.forEach((element) {
    var result = set.add(element);
    if (!result) {
      duplicates.add(element);
    }
  });

  print('Check if there are items duplicated');
  print('Original Length: ${onlyEnglish.length} and New Length: ${set.length}'
      ' Difference: ${onlyEnglish.length - set.length}');

  duplicates.forEach(print);
}

///Compare the list.
///
///Compare using deep collection equality(where it doesn't matter the order
///this is possible thanks to add equatable to the class that override the
///correspond methods
///
/// If the lists are difference print the error message and show the differences
/// (differences could be id or english string)
/// Also the difference could be new strings added to the AppStringsI18N file
///
/// If the lists are equals, create the json file with an specific format to
/// help the reading for the final user
///
/// only add to the json files those id where the spanish is not empty
/// and count them to compare and display the message saying how many words
/// are not translated and show the words stored in [wordsNotTranslated]
///
Future<void> compareLists() async {
  Function unOrdDeepEq = const DeepCollectionEquality.unordered().equals;
  var result = unOrdDeepEq(listOfTranslations, listOfStringsI18N);
  var wordsNotTranslated = <String>[];
  if (result) {
    var wordsIncluded = 0;
    var info = listOfTranslations.fold('{\n', (curr, next) {
      if (next.spanish.isEmpty) {
        wordsNotTranslated.add(next.english);
        return curr;
      }
      wordsIncluded++;
      return curr + '    "' + next.english + '": "' + next.spanish + '",\n';
    });

    //remove the last line and comma
    info = info.trim();

    var last = info.lastIndexOf(',');

    info = info.substring(0, last) + '\n}';

    var length = listOfStringsI18N.length;

    var difference = length - wordsIncluded;

    if (difference != 0) {
      print('Missing $difference translations: ');
      wordsNotTranslated.forEach(print);
    }

    await writeJSON(info);
  } else {
    print('Lists are different. Check the following items in translations.txt');
    var differences =
        listOfTranslations.where((e) => !listOfStringsI18N.contains(e));

    if (differences.isEmpty) {
      //If difference is empty, calculate the new Strings added them
      var differences =
          listOfStringsI18N.where((e) => !listOfTranslations.contains(e));
      print('New strings added it:');
      differences.forEach(print);
    } else {
      print('${differences.length} differences found it');
      differences.forEach(print);
    }
  }
}

///Write the new output file to send to the client.
///
Future<void> writeCleanFile(String info) async {
  var scriptPath = dirname(Platform.script.toFilePath());
  var pathToNewFile = join(scriptPath, 'plain.txt'); //new file name
  await File(pathToNewFile).writeAsString(info); //write the file

  print('Strings resources already extracted');
}

///Write the new json file.
Future<void> writeJSON(String info) async {
  var scriptPath = dirname(Platform.script.toFilePath());
  var pathToNewFile = join(scriptPath, 'strings.json'); //new file name
  //write the file
  await File(pathToNewFile).writeAsString(info);

  print('json file already created');
}
