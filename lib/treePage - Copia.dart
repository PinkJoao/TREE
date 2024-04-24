import 'dart:io';
import 'dart:convert' show json; //utf8;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'infoPage.dart';
import 'package:path_provider/path_provider.dart';
import 'package:lecle_downloads_path_provider/lecle_downloads_path_provider.dart';
/*
class TreePage extends StatefulWidget {
  final String token;
  final String folder_name;
  final List level_list;
  final father;
  final int current_level;
  final folderId;
  final driveId;

  const TreePage({
    Key? key,
    required this.token,
    required this.folder_name,
    required this.level_list,
    required this.father,
    required this.current_level,
    required this.folderId,
    required this.driveId,
  }) : super(key: key);

  @override
  _TreePageState createState() => _TreePageState();
}

class _TreePageState extends State<TreePage> {
  List<Widget> displayed_elements = [];
  final TextEditingController search_active_controller = TextEditingController();
  var drive_id = null;
  var folder_id = null;
  List photos_to_download = [];
  bool download_done = false;
  bool downloading = false;
  String img_extension = '.jpg';
  List father_filters = [];
  List already_downloaded = [];

  //late Directory appDocDir;
  late Directory downloadDir;
  //late Directory dcimDir;
  late Directory documentsDir;

  @override
  void initState() {
    super.initState();
    if (widget.father != null) {
      if (widget.father[0][0] != null) {
        for (var filter in widget.father[0]) {
          father_filters.add(filter);
        }
      }
      father_filters.add(widget.father[1]);
    }
    check_download();
    get_level_buttons();
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
        if (shared_item['name'] == folder_name) {
          var remote_item = shared_item['remoteItem'];
          var parent_reference = remote_item['parentReference'];
          drive_id = parent_reference['driveId'];
          folder_id = remote_item['id'];

          ids['drive_id'] = drive_id;
          ids['folder_id'] = folder_id;

          return ids;
        }
      }
      print('');
      print("Folder named [$folder_name] was NOT found");
    }
    return ids;
  }

  Future<String> create_folder(String folder_name) async {
    //final Directory folder = Directory('${appDocDir.path}/$folder_name/');
    final Directory folder = Directory('${downloadDir.path}/$folder_name/');

    if (await folder.exists()) {
      return folder.path;
    } else {
      final Directory new_folder = await folder.create(recursive: true);
      return new_folder.path;
    }
  }

  Future<void> store_file(List<int> bytes, String file_name, String file_extension) async {
    if (bytes.isNotEmpty) {
      await create_folder(widget.folder_name);
      //String filePath = '${appDocDir.path}/${widget.folder_name}/$file_name$file_extension';
      String filePath = '${downloadDir.path}/${widget.folder_name}/$file_name$file_extension';
      File file = File(filePath);
      try {
        await file.writeAsBytes(bytes);
      } catch (e) {
        print('');
        print('Error storing file [$file_name$file_extension]: $e');
        return null;
      }
      already_downloaded.add(file_name);
    } else {
      print('');
      print('Error: There are no bytes to store');
      return null;
    }
  }

  Future<bool> check_od_ids() async {
    print('');
    print('check_od_ids() was called');

    if(widget.driveId != null && widget.folderId != null){
      drive_id = widget.driveId;
      folder_id = widget.folderId;
    }

    if (folder_id == null && drive_id == null) {
      try {
        await get_od_ids(widget.folder_name);
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

  Future<bool> check_already_downloaded(var img_name) async {

    if (img_name != null) {
      String file_name = img_name.toString() + img_extension;
      try {
        //String filePath = '${appDocDir.path}/${widget.folder_name}/$file_name';
        String filePath = '${downloadDir.path}/${widget.folder_name}/$file_name';
        File file = File(filePath);
        if (await file.exists()) {
          return true;
        } else {
          return false;
        }
      } catch (e) {
        print('');
        print('Error recovering the image [$file_name]: $e');
        return false;
      }
    }else{
      return false;
    }
  }

  Future<void> aquire_level_photos() async {
    if(widget.current_level < 2){
      for(List active in widget.level_list[7]){
        List active_photo_names = active[1][5];
        for(var photo_name in active_photo_names){
          if(photo_name != null){
              bool already_downloaded = await check_already_downloaded(photo_name);
            if(already_downloaded == false){
              photos_to_download.add(photo_name);
            }
          }
        }
      }
    }else{
      String father_filters_string = father_filters.toString().replaceAll(']', '');

      for(List active in widget.level_list[7]){
        List active_filters = active[0];
        if(active_filters.toString().startsWith(father_filters_string)){
          List active_photo_names = active[1][5];
          for(var photo_name in active_photo_names){
            if(photo_name != null){
                bool already_downloaded = await check_already_downloaded(photo_name);
              if(already_downloaded == false){
                photos_to_download.add(photo_name);
              }
            }
          }
        }
      }
    }
  }


  Future<void> download_photos() async {
    print('');
    print('download_photos() was called');
    setState(() {
      downloading = true;
    });

    if(photos_to_download.isNotEmpty){

      bool check = await check_od_ids();
      if (check == false) {
        return null;
      }

      for (var photo_name in photos_to_download) {
        if(photo_name != null){
          String photo_file_name = photo_name + img_extension;
          try {
            http.Response get_img_response = await http.get(
              Uri.parse("https://graph.microsoft.com/v1.0/drives/${drive_id.toString()}/items/${folder_id.toString()}:/$photo_file_name:/content"),
              headers: {"Authorization": "Bearer ${widget.token}"},
            );

            if (get_img_response.statusCode == 200) {
              await store_file(get_img_response.bodyBytes, photo_name, img_extension);
            } else {
              print('');
              print("Failed to download the image [$photo_file_name] Status code: ${get_img_response.statusCode}");
            }
          } on Exception catch (e) {
            print('');
            print(e);
          }
        }
      }
      photos_to_download.removeWhere((element) => already_downloaded.contains(element));
      if(photos_to_download.isEmpty){
        setState(() {
          download_done = true;
          downloading = false;
          show_snackbar('Download concluído');
        });
      }
      setState(() {
        downloading = false;
      });
    }
  }

  Future<void> get_level_buttons() async { 
    
    setState(() {
    List already_added = [];
    
    for (var item in widget.level_list[widget.current_level]){
      List item_filters = item[0];
      var item_name = item[1];

      if(widget.father == null || item_filters.toString() == father_filters.toString()){

        if(!already_added.contains(item_name)){
          already_added.add(item_name);

          displayed_elements.add(
            Padding(padding: EdgeInsets.symmetric(vertical: 5),
            child:
              ElevatedButton(
                onPressed: () {
                  widget.current_level < 6
                      ? Navigator.push(
                          context,
                          new MaterialPageRoute(
                            builder: (context) => TreePage(
                              token: widget.token!,
                              folder_name: widget.folder_name,
                              level_list: widget.level_list,
                              father: item,
                              current_level: widget.current_level + 1,
                              folderId: widget.folderId,
                              driveId: widget.driveId,
                              )))
                                
                      : Navigator.push(
                          context,
                          new MaterialPageRoute(
                            builder: (context) => InfoPage(
                              token: widget.token!,
                              level_list: widget.level_list,
                              father: item,
                              folder_name: widget.folder_name,
                              driveId: widget.driveId,
                              folderId: widget.folderId,
                              )));
                },
                child: Text('\n' + item_name.toString() + '\n'),
              )
            )
          );
        }
      }
      
    }
    });}

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

    return Scaffold(
      appBar: AppBar(
        leading: BackButton(color: Colors.grey[900]),
        actions: <Widget>[
          if(widget.current_level != 1)
            IconButton(
              icon: downloading == true
                ? Container(
                        width: 24,
                        height: 24,
                        padding: const EdgeInsets.all(2.0),
                        child: const CircularProgressIndicator(
                          color: Colors.black,
                          strokeWidth: 3,
                        ),
                      )
                : download_done == true
                    ? Icon(Icons.cloud_done, color: Colors.grey[900])
                    : Icon(Icons.cloud_download ,color: Colors.grey[900]),
              tooltip: 'Baixar fotos deste nível',
              onPressed: download_done == true || downloading == true
                ? null
                : () async { await download_photos();},
            ),
        ],
        title: Text(widget.father != null
          ? widget.father.last.toString()
          : 'Símic | Tree')
        ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: displayed_elements,
          ),
        )
      ),
    );
  }

  Future<void> check_download() async{
    //appDocDir = await getApplicationDocumentsDirectory();
    downloadDir = await DownloadsPath.downloadsDirectory()?? await getApplicationDocumentsDirectory();

    await aquire_level_photos();
    if(photos_to_download.isEmpty){
      download_done = true;
      setState(() {});
    }
  }
}
*/