import 'dart:io';
import 'dart:ui';
import 'dart:async';
import 'package:intl/intl.dart';
import 'package:excel/excel.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  List<List> table = [];
  List<List> levels = [];
  List<dynamic> allPhotos = [];

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
      : Container(
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
                                  decoration: BoxDecoration( color: Color(0xFFf07f34), ),
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
                                          onLongPress: () {
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

                                      SizedBox( height: 20, ),

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
                                SizedBox(),
                              ] + inventoryWidgets,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
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
      : Container(
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
                        decoration: BoxDecoration(
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
                              decoration: BoxDecoration(
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
                                icon: Icon(Icons.delete_forever_rounded)
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
                                icon: Icon(Icons.cloud_upload_rounded)
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
                                decoration: BoxDecoration( color: Color(0xFFf07f34), ),
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

                                    SizedBox( height: 20, ),

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
                              SizedBox(),
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
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                  child: Text(
                    'Última atualização: $lastUpdate',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  )
                )
              ),

              ElevatedButton(
                onPressed: selectedInventory != null && selectedInventoryName == loadedInventoryName
                ? () {
                  Navigator.push(
                    context,
                    new MaterialPageRoute(
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
                child: Text('Árvore de ativos')
              ),

              TextField(
                controller: searchController,
                onChanged: (value) {
                  setState(() {
                    searchTerm = value;
                  });
                },
                decoration: InputDecoration(
                  hintText: 'TAG',
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

              ElevatedButton(
                onPressed: selectedInventory != null && loadedInventoryName == selectedInventoryName
                  ? () {
                    searchTerm == ''
                      ? showSnackbar(context, 'Por favor digite um termo de busca')
                      : Navigator.push(
                          context,
                          new MaterialPageRoute(
                            builder: (context) => SearchPage(
                              oneDriveIDs: downloadOneDriveIDs,
                              folder: selectedInventory!['folder']!,
                              levels: levels,
                              searchTerm: searchTerm,
                            )
                          )
                        );
                  }
                  :null,
                child: Text('Buscar por TAG'),
              ),

              //ElevatedButton(onPressed: () {print(levels);}, child: Text('teste'))
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
            ? Color.fromARGB(123, 240, 127, 52)
            : Colors.transparent,
          ),
          child: TextButton(
            onPressed: () async {
              setInventory(inventory);
            },
            onLongPress: () async {
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

  Future<bool?> showDownloadDialog() async {
    bool? answer;
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Base indisponível, deseja realizar o Download?', 
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: getTotalWidth(context) / 20),
            ),
          actionsAlignment: MainAxisAlignment.spaceAround,
          alignment: Alignment.bottomCenter,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(20.0))),
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

  Future<File?> getFileInDirectory([bool? loading]) async {
    print('Getting file in directory');
    List<File> xlFiles = await getDirectoryFiles(sheetFolder, downloadDir, 'xlsx') ?? [];
    
    if(xlFiles.isEmpty){
      if(offlineMode == true || initializing == true){
        return null;
      }else{
        bool? dialog = await showDownloadDialog();

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
        bool? dialog = await showDownloadDialog();
        if(dialog == true){
          File? xlFile = await downloadXl(loading);
          return xlFile;
        }else{
          return null;
        }
      }
    }
  }

  setLastUpdate(String xlFilePath){
    String fileName = xlFilePath.split('/').last;
    String date = fileName.substring(0,8);
    String time = fileName.substring(9,15);

    setState(() {
      lastUpdate = '${date.substring(0,4)}/${date.substring(4,6)}/${date.substring(6,8)} - ${time.substring(0,2)}:${time.substring(2,4)}';
    });
  }

  Future deleteXl() async {
    if(selectedInventoryName != selectedInventory!['name']! || selectedInventory == null || offlineMode == true || downloadOneDriveIDs == null){
      showSnackbar(context, 'Falha ao excluir planilha');
      return;
    }

    List<File> files = await getDirectoryFiles(sheetFolder, downloadDir, 'xlsx') ?? [];
    if(files.isEmpty){
      showSnackbar(context, 'Falha ao excluir planilha');
      return;
    }

    String? fileName;

    for(File file in files){
      if(file.path.split('/').last.contains(selectedInventory!['file']!)){
        fileName = file.path.split('/').last;
      }
    }

    if(fileName == null){
      showSnackbar(context, 'Falha ao excluir planilha');
      return;
    }

    print(fileName);

    File? checkFile = await moveFile(fileName, sheetFolder, trashFolder, downloadDir);
    if(checkFile == null){
      showSnackbar(context, 'Falha ao excluir planilha');
      return;
    }

    setState(() {
      loadedInventoryName = null;
    });

    print(loadedInventoryName.toString());
    print(selectedInventoryName);

    showSnackbar(context, 'Planilha movida para a lixeira com sucesso');

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

    File? xlFile = await getFileInDirectory(loading);
    if(xlFile == null){
      print('No xlsx file was found in storage');
      setLoading(false);
      return;
    }

    var excel = Excel.decodeBytes(xlFile.readAsBytesSync());
    var rawTable = excel.tables[sheetName];

    table.clear();

    for (var row in rawTable!.rows) {
      List new_row = [];
      if (row.isNotEmpty) {
        for (int column = 0; column < rawTable.maxColumns; column++) {
          if (row[column] == null) {
            new_row.add(null);
          } else {
            new_row.add(row[column]!.value.toString());
          }
        }
        table.add(new_row);
      }
    }

    levels.clear();

    for (int i = 0; i < 8; i++) {
      switch (i) {
        case 0:
          List new_list = [null];
          levels.add(new_list);
          break;

        case 1:
          List new_level = [];
          for (List row in table) {
            if(row[1].toString().contains('1')){ // && new_level.where((element) => element[0].toString() == [null].toString() && element[1].toString() == row[5].toString()).isEmpty
              new_level.add([
                [null], // filter
                row[5].toString()
              ]);
            }
          }
          levels.add(new_level);
          break;

        case 2:
          List new_level = [];
          for (List row in table) {
            if(row[1].toString().contains('2')){ // && new_level.where((element) => element[0].toString() == [row[5]].toString() && element[1].toString() == row[6].toString()).isEmpty
              new_level.add([
                [row[5].toString()], // filter
                row[6].toString()
              ]);
            }
          }
          levels.add(new_level);
          break;

        case 3:
          List new_level = [];
          for (List row in table) {
            if(row[1].toString().contains('3')){ // && new_level.where((element) => element[0].toString() == [row[5], row[6]].toString() && element[1].toString() == row[7].toString()).isEmpty
              new_level.add([
                [row[5].toString(), row[6].toString()], // filters
                row[7].toString()
              ]);
            }
          }
          levels.add(new_level);
          break;

        case 4:
          List new_level = [];
          for (List row in table) {
            if(row[1].toString().contains('4')){ // && new_level.where((element) => element[0].toString() == [row[5], row[6], row[7]].toString() && element[1].toString() == row[8].toString()).isEmpty
              new_level.add([
                [row[5].toString(), row[6].toString(), row[7].toString()], // filters
                row[8].toString()
              ]);
            }
          }
          levels.add(new_level);
          break;

        case 5:
          List new_level = [];
          for (List row in table) {
            if(row[1].toString().contains('5')){ // && new_level.where((element) => element[0].toString() == [row[5], row[6], row[7], row[8]].toString() && element[1].toString() == row[9].toString()).isEmpty
              new_level.add([
                [row[5].toString(), row[6].toString(), row[7].toString(), row[8].toString()], // filters
                row[9].toString()
              ]);
            }
          }
          levels.add(new_level);
          break;

        case 6:
          List new_level = [];
          for (List row in table) {
            if (row[7] != row[8] && (row[1].toString().contains('4') || row[1].toString().contains('5') || row[1].toString().contains('6'))) { // && new_level.where((element) => element[0].toString() == [row[5], row[6], row[7], row[8], row[9]].toString() && element[1].toString() == [row[10],row[4]].toString()).isEmpty
              new_level.add([
                [row[5].toString(), row[6].toString(), row[7].toString(), row[8].toString(), row[9].toString()], // filters
                [row[10].toString(),row[4].toString()]
              ]);
            }
          }
          levels.add(new_level);
          break;

          case 7:
          List last_level = [];
          for (List row in table) {
            if(!(row[5] == row[6] && row[5] == row[7] && row[5] == row[8]) && (row[1].toString().contains('4') || row[1].toString().contains('5') || row[1].toString().contains('6'))){

              List photos = [row[17],row[18],row[19],row[20]];
              photos.removeWhere((element) => element == null);
              photos.removeWhere((element) => element == 'null');
              photos.removeWhere((element) => element == 'N/A');
              allPhotos.addAll(photos);

              last_level.add([
                [row[5].toString(), row[6].toString(), row[7].toString(), row[8].toString(), row[9].toString(), [row[10].toString(),row[4].toString()]], // filters
                [
                  row[10].toString(), // 00 description
                  row[2].toString(),  // 01 TAG LOCAL
                  row[3].toString(),  // 02 TAG ENGEMAN
                  row[4].toString(),  // 03 TAG PROPOSTA
                  row[11].toString(), // 04 CODTIPAPL
                  row[12].toString(), // 05 NUMSER
                  row[13].toString(), // 06 MODELO
                  row[14].toString(), // 07 CODFOR
                  row[15].toString(), // 08 NUMPAT
                  row[16].toString(), // 09 OBS
                  photos   // 10 photos
                ]
              ]);
            }
          }
          levels.add(last_level);
          break;
      }
    }

    await getDuplicates();

    //String text = '';

    for(List level in levels){
      level.sort((a, b) => a.toString().toLowerCase().compareTo(b.toString().toLowerCase()));
      /*for(List? active in level){
        print(active.toString() + '\n\n');
        text = text + active.toString().replaceAll('\n', ' ') + '\n';
      }

      print('\n\n');
      text = text + '\n\n';*/
    }

    //text = text.substring(0,text.length - 3);
    

    setState(() {
      loadedInventoryName = selectedInventoryName;
    });

    setLastUpdate(xlFile.path);

    //await storeText(selectedInventory!['file']!, text, sheetFolder, downloadDir);

    setLoading(false);

    print('Inventory was loaded');
    return;
  }

  Future<void> getDuplicates() async {
    List checkList = [];
    List duplicates = [];
    for(var photo in allPhotos){
      if(!checkList.contains(photo)){
        checkList.add(photo);
      }else{
        int counter = 1; 
        String duplicate = photo + '_' + counter.toString();
        while(duplicates.contains(duplicate)){
          counter += 1;
          duplicate = photo + '_' + counter.toString();
        }
        duplicates.add(duplicate);
      }
    }

    for(List active in levels[7]){
      List photos = active[1][10];
      for(String duplicate in duplicates){
        String duplicateParent = duplicate.substring(0, duplicate.length - 2);
        if(photos.contains(duplicateParent)){
          active[1][10].add(duplicate);
        }
      }
    }
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
    await setInventory(preferences.getString('selectedInventoryName'));
    await loadInventory();

    setLoading(false);

    setState(() {
      initializing = false;
    });
  }
  
}