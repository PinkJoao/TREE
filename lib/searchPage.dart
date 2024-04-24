import 'package:flutter/material.dart';

import 'infoPage.dart';
import 'generalLib.dart';

class SearchPage extends StatefulWidget {
  final OneDriveIDs? oneDriveIDs;
  final String folder;
  final List levels;
  final String searchTerm;

  const SearchPage({
    Key? key,
    required this.oneDriveIDs,
    required this.folder,
    required this.levels,
    required this.searchTerm,
  }) : super(key: key);

  @override
  _SearchPageState createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  List<Widget> displayedElements = [];

  TextEditingController searchController = TextEditingController();
  String searchTerm = '';

  @override
  void initState() {
    super.initState();
    searchActives();
  }

  void searchActives() { setState(() {
    List alreadyAdded = [];
    
    for (var item in widget.levels[7]){
      List activeInfo = item[1];
      var activeName = item[0][5];
      List activeTags = [activeInfo[1], activeInfo[2], activeInfo[3]].nonNulls.toList();

      if(activeName == 'null' || activeName == 'N/A' || activeName == '#N/A'){
        activeName = null;
      }

      for(var tag in activeTags){
        if(activeName != null){
          String itemName = activeName.toString().replaceAll('[', '').replaceAll(', ', ' [');
          if((tag.toUpperCase().contains(widget.searchTerm.toUpperCase()) || tag.toUpperCase().contains(widget.searchTerm.replaceAll(' ', '-').toUpperCase())) /*|| (itemName.toUpperCase().contains(widget.searchTerm.toUpperCase()) || itemName.toUpperCase().contains(widget.searchTerm.replaceAll(' ', '-').toUpperCase()))*/){
            if(!alreadyAdded.contains(activeTags.toString())){
              displayedElements.add(
                Padding(
                  key: Key(itemName),
                  padding: EdgeInsets.symmetric(vertical: 5),
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        new MaterialPageRoute(
                          builder: (context) => InfoPage(
                            oneDriveIDs: widget.oneDriveIDs,
                            folder: widget.folder,
                            levels: widget.levels,
                            father: [[item[0][0], item[0][1], item[0][2],item[0][3],item[0][4]],item[0][5]],
                          )
                        )
                      );
                    },
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text('\n' + itemName + '\n')
                    )
                  )
                )
              );
              alreadyAdded.add(activeTags.toString());
            }
          }
        }
      }  
    }
    if(displayedElements.isEmpty){
      displayedElements.add(
        const Card(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            child: Text(
              'Nenhum ativo encontrado',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            )
          )
        )
      );
    }
    });}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: BackButton(color: Colors.grey[900]),
        title: Text(widget.searchTerm)
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
              TextField(
                controller: searchController,
                onChanged: (value) {
                  setState(() {
                    searchTerm = value;
                  });
                },
                decoration: InputDecoration(
                  hintText: 'Buscar',
                  border: const OutlineInputBorder(),
                  hintStyle: TextStyle(
                    color: Colors.grey[600],
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 15,
                    vertical: 10,
                  ),
                ),
              ),
            ] + displayedElements.where((element) => (element.key.toString().toUpperCase()
                                                                            .replaceAll('Á', 'A').replaceAll('É', 'E').replaceAll('Í', 'I').replaceAll('Ó', 'O').replaceAll('Ú', 'U')
                                                                            .replaceAll('À', 'A').replaceAll('È', 'E').replaceAll('Ì', 'I').replaceAll('Ò', 'O').replaceAll('Ù', 'U')
                                                                            .replaceAll('Â', 'A').replaceAll('Ê', 'E').replaceAll('Î', 'I').replaceAll('Ô', 'O').replaceAll('Û', 'U')
                                                                            .replaceAll('Ã', 'A').replaceAll('Õ', 'O')
                                                        .contains(searchTerm.toUpperCase()
                                                                            .replaceAll('Á', 'A').replaceAll('É', 'E').replaceAll('Í', 'I').replaceAll('Ó', 'O').replaceAll('Ú', 'U')
                                                                            .replaceAll('À', 'A').replaceAll('È', 'E').replaceAll('Ì', 'I').replaceAll('Ò', 'O').replaceAll('Ù', 'U')
                                                                            .replaceAll('Â', 'A').replaceAll('Ê', 'E').replaceAll('Î', 'I').replaceAll('Ô', 'O').replaceAll('Û', 'U')
                                                                            .replaceAll('Ã', 'A').replaceAll('Õ', 'O')))).toList(),
        ),
      )
    );
  }
}
