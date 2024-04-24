import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:lecle_downloads_path_provider/lecle_downloads_path_provider.dart';

import 'infoPage.dart';
import 'generalLib.dart';

class TreePage extends StatefulWidget {
  final OneDriveIDs? oneDriveIDs;
  final String folder;
  final List levels;
  final dynamic father;
  final int currentLevel;

  const TreePage({
    Key? key,
    required this.oneDriveIDs,
    required this.folder,
    required this.levels,
    required this.father,
    required this.currentLevel,
  }) : super(key: key);

  @override
  _TreePageState createState() => _TreePageState();
}

class _TreePageState extends State<TreePage> {
  List<Widget> displayedElements = [];
  
  bool downloadDone = false;
  bool downloadBreak = false;

  int totalPhotosForThisLevel = 0;
  int downloadedPhotosForThisLevel = 0;

  String imgExtension = '.jpg';
  List fatherFilters = [];
  List<String> downloadingFiles = [];

  TextEditingController searchController = TextEditingController();
  String searchTerm = '';

  late Directory downloadDir;

  @override
  void initState() {
    super.initState();
    initialize();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: BackButton(color: Colors.grey[900]),
        actions: <Widget>[
          if(widget.currentLevel != 1)
            IconButton(
              icon: downloadDone
                ? Icon(Icons.cloud_done, color: Colors.grey[900])
                : widget.oneDriveIDs == null
                  ? Icon(Icons.cloud_download ,color: Colors.orange)
                  : widget.oneDriveIDs!.getDownloading()
                    ? Container(
                        width: 24,
                        height: 24,
                        padding: const EdgeInsets.all(2.0),
                        child: const CircularProgressIndicator(
                          color: Colors.black,
                          strokeWidth: 3,
                        ),
                      )
                    : Icon(Icons.cloud_download ,color: Colors.grey[900]),
              tooltip: '[$downloadedPhotosForThisLevel/$totalPhotosForThisLevel]',
              onPressed: downloadDone || widget.oneDriveIDs == null
                ? null
                : widget.oneDriveIDs!.getDownloading()
                  ? () {setState(() { downloadBreak = true; });}
                  : () async { await downloadPhotos();},
            ),
        ],
        title: Text(widget.father != null
          ? widget.father.last.toString()
          : 'Símic | Tree')
        ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children:<Widget>[
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


  Future<void> getLevelButtons() async { 
    setState(() {
    List alreadyAdded = [];
    
    for (var item in widget.levels[widget.currentLevel]){
      List itemFilters = item[0];
      var itemName = item[1].toString().replaceAll('[', '').replaceAll(', ', ' [');

      if(widget.father == null || itemFilters.toString() == fatherFilters.toString()){

        if(!alreadyAdded.contains(itemName)){
          alreadyAdded.add(itemName);

          displayedElements.add(
            Padding(padding: EdgeInsets.symmetric(vertical: 5),
            key: Key(itemName),
            child:
              ElevatedButton(
                onPressed: () {
                  widget.currentLevel < 6
                      ? Navigator.push(
                          context,
                          new MaterialPageRoute(
                            builder: (context) => TreePage(
                              oneDriveIDs: widget.oneDriveIDs,
                              folder: widget.folder,
                              levels: widget.levels,
                              father: item,
                              currentLevel: widget.currentLevel + 1,
                              )
                          )
                        ).then((value) => checkDownload())
                                
                      : Navigator.push(
                          context,
                          new MaterialPageRoute(
                            builder: (context) => InfoPage(
                              oneDriveIDs: widget.oneDriveIDs,
                              folder: widget.folder,
                              levels: widget.levels,
                              father: item,
                            )
                          )
                        ).then((value) => checkDownload());
                },
                child: Text('\n' + itemName.toString() + '\n'),
              )
            )
          );
          //print(displayedElements.last.key);
        }
      }
      
    }
    });
  }

  Future<List<String>?> getFileNamesForThisLevel([bool? removeDownloaded]) async {  ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    List<String> fileNames = [];

    if(widget.currentLevel < 2){
      for(List active in widget.levels[7]){
        List activePhotoNames = active[1][10];
        for(var photoName in activePhotoNames){
          if(photoName != null && photoName != 'null'){
            fileNames.add(photoName + '.jpg');
          }
        }
      }
    }else{
      String fatherFiltersString = fatherFilters.toString().replaceAll(']', '').replaceAll('[', '');

      for(List active in widget.levels[7]){
        String activeFilters = active[0].toString().replaceAll(']', '').replaceAll('[', '');
        if(activeFilters.toString().startsWith(fatherFiltersString)){             
          List activePhotoNames = active[1][10];
          for(var photoName in activePhotoNames){
            if(photoName != null && photoName != 'null'){
              fileNames.add(photoName + '.jpg');
            }
          }
        }
      }
    }

    fileNames = fileNames.toSet().toList();

    if(removeDownloaded == true){
      List<String> downloadedFiles = await getDirectoryFileNames(widget.folder, downloadDir) ?? [];
      fileNames.removeWhere((element) => downloadedFiles.contains(element));
    }

    return fileNames;
  }

  Future<bool?> checkDownload() async {  ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    List<String> fileNames = await getFileNamesForThisLevel(true) ?? [];
    List<String> totalFileNames = await getFileNamesForThisLevel() ?? [];

    if(fileNames.isEmpty){
      setState(() {
        downloadDone = true;
        totalPhotosForThisLevel = totalFileNames.length;
        downloadedPhotosForThisLevel = totalFileNames.length - fileNames.length;
      });
      return true;
    }else{
      setState(() {
        totalPhotosForThisLevel = totalFileNames.length;
        downloadedPhotosForThisLevel = totalFileNames.length - fileNames.length;
      });
      print('There are [${fileNames.length}] missing files at this level');
      //for(String file in fileNames){
      //  print('File [$file] was not found');
      //}
      return false;
    }
  }

  Future downloadPhotos () async {  ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

    downloadingFiles.clear();

    setState(() {
      widget.oneDriveIDs!.setDownloading(true);
    });

    List<String> fileNames = await getFileNamesForThisLevel(true) ?? [];

    downloadingFiles.addAll(fileNames);

    for(String fileName in fileNames){
      if(downloadBreak == false){
        Uint8List? fileBytes = await downloadFile(fileName, widget.oneDriveIDs!);
        if(fileBytes != null){
          File? checkFile = await storeFile(fileBytes, fileName, widget.folder, downloadDir);
          if(checkFile != null){
            downloadingFiles.remove(fileName);
            setState(() {
              downloadedPhotosForThisLevel += 1;
            });
          }
        }
      }
    }

    setState(() {
      widget.oneDriveIDs!.setDownloading(false);
      downloadBreak = false;
    });

    if(downloadingFiles.isEmpty){
      setState(() {
        downloadDone = true;
      });
    }
  }

  Future initialize() async { ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    downloadDir = await DownloadsPath.downloadsDirectory()?? await getApplicationDocumentsDirectory();

    if (widget.father != null) {
      if (widget.father[0][0] != null) {
        for (var filter in widget.father[0]) {
          fatherFilters.add(filter);
        }
      }
      fatherFilters.add(widget.father[1]);
    }
    
    getLevelButtons();
    await checkDownload();
  }
}