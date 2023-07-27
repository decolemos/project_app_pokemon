import 'package:flutter/material.dart';
import 'package:list_crud_pokemon/components/img_pokemon.dart';
import 'package:list_crud_pokemon/components/subtitle_tipo.dart';
import 'package:list_crud_pokemon/pages/poke_perfil.dart';
import '../models/pokemon.dart';

class PokemonListTile extends StatefulWidget {
  final Pokemon pokemon;
  final void Function() editarPokemon;
  final void Function(String id) removerPokemon;
  final Color? corSelecionada;

  const PokemonListTile({super.key, 
    required this.pokemon, 
    required this.editarPokemon, 
    required this.removerPokemon, 
    this.corSelecionada,
  });

  @override
  State<PokemonListTile> createState() => _PokemonListTileState();
}

class _PokemonListTileState extends State<PokemonListTile> {
  @override
  Widget build(BuildContext context) {
    
    return Card(
      child: ListTile(
        onTap: () {
          Navigator.pushNamed(context, "poke_perfil");
        },
        leading: SizedBox(
          width: 70,
          height: 70,
          child: ImgPokemon(url: widget.pokemon.imagePokemon)),
        title: Text(widget.pokemon.nome),
        subtitle: Row(
          children: [
            SubtitleTipo(tipoPokemon: widget.pokemon.primeiroTipo),
            if(widget.pokemon.segundoTipo != null)
              SubtitleTipo(tipoPokemon: widget.pokemon.segundoTipo!)  
          ],
        ),
        trailing: PopupMenuButton(itemBuilder: (context) {
            return [
              const PopupMenuItem<int>(
                value: 0,
                child: Row(
                  children: [
                    Text("Editar"),
                    Icon(Icons.edit)
                  ],
                )
              ),
              const PopupMenuItem<int>(
                value: 1,
                child: Row(
                  children: [
                    Text("Remover"),
                    Icon(Icons.delete)
                  ],
                )
              ),
            ];
          },
          onSelected: (value) {
            if(value == 0){
              widget.editarPokemon();
            } else if (value == 1) {
              widget.removerPokemon(widget.pokemon.id);
            }
          },
        ),
      ),
    );
  }
}