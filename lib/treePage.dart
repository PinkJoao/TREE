import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:path_provider/path_provider.dart';
import 'package:lecle_downloads_path_provider/lecle_downloads_path_provider.dart';

import 'infoPage.dart';
import 'generalLib.dart';

class TreePage extends StatefulWidget {
  final OneDriveIDs? oneDriveIDs;
  final String folder;
  final List<List> levels;
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
  TreePageState createState() => TreePageState();
}

class TreePageState extends State<TreePage> {
  late Directory downloadDir;

  bool downloadDone = false;
  bool downloadBreak = false;
  
  List<String> allFilesForThisLevel = [];
  List<String> downloadedFilesForThisLevel = [];

  int totalFilesForThisLevel = 0;
  int totalDownloadedFilesForThisLevel = 0;

  List fatherFilters = [];
  List<String> pendingFileNames = [];

  TextEditingController searchController = TextEditingController();
  String searchTerm = '';
  String tempText = '';

  TextEditingController filterController = TextEditingController();
  String filterTerm = '';


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
                  ? const Icon(Icons.cloud_download ,color: Colors.orange)
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
              tooltip: '[$totalDownloadedFilesForThisLevel/$totalFilesForThisLevel]',
              onPressed: downloadDone || widget.oneDriveIDs == null
                ? null
                : widget.oneDriveIDs!.getDownloading()
                  ? () {setState(() { downloadBreak = true; });}
                  : () async { await downloadLevelPhotos();},
            ),
        ],
        title: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Text(widget.father != null && widget.father != 'null'
            ? '${widget.father.last.toString()} [Nível ${widget.currentLevel}] '
            : 'Símic | Tree',
          )
        )
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            if(widget.currentLevel != 6)
              TextField(
                controller: searchController,
                onChanged: (value) {
                  setState(() { 
                    tempText = value.toUpperCase().replaceAll(' ', '-'); 
                  });
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
            
            if(widget.currentLevel != 6)
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

            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                if(searchTerm.length > 2)
                  for(List active in widget.levels[7].where((element) => matchSearch(element) && matchFather(element)      ))
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
                                father: [[active[0][0], active[0][1], active[0][2],active[0][3],active[0][4]],active[0][5]],
                              )
                            )
                          ).then((value) => getPendingFileNames());
                        },
                        child: Container(
                          alignment: Alignment.centerLeft,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [

                              Flexible(
                                child: Text('\n${active[1][0].toString()} \n[${active[1][3].toString()}]\n',)
                              ),

                              if(pendingFileNames.where((element) => element.contains(active[1][3].toString())).isNotEmpty)
                                const IconButton(
                                  onPressed: null , 
                                  icon: Icon(CupertinoIcons.check_mark_circled, color: Colors.greenAccent,)
                                ),

                            ],
                          ),
                        ),
                      )
                    ),
                    
                  if(searchController.text.length < 3)
                    for(List active in widget.levels[widget.currentLevel].where((element) => matchLevel(element)       ))
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 5),
                      key: Key('${active[1].toString().replaceAll('[', '').replaceAll(', ', ' [')} : ${UniqueKey()}'),
                      child: ElevatedButton(
                        onPressed: widget.currentLevel == 6
                          ? () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => InfoPage(
                                  oneDriveIDs: widget.oneDriveIDs,
                                  folder: widget.folder,
                                  levels: widget.levels,
                                  father: active,
                                )
                              )
                            ).then((value) => getPendingFileNames());
                          }
                          : () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => TreePage(
                                  oneDriveIDs: widget.oneDriveIDs,
                                  folder: widget.folder,
                                  levels: widget.levels,
                                  father: active,
                                  currentLevel: widget.currentLevel + 1,
                                )
                              )
                            ).then((value) => getPendingFileNamesAndCheckDownload());
                          },
                        child: Container(
                          alignment: Alignment.centerLeft,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: widget.currentLevel == 6
                            ? [
                              Flexible(
                                  child: Text('\n${active[1].toString().replaceAll('[', '').replaceAll(', ', ' [')}\n')
                                ),

                                if(pendingFileNames.where((element) => element.startsWith(active[1][1].toString().replaceAll('/', '%').replaceAll('"', '@'))).isNotEmpty)
                                  const IconButton(
                                    onPressed: null,
                                    icon: Icon(CupertinoIcons.check_mark_circled, color: Colors.greenAccent,)
                                  ),
                            ]
                            : [

                                Flexible(
                                  child: Text('\n${active[1].toString().replaceAll('[', '').replaceAll(', ', ' [')}\n')
                                ),

                              ],
                          ),
                        ),
                      )
                    )

              ].where((element) => (element.key.toString().split(' : ').first.toUpperCase()
                                                          .replaceAll('Á', 'A').replaceAll('É', 'E').replaceAll('Í', 'I').replaceAll('Ó', 'O').replaceAll('Ú', 'U')
                                                          .replaceAll('À', 'A').replaceAll('È', 'E').replaceAll('Ì', 'I').replaceAll('Ò', 'O').replaceAll('Ù', 'U')
                                                          .replaceAll('Â', 'A').replaceAll('Ê', 'E').replaceAll('Î', 'I').replaceAll('Ô', 'O').replaceAll('Û', 'U')
                                                          .replaceAll('Ã', 'A').replaceAll('Õ', 'O')
                                      .contains(filterTerm.toUpperCase()
                                                          .replaceAll('Á', 'A').replaceAll('É', 'E').replaceAll('Í', 'I').replaceAll('Ó', 'O').replaceAll('Ú', 'U')
                                                          .replaceAll('À', 'A').replaceAll('È', 'E').replaceAll('Ì', 'I').replaceAll('Ò', 'O').replaceAll('Ù', 'U')
                                                          .replaceAll('Â', 'A').replaceAll('Ê', 'E').replaceAll('Î', 'I').replaceAll('Ô', 'O').replaceAll('Û', 'U')
                                                          .replaceAll('Ã', 'A').replaceAll('Õ', 'O')))).toList(),
            ),

                
            
          ]
        ),
      )
    );
  }

  bool matchLevel(List active){
    List activeFilters = active[0];
    if(widget.currentLevel == 1 || widget.father == null || widget.father == 'null' || widget.father == ''){
      return true;
    }else if(activeFilters.toString() == fatherFilters.toString()){
      return true;
    }
    return false;
  }

  bool matchFather(List active){
    List fathers = active[0];
    if(widget.currentLevel == 1){
      return true;
    }else if(widget.currentLevel == 2){
      if(fathers[0].toString() == widget.father[1].toString()){
        return true;
      }else{
        return false;
      }
    }else{
      List<String> matchFathers = [];
      matchFathers.addAll(widget.father[0]);
      matchFathers.add(widget.father[1]);

      if (matchFathers.every((item) => fathers.contains(item))) {
        return true;
      }

      return false;
    }
    
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

  updateSearch(){
    if(tempText.isEmpty || tempText == ''){
      showSnackbar(context, 'Por favor digite um termo de busca');
      setState(() { });
    }else if(tempText.length < 3){
      showSnackbar(context, 'Por favor digite um termo de busca maior');
      setState(() { });
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

  Future  getPendingFileNamesAndCheckDownload() async {
    await getPendingFileNames();
    await checkDownload();
  }

  Future getPendingFileNames() async {
    pendingFileNames.clear();
    pendingFileNames = await getDirectoryFileNames('PENDENTES TREE', downloadDir) ?? [];
    setState(() {});
  }

  Future<bool> checkDownload() async {
    if(allFilesForThisLevel.isEmpty){
      for(List active in widget.levels[7].where((element) => matchFather(element)      )){
        allFilesForThisLevel.addAll(active[1][10]);
      }
    }
    
    allFilesForThisLevel = allFilesForThisLevel.toSet().toList();
    
    List<String>? filesInDirectory = await getDirectoryFileNames(widget.folder, downloadDir, 'jpg') ?? [];
    downloadedFilesForThisLevel.clear();
    downloadedFilesForThisLevel.addAll(filesInDirectory.where((element) => allFilesForThisLevel.contains(element.split('.').first)));

    setState(() {
      totalFilesForThisLevel = allFilesForThisLevel.length;
      totalDownloadedFilesForThisLevel = downloadedFilesForThisLevel.length;
    });


    if(totalFilesForThisLevel - totalDownloadedFilesForThisLevel == 0){
      setState(() {
        downloadDone = true;
      });
      return true;
    }else{
      return false;
    }
  }

  Future downloadLevelPhotos() async {
    setState(() {
      widget.oneDriveIDs!.setDownloading(true);
    });

    List<String> missingFiles = allFilesForThisLevel.where((element) => !downloadedFilesForThisLevel.contains(element)).toList();
    int downloadedFiles = 0;

    for(String fileName in missingFiles){
      if(downloadBreak == false){
        Uint8List? fileBytes = await downloadFile('$fileName.jpg', widget.oneDriveIDs!);
        if(fileBytes != null){
          File? checkFile = await storeFile(fileBytes, '$fileName.jpg', widget.folder, downloadDir);
          if(checkFile != null){
            downloadedFiles += 1;
            setState(() {
              totalDownloadedFilesForThisLevel += 1;
            });
          }
        }
      }
    }

    setState(() {
      widget.oneDriveIDs!.setDownloading(false);
      downloadBreak = false;
    });

    if(downloadedFiles == missingFiles.length){
      setState(() {
        downloadDone = true;
      });
    }

  }

  getFatherFilters(){
    if (widget.father != null && widget.father != 'null') {
      if (widget.father[0][0] != null && widget.father[0][0] != 'null') {
        for (var filter in widget.father[0]) {
          fatherFilters.add(filter);
        }
      }
      fatherFilters.add(widget.father[1]);
    }
  }

  Future initialize() async {
    downloadDir = await DownloadsPath.downloadsDirectory()?? await getApplicationDocumentsDirectory();
    pendingFileNames = await getDirectoryFileNames('PENDENTES TREE', downloadDir) ?? [];
    await checkDownload();
    getFatherFilters();
    setState(() { });
  }


  
}