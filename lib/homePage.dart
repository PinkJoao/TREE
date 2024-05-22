import 'dart:io';
import 'dart:ui';
import 'dart:async';
import 'package:intl/intl.dart';
import 'package:excel/excel.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lecle_downloads_path_provider/lecle_downloads_path_provider.dart';

import 'treePage.dart';
import 'searchPage.dart';
import 'generalLib.dart';

class HomePage extends StatefulWidget {
  final dynamic token;

  const HomePage({Key? key, required this.token}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {

  bool loading = false;
  bool drawerLoading = false;
  bool offlineMode = true;
  bool initializing = true;

  late Directory downloadDir;
  late SharedPreferences preferences;
  late OneDriveIDs uploadOneDriveIDs;

  OneDriveIDs? downloadOneDriveIDs;

  TextEditingController searchController = TextEditingController();
  String searchTerm = '';

  String uploadfolder  = 'testFolderTI';
  String pendingFolder = 'PENDENTES TREE';
  String storageFolder = 'FOTOS TREE';
  String trashFolder   = 'LIXEIRA TREE';
  String sheetFolder   = 'PLANILHAS TREE';
  String sheetName     = 'BASE CONSOLIDADA';

  String? selectedInventoryName;
  String? loadedInventoryName;
  String lastUpdate = '';

  Map<String,String>? selectedInventory;
  
  Map<String, Map<String, String>> inventories = {
    'Aratu - BA'          : {'file' : 'LISTA DE ATIVOS ARATU CONSOLIDADO.xlsx'         , 'folder' : 'Z-FOTOS CONSOLIDADAS (ARATU)'         , 'name' : 'Aratu - BA'         },
    'Itaqui - MA'         : {'file' : 'LISTA DE ATIVOS ITAQUI CONSOLIDADO.xlsx'        , 'folder' : 'Z-FOTOS CONSOLIDADAS (ITAQUI)'        , 'name' : 'Itaqui - MA'        },
    'Rio de Janeiro - RJ' : {'file' : 'LISTA DE ATIVOS RIO DE JANEIRO CONSOLIDADO.xlsx', 'folder' : 'Z-FOTOS CONSOLIDADAS (RIO DE JANEIRO)', 'name' : 'Rio de Janeiro - RJ'},
    'Rondonópolis - MT'   : {'file' : 'LISTA DE ATIVOS RONDONÓPOLIS CONSOLIDADO.xlsx'  , 'folder' : 'Z-FOTOS CONSOLIDADAS (RONDONÓPOLIS)'  , 'name' : 'Rondonópolis - MT'  },
    'Santos - SP'         : {'file' : 'LISTA DE ATIVOS SANTOS CONSOLIDADO.xlsx'        , 'folder' : 'Z-FOTOS CONSOLIDADAS (SANTOS)'        , 'name' : 'Santos - SP'        },
    'Suape - PE'          : {'file' : 'LISTA DE ATIVOS SUAPE CONSOLIDADO.xlsx'         , 'folder' : 'Z-FOTOS CONSOLIDADAS (SUAPE)'         , 'name' : 'Suape - PE'         },
    'Vila do Conde - PA'  : {'file' : 'LISTA DE ATIVOS VILA DO CONDE CONSOLIDADO.xlsx' , 'folder' : 'Z-FOTOS CONSOLIDADAS (VILA DO CONDE)' , 'name' : 'Vila do Conde - PA' },
  };

  List<String> inventoryList = [
    'Aratu - BA',
    'Itaqui - MA',
    'Rio de Janeiro - RJ',
    'Rondonópolis - MT',
    'Santos - SP',
    'Suape - PE',
    'Vila do Conde - PA',
  ];

  List<List> pendingFiles = [];
  List<Widget> pendingWidgets = [];
  List<Widget> inventoryWidgets = [];
  List<List> levels = [];

  @override
  void initState() {
    super.initState();
    initialize();
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: Text(selectedInventoryName ?? 'Símic | TREE'),
        iconTheme: IconThemeData(color: Colors.grey[900]),
      ),
      drawerScrimColor: Colors.transparent,
      drawerEnableOpenDragGesture: true,
      drawer: loading
      ? null
      : SizedBox(
          width: getTotalWidth(context),
          height: getTotalHeight(context),
          child: Drawer(
            backgroundColor: Colors.transparent,
            elevation: 0,
            child: GestureDetector(
              onHorizontalDragEnd: (v) {/* do nothing */},
              child: Row(
                children: [
                  BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
                    child: Container(
                      width: getTotalWidth(context) / 10 * 8,
                      height: getTotalHeight(context),
                      color: Colors.grey[900],
                      child: Stack(
                        children: [
                          SingleChildScrollView(
                            padding: EdgeInsets.zero,
                            child: drawerLoading || loading
                            ? Column(
                              children: [
                                Padding(padding: EdgeInsets.symmetric(vertical: getTotalHeight(context)/2), 
                                  child: Center(
                                    child: CircularProgressIndicator(color: orangeColor)
                                  )
                                )
                              ]
                            ) 
                            : Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                DrawerHeader(
                                  decoration: const BoxDecoration( color: Color(0xFFf07f34), ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        width: 80,
                                        height: 80,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: Colors.grey[900],
                                        ),
                                        child: GestureDetector(
                                          child: Image.asset('assets/images/simicLogo.png'),
                                          onLongPress: () async {
                                            if(levels.isNotEmpty && selectedInventoryName == loadedInventoryName){
                                              HapticFeedback.mediumImpact();
                                              await createTxtSheet(levels);
                                              HapticFeedback.vibrate();
                                            }

                                            /*setState(() {
                                              adminTrigger1 = !adminTrigger1;

                                              if(adminTrigger1 && adminTrigger2){
                                                adminMode = true;
                                                uploadfolder = testFolder;
                                                updateIDs();
                                              }else{
                                                adminMode = false;
                                                uploadfolder = oneDriveFolder;
                                                updateIDs();
                                              }
                                            });*/
                                          },
                                        ),
                                      ),

                                      const SizedBox( height: 20, ),

                                      Text(
                                        'Inventários',
                                        style: TextStyle(
                                          color: Colors.grey[900],
                                          fontSize: 25,
                                          fontWeight: FontWeight.bold
                                        ),
                                      ),
                                    ],
                                  )
                                ),
                                const SizedBox(),
                              ] + inventoryWidgets,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    child: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.centerLeft, 
                          end: Alignment.centerRight,
                          stops: [0 , 0.5],
                          colors: [
                            Color.fromARGB(155, 0, 0, 0), 
                            Colors.transparent,
                          ]
                        )
                      ),
                      child: Stack(
                        children: [
                          
                          GestureDetector(
                            onTap: drawerLoading
                            ? null
                            : () { Navigator.pop(context); },
                            onHorizontalDragEnd: drawerLoading
                            ? null
                            : (v) { Navigator.pop(context); },
                          ),
                        ],
                      ),
                    )
                  ),
                ],
              ),
            ),
          ),
        ),
      onDrawerChanged: (bool isDrawerOpened) async {
        if (isDrawerOpened) {
          //getInventoryWidgets();
          //await onDrawerOpened();
        } else if (!isDrawerOpened) {
          await onDrawerClosed();
        }
      },
      endDrawerEnableOpenDragGesture: true,
      endDrawer: loading
      ? null
      : SizedBox(
          width: getTotalWidth(context),
          height: getTotalHeight(context),
          child: Drawer(
            backgroundColor: Colors.transparent,
            elevation: 0,
            child: GestureDetector(
              onHorizontalDragEnd: (v) {/* do nothing */},
              child: Row(
                children: [
                  Expanded(
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 5.0, sigmaY: 5.0),
                      child: Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.centerRight,
                            end: Alignment.centerLeft,
                            stops: [0 , 0.5],
                            colors: [
                              Color.fromARGB(155, 0, 0, 0), 
                              Colors.transparent,
                            ]
                          )
                        ),
                        child: Column(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: () { Navigator.pop(context); },
                                onHorizontalDragEnd: (v) { Navigator.pop(context); },
                              ),
                            ),

                            Container(
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.redAccent
                              ),
                              
                              height: getTotalWidth(context) / 10 * 1.3,
                              width: getTotalWidth(context) / 10 * 1.3,
                              child: IconButton.filled(
                                onPressed: () async {
                                  await deleteSelected();
                                },
                                color: Colors.grey[900], 
                                icon: const Icon(Icons.delete_forever_rounded)
                              ),
                            ),

                            SizedBox(height: getTotalWidth(context) / 10 * 0.8),
                        
                            Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: drawerLoading || offlineMode
                                ? Colors.grey
                                : Colors.greenAccent,
                              ),
                              height: getTotalWidth(context) / 10 * 1.7,
                              width: getTotalWidth(context) / 10 * 1.7,
                              child: IconButton(
                                onPressed: offlineMode 
                                ? null 
                                : () async {
                                  await uploadSelected();
                                },
                                color: Colors.grey[900], 
                                icon: const Icon(Icons.cloud_upload_rounded)
                              ),
                            ),

                            SizedBox(height: getTotalWidth(context) / 10 * 0.8),
                          ],
                        )
                      )
                    ),
                  ),
                  Container(
                    width: getTotalWidth(context) / 10 * 8,
                    height: getTotalHeight(context),
                    color: Colors.grey[900],
                    child: Stack(
                      children: [
                        SingleChildScrollView(
                          padding: EdgeInsets.zero,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              DrawerHeader(
                                decoration: const BoxDecoration( color: Color(0xFFf07f34), ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Container(
                                      width: 80,
                                      height: 80,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Colors.grey[900],
                                      ),
                                      child: GestureDetector(
                                        child: Image.asset('assets/images/simicLogo.png'),
                                        onLongPress: () {
                                          /*setState(() {
                                            adminTrigger2 = !adminTrigger2;

                                            if(adminTrigger1 && adminTrigger2){
                                              adminMode = true;
                                              uploadfolder = testFolder;
                                              updateIDs();
                                            }else{
                                              adminMode = false;
                                              uploadfolder = oneDriveFolder;
                                              updateIDs();
                                            }
                                          });*/
                                        },
                                      ),
                                    ),

                                    const SizedBox( height: 20, ),

                                    Text(
                                      'Fotos pendentes',
                                      style: TextStyle(
                                        color: Colors.grey[900],
                                        fontSize: 25,
                                        fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                )
                              ),
                              const SizedBox(),
                            ] + pendingWidgets,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      onEndDrawerChanged: (bool isEndDrawerOpened) async {
        if (isEndDrawerOpened) {
          await getPendingFiles();
          //await onDrawerOpened();
        } else if (!isEndDrawerOpened) {
          //await onDrawerClosed();
        }
      },
      body: Center(
        child: loading
        ? Center(
            child: Text('Carregando Inventário...'.toUpperCase(),
              style: TextStyle(
                fontSize: getTotalWidth(context)/22,
                fontWeight: FontWeight.bold,
              ),
            ),
          )//CircularProgressIndicator( color: orangeColor, )
        : Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                  child: Text(
                    'Última atualização: $lastUpdate',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  )
                )
              ),

              ElevatedButton(
                onPressed: selectedInventory != null && selectedInventoryName == loadedInventoryName
                ? () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => TreePage(
                        oneDriveIDs: downloadOneDriveIDs,
                        folder: selectedInventory!['folder']!,
                        levels: levels,
                        father: null,
                        currentLevel: 1,
                      )
                    )
                  );
                }
                : null, 
                child: const Text('Árvore de ativos')
              ),

              TextField(
                controller: searchController,
                onChanged: (value) {
                  setState(() {
                    searchTerm = value;
                  });
                },
                onEditingComplete: selectedInventory != null && loadedInventoryName == selectedInventoryName
                  ? () {
                    searchTerm.length < 3
                      ? searchTerm.isNotEmpty 
                        ? showSnackbar(context, 'Por favor digite um termo de busca maior')
                        : showSnackbar(context, 'Por favor digite um termo de busca')
                      : Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => SearchPage(
                              oneDriveIDs: downloadOneDriveIDs,
                              folder: selectedInventory!['folder']!,
                              levels: levels,
                              searchTerm: searchTerm.replaceAll(' ', '-').toUpperCase(),
                            )
                          )
                        );
                  }
                  :null,
                decoration: InputDecoration(
                  hintText: 'Buscar por TAG',
                  border: const OutlineInputBorder(),
                  hintStyle: TextStyle(
                    color: Colors.grey[600],
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 15,
                    vertical: 10,
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(CupertinoIcons.search, color: selectedInventory != null && loadedInventoryName == selectedInventoryName ? orangeColor : Colors.grey[800]),
                    onPressed: selectedInventory != null && loadedInventoryName == selectedInventoryName
                      ? () {
                        searchTerm.length < 3
                          ? searchTerm.isNotEmpty
                            ? showSnackbar(context, 'Por favor digite um termo de busca maior')
                            : showSnackbar(context, 'Por favor digite um termo de busca')
                          : Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => SearchPage(
                                  oneDriveIDs: downloadOneDriveIDs,
                                  folder: selectedInventory!['folder']!,
                                  levels: levels,
                                  searchTerm: searchTerm.replaceAll(' ', '-').toUpperCase(),
                                )
                              )
                            );
                      }
                      :null,
                  )
                ),
              ),

              /*ElevatedButton(
                onPressed: () {
                  for(int i = 0; i < levels2[7].length; i++){
                    if(levels1[7][i].toString() != levels2[7][i].toString()){
                      print('ativo ${levels1[7][i].toString()} \n\n diverge de ${levels2[7][i].toString()}');
                    }
                  };
                }, 
                style: ButtonStyle(backgroundColor: MaterialStateProperty.all(Colors.lightBlue)),
                child: Text('teste')
              ),

              ElevatedButton(
                onPressed: () {
                  setState(() {
                    if(levels == levels1){
                      levels = levels2;
                    }else if( levels == levels2){
                      levels = levels1;
                    }
                  });
                }, 
                style: ButtonStyle(backgroundColor: MaterialStateProperty.all(Colors.lightBlue)),
                child: Text('teste 2')
              )*/
            ],
          )
        )
      ),    
    );
  }

  getInventoryWidgets() {
    inventoryWidgets.clear();
    for(String inventory in inventoryList){
      inventoryWidgets.add(
        Container(
          height: getTotalHeight(context)/10,
          decoration: BoxDecoration(
            color: selectedInventoryName == inventory
            ? const Color.fromARGB(123, 240, 127, 52)
            : Colors.transparent,
          ),
          child: TextButton(
            onPressed: () async {
              setInventory(inventory);
            },
            onLongPress: () async {
              setInventory(inventory);
              if(selectedInventoryName == inventory){
                await deleteXl();
              }
            },
            child: Text(
              inventory,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
                color: selectedInventoryName == inventory
                ? Colors.greenAccent
                : orangeColor,
              ),
            ),
          ),
        )
      );
    }
    setState(() {});
  }

  Future onDrawerClosed() async {
    if(selectedInventoryName != loadedInventoryName){
      setLoading(true);
      await loadInventory(true);
      setLoading(false);
    }
  }

  Future<bool?> showDownloadDialog([String? text]) async {
    bool? answer;
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(text ?? 'Base indisponível, deseja realizar o Download?', 
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: getTotalWidth(context) / 20),
            ),
          actionsAlignment: MainAxisAlignment.spaceAround,
          alignment: Alignment.bottomCenter,
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(20.0))),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, true);
              },
              child: Text('Sim',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: getTotalWidth(context) / 20)
              )
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: Text('Não',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: getTotalWidth(context) / 20)
              )
            ),
          ],
        );
      },
    ).then((value) {answer = value;});

    return answer;
  }

  setLastUpdate(String filePath){
    String fileName = filePath.split('/').last.split('.').first;
    String date = fileName.substring(0,8);
    String time = fileName.substring(9,15);

    setState(() {
      lastUpdate = '${date.substring(0,4)}/${date.substring(4,6)}/${date.substring(6,8)} - ${time.substring(0,2)}:${time.substring(2,4)}';
    });
  }

  Future deleteXl() async {
    if(selectedInventoryName != selectedInventory!['name']! || selectedInventory == null || offlineMode == true || downloadOneDriveIDs == null){
      showSnackbar(context, 'Selecione um inventário para excluir');
      return;
    }

    List<File> files = await getDirectoryFiles(sheetFolder, downloadDir) ?? [];
    if(files.isEmpty){
      showSnackbar(context, 'Inventário não está armazenado');
      return;
    }

    files.removeWhere((element) => !element.path.split('/').last.contains(selectedInventory!['file']!.split('.').first));
    

    if(files.isEmpty){
      showSnackbar(context, 'Inventário não está armazenado');
      return;
    }

    List<File?> movedFiles = [];

    for(File file in files){
      File? checkFile = await moveFile(file.path.split('/').last, sheetFolder, trashFolder, downloadDir);
      movedFiles.add(checkFile);
    }

    if(movedFiles.isNotEmpty){
      showSnackbar(context, 'Falha ao excluir inventário');
      return;
    }

    setState(() {
      loadedInventoryName = null;
    });

    print(loadedInventoryName.toString());
    print(selectedInventoryName);

    showSnackbar(context, 'Inventário com sucesso');

  }

  Future<File?> downloadTxt([bool? loading]) async {
    print('Downloading txt file');

    if(loading == true){
      setLoading(true);
    }

    if(downloadOneDriveIDs == null){
      await getDownloadOneDriveIds();
      if (downloadOneDriveIDs == null){
        showSnackbar(context, 'Falha na conexão');
        return null;
      }
    }

    Uint8List? fileBytes = await downloadFile(selectedInventory!['file']!.replaceAll('xlsx', 'txt'), downloadOneDriveIDs!);
    if(fileBytes == null){
      showSnackbar(context, 'Falha ao baixar arquivo txt');
      return null;
    }

    File? txtFile = await storeFile(fileBytes, '${DateFormat('yyyyMMdd HHmmss').format(DateTime.now())} ${selectedInventory!['file']!.replaceAll('xlsx', 'txt')}', sheetFolder ,downloadDir);
    if(txtFile == null){
      showSnackbar(context, 'Falha ao armazenar arquivo txt');
      return null;
    }

    

    if(loading == true){
      setLoading(false);
    }

    return txtFile;
  }

  Future<File?> downloadXl([bool? loading]) async {
    print('Downloading xlsx file');

    if(loading == true){
      setLoading(true);
    }

    if(downloadOneDriveIDs == null){
      await getDownloadOneDriveIds();
      if (downloadOneDriveIDs == null){
        showSnackbar(context, 'Falha na conexão');
        return null;
      }
    }

    Uint8List? fileBytes = await downloadFile(selectedInventory!['file']!, downloadOneDriveIDs!);
    if(fileBytes == null){
      showSnackbar(context, 'Falha ao baixar arquivo xlsx');
      return null;
    }


    File? xlFile = await storeFile(fileBytes, '${DateFormat('yyyyMMdd HHmmss').format(DateTime.now())} ${selectedInventory!['file']!}', sheetFolder ,downloadDir);
    if(xlFile == null){
      showSnackbar(context, 'Falha ao armazenar arquivo xlsx');
      return null;
    }


    if(loading == true){
      setLoading(false);
    }

    return xlFile;
  }

  Future<File?> getTxtFile([bool? loading]) async {
    print('Getting text file');
    List<File> txtFiles = await getDirectoryFiles(sheetFolder, downloadDir, 'txt') ?? [];
    
    if(txtFiles.isEmpty){
      if(offlineMode == true || initializing == true){
        return null;
      }else{
        bool? dialog = await showDownloadDialog('Arquivo de leitura rápida INDISPONÍVEL, deseja realizar o Download?');

        if(dialog == true){
          File? txtFile = await downloadTxt(loading);
          return txtFile;
        }else{
          return null;
        }
      }
    }else{
      for(File file in txtFiles){
        if(file.path.contains(selectedInventory!['file']!.replaceAll('xlsx', 'txt'))){
          print('File [${file.path}] was found in directory');
          return file;
        }
      }
      if(offlineMode == true || initializing == true){
        return null;
      }else{
        bool? dialog = await showDownloadDialog('Arquivo de leitura rápida INDISPONÍVEL, deseja realizar o Download?');
        if(dialog == true){
          File? txtFile = await downloadTxt(loading);
          return txtFile;
        }else{
          return null;
        }
      }
    }
  }


  Future<File?> getXlFile([bool? loading]) async {
    print('Getting excel file');
    List<File> xlFiles = await getDirectoryFiles(sheetFolder, downloadDir, 'xlsx') ?? [];
    
    if(xlFiles.isEmpty){
      if(offlineMode == true || initializing == true){
        return null;
      }else{
        bool? dialog = await showDownloadDialog('PLANILHA INDISPONÍVEL, deseja realizar o Download?');

        if(dialog == true){
          File? xlFile = await downloadXl(loading);
          return xlFile;
        }else{
          return null;
        }
      }
    }else{
      for(File file in xlFiles){
        if(file.path.contains(selectedInventory!['file']!)){
          print('File [${file.path}] was found in directory');
          return file;
        }
      }
      if(offlineMode == true || initializing == true){
        return null;
      }else{
        bool? dialog = await showDownloadDialog('PLANILHA INDISPONÍVEL, deseja realizar o Download?');
        if(dialog == true){
          File? xlFile = await downloadXl(loading);
          return xlFile;
        }else{
          return null;
        }
      }
    }
  }


  Future<List<List>> loadTxtInventory (String text) async { //------------------------------------------------------------
    List<List> levelList = [];
    List<String> levelStrings = text.split('\n\n\n');
    
    for (int i = 0; i < 8; i++) {
      switch (i) {
        case 0:
          List newList = [null];
          levelList.add(newList);
          break;
        
        case 1:
          List<String> activeStrings = levelStrings[i].split('\n');
          List newLevel = [];
          for(String activeString in activeStrings){
            activeString = activeString.substring(2, activeString.length -1);
            List<String> activeSplit = activeString.split('], ');
            String activeName = activeSplit.last;
            List<String> filters = activeSplit.first.split(', ');
            newLevel.add([filters, activeName]);
          }
          levelList.add(newLevel);
          break;
        
        case 2:
          List<String> activeStrings = levelStrings[i].split('\n');
          List newLevel = [];
          for(String activeString in activeStrings){
            activeString = activeString.substring(2, activeString.length -1);
            List<String> activeSplit = activeString.split('], ');
            String activeName = activeSplit.last;
            List<String> filters = activeSplit.first.split(', ');
            newLevel.add([filters, activeName]);
          }
          levelList.add(newLevel);
          break;
        
        case 3:
          List<String> activeStrings = levelStrings[i].split('\n');
          List newLevel = [];
          for(String activeString in activeStrings){
            activeString = activeString.substring(2, activeString.length -1);
            List<String> activeSplit = activeString.split('], ');
            String activeName = activeSplit.last;
            List<String> filters = activeSplit.first.split(', ');
            newLevel.add([filters, activeName]);
          }
          levelList.add(newLevel);
          break;
        
        case 4:
          List<String> activeStrings = levelStrings[i].split('\n');
          List newLevel = [];
          for(String activeString in activeStrings){
            activeString = activeString.substring(2, activeString.length -1);
            List<String> activeSplit = activeString.split('], ');
            String activeName = activeSplit.last;
            List<String> filters = activeSplit.first.split(', ');
            newLevel.add([filters, activeName]);
          }
          levelList.add(newLevel);
          break;
        
        case 5:
          List<String> activeStrings = levelStrings[i].split('\n');
          List newLevel = [];
          for(String activeString in activeStrings){
            activeString = activeString.substring(2, activeString.length -1);
            List<String> activeSplit = activeString.split('], ');
            String activeName = activeSplit.last;
            List<String> filters = activeSplit.first.split(', ');
            newLevel.add([filters, activeName]);
          }
          levelList.add(newLevel);
          break;
        
        case 6:
          List<String> activeStrings = levelStrings[i].split('\n');
          List<List> newLevel = [];
          for(String activeString in activeStrings){
            activeString = activeString.substring(2, activeString.length -2);
            List<String> activeSplit = activeString.split('], [');
            List<String> activeInfo = activeSplit.last.split(', ');
            List<String> filters = activeSplit.first.split(', ');
            newLevel.add([filters, activeInfo]);
          }
          levelList.add(newLevel);
          break;
        
        case 7:
          List<String> activeStrings = levelStrings[i].split('\n');
          List lastLevel = [];
          for(String activeString in activeStrings){
            activeString = activeString.substring(2, activeString.length -3);
            List<String> activeSplit = activeString.split(']], [');

            String filtersString = activeSplit.first;
            List<String> commonFilters = filtersString.split(', [').first.split(', ');
            List<String> compoundFilters = filtersString.split(', [').last.split(', ');
            List filters = [];
            filters.addAll(commonFilters);
            filters.add(compoundFilters);

            String infoString = activeSplit.last;
            List<String> activeInfo = infoString.split(', [').first.split(', ');
            List<String> photos = infoString.split(', [').last.split(', ');
            photos.removeWhere((element) => element == '' || element == 'null' || element == ' ' || element == 'N/A' || element == 'n/a');


            lastLevel.add(
              [
                filters,          // 00 filters
                [
                  activeInfo[0],  // 01 00 description
                  activeInfo[1],  // 01 01 localTag
                  activeInfo[2],  // 01 02 engTag
                  activeInfo[3],  // 01 03 proposedTag
                  activeInfo[4],  // 01 04 codtipalp
                  activeInfo[5],  // 01 05 serial
                  activeInfo[6],  // 01 06 model
                  activeInfo[7],  // 01 07 codfor
                  activeInfo[8],  // 01 08 numpat
                  activeInfo[9],  // 01 09 observation
                  photos          // 01 10 photos
                ]
              ]
            );
          }
          levelList.add(lastLevel);
          break;
      }
    }

    return levelList;
  }

  Future<List<List>> loadXlInventory (Excel excel) async { //-------------------------------------------------------------
    Sheet? rawTable = excel.tables[sheetName];

    List table = [];

    for (var row in rawTable!.rows) {
      List newRow = [];
      if (row.isNotEmpty) {
        for (int column = 0; column < rawTable.maxColumns; column++) {
          if (row[column] == null) {
            newRow.add(null);
          } else {
            newRow.add(row[column]!.value.toString());
          }
        }
        table.add(newRow);
      }
    }

    List<List> levelList = [];
    List<String> allPhotos = [];

    for (int i = 0; i < 8; i++) {
      switch (i) {
        case 0:
          List newList = [null];
          levelList.add(newList);
          break;

        case 1:
          List newLevel = [];
          for (List row in table) {
            if(row[1].toString().contains('1')){ // && newLevel.where((element) => element[0].toString() == [null].toString() && element[1].toString() == row[5].toString()).isEmpty
              newLevel.add([
                [null], // filter
                row[5].toString()
              ]);
            }
          }
          levelList.add(newLevel);
          break;

        case 2:
          List newLevel = [];
          for (List row in table) {
            if(row[1].toString().contains('2')){ // && newLevel.where((element) => element[0].toString() == [row[5]].toString() && element[1].toString() == row[6].toString()).isEmpty
              newLevel.add([
                [row[5].toString()], // filter
                row[6].toString()
              ]);
            }
          }
          levelList.add(newLevel);
          break;

        case 3:
          List newLevel = [];
          for (List row in table) {
            if(row[1].toString().contains('3')){ // && newLevel.where((element) => element[0].toString() == [row[5], row[6]].toString() && element[1].toString() == row[7].toString()).isEmpty
              newLevel.add([
                [row[5].toString(), row[6].toString()], // filters
                row[7].toString()
              ]);
            }
          }
          levelList.add(newLevel);
          break;

        case 4:
          List newLevel = [];
          for (List row in table) {
            if(row[1].toString().contains('4')){ // && newLevel.where((element) => element[0].toString() == [row[5], row[6], row[7]].toString() && element[1].toString() == row[8].toString()).isEmpty
              newLevel.add([
                [row[5].toString(), row[6].toString(), row[7].toString()], // filters
                row[8].toString()
              ]);
            }
          }
          levelList.add(newLevel);
          break;

        case 5:
          List newLevel = [];
          for (List row in table) {
            if(row[7] != row[8] && (row[1].toString().contains('4') || row[1].toString().contains('5'))){ // && newLevel.where((element) => element[0].toString() == [row[5], row[6], row[7], row[8]].toString() && element[1].toString() == row[9].toString()).isEmpty
              newLevel.add([
                [row[5].toString(), row[6].toString(), row[7].toString(), row[8].toString()], // filters
                row[9].toString()
              ]);
            }
          }
          levelList.add(newLevel);
          break;

        case 6:
          List newLevel = [];
          for (List row in table) {
            if (row[7] != row[8] && (row[1].toString().contains('4') || row[1].toString().contains('5') || row[1].toString().contains('6'))) { // && newLevel.where((element) => element[0].toString() == [row[5], row[6], row[7], row[8], row[9]].toString() && element[1].toString() == [row[10],row[4]].toString()).isEmpty
              newLevel.add([
                [row[5].toString(), row[6].toString(), row[7].toString(), row[8].toString(), row[9].toString()], // filters
                [row[10].toString(),row[4].toString()]
              ]);
            }
          }
          levelList.add(newLevel);
          break;

          case 7:
          List lastLevel = [];
          for (List row in table) {
            if(!(row[5] == row[6] && row[5] == row[7] && row[5] == row[8]) && (row[1].toString().contains('4') || row[1].toString().contains('5') || row[1].toString().contains('6'))){

              List<String> photos = [row[17].toString(),row[18].toString(),row[19].toString(),row[20].toString()];
              photos.removeWhere((element) => !element.contains('IMG_'));
              photos = photos.toSet().toList();
              allPhotos.addAll(photos);

              lastLevel.add([
                [row[5].toString(), row[6].toString(), row[7].toString(), row[8].toString(), row[9].toString(), [row[10].toString(),row[4].toString()]], // 00 filters
                [
                  row[10].toString(), // 01 00 description
                  row[2].toString(),  // 01 01 localTag
                  row[3].toString(),  // 01 02 engTag
                  row[4].toString(),  // 01 03 proposedTag
                  row[11].toString(), // 01 04 codtipalp
                  row[12].toString(), // 01 05 serial
                  row[13].toString(), // 01 06 model
                  row[14].toString(), // 01 07 codfor
                  row[15].toString(), // 01 08 numpat
                  row[16].toString(), // 01 09 observation
                  photos              // 01 10 photos
                ]
              ]);
            }
          }
          levelList.add(lastLevel);
          break;
      }
    }

    levelList = await getDuplicates(levelList, allPhotos);

    /*for(List level in levelList){
      level.sort((a, b) => a.toString().toLowerCase().compareTo(b.toString().toLowerCase()));
    }*/

    return levelList;
  }

  Future createTxtSheet(List<List> levelList) async {
    print('Creating TXT file');
    String text = '';

    for(List level in levelList){
      for(List? active in level){
        print(active.toString() + '\n\n');
        text = '$text${active.toString().replaceAll('\n', ' ')}\n';
      }

      print('\n\n');
      text = '$text\n\n';
    }

    text = text.substring(0,text.length - 3);

    await storeText('${DateFormat('yyyyMMdd HHmmss').format(DateTime.now())} ${selectedInventory!['file']!.replaceAll('xlsx', 'txt')}', text, sheetFolder, downloadDir);
  }


  Future loadInventory([bool? loading]) async {
    print('Loading inventory');
    setLoading(true);

    if(selectedInventory == null){
      setLoading(false);
      print('No inventory was selected');
      return;
    }

    await getDownloadOneDriveIds();

    // TRY TO GET THE TXT FILE

    File? textFile = await getTxtFile(loading);

    // IF NOT POSSIBLE, TRY TO GET THE EXCEL FILE

    File? xlFile;

    if(textFile == null){
      print('txt file was not found');
      xlFile = await getXlFile(loading);
    }

    // IF NEITHER OF THE FILES ARE FOUND, RETURN

    if(textFile == null && xlFile == null){
      print('No sheet data file was found');
      setLoading(false);
      return null;
    }

    // DEPENDING ON THE FILE, LOAD THE INVENTORY ACCORDING

    if(textFile != null){
      levels = await loadTxtInventory(textFile!.readAsStringSync());
    }else if (xlFile != null){
      levels = await loadXlInventory(Excel.decodeBytes(xlFile!.readAsBytesSync()));
    }

    if(levels.isEmpty){
      print('Error loading the inventory');
      setLoading(false);
      return;
    }else{

      setState(() {
        loadedInventoryName = selectedInventoryName;
      });

      if(textFile != null){
        setLastUpdate(textFile.path);
      }else if(xlFile != null){
        setLastUpdate(xlFile.path);
      }

      setLoading(false);

      print('Inventory was loaded');
      return;
    }
  }

  Future<List<List>> getDuplicates(List<List> levelList, List<String> allPhotos) async {
    List<List> newLevelList = levelList;
    List<String> checkList = [];
    List duplicates = [];

    for(var photo in allPhotos){
      if(!checkList.contains(photo)){
        checkList.add(photo);
      }else{
        int counter = 1; 
        String duplicate = '${photo}_$counter';
        while(duplicates.contains(duplicate)){
          counter += 1;
          duplicate = duplicate = '${photo}_$counter';
        }
        duplicates.add(duplicate);
      }
    }

    for(List active in newLevelList[7]){
      List photos = active[1][10];

      //active[1][10].addAll(duplicates.where((duplicate) => photos.where((photo) => duplicate.startsWith(photo)).isNotEmpty));

      for(String duplicate in duplicates){
        String duplicateParent = duplicate.substring(0, duplicate.length - 2);
        if(photos.contains(duplicateParent)){
          active[1][10].add(duplicate);
        }
      }
    }

    return newLevelList;
  }

  Future deleteSelected() async {
    List packsWillBeRemoved = [];
    for(List filePackTuple in pendingFiles){
      List filesWillBeRemoved = [];
      List files = filePackTuple[0];
      //String filePackString = files[0].path.substring(0, files[0].path.length - 4).split('/').last; // importante notar o -4
      bool selection = filePackTuple[1];
      if(selection == true){
        for(File file in files){
          String fileName = file.path.split('/').last;
          File? deletedFile = await moveFile(fileName, pendingFolder, trashFolder, downloadDir);
          if(deletedFile != null){
            filesWillBeRemoved.add(file);
          }
        }
      }
      if(filesWillBeRemoved.length == files.length){
        packsWillBeRemoved.add(filePackTuple);
      }
    }
    for(List filePackTuple in packsWillBeRemoved){
      pendingFiles.remove(filePackTuple);
    }
   await getPendingWidgets();
  }

  Future uploadSelected() async {

  }

  Future getPendingFiles() async {
    List<File>? pendingPhotoFiles = await getDirectoryFiles(pendingFolder, downloadDir, 'jpg');
    if (pendingPhotoFiles == null) {
      return null;
    }

    pendingFiles.clear();

    List<File> currentFilePack = [];

    for (File file in pendingPhotoFiles) {
      String fileName = file.path.split('/').last.substring(0, file.path.split('/').last.length - 6); // importante notar o -6
      if (currentFilePack.isEmpty) {
        currentFilePack.add(file);
      } else {
        if (currentFilePack.first.path.contains(fileName)) {
          currentFilePack.add(file);
        } else {
          pendingFiles.add([List<File>.from(currentFilePack), false]);
          currentFilePack.clear();
          currentFilePack.add(file);
        }
      }
    }
    if (currentFilePack.isNotEmpty) {
      pendingFiles.add([List<File>.from(currentFilePack), false]);
    }

    await getPendingWidgets();
  }

  Future getPendingWidgets() async {///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    pendingWidgets.clear();

    for (List filePackTuple in pendingFiles) {
      List files = filePackTuple[0];
      String filePackString = files[0].path.substring(0, files[0].path.length - 4).split('/').last; // importante notar o -4
      List<Widget> carouselWidgets = [];
      for (File file in files) {
        carouselWidgets.add(
          GestureDetector(
            onTap: () { showInFullScreen(file.path, context); },
            child: Hero(
              tag: file.path,
              child: Image.file(file),
            ),
          )
        );
      }

      CarouselSlider filePackCarousel = CarouselSlider(
        items: carouselWidgets,
        options: CarouselOptions(
          height: getTotalHeight(context) / 4,
          viewportFraction: 1,
          enableInfiniteScroll: false,
          enlargeCenterPage: true,
        ),
      );

      Widget activityWidget = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CheckboxListTile(
            title: Text(filePackString, style: TextStyle(fontSize: getTotalWidth(context)/28.6, fontWeight: FontWeight.bold)),
            activeColor: Colors.greenAccent,
            checkColor: Colors.grey[900],
            value: filePackTuple[1],
            onChanged: (bool? value) async {
              setState(() {
                filePackTuple[1] = value;
              });
              await getPendingWidgets();
            },
          ),
          filePackCarousel,
        ],
      );
      pendingWidgets.add(activityWidget);
    }

    setState(() {});
  }

  setInventory(String? inventoryName) {
    if(inventoryName != null && inventoryList.contains(inventoryName)){
      selectedInventoryName = inventoryName;
      preferences.setString('selectedInventoryName', inventoryName);
      selectedInventory = inventories[inventoryName];
      getInventoryWidgets();
    }
  }

  Future setNetworkMode() async {
    if (widget.token != null) {
      if(selectedInventory != null){
        OneDriveIDs? ids = await getOneDriveIDs(widget.token, selectedInventory!['folder']!);
        if (ids != null) {
          downloadOneDriveIDs = ids;
          offlineMode = false;
        } else {
          showSnackbar(context, 'Atenção, TREE está em modo OFFLINE');
        }
      }else{
        offlineMode = false;
      }
      
    } else {
      showSnackbar(context, 'Atenção, TREE está em modo OFFLINE');
    }
  }

  Future getDownloadOneDriveIds() async {
    if(offlineMode == false && selectedInventoryName != null && selectedInventory != null){
      OneDriveIDs? ids = await getOneDriveIDs(widget.token, selectedInventory!['folder']!);
      if (ids != null) {
        downloadOneDriveIDs = ids;
      }else{
        setNetworkMode();
      }
    }
  }

  setLoading(bool set, [bool? drawer]){
    setState(() {
      loading = set;
    });

    if(drawer != null){
      setState(() {
        loading = drawer;
      });
    }
  }

  Future initialize() async {
    
    setLoading(true);

    downloadDir = await DownloadsPath.downloadsDirectory() ?? await getApplicationDocumentsDirectory();
    preferences = await SharedPreferences.getInstance();
    
    getInventoryWidgets();
    await setNetworkMode();
    //await setInventory(preferences.getString('selectedInventoryName'));
    //await loadInventory();

    setLoading(false);

    setState(() {
      initializing = false;
    });
  }
  
}