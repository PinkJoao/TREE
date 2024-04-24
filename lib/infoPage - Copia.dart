import 'dart:io';
import 'dart:convert' show json;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'lib.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lecle_downloads_path_provider/lecle_downloads_path_provider.dart';
import 'package:lecle_downloads_path_provider/constants/downloads_directory_type.dart';
/*
class InfoPage extends StatefulWidget {
  final String token;
  final List level_list;
  final father;
  final String folder_name;
  final folderId;
  final driveId;

  const InfoPage({
    Key? key,
    required this.token,
    required this.level_list,
    required this.father,
    required this.folder_name,
    required this.folderId,
    required this.driveId,
  }) : super(key: key);

  @override
  _InfoPageState createState() => _InfoPageState();
}

class _InfoPageState extends State<InfoPage> {
  late ImagePicker imagePicker;

  var drive_id = null;
  var folder_id = null;

  //late Directory appDocDir;
  late Directory downloadDir;
  late Directory dcimDir;

  List   info_list           = [];
  String description         = 'DESCRIÇÃO: ';
  String local_tag           = 'TAG LOCAL: ';
  String eng_tag             = 'TAG ENGEMAN: ';
  String alternative_tag     = 'TAG PROPOSTA: ';
  String observation         = 'OBSERVAÇÃO: ';
  String tree                = '';

  List         image_names   = [];
  List         images        = [];
  List<Widget> image_widgets = [];

  bool loading = true;

  @override
  void initState() {
    super.initState();
    imagePicker = ImagePicker();
    get_active_info();
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

  List search_active(){
    List father_filters = [];
    for(var filter in widget.father[0]){
      father_filters.add(filter);
    }
    father_filters.add(widget.father[1]);

    for(var item in widget.level_list[7]){
      if(item[0].toString() == father_filters.toString()){
        return item;
      }
    }
    return [null];
  }

  Future<void> get_active_info() async {
    //appDocDir = await getApplicationDocumentsDirectory();
    downloadDir = await DownloadsPath.downloadsDirectory()?? await getApplicationDocumentsDirectory();
    dcimDir = await DownloadsPath.downloadsDirectory(dirType: DownloadDirectoryTypes.dcim)?? await getApplicationDocumentsDirectory();

    List active = search_active();
    if(active[0] != null){
      info_list       = active[1];
      description     = description     + info_list[0].toString();
      local_tag       = local_tag       + info_list[1].toString();
      eng_tag         = eng_tag         + info_list[2].toString();
      alternative_tag = alternative_tag + info_list[3].toString();
      observation     = observation     + info_list[4].toString();
      image_names     =                   info_list[5];
      
      tree = active[0].toSet().toString().replaceAll(',', ' //');
      tree = tree.substring(1, tree.length-1);

      if(description == 'DESCRIÇÃO: ' || description == 'DESCRIÇÃO: N/A' || description == 'DESCRIÇÃO: null'){                      description     = 'DESCRIÇÃO:     INDISPONÍVEL';}
      if(local_tag == 'TAG LOCAL: ' || local_tag == 'TAG LOCAL: N/A' || local_tag == 'TAG LOCAL: null'){                            local_tag       = 'TAG LOCAL:     INDISPONÍVEL';}
      if(eng_tag == 'TAG ENGEMAN: ' || eng_tag == 'TAG ENGEMAN: N/A' || eng_tag == 'TAG ENGEMAN: null'){                            eng_tag         = 'TAG ENGEMAN:   INDISPONÍVEL';}
      if(alternative_tag == 'TAG PROPOSTA: ' || alternative_tag == 'TAG PROPOSTA: N/A' || alternative_tag == 'TAG PROPOSTA: null'){ alternative_tag = 'TAG PROPOSTA:  INDISPONÍVEL';}
      if(observation == 'OBSERVAÇÃO: ' || observation == 'OBSERVAÇÃO: N/A' || observation == 'OBSERVAÇÃO: null'){                   observation     = 'OBSERVAÇÃO:    INDISPONÍVEL';}

      for(String image_name in image_names){
        var image_file =  await get_image_file(image_name);
        if(image_file != null){
          images.add([image_name, image_file]);
        }
      }

      for(List image in images){
        image_widgets.add(
          GestureDetector(
            onTap: () {
              show_full_screen_image(image[1].path);
            },
            child: Hero(
              tag: image[0],
              child:
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(image[0],
                  style: TextStyle(fontWeight: FontWeight.bold),
                  ),

                  Flexible(child: Image.file(image[1]),),
                ],
              )
            ),
          ),
        );
      }
    }
    setState(() {
      loading = false;
    });
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

    if (widget.driveId != null && widget.folderId != null) {
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

  Future get_image_file(var img_name) async {
    print('');
    String file_name = img_name.toString() + '.jpg';
    print('get_image_file() was called for the image [$file_name]');

    if (img_name != null) {
      try {
        //String filePath = '${appDocDir.path}/${widget.folder_name}/$file_name';
        String filePath = '${downloadDir.path}/${widget.folder_name}/$file_name';
        File file = File(filePath);
        if (await file.exists()) {
          return file;
        } else {
          print('');
          print('Image [$file_name] was NOT found at $filePath');
        }
      } catch (e) {
        print('');
        print('Error recovering the image [$file_name]: $e');
      }

      try {
        print('');
        print('Trying to download the image [${file_name}]');

        bool check = await check_od_ids();
        if (check == false) {
          return null;
        }

        http.Response get_img_response = await http.get(
          Uri.parse(
              "https://graph.microsoft.com/v1.0/drives/${drive_id.toString()}/items/${folder_id.toString()}:/$file_name:/content"),
          headers: {"Authorization": "Bearer ${widget.token}"},
        );

        if (get_img_response.statusCode == 200) {
          print('');
          print('Image [$file_name] successfully downloaded');
          var file = await store_file(get_img_response.bodyBytes, img_name, '.jpg', downloadDir);
          return file;
        } else {
          print('');
          print(
              "Failed to download the file [$file_name]. Status code: ${get_img_response.statusCode}");
          return null;
        }
      } catch (er) {
        print('Error downloading the image [$file_name]: $er');
        return null;
      }
    }
    return null;
  }

  Future<String> create_folder(String folder_name, Directory directory) async {
    //final Directory folder = Directory('${appDocDir.path}/$folder_name/');
    final Directory folder = Directory('${directory.path}/$folder_name/');

    if (await folder.exists()) {
      return folder.path;
    } else {
      final Directory new_folder = await folder.create(recursive: true);
      return new_folder.path;
    }
  }

  Future store_file(List<int> bytes, String file_name, String file_extension, Directory directory) async {
    print('');
    print('store_file() was called');
    if (bytes.isNotEmpty) {
      await create_folder(widget.folder_name, directory);
      //String filePath = '${appDocDir.path}/${widget.folder_name}/$file_name$file_extension';
      String filePath = '${directory.path}/${widget.folder_name}/$file_name$file_extension';
      File file = File(filePath);
      try {
        await file.writeAsBytes(bytes);
        print('File was stored successfully');
        return file;
      } catch (e) {
        print('Error storing file: $e');
        return null;
      }
    } else {
      print('Error: There are no bytes to store');
      return null;
    }
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
        title: Text(widget.father[1].toString())),
      body: Stack(
        children: [
          ListView(
            children: [
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    
                    SizedBox(height: total_height/5*2,),

                    ElevatedButton(
                      onPressed: loading == false ? add_photo :null, 
                      child: Text('Adicionar nova foto', 
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)
                      )
                    ),

                    Card(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                        child: Text(
                          tree,
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        )
                      )
                    ),

                    //if(description != 'DESCRIÇÃO: ' && description != 'DESCRIÇÃO: N/A' && description != 'DESCRIÇÃO: null')
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                          child: Text(
                            description,
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          )
                        )
                      ),

                    //if(local_tag != 'TAG LOCAL: ' && local_tag != 'TAG LOCAL: N/A' && local_tag != 'TAG LOCAL: null')
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                          child: Text(
                            local_tag,
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          )
                        )
                      ),

                    //if(eng_tag != 'TAG ENGEMAN: ' && eng_tag != 'TAG ENGEMAN: N/A' && eng_tag != 'TAG ENGEMAN: null')
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                          child: Text(
                            eng_tag,
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          )
                        )
                      ),

                    //if(alternative_tag != 'TAG PROPOSTA: ' && alternative_tag != 'TAG PROPOSTA: N/A' && alternative_tag != 'TAG PROPOSTA: null')
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                          child: Text(
                            alternative_tag,
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          )
                        )
                      ),

                    //if(observation != 'OBSERVAÇÃO: ' && observation != 'OBSERVAÇÃO: N/A' && observation != 'OBSERVAÇÃO: null')
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                          child: Text(
                            observation,
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          )
                        )
                      ),

                  ],
                ),
              ),
            ],
          ),
          Container(
            color: Colors.grey[850],
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              child: CarouselSlider(
                items: image_widgets,
                options: CarouselOptions(
                  height: (total_height/5)*2,
                  enableInfiniteScroll: false,
                  enlargeCenterPage: true,
                ),
              ),
            ),
          )
        ],
      ),
    );
  }

  Future<void> add_photo() async {
    print('');
    print('add_photo() was called');

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Escolher fonte'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, 'camera');
              },
              child: Text('Câmera'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context, 'gallery');
              },
              child: Text('Galeria'),
            ),
          ],
        );
      },
    ).then((value) async {
      if (value != null) {
        XFile? photo;

        if (value == 'camera') {
          photo = await imagePicker.pickImage(source: ImageSource.camera);
        } else if (value == 'gallery') {
          photo = await imagePicker.pickImage(source: ImageSource.gallery);
        }

        if (photo == null) {
          return null;
        }

        String photo_name = alternative_tag.split(': ')[1] + '_' + 'IMG' + '_' + DateFormat('yyyyMMdd_HHmmss').format(DateTime.now()) + '.jpg';
        Uint8List file_bytes = await File(photo.path).readAsBytesSync();
        File? file = await store_file(file_bytes, photo_name, '', dcimDir);

        if (file == null) {
          return null;
        }

        final prefs = await SharedPreferences.getInstance();
        List<String>? files_for_later = prefs.getStringList('files_for_later');

        if (files_for_later == null || files_for_later.isEmpty) {
          files_for_later = [];
        }

        if (file.path != null && file.path != 'null') {
          files_for_later.add(file.path);
        }

        await prefs.setStringList('files_for_later', files_for_later);

        show_snackbar('Arquivo guardado para envio posterior');
      }
    });
  } 
}
*/
