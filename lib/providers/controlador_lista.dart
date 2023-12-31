import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:list_crud_pokemon/models/abilitie_pokemon.dart';
import 'package:list_crud_pokemon/models/base_stats_pokemon.dart';
import 'package:list_crud_pokemon/models/evolution.dart';
import '../models/pokemon.dart';
import 'package:http/http.dart' as http;

class ControladorLista extends ChangeNotifier {

  final List<Pokemon> _pokemons = [];

  List<Pokemon> get pokemons => _pokemons;

  final String url = "https://crudpokemonfirebase-default-rtdb.firebaseio.com";
  final String urlPokeApi = "https://pokeapi.co/api/v2/pokemon";
  final String urlPokeSpecies = "https://pokeapi.co/api/v2/pokemon-species";

  Future<void> buscarPokemonViaApi() async {
    buscarCadeiaEvolucao("1");
    try {
      final response = await http.get(Uri.parse("$url/pokemons.json"));
      final jsonResponse = jsonDecode(response.body);

      if(jsonResponse == null) return;

      for(final key in jsonResponse.keys) {
        await adicionarPokemonLista(Pokemon(
          id: key, 
          nome: jsonResponse[key]["nome"],
          primeiroTipo: jsonResponse[key]["primeiroTipo"], 
          segundoTipo: jsonResponse[key]["segundoTipo"],
          abilities: [],
          baseStatsList: [],
          moveList: [],
          evolutionChain: await buscarCadeiaEvolucao(jsonResponse[key]["nome"])
          )
        );
      }
      notifyListeners();
    } catch (e) {
      log(e.toString());
    }
  }

  bool verificarSeNomeExiste(String nome) {
    int index = _pokemons.indexWhere((pokemon) => pokemon.nome.toLowerCase() == nome.toLowerCase());
    return index != -1;
  }

  Future<void> adicionarPokemonFirebase(String nome, String primeiroTipo, String? segundoTipo) async {
    // print(segundoTipo == null);
    bool pokemonExiste = verificarSeNomeExiste(nome);

    if(pokemonExiste){
      log("Pokemon já existe na lista");
      return;
    } 

    try {
      final response = await http.post(
        Uri.parse("$url/pokemons.json"), 
        body: jsonEncode({
          "nome": nome,
          "primeiroTipo": primeiroTipo,
          "segundoTipo": segundoTipo
        })
      );

      final jsonResponse = jsonDecode(response.body);

      await adicionarPokemonLista(Pokemon(
          id: jsonResponse["name"], 
          nome: nome, 
          primeiroTipo: primeiroTipo, 
          segundoTipo: segundoTipo,
          abilities: [],
          baseStatsList: [],
          moveList: []
        )
      );
      notifyListeners();
    } catch (e) {
      log(e.toString());
    }
  }

  Future<void> adicionarPokemonLista(Pokemon pokemon) async {

    try {
      final response = await http.get(
        Uri.parse("$urlPokeApi/${pokemon.nome.toLowerCase()}"));
      final jsonResponse = jsonDecode(response.body);

      pokemon.moveList = buscarAtaquesPokemon(jsonResponse);

      for(int index = 0; index < jsonResponse["abilities"].length; index++) {
      pokemon.abilities.add(
        AbilitiePokemon(
          ability: (jsonResponse["abilities"][index]["ability"]["name"]), 
          isHidden: (jsonResponse["abilities"][index]["is_hidden"]),
          )
        );
      }

      for(int index = 0; index < jsonResponse["stats"].length; index++) {
        pokemon.baseStatsList?.add(
          BaseStatsPokemon(
            baseStats: (jsonResponse["stats"][index]["base_stat"]), 
            name: (jsonResponse["stats"][index]["stat"]["name"]),
          )
        );
      }

      pokemon.heigth = jsonResponse["height"];
      pokemon.weight = jsonResponse["weight"];
      pokemon.imagePokemonCard = 
        jsonResponse["sprites"]["other"]["official-artwork"]["front_default"];
      pokemon.imagePokemonDetail = 
        jsonResponse["sprites"]["other"]["home"]["front_default"];

    } catch (e) {
      log(e.toString());
    }
    _pokemons.add(pokemon);
  }

  Future<List<List<Evolution>>> buscarCadeiaEvolucao(String nomePokemon) async {
    // print("$urlPokeSpecies/${nomePokemon.toLowerCase()}");
    final response = await http.get(Uri.parse("$urlPokeSpecies/${nomePokemon.toLowerCase()}"));
    final jsonResponse = jsonDecode(response.body);

    final String evolutionChain = jsonResponse["evolution_chain"]["url"];

    final evolutionChainReponse = await http.get(Uri.parse(evolutionChain));
    final jsonEvolutionChainReponse = jsonDecode(evolutionChainReponse.body);

    bool completeChainFound = false;
    dynamic chainPath = jsonEvolutionChainReponse["chain"];
    List<List<Evolution>> evolutionList = [];

    while(completeChainFound == false) {
      String nome = chainPath["species"]["name"];

      for(int index = 0; index < chainPath["evolves_to"].length; index++){
        // minLevel = chainPath["evolution_details"][0]["min_level"];
        // trigger = chainPath["evolution_details"][0]["trigger"]["name"];
        evolutionList.add([
          Evolution(
            name: nome
          ),
          Evolution(
            name: chainPath["evolves_to"][index]["species"]["name"]
          )
        ]);
      }
      if(chainPath["evolves_to"].isEmpty){
        completeChainFound = true;
      } else {
        chainPath = chainPath["evolves_to"][0];
      }
    }
    // for(int index = 0; index < evolutionList.length; index++){
    //   log(evolutionList[index][0].name);
    //   log(evolutionList[index][1].name);
    // }
    return evolutionList;
  }

  List<String> buscarAtaquesPokemon(dynamic jsonResponse) {
    List<String> newMoveList = [];
    for(int index = 0; index < jsonResponse["moves"].length; index++){
      newMoveList.add(jsonResponse["moves"][index]["move"]["name"]); 
    }
    return newMoveList;
  }
  
  Future<void> editarPokemon(
    String id, 
    String novoNome, 
    String novoPrimeiroTipo, 
    String? novoSegundoTipo
    ) async {

    final response = await http.put(
      Uri.parse("$url/pokemons/$id.json"), 
      body: jsonEncode(
        {
          "nome": novoNome,
          "primeiroTipo": novoPrimeiroTipo,
          "segundoTipo": novoSegundoTipo
        }
      ) 
    );
    
    final responseImagem = await http.get(Uri.parse("$urlPokeApi/${novoNome.toLowerCase()}"));
    final jsonResponse = jsonDecode(responseImagem.body);
    final String novoImagemPokemon = jsonResponse["sprites"]["other"]["official-artwork"]["front_default"];

    jsonDecode(response.body);
    int index = _pokemons.indexWhere((pokemon) => pokemon.id == id);
    _pokemons[index].nome = novoNome;
    _pokemons[index].primeiroTipo = novoPrimeiroTipo;
    _pokemons[index].segundoTipo = novoSegundoTipo;  
    _pokemons[index].imagePokemonCard = novoImagemPokemon;
    notifyListeners();

  }
 
  Future<void> removerPokemon(String id) async {
    await http.delete(Uri.parse("$url/pokemons/$id.json"));
    int index = _pokemons.indexWhere((pokemon) => pokemon.id == id);
    _pokemons.removeAt(index);
    notifyListeners();
  }
}