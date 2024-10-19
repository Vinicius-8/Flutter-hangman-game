import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class ApiQuote {
  final String _apiStoic = 'https://stoic.tekloon.net/stoic-quote';

  Future<String> getQuote() async {
    debugPrint("[api_quote.dart] buscando quotes...");

    final response = await http.get(Uri.parse(_apiStoic));

    if (response.statusCode == 200) {
      // Usar Utf8Decoder para decodificar corretamente a resposta
      String decodedBody = utf8.decode(response.bodyBytes);            
      return jsonDecode(decodedBody)["data"]["quote"];
    } else {
      throw Exception('Failed to fetch quote');
    }
  }
}