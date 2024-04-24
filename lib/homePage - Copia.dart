import 'dart:io';
import 'dart:convert' show json; //utf8;
import 'package:excel/excel.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'lib.dart';
import 'treePage.dart';
import 'searchPage.dart';
import 'uploadPage.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lecle_downloads_path_provider/lecle_downloads_path_provider.dart';
import 'package:lecle_downloads_path_provider/constants/downloads_directory_type.dart';
/*
class HomePage extends StatefulWidget {
  final token;

  const HomePage({Key? key, required this.token}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List rows = [];
  List levels = [];
  String search_active = "";
  final TextEditingController search_active_controller = TextEditingController();

  String folder_name = '';
  String file_name   = '';
  String sheet_name  = 'BASE CONSOLIDADA';
  
  var drive_id = null;
  var folder_id = null;
  List<int> sheet_bytes = [];

  String last_update = '';

  late Directory appDocDir;
  //late Directory downloadDir;
  //late Directory dcimDir;
  //late Directory documentsDir;

  bool loading_sheet = false;
  bool sheet_loaded = false;

  String selected_inventory = 'Selecionar Inventário';
  String new_inventory = 'Selecionar Inventário';

  List all_photos_lib = [];

  
  @override
  void initState() {
    super.initState();
    loading_sheet = true;
    SharedPreferences.getInstance().then((prefs) {
      setState(() {
        last_update = prefs.getString('last_update') ?? '';
        new_inventory = prefs.getString('selected_inventory') ?? 'Selecionar Inventário';
        set_folder_name(new_inventory);
        if (selected_inventory != 'Selecionar Inventário') {
          load_sheet();
          check_od_ids();
        }else{
          loading_sheet = false;
        }
      });
    });
    
  }


  void show_snackbar(String message) {
    final snackBar = SnackBar(
      content: Container(
        padding: EdgeInsets.all(12),
        height: 40,
        decoration: BoxDecoration(
          color: Colors.grey[700],
          borderRadius: BorderRadius.all(Radius.circular(10)),
        ),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white,
          ),
        ),
      ),
      behavior: SnackBarBehavior.floating,
      duration: Duration(seconds: 5),
      backgroundColor: Colors.transparent,
      elevation: 0,
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  Future<Map<String, String>> get_od_ids(String folder_name) async {
    print('');
    print('get_od_ids() was called');

    Map<String, String> ids = {};

    http.Response shared_withM_me_response = await http.get(
      Uri.parse("https://graph.microsoft.com/v1.0/me/drive/sharedWithMe"),
      headers: {"Authorization": "Bearer ${widget.token}"},
    );

    if (shared_withM_me_response.statusCode == 200) {
      var shared_items_data = json.decode(shared_withM_me_response.body);
      var shared_items = shared_items_data['value'];

      for (var shared_item in shared_items) {
        if (shared_item['name'] == folder_name && shared_item['webUrl'] != "https://simiccombr.sharepoint.com/sites/GestoPCM-Ultracargo/Documentos%20Compartilhados/FASE%201.0%20-%20Invent%C3%A1rio%20de%20Ativos/Suape%20-%20PE/01.Em%20desenvolvimento/L%C3%ADvio%20Silas/01%20-%20Fotos/Z-FOTOS%20CONSOLIDADAS%20(SUAPE)") {
          var remote_item = shared_item['remoteItem'];
          var parent_reference = remote_item['parentReference'];
          drive_id = parent_reference['driveId'];
          folder_id = remote_item['id'];

          ids['drive_id'] = drive_id;
          ids['folder_id'] = folder_id;
          if(drive_id == null || folder_id == null){
            print('Folder ids were NOT found');
          }
          return ids;
        }
      }
      print('');
      print("Folder named [$folder_name] was NOT found");
    }else{
      print('Failed to request driver ids. Status code: ${shared_withM_me_response.statusCode}');
    }
    return ids;
  }

  Future<bool> check_od_ids() async {
    print('');
    print('check_od_ids() was called');

    if (folder_id == null && drive_id == null) {
      try {
        await get_od_ids(folder_name);
      } on Exception catch (e) {
        print('');
        print(e);
        print('');
        show_snackbar("Falha na conexão, não foi possível recuperar o diretório");
        return false;
      }
    }

    if (folder_id == null && drive_id == null) {
      show_snackbar("ERRO: Diretório não encontrado");
      return false;
    }
    return true;
  }

  Future<void> download_xlsx() async {
    print('');
    print('download_xlsx() was called');

    bool check = await check_od_ids();
    if (check == false) {
      return null;
    }

    try {
      http.Response get_file_response = await http.get(
        Uri.parse("https://graph.microsoft.com/v1.0/drives/${drive_id.toString()}/items/${folder_id.toString()}:/$file_name:/content"),
        headers: {"Authorization": "Bearer ${widget.token}"},
      );

      if (get_file_response.statusCode == 200) {
        sheet_bytes = get_file_response.bodyBytes;
        last_update = DateString(DateTime.now()).toString();
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('last_update', last_update);
        setState(() {});
        show_snackbar('Atualização concluída com sucesso');

      }
      else {
        print('');
        print("Failed to download the file. Status code: ${get_file_response.statusCode}");
        show_snackbar('Falha no download. Status code: ${get_file_response.statusCode}');
        return null;
      }
    } on Exception catch (e) {
      print('');
      print(e);
      show_snackbar('Falha no download, verifique a conexão');
      return null;
    }
  }

  Future<List<int>> recover_sheet_bytes() async {
    print('');
    print('recover_sheet_bytes() was called');
    try {
      String filePath = '${appDocDir.path}/${folder_name}/$file_name';
      //String filePath = '${documentsDir.path}/${folder_name}/$file_name';
      //String filePath = '${downloadDir.path}/${folder_name}/$file_name';
      File file = File(filePath);
      if (await file.exists()) {
        List<int> bytes = await file.readAsBytes();
        print('File recovered successfully from: $filePath');
        return bytes;
      } else {
        print('Error: File not found at $filePath');
        return [];
      }
    } catch (e) {
      print('Error recovering file: $e');
      return [];
    }
  }

  Future<String> create_folder(String folder_name) async {
    final Directory folder = Directory('${appDocDir.path}/$folder_name/');
    //final Directory folder = Directory('${documentsDir.path}/$folder_name/');
    //final Directory folder = Directory('${downloadDir.path}/$folder_name/');

    if (await folder.exists()) {
      return folder.path;
    } else {
      final Directory new_folder = await folder.create(recursive: true);
      return new_folder.path;
    }
  }

  Future<void> store_file(List<int> bytes, String file_name) async {
    print('store_file() was called');
    if (bytes.isNotEmpty) {
      try {
        await create_folder(folder_name);
        String filePath = '${appDocDir.path}/${folder_name}/$file_name';
        //String filePath = '${documentsDir.path}/${folder_name}/$file_name';
        //String filePath = '${downloadDir.path}/${folder_name}/$file_name';
        File file = File(filePath);
        await file.writeAsBytes(bytes, mode: FileMode.write, flush: true);
        print('File was stored successfully');
      } catch (e) {
        print('Error storing file: $e');
      }
    } else {
      print('Error: There are no bytes to store');
    }
  }

  Future<bool> check_and_get_sheet_bytes() async {
    print('');
    print('check_and_get_sheet_bytes() was called');

    sheet_bytes = await recover_sheet_bytes();
    if (sheet_bytes.isEmpty) {
      await download_xlsx();
      if (sheet_bytes.isNotEmpty) {
        await store_file(sheet_bytes, file_name);
      } else {
        return false;
      }
    }
    
    return true;
  }

  Future<void> load_sheet() async {
    print('');
    print('load_sheet() was called');

    appDocDir = await getApplicationDocumentsDirectory();
    //var dirType = DownloadDirectoryTypes.documents;
    //documentsDir = await DownloadsPath.downloadsDirectory(dirType: dirType) ?? await getApplicationDocumentsDirectory();
    //downloadDir = await DownloadsPath.downloadsDirectory()?? await getApplicationDocumentsDirectory();

    await check_and_get_sheet_bytes();
    if (sheet_bytes.isEmpty){
      print('failed to load sheet');
      show_snackbar('falha no carregamento da planilha');
      setState(() {
        loading_sheet = false;
      });
      return null;
    }

    var excel = Excel.decodeBytes(sheet_bytes);
    var table = excel.tables[sheet_name];
    rows.clear();
    levels.clear();
    for (var row in table!.rows) {
      List new_row = [];
      if (row.isNotEmpty) {
        for (int column = 0; column < table.maxColumns; column++) {
          if (row[column] == null) {
            new_row.add(null);
          } else {
            new_row.add(row[column]!.value.toString());
          }
        }
        rows.add(new_row);
      }
    }

    for (int i = 0; i < 8; i++) {
      switch (i) {
        case 0:
          List new_list = [null];
          levels.add(new_list);
          break;

        case 1:
          List new_level = [];
          for (List row in rows) {
            if(row[17] != null && row[17] != 'FOTO 1'){
              new_level.add([
                [null], // filter
                row[i + 4]
              ]);
            }
          }
          levels.add(new_level);
          break;

        case 2:
          List new_level = [];
          for (List row in rows) {
            if(row[17] != null && row[17] != 'FOTO 1'){
              new_level.add([
                [row[5]], // filter
                row[i + 4]
              ]);
            }
          }
          levels.add(new_level);
          break;

        case 3:
          List new_level = [];
          for (List row in rows) {
            if(row[17] != null && row[17] != 'FOTO 1'){
              new_level.add([
                [row[5], row[6]], // filters
                row[i + 4]
              ]);
            }
          }
          levels.add(new_level);
          break;

        case 4:
          List new_level = [];
          for (List row in rows) {
            if(row[17] != null && row[17] != 'FOTO 1'){
              new_level.add([
                [row[5], row[6], row[7]], // filters
                row[i + 4]
              ]);
            }
          }
          levels.add(new_level);
          break;

        case 5:
          List new_level = [];
          for (List row in rows) {
            if(row[17] != null && row[17] != 'FOTO 1'){
              new_level.add([
                [row[5], row[6], row[7], row[8]], // filters
                row[i + 4]
              ]);
            }
          }
          levels.add(new_level);
          break;

        case 6:
          List new_level = [];
          for (List row in rows) {
            if (row[17] != null && row[17] != 'FOTO 1') {
              new_level.add([
                [row[5], row[6], row[7], row[8], row[9]], // filters
                row[i + 4]
              ]);
            }
          }
          levels.add(new_level);
          break;

          case 7:
          List last_level = [];
          for (List row in rows) {
            if(row[17] != null && row[17] != 'FOTO 1'){

              List photos = [row[17],row[18],row[19],row[20]];
              photos.removeWhere((element) => element == null);
              all_photos_lib.addAll(photos);

              last_level.add([
                [row[5], row[6], row[7], row[8], row[9], row[10]], // filters
                [
                  row[10], // 00 description
                  row[2],  // 01 local tag
                  row[3],  // 02 eng tag
                  row[4],  // 03 alt tag
                  row[16], // 04 obs
                  photos   // 05 photos
                ]
              ]);
            }
          }
          levels.add(last_level);
          break;
      }
    }

    await get_duplicates();

    print('');
    print('sheet was loaded');
    setState(() {
      loading_sheet = false;
      sheet_loaded = true;
    });
  }

  Future<void> get_duplicates() async {
    List check_list = [];
    List duplicates = [];
    for(var photo in all_photos_lib){
      if(!check_list.contains(photo)){
        check_list.add(photo);
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
      List active_photos = active[1][5];
      for(String duplicate in duplicates){
        String duplicate_parent = duplicate.substring(0, duplicate.length - 2);
        if(active_photos.contains(duplicate_parent)){
          active[1][5].add(duplicate);
        }
      }
    }
  }

  void set_folder_name(inventory) {
    switch (inventory) {
      case 'Aratu - BA':
        setState(() {
          selected_inventory = 'Aratu - BA';
          folder_name = 'Z-FOTOS CONSOLIDADAS (ARATU)';
          file_name = 'LISTA DE ATIVOS ARATU CONSOLIDADO.xlsx';
        });
        break;
      case 'Itaqui - MA':
        setState(() {
          selected_inventory = 'Itaqui - MA';
          folder_name = 'Z-FOTOS CONSOLIDADAS (ITAQUI)';
          file_name = 'LISTA DE ATIVOS ITAQUI CONSOLIDADO.xlsx';
        });
        break;
      case 'Rio de Janeiro - RJ':
        setState(() {
          selected_inventory = 'Rio de Janeiro - RJ';
          folder_name = 'Z-FOTOS CONSOLIDADAS (RIO DE JANEIRO)';
          file_name = 'LISTA DE ATIVOS RIO DE JANEIRO CONSOLIDADO.xlsx';
        });
        break;
      case 'Rondonópolis - MT':
        setState(() {
          selected_inventory = 'Rondonópolis - MT';
          folder_name = 'Z-FOTOS CONSOLIDADAS (RONDONÓPOLIS)';
          file_name = 'LISTA DE ATIVOS RONDONÓPOLIS CONSOLIDADO.xlsx';
        });
        break;
      case 'Santos - SP':
        setState(() {
          selected_inventory = 'Santos - SP';
          folder_name = 'Z-FOTOS CONSOLIDADAS (SANTOS)';
          file_name = 'LISTA DE ATIVOS SANTOS CONSOLIDADO.xlsx';
        });
        break;
      case 'Suape - PE':
        setState(() {
          selected_inventory = 'Suape - PE';
          folder_name = 'Z-FOTOS CONSOLIDADAS (SUAPE)';
          file_name = 'LISTA DE ATIVOS SUAPE CONSOLIDADO.xlsx';
        });
        break;
      case 'Vida do Conde - PA':
        setState(() {
          selected_inventory = 'Vida do Conde - PA';
          folder_name = 'Z-FOTOS CONSOLIDADAS (VILA DO CONDE)';
          file_name = 'LISTA DE ATIVOS VILA DO CONDE CONSOLIDADO.xlsx';
        });
        break;
    }
  }

  Future<void> on_drawer_closed(String new_inventory) async {
    if (new_inventory != selected_inventory) {
      setState(() {
        loading_sheet = true;
      });
      set_folder_name(new_inventory);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('selected_inventory', selected_inventory);
      await get_od_ids(folder_name);
      
      await load_sheet();
    }
  }
  
  void go_to_tree_page(){
    /*Navigator.push(
      context,
      new MaterialPageRoute(
        builder: (context) => TreePage(
          token: widget.token!,
          folder_name: folder_name,
          level_list: levels!,
          father: null,
          current_level: 1!,
          folderId: folder_id,
          driveId: drive_id,
        )
      )
    );*/
  }

  @override
  Widget build(BuildContext context) {
    final orangeColor = MaterialColor(
      0xFFf07f34,
      <int, Color>{
        50: Colors.orange[50]!,
        100: Colors.orange[100]!,
        200: Colors.orange[200]!,
        300: Colors.orange[300]!,
        400: Colors.orange[400]!,
        500: Colors.orange[500]!,
        600: Colors.orange[600]!,
        700: Colors.orange[700]!,
        800: Colors.orange[800]!,
        900: Colors.orange[900]!,
      },
    );

    double total_height = MediaQuery.of(context).size.height;

    return WillPopScope(
      onWillPop: () async{
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text('Símic | Tree'),
          iconTheme: IconThemeData(color: Colors.grey[900]),
        ),
        drawer: Drawer(
          
          child: ListView(
            padding: EdgeInsets.zero,
            children: [

              DrawerHeader(
                decoration: BoxDecoration(
                  color: Color(0xFFf07f34),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    //Image.asset('assets/images/simic_logo.png',),
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.grey[900], // Adjust the color as needed
                      ),
                      child: Image.asset('assets/images/simic_logo.png',),
                    ),

                    SizedBox(height: 20,),

                    Text(
                      new_inventory,
                      style: TextStyle(
                          color: Colors.grey[900],
                          fontSize: 25,
                          fontWeight: FontWeight.bold),
                    ),
                  ],
                )
                
                ),
              ListTile(
                title: const Text('Aratu - BA'),
                onTap: () {
                  setState(() {
                    new_inventory = 'Aratu - BA';
                  });
                },
              ),
              ListTile(
                title: const Text('Itaqui - MA'),
                onTap: () {
                  setState(() {
                    new_inventory = 'Itaqui - MA';
                  });
                },
              ),
              ListTile(
                title: const Text('Rio de Janeiro - RJ'),
                onTap: () {
                  setState(() {
                    new_inventory = 'Rio de Janeiro - RJ';
                  });
                },
              ),
              ListTile(
                title: const Text('Rondonópolis - MT'),
                onTap: () {
                  setState(() {
                    new_inventory = 'Rondonópolis - MT';
                  });
                },
              ),
              ListTile(
                title: const Text('Santos - SP'),
                onTap: () {
                  setState(() {
                    new_inventory = 'Santos - SP';
                  });
                },
              ),
              ListTile(
                title: const Text('Suape - PE'),
                onTap: () {
                  setState(() {
                    new_inventory = 'Suape - PE';
                  });
                },
              ),
              ListTile(
                title: const Text('Vida do Conde - PA'),
                onTap: () {
                  setState(() {
                    new_inventory = 'Vida do Conde - PA';
                  });
                },
              ),
            ]
          )
        ),
        onDrawerChanged: (bool isDrawerOpen) {
          if (!isDrawerOpen) {
            on_drawer_closed(new_inventory);
          }
        },
        
        
        body: loading_sheet == true
        ? Center(child: CircularProgressIndicator(color: orangeColor)) 
        : RefreshIndicator(
          onRefresh: () async {
            setState(() {
              loading_sheet = true;
            });
            await get_od_ids(folder_name);
            await download_xlsx();
            await load_sheet();
            await store_file(sheet_bytes, file_name);
          },
          child: Stack(
            children: [
              SingleChildScrollView(
                physics: BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                child: Column(
                  mainAxisSize: MainAxisSize.max,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                        child: Text(
                          'Última atualização: ' + last_update.toString(),
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        )
                      )
                    ),

                    ElevatedButton(
                      onPressed: sheet_loaded == true 
                        ? () {
                          /*Navigator.push(
                            context,
                            new MaterialPageRoute(
                              builder: (context) => TreePage(
                                token: widget.token!,
                                folder_name: folder_name,
                                level_list: levels!,
                                father: null,
                                current_level: 1!,
                                folderId: folder_id,
                                driveId: drive_id,
                              )
                            )
                          );*/
                        }
                        : null,
                      child: Text('Árvore de níveis'),
                    ),

                    TextField(
                      controller: search_active_controller,
                      onChanged: (value) {
                        setState(() {
                          search_active = value;
                        });
                      },
                      decoration: InputDecoration(
                        hintText: 'Buscar ativo por TAG',
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
                      onPressed: sheet_loaded == true 
                        ? () {
                          search_active == ''
                            ? show_snackbar('Por favor digite um termo de busca')
                            : Navigator.push(
                                context,
                                new MaterialPageRoute(
                                  builder: (context) => SearchPage(
                                    oneDriveIDs: widget.token!,
                                    folder: folder_name,
                                    levels: levels,
                                    searchTerm: search_active,
                                  )
                                )
                              );
                        }
                        :null,
                      child: Text('Buscar'),
                    ),
                    SizedBox(height: 150),
                  ]
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(vertical:20  , horizontal:20),
                child: Align(
                  alignment: Alignment.bottomRight,
                  child: FloatingActionButton(
                    backgroundColor: orangeColor,
                    onPressed: (){
                      Navigator.push(
                        context,
                        new MaterialPageRoute(
                          builder: (context) => UploadPage(
                            token: widget.token!,
                          ) 
                        )
                      );
                    },
                    child: Icon(Icons.upload, size: 35.0, color: Colors.grey[900])),
                )
              ),
            ],
          )
        )
      )
    );
  }
}
*/