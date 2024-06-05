import 'dart:io';
import 'dart:developer';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/cupertino.dart';
import 'package:path_provider/path_provider.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:lecle_downloads_path_provider/lecle_downloads_path_provider.dart';

import 'generalLib.dart';

class InfoPage extends StatefulWidget {
  final OneDriveIDs? oneDriveIDs;
  final String folder;
  final List levels;
  final String title;
  final String tag;

  const InfoPage({
    Key? key,
    required this.oneDriveIDs,
    required this.folder,
    required this.levels,
    required this.title,
    required this.tag,
  }) : super(key: key);

  @override
  InfoPageState createState() => InfoPageState();
}

class InfoPageState extends State<InfoPage> {
  late Directory downloadDir;

  String pendingFolder  = 'PENDENTES TREE';
  String trashFolder    = 'LIXEIRA TREE';

  bool isRedExpanded = false;
  bool isGreenExpanded = false;
  bool isBlueExpanded = false;
  bool isPurpleExpanded = false;

  List<dynamic> infoList      = [];
  Map<String, String> infoMap = {};

  String customAnomaly = '';

  List<String>           imageNames = [];
  List<String> downloadedImageNames = [];
  List<String>            anomalies = [];
  List<Widget>         imageWidgets = [];

  bool loading = true;

  final GlobalKey _containerKey = GlobalKey();
  late Future<double> containerHeight;

  @override
  void initState() {
    super.initState();
    getActiveInfo();
    containerHeight = getContainerHeight();
  }

  Future<double> getContainerHeight() async {
    await Future.delayed(const Duration(milliseconds: 100)); // Allow rendering time
    final RenderBox renderBox = _containerKey.currentContext?.findRenderObject() as RenderBox;
    return renderBox.size.height;
  }

  @override
  Widget build(BuildContext context) {
    
    return Scaffold(
      appBar: AppBar(
        leading: BackButton(color: Colors.grey[900]),
        title: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Text(widget.title),
        ) 
      ),
      body: Stack(
        children: [
          ListView(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    FutureBuilder<double>(
                      future: containerHeight,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.done) {
                          return SizedBox(height: snapshot.data);
                        } else {
                          return const SizedBox(height: 0);
                        }
                      },
                    ),

                    for(String info in infoMap.values)
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                          child: Text(
                            info,
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          )
                        )
                      ),
                  ],
                ),
              ),
            ],
          ),
          Container(
            key: _containerKey,
            color: Colors.grey[850],
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 10, 10, 0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [

                  Stack(
                    alignment: Alignment.bottomCenter,
                    children: [
                      CarouselSlider(
                        items: imageWidgets,
                        options: CarouselOptions(
                          height: imageWidgets.isNotEmpty ? (getTotalHeight(context) / 5) * 2 : 38,
                          enableInfiniteScroll: false,
                          enlargeCenterPage: true,
                        ),
                      ),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        mainAxisSize: MainAxisSize.max,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              mainAxisAlignment: MainAxisAlignment.end,
                              mainAxisSize: MainAxisSize.max,
                              children: [
                                if (imageWidgets.isNotEmpty && imageNames.where((element) => element.endsWith('_1')).isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 5),
                                    child: AnimatedContainer(
                                      duration: const Duration(milliseconds: 300),
                                      decoration: BoxDecoration(
                                        color: const Color.fromARGB(50, 255, 75, 75),
                                        border: Border.all(color: Colors.redAccent),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      width: isRedExpanded ? getTotalWidth(context) - 30 : 37,
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.end,
                                        children: [
                                          if (isRedExpanded)
                                            const Flexible(
                                              child: Card(
                                                child: Padding(
                                                  padding: EdgeInsets.symmetric(horizontal: 5, vertical: 5),
                                                  child: SingleChildScrollView(
                                                    scrollDirection: Axis.horizontal,
                                                    child: Text(
                                                      'ESTE ATIVO PODE CONTER FOTOS INCOERENTES',
                                                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.redAccent),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          IconButton(
                                            padding: EdgeInsets.zero,
                                            constraints: const BoxConstraints(minHeight: 35, minWidth: 35),
                                            icon: const Icon(CupertinoIcons.exclamationmark_triangle, color: Colors.redAccent),
                                            onPressed: () {
                                              setState(() {
                                                isRedExpanded = !isRedExpanded;
                                              });
                                            },
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),

                                if (!loading && imageNames.isEmpty)
                                  Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 5),
                                    child: AnimatedContainer(
                                      duration: const Duration(milliseconds: 300),
                                      decoration: BoxDecoration(
                                        color: const Color.fromARGB(50, 100, 255, 50),
                                        border: Border.all(color: Colors.lightGreen),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      width: isGreenExpanded ? getTotalWidth(context) - 30 : 37,
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.end,
                                        children: [
                                          if (isGreenExpanded)
                                            const Flexible(
                                              child: Card(
                                                child: Padding(
                                                  padding: EdgeInsets.symmetric(horizontal: 5, vertical: 5),
                                                  child: SingleChildScrollView(
                                                    scrollDirection: Axis.horizontal,
                                                    child: Text(
                                                      'ESTE ATIVO NÃO POSSUI FOTOS REGISTRADAS',
                                                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.lightGreen),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          IconButton(
                                            padding: EdgeInsets.zero,
                                            constraints: const BoxConstraints(minHeight: 35, minWidth: 35),
                                            icon: const Icon(CupertinoIcons.exclamationmark_circle, color: Colors.lightGreen),
                                            onPressed: () {
                                              setState(() {
                                                isGreenExpanded = !isGreenExpanded;
                                              });
                                            },
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),

                                if (!loading && imageNames.isNotEmpty && imageWidgets.isEmpty)
                                  Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 5),
                                    child: AnimatedContainer(
                                      duration: const Duration(milliseconds: 300),
                                      decoration: BoxDecoration(
                                        color: const Color.fromARGB(50, 50, 100, 255),
                                        border: Border.all(color: Colors.lightBlue),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      width: isBlueExpanded ? getTotalWidth(context) - 30 : 37,
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.end,
                                        children: [
                                          if (isBlueExpanded)
                                            const Flexible(
                                              child: Card(
                                                child: Padding(
                                                  padding: EdgeInsets.symmetric(horizontal: 5, vertical: 5),
                                                  child: SingleChildScrollView(
                                                    scrollDirection: Axis.horizontal,
                                                    child: Text(
                                                      'NÃO FOI POSSÍVEL RECUPERAR AS FOTOS DESTE ATIVO',
                                                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.lightBlue),
                                                    ),
                                                  )
                                                ),
                                              ),
                                            ),
                                          IconButton(
                                            padding: EdgeInsets.zero,
                                            constraints: const BoxConstraints(minHeight: 35, minWidth: 35),
                                            icon: const Icon(CupertinoIcons.exclamationmark_octagon, color: Colors.lightBlue),
                                            onPressed: () {
                                              setState(() {
                                                isBlueExpanded = !isBlueExpanded;
                                              });
                                            },
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),

                                if (!loading && imageNames.isNotEmpty && imageWidgets.isNotEmpty && downloadedImageNames.length < imageNames.length)
                                  Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 5),
                                    child: AnimatedContainer(
                                      duration: const Duration(milliseconds: 300),
                                      decoration: BoxDecoration(
                                        color: const Color.fromARGB(50, 225, 50, 235),
                                        border: Border.all(color: const Color.fromARGB(255, 225, 115, 235)),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      width: isPurpleExpanded ? getTotalWidth(context) - 30 : 37,
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.end,
                                        children: [
                                          if (isPurpleExpanded)
                                            const Flexible(
                                              child: Card(
                                                child: Padding(
                                                  padding: EdgeInsets.symmetric(horizontal: 5, vertical: 5),
                                                  child: SingleChildScrollView(
                                                    scrollDirection: Axis.horizontal,
                                                    child: Text(
                                                      'NÃO FOI POSSÍVEL RECUPERAR TODAS AS FOTOS DESTE ATIVO',
                                                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color.fromARGB(255, 225, 115, 235)),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),

                                          IconButton(
                                            padding: EdgeInsets.zero,
                                            constraints: const BoxConstraints(minHeight: 35, minWidth: 35),
                                            icon: const Icon(CupertinoIcons.exclamationmark_octagon, color: Color.fromARGB(255, 225, 115, 235)),
                                            onPressed: () {
                                              setState(() {
                                                isPurpleExpanded = !isPurpleExpanded;
                                              });
                                            },
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                              ],
                            )
                          )
                        ],
                      )
                      
                    ],
                  ),

                  Row(
                    mainAxisSize: MainAxisSize.max,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [

                      Expanded(
                        child: ElevatedButton(
                          onPressed: loading == false ? addPhoto : null,
                          child: const Text('Adicionar foto',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)
                          ),
                        ),
                      ),

                      const SizedBox(width: 5,),

                      ElevatedButton(
                          onPressed: loading ? null : (){
                            anomalies.clear();
                            List<String> anomalyStrings = [
                              'anomalia 1',
                              'anomalia 2',
                              'anomalia 3',
                              'anomalia 4',
                              'anomalia 5',
                            ];
                            showModalBottomSheet(
                              context: context,
                              builder: (BuildContext context) {
                                return ListView(
                                  children: [

                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 10),
                                      child: ElevatedButton(
                                        onPressed: () async {
                                          await storeAnomaly();
                                          Navigator.pop(context);
                                        }, 
                                        child: const Text('Salvar anomalia'),
                                      ),
                                    ),

                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 10),
                                      child: TextField(
                                        onChanged: (value){
                                          customAnomaly = value;
                                        },
                                        decoration: InputDecoration(
                                          hintText: 'Outro:',
                                          border: const OutlineInputBorder(),
                                          hintStyle: TextStyle(
                                            color: Colors.grey[600],
                                          ),
                                          contentPadding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                          ),
                                        ),
                                      ),
                                    ),

                                    

                                    /*for(String anomaly in anomalyStrings)
                                      SmartCheckboxListTile(
                                        title: Text(anomaly, style: TextStyle(fontSize: getTotalWidth(context)/28.6, fontWeight: FontWeight.bold)),
                                        activeColor: Colors.greenAccent,
                                        checkColor: Colors.grey[900],
                                        onChanged: (bool? value) async {
                                          if(value == true){
                                            anomalies.add(anomaly);
                                          }else{
                                            anomalies.remove(anomaly);
                                          }
                                        },
                                      ),*/


                                  ],
                                );
                              },
                            );
                          },
                          child: const Icon(CupertinoIcons.pencil_ellipsis_rectangle)
                        ),
                      
                      

                      

                    ],
                  )

                  
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  List searchActive(){

    for(var item in widget.levels[7]){
      if(item[1][3].toString() == widget.tag){
        return item;
      }
    }
    
    return [null];
  }

  Future<void> getActiveInfo() async {
    downloadDir = await DownloadsPath.downloadsDirectory()?? await getApplicationDocumentsDirectory();

    List active = searchActive();

    if(active[0] != null){
      infoList               = active[1];

      infoMap['proposedTag'] = 'TAG PROPOSTA: ${infoList[3]}';
      infoMap['description'] = 'DESCRIÇÃO: ${   infoList[0]}';
      infoMap['tree']        = '';
      infoMap['localTag']    = 'TAG LOCAL: ${   infoList[1]}';
      infoMap['engTag']      = 'TAG ENGEMAN: ${ infoList[2]}';
      infoMap['codtipalp']   = 'CODTIPAPL: ${   infoList[4]}';
      infoMap['serial']      = 'NUMSER: ${      infoList[5]}';
      infoMap['model']       = 'MODELO: ${      infoList[6]}';
      infoMap['codfor']      = 'CODFOR: ${      infoList[7]}';
      infoMap['numpat']      = 'NUMPAT: ${      infoList[8]}';
      infoMap['observation'] = 'OBSERVAÇÃO: ${  infoList[9]}';

      

      String tree = active[0].toString().split('[')[1].replaceAll(', ', ' || ');
      infoMap.update('tree', (value) => tree.substring(0, tree.length - 4));

      imageNames.addAll(infoList[11]);

      for(String key in infoMap.keys){
        if(infoMap[key]!.endsWith('N/A') || infoMap[key]!.endsWith('null') || infoMap[key]!.endsWith('DESCRIÇÃO: ')){
          infoMap.update(key, (value) => '${infoMap[key]!.split(': ').first}: INDISPONÍVEL');
        }
      }

      await insertImageWidgets(imageNames);

      List<File>? pendingPhotos = await getDirectoryFiles(pendingFolder, downloadDir, 'jpg');
      if(pendingPhotos != null){
        for(File imageFile in pendingPhotos){
          String fileTag = imageFile.path.split('/').last.split('_').first.replaceAll('%', '/').replaceAll('@', '"');
          if(fileTag == infoList[3]){
            insertPendingWidget(imageFile);
          }
        }
      }
    }

    if(imageWidgets.isEmpty){
      isBlueExpanded = true;
      isGreenExpanded = true;
    }

    if(mounted){
      setState(() {
        containerHeight = getContainerHeight();
        loading = false;
      });
    }
  }

  insertPendingWidget(File imageFile){
    String fileName = 'IMG${imageFile.path.split('/').last.split('IMG').last.replaceAll('.jpg', '').replaceAll('.jpeg', '').replaceAll('.png', '')}';
    Key widgetKey = Key(imageFile.path);
    imageWidgets.add(
      GestureDetector(
        key: widgetKey,
        onTap: () {
          showInFullScreen(imageFile.path, context);
        },
        child: Hero(
          tag: widgetKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [

                  Text(fileName,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  
                  IconButton(
                    onPressed: () async {
                      if(await moveFile(imageFile.path.split('/').last, pendingFolder, trashFolder, downloadDir) != null){
                        setState(() {
                          imageWidgets.removeAt(imageWidgets.indexOf(imageWidgets.firstWhere((widget) => widget.key == widgetKey)));
                          containerHeight = getContainerHeight();
                        });
                      }
                    },
                    icon: const Icon(CupertinoIcons.xmark_circle,
                      color: Colors.redAccent,
                    )
                  ),

                ],
              ),

              Flexible(child: Image.file(imageFile),),
            ],
          ),
        ),
      ),
    );

    if(mounted){
      setState(() { });
    }
  }

  Future insertImageWidgets(List imageNames) async {
    for(String imageName in imageNames){
      File? imageFile =  await getImageFile(imageName);
      if(imageFile != null){
        Key widgetKey = Key(imageFile.path);
        String fileName = imageFile.path.split('/').last.split('.').first;
        downloadedImageNames.add(imageName);
        imageWidgets.add(
          GestureDetector(
            key: widgetKey,
            onTap: () {
              showInFullScreen(imageFile.path, context);
            },
            child: Hero(
              tag: widgetKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [

                      Text(fileName,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),

                  Flexible(child: Image.file(imageFile),),
                ],
              ),
            ),
          ),
        );
      }
    }
   
    if(mounted){
      setState(() { });
    }
  }



  Future<File?> getImageFile(var imgName) async {
    if(imgName == "null" || imgName == null || imgName == '' || imgName == ' '){
      return null;
    }

    String fileName = '${imgName.toString()}.jpg';
    log('getImageFile() was called for the image [$fileName]');

    List<File> files = await getDirectoryFiles(widget.folder, downloadDir) ?? [];

    if(files.isNotEmpty){
      for(File file in files){
        if(file.path.contains(imgName)){
          return file;
        }
      }
    }

    log('File [$fileName] was not found');
    if(widget.oneDriveIDs != null){
      log('Trying to download the file [$fileName]');

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

  Future storeAnomaly() async {
    String text = '';

    if(customAnomaly != ''){
      text = 'Anomalia [customizada]: $customAnomaly\n';
    }
    for(String anomaly in anomalies){
      text = '${text}Anomalia [${anomalies.indexOf(anomaly) + 1}]: $anomaly\n';
    }

    File? checkFile = await storeText('${infoList[3].replaceAll('/', '%').replaceAll('"', '@')}_TXT_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.txt', text, pendingFolder, downloadDir);
    if(checkFile != null){
      showSnackbar(context, 'Anomalia armazenada com sucesso');
    }
  }

  Future<void> addPhoto() async {
    if(infoMap['proposedTag']!.contains('INDISPONÍVEL')){
      showSnackbar(context, 'Este ativo não possui tag, ou não foi totalmente carregado');
      log('1');
      return;

    }else if((infoList[3].toString() == '' || infoList[3].toString() == 'null' || infoList[3] == null)){
      log('2');
      showSnackbar(context, 'Este ativo não possui tag, ou não foi totalmente carregado');
      return;

    }else if(infoList.length < 3){
      showSnackbar(context, 'Este ativo não possui tag, ou não foi totalmente carregado');
      log('3');
      return;
    }

    try {
      Uint8List? fileBytes = await takePhoto(context);

      if (fileBytes == null) {
        return;
      }

      // Handle the file saving or uploading
      File? file = await storeFile(fileBytes, '${infoList[3].replaceAll('/', '%').replaceAll('"', '@')}_IMG_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.jpg', pendingFolder, downloadDir);

      if (file == null) {
        showSnackbar(context, 'Falha no armazenamento da foto');
        return;
      }

      insertPendingWidget(file);
      
      setState(() {
        containerHeight = getContainerHeight();
      });

      showSnackbar(context, 'Foto armazenada com sucesso');
      
    } catch (e) {
      showSnackbar(context, 'Falha no armazenamento da foto');
      log('Error adding photo: $e');
    }
  }

}