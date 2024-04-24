import 'dart:io';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:lecle_downloads_path_provider/lecle_downloads_path_provider.dart';

import 'package:camerawesome/camerawesome_plugin.dart';

import 'generalLib.dart';

class InfoPage extends StatefulWidget {
  final OneDriveIDs? oneDriveIDs;
  final String folder;
  final List levels;
  final dynamic father;

  const InfoPage({
    Key? key,
    required this.oneDriveIDs,
    required this.folder,
    required this.levels,
    required this.father,
  }) : super(key: key);

  @override
  _InfoPageState createState() => _InfoPageState();
}

class _InfoPageState extends State<InfoPage> {
  ImagePicker imagePicker = ImagePicker();

  late Directory downloadDir;
  String pendingFolder  = 'PENDENTES TREE';

  List   infoList       = [];
  String description    = 'DESCRIÇÃO: ';
  String localTag       = 'TAG LOCAL: ';
  String engTag         = 'TAG ENGEMAN: ';
  String alternativeTag = 'TAG PROPOSTA: ';
  String codtipalp      = 'CODTIPAPL: ';
  String serial         = 'NUMSER: ';
  String model          = 'MODELO: ';
  String codfor         = 'CODFOR: ';
  String numpat         = 'NUMPAT: ';
  String observation    = 'OBSERVAÇÃO: ';
  String tree           = '';

  List         imageNames   = [];
  List         images       = [];
  List<Widget> imageWidgets = [];

  bool loading = true;

  @override
  void initState() {
    super.initState();
    getActiveInfo();
  }
  

  @override
  Widget build(BuildContext context) {
    
    return Scaffold(
      appBar: AppBar(
        leading: BackButton(color: Colors.grey[900]),
        title: Text(widget.father[1][0].toString())),
      body: Stack(
        children: [
          ListView(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    
                    SizedBox(height: getTotalHeight(context)/5*2,),

                    if(imageNames.where((element) => element.endsWith('_1')).length > 0)
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                          child: Text(
                            'ATENÇÃO: ESTE ATIVO PODE CONTER FOTOS INCOERENTES',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.redAccent),
                          )
                        )
                      ),

                    ElevatedButton(
                      onPressed: loading == false ? addPhoto :null, 
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

                    Card(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                        child: Text(
                          description,
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        )
                      )
                    ),

                    Card(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                        child: Text(
                          localTag,
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        )
                      )
                    ),

                    Card(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                        child: Text(
                          engTag,
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        )
                      )
                    ),

                    Card(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                        child: Text(
                          alternativeTag,
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        )
                      )
                    ),

                    Card(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                        child: Text(
                          codtipalp,
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        )
                      )
                    ),

                    Card(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                        child: Text(
                          serial,
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        )
                      )
                    ),

                    Card(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                        child: Text(
                          model,
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        )
                      )
                    ),

                    Card(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                        child: Text(
                          codfor,
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        )
                      )
                    ),

                    Card(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                        child: Text(
                          numpat,
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        )
                      )
                    ),

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
              padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
              child: CarouselSlider(
                items: imageWidgets,
                options: CarouselOptions(
                  height: (getTotalHeight(context)/5)*2,
                  enableInfiniteScroll: false,
                  enlargeCenterPage: true,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List searchActive(){
    List fatherFilters = [];
    for(var filter in widget.father[0]){
      fatherFilters.add(filter);
    }
    fatherFilters.add(widget.father[1]);

    for(var item in widget.levels[7]){
      if(item[0].toString() == fatherFilters.toString()){
        return item;
      }
    }
    
    return [null];
  }

  Future<void> getActiveInfo() async {
    downloadDir = await DownloadsPath.downloadsDirectory()?? await getApplicationDocumentsDirectory();

    List active = searchActive();
    if(active[0] != null){
      infoList       = active[1];
      description    = description    + infoList[0].toString();
      localTag       = localTag       + infoList[1].toString();
      engTag         = engTag         + infoList[2].toString();
      alternativeTag = alternativeTag + infoList[3].toString();
      codtipalp      = codtipalp      + infoList[4].toString();
      serial         = serial         + infoList[5].toString();
      model          = model          + infoList[6].toString();
      codfor         = codfor         + infoList[7].toString();
      numpat         = numpat         + infoList[8].toString();
      observation    = observation    + infoList[9].toString();
      imageNames.addAll(infoList[10]);
      
      tree = active[0].toSet().toString().replaceAll(',', ' //').split('[').first + infoList[0].toString();
      //tree = tree.substring(1, tree.length-1);

      if(description    == 'DESCRIÇÃO: '    || description    == 'DESCRIÇÃO: N/A'    || description    == 'DESCRIÇÃO: null'   ){ description    = 'DESCRIÇÃO: INDISPONÍVEL'   ;}
      if(localTag       == 'TAG LOCAL: '    || localTag       == 'TAG LOCAL: N/A'    || localTag       == 'TAG LOCAL: null'   ){ localTag       = 'TAG LOCAL: INDISPONÍVEL'   ;}
      if(engTag         == 'TAG ENGEMAN: '  || engTag         == 'TAG ENGEMAN: N/A'  || engTag         == 'TAG ENGEMAN: null' ){ engTag         = 'TAG ENGEMAN: INDISPONÍVEL' ;}
      if(alternativeTag == 'TAG PROPOSTA: ' || alternativeTag == 'TAG PROPOSTA: N/A' || alternativeTag == 'TAG PROPOSTA: null'){ alternativeTag = 'TAG PROPOSTA: INDISPONÍVEL';}
      if(codtipalp      == 'CODTIPAPL: '    || codtipalp      == 'CODTIPAPL: N/A'    || codtipalp      == 'CODTIPAPL: null'   ){ codtipalp      = 'CODTIPAPL: INDISPONÍVEL'   ;}
      if(serial         == 'NUMSER: '       || serial         == 'NUMSER: N/A'       || serial         == 'NUMSER: null'      ){ serial         = 'NUMSER: INDISPONÍVEL'      ;}
      if(model          == 'MODELO: '       || model          == 'MODELO: N/A'       || model          == 'MODELO: null'      ){ model          = 'MODELO: INDISPONÍVEL'      ;}
      if(codfor         == 'CODFOR: '       || codfor         == 'CODFOR: N/A'       || codfor         == 'CODFOR: null'      ){ codfor         = 'CODFOR: INDISPONÍVEL'      ;}
      if(numpat         == 'NUMPAT: '       || numpat         == 'NUMPAT: N/A'       || numpat         == 'NUMPAT: null'      ){ numpat         = 'NUMPAT: INDISPONÍVEL'      ;}
      if(observation    == 'OBSERVAÇÃO: '   || observation    == 'OBSERVAÇÃO: N/A'   || observation    == 'OBSERVAÇÃO: null'  ){ observation    = 'OBSERVAÇÃO: INDISPONÍVEL'  ;}


      for(String imageName in imageNames){
        var imageFile =  await getImageFile(imageName);
        if(imageFile != null){
          images.add([imageName, imageFile]);
        }
      }

      List<File>? pendingPhotos = await getDirectoryFiles(pendingFolder, downloadDir, 'jpg');
      if(pendingPhotos != null){
        for(File file in pendingPhotos){
          String fileName = file.path.split('/').last;
          if(fileName.contains(infoList[3].toString())){
            images.add([fileName,file]);
          }
        }
      }

      for(List image in images){
        insertImageWidget(image[0], image[1]);
      }
    }
    if(this.mounted){
      setState(() {
        loading = false;
      });
    }
  }

  Future<File?> getImageFile(var imgName) async {
    if(imgName == "null" || imgName == null){
      return null;
    }

    String fileName = imgName.toString() + '.jpg';
    print('getImageFile() was called for the image [$fileName]');

    List<File> files = await getDirectoryFiles(widget.folder, downloadDir) ?? [];

    if(files.isNotEmpty){
      for(File file in files){
        if(file.path.contains(imgName)){
          return file;
        }
      }
    }

    print('File [$fileName] was not found');
    if(widget.oneDriveIDs != null){
      print('Trying to download the file [$fileName]');

      Uint8List? fileBytes = await downloadFile(fileName, widget.oneDriveIDs!);

      if(fileBytes != null){
        File? file = await storeFile(fileBytes, fileName, widget.folder, downloadDir);
        if(file != null){
          return file;
        }
      }
    }
    return null;
  }

  insertImageWidget(String fileName, File file){
    imageWidgets.add(
      GestureDetector(
        key: Key(fileName),
        onTap: () {
          showInFullScreen(file.path, context);
        },
        child: Hero(
          tag: fileName,
          child:
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(fileName,
              style: TextStyle(fontWeight: FontWeight.bold),
              ),

              Flexible(child: Image.file(file),),
            ],
          )
        ),
      ),
    );
    setState(() {
      
    });
  }

  Future<void> addPhoto() async {
    print('addPhoto() was called');

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          actionsAlignment: MainAxisAlignment.spaceAround,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(20.0))),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, 'gallery');
              },
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Icon(
                    Icons.add_photo_alternate,
                    size: getTotalWidth(context) / 12,
                  ),

                  Padding(
                    padding: EdgeInsets.fromLTRB(10, 10, 10, 0),
                    child: Text('Galeria',
                      style: TextStyle(
                        fontWeight: FontWeight.bold, fontSize: getTotalWidth(context) / 20
                      )
                    )
                  )
                ]
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context, 'camera');
              },
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Icon(
                    Icons.add_a_photo,
                    size: getTotalWidth(context) / 12,
                  ),

                  Padding(
                    padding: EdgeInsets.fromLTRB(10, 10, 10, 0),
                    child: Text('Câmera',
                      style: TextStyle(
                        fontWeight: FontWeight.bold, fontSize: getTotalWidth(context) / 20
                      )
                    )
                  )
                ]
              ),
            )
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

          Uint8List fileBytes = await File(photo.path).readAsBytes();

          /*Uint8List? fileBytes;

          if (value == 'camera') {

            if(photo == null){
              return null;
            }
            fileBytes = ;
            if(fileBytes == null || fileBytes.isEmpty){
              return null;
            }
          } else if (value == 'gallery') {
            XFile? photo = await imagePicker.pickImage(source: ImageSource.gallery);
            if(photo == null){
              return null;
            }
            fileBytes = File(photo.path).readAsBytesSync();
            if(fileBytes.isEmpty){
              return null;
            }
          }*/

          String photoName = '${alternativeTag.split(': ')[1]}_IMG_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.jpg';
          File? file = await storeFile(fileBytes, photoName, pendingFolder, downloadDir);

          if (file == null) {
            return null;
          }

          insertImageWidget(file.path.split('/').last.split('.').first, file);

          showSnackbar(context, 'Arquivo guardado para envio posterior');
        }
      }
    );
  } 
}
