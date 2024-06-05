import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:path_provider/path_provider.dart';
import 'package:lecle_downloads_path_provider/lecle_downloads_path_provider.dart';

import 'infoPage.dart';
import 'generalLib.dart';

class SearchPage extends StatefulWidget {
  final OneDriveIDs? oneDriveIDs;
  final String folder;
  final List<List> levels;
  final String searchTerm;

  const SearchPage({
    Key? key,
    required this.oneDriveIDs,
    required this.folder,
    required this.levels,
    required this.searchTerm,
  }) : super(key: key);

  @override
  SearchPageState createState() => SearchPageState();
}

class SearchPageState extends State<SearchPage> {

  late Directory downloadDir;

  List<String> pendingFileNames = [];
  
  TextEditingController searchController = TextEditingController();
  String searchTerm = '';
  String tempText = '';

  TextEditingController filterController = TextEditingController();
  String filterTerm = '';

  @override
  void initState() {
    super.initState();
    searchTerm = widget.searchTerm;
    searchController.text = searchTerm;
    initialize();
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: BackButton(color: Colors.grey[900]),
        title: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Text(searchTerm),
        ) 
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            TextField(
              controller: searchController,
              onChanged: (value) {
                setState(() { tempText = value.toUpperCase().replaceAll(' ', '-'); });
              },
              onEditingComplete: () {
                updateSearch();
              },
              onTapOutside: (value) {
                updateSearch();
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
                suffixIcon: IconButton(
                  icon: Icon(CupertinoIcons.search, color: orangeColor),
                  onPressed: () {
                    updateSearch();
                  }
                )
              ),
            ),

            const SizedBox(height: 5,),

            TextField(
              controller: filterController,
              onChanged: (value){
                setState(() { filterTerm = value; });
              },
              onEditingComplete: () {
                updateFilter();
              },
              onTapOutside: (value) {
                updateFilter();
              },
              decoration: InputDecoration(
                hintText: 'Filtrar',
                border: const OutlineInputBorder(),
                hintStyle: TextStyle(
                  color: Colors.grey[600],
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 15,
                  vertical: 10,
                ),
                suffixIcon: IconButton(
                  icon: Icon(CupertinoIcons.search_circle, color: orangeColor),
                  onPressed: () {
                    updateFilter();
                  }
                )
              ),
            ),

            const SizedBox(height: 5,),

            if(searchTerm.length > 2)
              for(List active in widget.levels[7].where((element) => matchSearch(element) && matchFilter(element)        ))
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 5),
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => InfoPage(
                            oneDriveIDs: widget.oneDriveIDs,
                            folder: widget.folder,
                            levels: widget.levels,
                            title: active[1][0],
                            tag: active[1][3],
                          )
                        )
                      ).then((value) => getPendingFileNames());
                    },
                    onLongPress: () async {
                      await takePhotoAndStore(context, active[1][3].replaceAll('/', '%').replaceAll('"', '@'), 'PENDENTES TREE', downloadDir);
                      getPendingFileNames();
                    },
                    child: Container(
                      alignment: Alignment.centerLeft,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [

                          Flexible(
                            child: Text('\n${active[1][0]} \n[${active[1][3]}]\n',)
                          ),

                          if(blueCheck(active) && !greenCheck(active))
                            const IconButton(
                              onPressed: null, 
                              icon: Icon(CupertinoIcons.check_mark_circled, color: Color.fromARGB(255, 0, 125, 255),)
                            ),

                          if(greenCheck(active))
                            const IconButton(
                              onPressed: null, 
                              icon: Icon(CupertinoIcons.check_mark_circled, color: Colors.greenAccent,)
                            ),

                        ],
                      ),
                    ),
                  )
                )
            
          ]
        ),
      )
    );
  }

  bool blueCheck(List active){
    return (active[1][1] != 'null' && active[1][1] != '');
  }

  bool greenCheck(List active){
    if(active[1][10] == 'true'){
      return true;
    }
    if(pendingFileNames.where((element) => element.startsWith(active[1][3].replaceAll('/', '%').replaceAll('"', '@'))).isNotEmpty){
      return true;
    }
    return false;
  }

  bool matchSearch(List active){
    String tag = active[1][3];

    List<String> splitTerm = searchTerm.split('*');

    if(splitTerm.length == 1){
      if(tag.contains(searchTerm)){
        return true;
      }
    }else if(splitTerm.length == 2){
      if(tag.startsWith(splitTerm.first) && tag.endsWith(splitTerm.last)){
        return true;
      }
    }else{
      if(tag.startsWith(splitTerm.first) && tag.endsWith(splitTerm.last)){
        for(String term in splitTerm.getRange(1, splitTerm.length - 1)){
          if(!tag.contains(term)){
            return false;
          }
        }
        return true;
      }
    }

    if(splitTerm.length > 1){
      if(tag.startsWith(splitTerm.first) && tag.endsWith(splitTerm.last)){
        return true;
      }
    }else{
      if(tag.contains(searchTerm)){
        return true;
      }
    }

    return false;
  }

  bool matchFilter(List active){
    String tag = active[1][3];
    String description = active[1][0];

    String name = '$description [$tag]';

    return name.toUpperCase()
           .replaceAll('Á', 'A').replaceAll('É', 'E').replaceAll('Í', 'I').replaceAll('Ó', 'O').replaceAll('Ú', 'U')
           .replaceAll('À', 'A').replaceAll('È', 'E').replaceAll('Ì', 'I').replaceAll('Ò', 'O').replaceAll('Ù', 'U')
           .replaceAll('Â', 'A').replaceAll('Ê', 'E').replaceAll('Î', 'I').replaceAll('Ô', 'O').replaceAll('Û', 'U')
           .replaceAll('Ã', 'A').replaceAll('Õ', 'O')
           .contains(filterTerm.toUpperCase()
           .replaceAll('Á', 'A').replaceAll('É', 'E').replaceAll('Í', 'I').replaceAll('Ó', 'O').replaceAll('Ú', 'U')
           .replaceAll('À', 'A').replaceAll('È', 'E').replaceAll('Ì', 'I').replaceAll('Ò', 'O').replaceAll('Ù', 'U')
           .replaceAll('Â', 'A').replaceAll('Ê', 'E').replaceAll('Î', 'I').replaceAll('Ô', 'O').replaceAll('Û', 'U')
           .replaceAll('Ã', 'A').replaceAll('Õ', 'O'));
  }

  updateSearch(){
    if(tempText.isEmpty || tempText == ''){
      showSnackbar(context, 'Por favor digite um termo de busca');
    }else if(tempText.length < 3){
      showSnackbar(context, 'Por favor digite um termo de busca maior');
    }else{
      setState(() {
        searchTerm = tempText;
        searchController.text = searchTerm;
      });
    }
  }

  updateFilter(){
    setState(() {
      filterTerm = filterTerm.toUpperCase();
      filterController.text = filterTerm;
    });
  }

  Future getPendingFileNames() async {
    pendingFileNames.clear();
    pendingFileNames = await getDirectoryFileNames('PENDENTES TREE', downloadDir) ?? [];
    setState(() {});
  }

  Future initialize() async {
    downloadDir = await DownloadsPath.downloadsDirectory() ?? await getApplicationDocumentsDirectory();
    pendingFileNames = await getDirectoryFileNames('PENDENTES TREE', downloadDir) ?? [];
    setState(() {});
  }
}
