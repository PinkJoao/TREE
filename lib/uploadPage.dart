import 'dart:io';
import 'dart:convert' show json;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'lib.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UploadPage extends StatefulWidget {
  final String token;

  const UploadPage({
    Key? key,
    required this.token,
  }) : super(key: key);

  @override
  _UploadPageState createState() => _UploadPageState();
}

class _UploadPageState extends State<UploadPage> {
  String folder_name = 'testFolderTI';
  var folder_id = null;
  var drive_id = null;
  String apiEndpoint = "https://graph.microsoft.com/v1.0";

  late final prefs;
  bool uploading = false;
  
  late List<String> files_for_later;
  List<List> file_list = [];
  List<Widget> image_widgets = [];


  @override
  void initState() {
    super.initState();
    get_stored_files(true);
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

  void show_full_screen_image(String imagePath) {
    Navigator.push(
      context,
      new MaterialPageRoute(
        builder: (context) => FullScreenImage(imagePath: imagePath),
      ),
    );
  }

  Future<Map<String, String>> get_od_ids(String folder_name) async {
    print('');
    print('get_od_ids() was called');

    Map<String, String> ids = {};

    try{
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

            print(ids.toString());

            return ids;
          }
        }
        print('');
        print("Folder named [$folder_name] was NOT found");
      }
    } catch(e){
      print(e);
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
        show_snackbar( "Falha na conexão, não foi possível recuperar o diretório");
        return false;
      }
    }

    if (folder_id == null && drive_id == null) {
      show_snackbar("ERRO: Diretório não encontrado");
      return false;
    }
    return true;
  }

  Future get_file_from(String file_path) async {
    print('');
    String file_name = file_path.split('/')[6];
    print('get_file_from() was called for the file [$file_name]');

    try {
      File file = File(file_path);
      if (await file.exists()) {
        print('');
        print('File [$file_name] WAS found at $file_path');
        return file;
      } else {
        print('');
        print('File [$file_name] was NOT found at $file_path');
      }
    } catch (e) {
      print('');
      print('Error recovering the File [$file_name]: $e');
    }
  }

  Future get_stored_files(bool initialize) async {
    print('');
    print('get_stored_files() was called');
    file_list.clear();
    image_widgets.clear();

    if(initialize == true){
      prefs = await SharedPreferences.getInstance();
    }

    files_for_later = prefs.getStringList('files_for_later') ?? [];

    if(files_for_later.isEmpty){
      show_snackbar('Não restam arquivos para enviar');
      print('there are no stored files to recover');
      return null;
    }

    for(String file_path in files_for_later){
      File? file = await get_file_from(file_path);
      if(file != null){
        file_list.add([false,file]);
      }
    }

    await load_files_on_screen();
    
  }

  Future<void> delete_photos() async {
    print('');
    print('delete_photos() was called');

    List<List> new_file_list = [];

    for(List tuple in file_list){
      if(tuple[0] == false){
        new_file_list.add(tuple);
      }else if(files_for_later.isNotEmpty){
        files_for_later.remove(tuple[1].path);
        tuple[1].delete();
        String file_name = tuple[1].path.toString().split(')/')[1];
        print('the file [${file_name} was deleted from path');
      }
    }
    prefs.setStringList('files_for_later', files_for_later);


    file_list.clear();
    file_list.addAll(new_file_list);
    await load_files_on_screen();
    show_snackbar('Os arquivos selecionados foram excluídos');
  }

  Future load_files_on_screen() async {
    print('');
    print('load_files_on_screen() was called');

    image_widgets.clear();

    for(List tuple in file_list){
      File file = tuple[1];
      String file_name = file.path.toString().split(')/')[1];
      String tag = file_name.split('_')[0];
      String active = file.path.toString().split('(')[1].split(')')[0];
      String date = file_name.split('_')[2];
      date = date.substring(6,8) + '/' + date.substring(4,6) + '/' + date.substring(0,4);

      image_widgets.add(
        Container(
          height: 180,
          child: Padding(
            padding: EdgeInsets.fromLTRB(0, 0, 0, 16),
            child: Row(
              children: [
                Flexible(
                  child: Row(
                    children: [
                      Padding(
                        padding: EdgeInsets.fromLTRB(0, 8, 16, 0),
                        child: Align(
                          alignment: Alignment.topLeft,
                          child: Container(
                            height: 20,
                            width: 20,
                            child: GestureDetector(
                              onTap: (){
                                setState(() {
                                  tuple[0] = !tuple[0];
                                  
                                });
                                load_files_on_screen();
                              },
                              child: tuple[0] == false
                              ? Icon(Icons.check_box_outline_blank)
                              : Icon(Icons.check_box)
                            ),
                          )
                        ),
                      ),

                      GestureDetector(
                        onTap: () {show_full_screen_image(file.path);},
                        child: Hero(
                          tag: file.path,
                          child: Image.file(file),
                        ),
                      ),
                    ],
                  ),
                ),
                
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children:[
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                          child: Text(tag,
                            style: TextStyle( fontSize: 16, fontWeight: FontWeight.bold),
                          )
                        )
                      ),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                          child: Text(active,
                            style: TextStyle( fontSize: 16, fontWeight: FontWeight.bold),
                          )
                        )
                      ),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                          child: Text(date,
                            style: TextStyle( fontSize: 16, fontWeight: FontWeight.bold),
                          )
                        )
                      ),
                    ]
                  )
                )
              ],
            )
          )
        )
      );
    }

    setState(() {});
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

    return Scaffold(
      appBar: AppBar(
        leading: BackButton(color: Colors.grey[900]),
        title: Text('Enviar fotos guardadas')
      ),
      body: uploading == true
      ? Center(child: CircularProgressIndicator(color: orangeColor))

      : Stack(
        children: [
          SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(10, 16, 10, 16),
            child: Column(
              children: image_widgets
            )
          ),
          Padding(
            padding: EdgeInsets.symmetric(vertical:20  , horizontal:20),
            child: Align(
              alignment: Alignment.bottomRight,
              child: FloatingActionButton(
                heroTag: 'unique_hero_tag_for_upload_button',
                backgroundColor: Colors.greenAccent,
                onPressed: () async {
                  setState(() {
                    uploading = true;
                  });
                  await upload_photos();
                },
                child: Icon(Icons.upload, size: 35.0, color: Colors.grey[900])),
            )
          ),
          Padding(
            padding: EdgeInsets.symmetric(vertical:20  , horizontal:20),
            child: Align(
              alignment: Alignment.bottomLeft,
              child: FloatingActionButton(
                heroTag: 'unique_hero_tag_for_delete_button',
                backgroundColor: Colors.redAccent,
                onPressed: () async {
                  await delete_photos();
                },
                child: Icon(Icons.delete_forever, size: 35.0, color: Colors.grey[900])),
            )
          ),
        ]
      )
    );
  }

  Future<void> upload_photos() async {
    print('');
    print('upload_photos() was called');

    bool check = await check_od_ids();
    if (check == false) {
      setState(() {
        uploading = false;
      });
      return null;
    }

    Map<String, String> headers = {
      "Authorization": "Bearer ${widget.token}",
      "Content-Type": "image/jpg"
    };

    for(List tuple in file_list){
      if(tuple[0] == true){
        String file_name = tuple[1].path.toString().split(')/')[1];
        await upload_file(tuple[1], file_name, headers);
      }
    }

    prefs.setStringList('files_for_later', files_for_later);

    await get_stored_files(false);

    setState(() {
      uploading = false;
    });
  }

  Future<void> upload_file(File file, String file_name, Map<String, String> headers) async {
    print('');
    print('upload_file() was called');

    Uint8List fileBytes = File(file.path).readAsBytesSync();
    String url = "$apiEndpoint/drives/$drive_id/items/$folder_id:/$file_name:/content";

    try{
        http.Response response = await http.put(Uri.parse(url), headers: headers, body: fileBytes);

        if (response.statusCode == 201) {
          print("File $file_name uploaded successfully");
          files_for_later.remove(file.path);
          
        } else if (response.statusCode == 200) {
          show_snackbar('Foto $file_name já foi enviada antreriormente!');
          print("File $file_name already uploaded");
          files_for_later.remove(file.path);

        } else {
          show_snackbar('Falha no envio da foto $file_name, tente novamente');
          print("File $file_name upload failed");
          print('Status code:${response.statusCode}');
          print(response.body);
        }

      } catch(exception){
        show_snackbar('Falha no envio da foto $file_name, verifique a conexão');
        print("File $file_name upload failed");
        print('Exception:${exception}');
      }
  }
}
