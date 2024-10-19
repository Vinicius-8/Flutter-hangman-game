import 'dart:math';

// import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_hangman/utilities/api_quote.dart';
import 'package:flutter_hangman/utilities/quote_model.dart';
import 'package:flutter_hangman/utilities/word_list.dart';

class HangmanWords {
  int wordCounter = 0;
  List<int> _usedNumbers = [];
  List<String> _words = [];

  Future readWords() async {
    // String fileText = await rootBundle.loadString('res/hangman_words.txt');
    // _words = fileText.split('\n');
    _words = WordList().wordList;
  }

  void resetWords() {
    wordCounter = 0;
    _usedNumbers = [];
//    _words = [];
  }

  // ignore: missing_return
  getWord() {
    wordCounter += 1;
    var rand = Random();
    int wordLength = _words.length;
    int randNumber = rand.nextInt(wordLength);
    bool notUnique = true;
    if (wordCounter - 1 == _words.length) {
      notUnique = false;
      return '';
    }
    while (notUnique) {
      if (!_usedNumbers.contains(randNumber)) {
        notUnique = false;
        _usedNumbers.add(randNumber);
        return _words[randNumber];
      } else {
        randNumber = rand.nextInt(wordLength);
      }
    }
  }

  String getHiddenWord(int wordLength) {
    String hiddenWord = '';
    for (int i = 0; i < wordLength; i++) {
      hiddenWord += '_';
    }
    return hiddenWord;
  }

  Future<QuoteModel> getQuote() async {
    String quote = await ApiQuote().getQuote();
    QuoteModel p = processPhrase(quote);    
    return p;
  }

  QuoteModel processPhrase(String phrase) {
    List<String> words = phrase.split(' ');
    String chosenWord = '';    

    List<String> wordsValidas = [];

    // Encontrar a primeira palavra com no mínimo 5 letras
    for (int i = 0; i < words.length; i++) {
      if (words[i].length >= 5 && RegExp(r'^[a-zA-Z]+$').hasMatch(words[i])) {
        wordsValidas.add(words[i]);
      }
    }

    // Se não encontrar nenhuma palavra, retorna a frase original
    if (wordsValidas.isEmpty) {
      throw Exception("Word not found!");
    }

    Random random = Random();
    chosenWord = wordsValidas[random.nextInt(wordsValidas.length)];

    // Criar uma string com underscores do mesmo tamanho da palavra escolhida
    String underscores = '_' * chosenWord.length;

    // Substituir a palavra escolhida por underscores na lista de palavras
    for (int i = 0; i < words.length; i++) {
      if (words[i] == chosenWord) {
        words[i] = underscores;
        break;
      }
    }

    String phraseWithUnderscores = words.join(' ');
    
    return QuoteModel(quote: phrase.toLowerCase().trim(), word: chosenWord.toLowerCase().trim(), quoteHidden: phraseWithUnderscores.toLowerCase().trim());
  }
}
