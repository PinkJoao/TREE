/*import 'dart:io';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/cupertino.dart';
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
  String trashFolder    = 'LIXEIRA TREE';

  bool isRedExpanded = false;
  bool isGreenExpanded = false;
  bool isBlueExpanded = false;
  bool isPurpleExpanded = false;

  List   infoList    = [];
  String description = 'DESCRIÇÃO: ';
  String localTag    = 'TAG LOCAL: ';
  String engTag      = 'TAG ENGEMAN: ';
  String proposedTag = 'TAG PROPOSTA: ';
  String codtipalp   = 'CODTIPAPL: ';
  String serial      = 'NUMSER: ';
  String model       = 'MODELO: ';
  String codfor      = 'CODFOR: ';
  String numpat      = 'NUMPAT: ';
  String observation = 'OBSERVAÇÃO: ';
  String tree        = '';

  List<String>         imageNames   = [];
  List<String> downloadedImageNames = [];
  List<Widget>         imageWidgets = [];

  bool loading = true;

  final GlobalKey _containerKey = GlobalKey();
  late Future<double> containerHeight;

  bool showTagDialog = false;
  String? userTag;

  @override
  void initState() {
    super.initState();
    getActiveInfo();
    containerHeight = getContainerHeight();
  }

  Future<double> getContainerHeight() async {
    await Future.delayed(Duration(milliseconds: 100)); // Allow rendering time
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
          child: Text(widget.father[1][0].toString()),
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
                          return SizedBox(height: 0);
                        }
                      },
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
                          proposedTag,
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
            key: _containerKey,
            color: Colors.grey[850],
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 10, 10, 0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [

                  Stack(
                    alignment: Alignment.center,
                    children: [
                      CarouselSlider(
                        items: imageWidgets,
                        options: CarouselOptions(
                          height: imageWidgets.isNotEmpty ? (getTotalHeight(context) / 5) * 2 : 0,
                          enableInfiniteScroll: false,
                          enlargeCenterPage: true,
                        ),
                      ),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              if (imageWidgets.isNotEmpty && imageNames.where((element) => element.endsWith('_1')).isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 5),
                                  child: AnimatedContainer(
                                    duration: Duration(milliseconds: 300),
                                    decoration: BoxDecoration(
                                      color: const Color.fromARGB(50, 255, 75, 75),
                                      border: Border.all(color: Colors.redAccent),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    width: isRedExpanded ? getTotalWidth(context) * 0.9 : 38,
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        if (isRedExpanded)
                                          const Flexible(
                                            child: Card(
                                              child: Padding(
                                                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                                child: SingleChildScrollView(
                                                  scrollDirection: Axis.horizontal,
                                                  child: Text(
                                                    'ESTE ATIVO PODE CONTER FOTOS INCOERENTES',
                                                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.redAccent),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        IconButton(
                                          padding: EdgeInsets.zero,
                                          constraints: BoxConstraints(minHeight: 35, minWidth: 35),
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

                              if (imageNames.isEmpty)
                                Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 5),
                                  child: AnimatedContainer(
                                    duration: Duration(milliseconds: 300),
                                    decoration: BoxDecoration(
                                      color: const Color.fromARGB(50, 100, 255, 50),
                                      border: Border.all(color: Colors.lightGreen),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    width: isGreenExpanded ? getTotalWidth(context) * 0.9 : 38,
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        if (isGreenExpanded)
                                          const Flexible(
                                            child: Card(
                                              child: Padding(
                                                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                                child: SingleChildScrollView(
                                                  scrollDirection: Axis.horizontal,
                                                  child: Text(
                                                    'ESTE ATIVO NÃO POSSUI FOTOS REGISTRADAS',
                                                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.lightGreen),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        IconButton(
                                          padding: EdgeInsets.zero,
                                          constraints: BoxConstraints(minHeight: 35, minWidth: 35),
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

                              if (imageNames.isNotEmpty && imageWidgets.isEmpty)
                                Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 5),
                                  child: AnimatedContainer(
                                    duration: Duration(milliseconds: 300),
                                    decoration: BoxDecoration(
                                      color: const Color.fromARGB(50, 50, 100, 255),
                                      border: Border.all(color: Colors.lightBlue),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    width: isBlueExpanded ? getTotalWidth(context) * 0.9 : 38,
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        if (isBlueExpanded)
                                          const Flexible(
                                            child: Card(
                                              child: Padding(
                                                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                                child: SingleChildScrollView(
                                                  scrollDirection: Axis.horizontal,
                                                  child: Text(
                                                    'NÃO FOI POSSÍVEL RECUPERAR AS FOTOS DESTE ATIVO',
                                                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.lightBlue),
                                                  ),
                                                )
                                              ),
                                            ),
                                          ),
                                        IconButton(
                                          padding: EdgeInsets.zero,
                                          constraints: BoxConstraints(minHeight: 35, minWidth: 35),
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

                              if (imageNames.isNotEmpty && imageWidgets.isNotEmpty && downloadedImageNames.length < imageNames.length)
                                Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 5),
                                  child: AnimatedContainer(
                                    duration: Duration(milliseconds: 300),
                                    decoration: BoxDecoration(
                                      color: const Color.fromARGB(50, 225, 50, 235),
                                      border: Border.all(color: Color.fromARGB(255, 225, 115, 235)),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    width: isPurpleExpanded ? getTotalWidth(context) * 0.9 : 38,
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        if (isPurpleExpanded)
                                          const Flexible(
                                            child: Card(
                                              child: Padding(
                                                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                                child: SingleChildScrollView(
                                                  scrollDirection: Axis.horizontal,
                                                  child: Text(
                                                    'NÃO FOI POSSÍVEL RECUPERAR TODAS AS FOTOS DESTE ATIVO',
                                                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color.fromARGB(255, 225, 115, 235)),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),

                                        IconButton(
                                          padding: EdgeInsets.zero,
                                          constraints: BoxConstraints(minHeight: 35, minWidth: 35),
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
                        ],
                      )

                      /*Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Column(
                            children: [
                              if (imageWidgets.isNotEmpty && imageNames.where((element) => element.endsWith('_1')).isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 5),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: const Color.fromARGB(50, 255, 75, 75),
                                      border: Border.all(color: Colors.redAccent),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Row(
                                      children: [
                                        Card(
                                          child: Padding(
                                            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                            child: TextScroll(
                                              'ATENÇÃO: ESTE ATIVO PODE CONTER FOTOS INCOERENTES',
                                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.redAccent),
                                              velocity: Velocity(pixelsPerSecond: Offset(50, 0)),
                                              numberOfReps: 3,
                                            ),
                                          ),
                                        ),

                                        IconButton(
                                          padding: EdgeInsets.zero,
                                          constraints: BoxConstraints(minHeight: 35, minWidth: 35),
                                          icon: Icon(CupertinoIcons.exclamationmark_triangle, color: Colors.redAccent,),
                                          onPressed: null,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),

                              if (imageNames.isEmpty)    
                                Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 5),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: const Color.fromARGB(50, 100, 255, 50),
                                      border: Border.all(color: Colors.lightGreen),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Row(
                                      children: [
                                        Card(
                                          child: Padding(
                                            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                            child: TextScroll(
                                              'ESTE ATIVO NÃO POSSUI FOTOS REGISTRADAS',
                                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.lightGreen),
                                              velocity: Velocity(pixelsPerSecond: Offset(50, 0)),
                                              numberOfReps: 3,
                                            ),
                                          ),
                                        ),

                                        IconButton(
                                          padding: EdgeInsets.zero,
                                          constraints: BoxConstraints(minHeight: 35, minWidth: 35),
                                          icon: Icon(CupertinoIcons.exclamationmark_circle, color: Colors.lightGreen,),
                                          onPressed: null,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),

                              if (imageNames.isNotEmpty && imageWidgets.isEmpty)
                                Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 5),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: const Color.fromARGB(50, 50, 100, 255),
                                      border: Border.all(color: Colors.lightBlue),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Row(
                                      children: [
                                        Card(
                                          child: Padding(
                                            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                            child: TextScroll(
                                              'NÃO FOI POSSÍVEL RECUPERAR AS FOTOS DESTE ATIVO',
                                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.lightBlue),
                                              velocity: Velocity(pixelsPerSecond: Offset(50, 0)),
                                              numberOfReps: 3,
                                            ),
                                          ),
                                        ),

                                        IconButton(
                                          padding: EdgeInsets.zero,
                                          constraints: BoxConstraints(minHeight: 35, minWidth: 35),
                                          icon: Icon(CupertinoIcons.exclamationmark_octagon, color: Colors.lightBlue,),
                                          onPressed: null,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),

                              if (imageNames.isNotEmpty && imageWidgets.isNotEmpty && downloadedImageNames.length < imageNames.length)
                                Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 5),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: const Color.fromARGB(50, 225, 50, 235),
                                      border: Border.all(color: Color.fromARGB(255, 225, 115, 235)),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Row(
                                      children: [
                                        Card(
                                          child: Padding(
                                            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                            child: TextScroll(
                                              'NÃO FOI POSSÍVEL RECUPERAR TODAS AS FOTOS DESTE ATIVO',
                                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color.fromARGB(255, 225, 115, 235)),
                                              velocity: Velocity(pixelsPerSecond: Offset(50, 0)),
                                              numberOfReps: 3,
                                            ),
                                          ),
                                        ),

                                        IconButton(
                                          padding: EdgeInsets.zero,
                                          constraints: BoxConstraints(minHeight: 35, minWidth: 35),
                                          icon: Icon(CupertinoIcons.exclamationmark_octagon, color: Color.fromARGB(255, 225, 115, 235),),
                                          onPressed: null,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                            ],
                          )
                        ],
                      )*/

                      
                    ],
                  ),

                      


                  ElevatedButton(
                    onPressed: loading == false ? addPhoto : null,
                    child: const Text('Adicionar nova foto',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)
                    ),
                  ),
                  /*
                  if (imageWidgets.isNotEmpty && imageNames.where((element) => element.endsWith('_1')).isNotEmpty)
                    const Card(
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Text(
                            'ATENÇÃO: ESTE ATIVO PODE CONTER FOTOS INCOERENTES',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.redAccent),
                          ),
                        ),
                      ),
                    ),
                  if (imageNames.isEmpty)
                    const Card(
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Text(
                            'ESTE ATIVO NÃO POSSUI FOTOS REGISTRADAS',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.lightGreen),
                          ),
                        ),
                      ),
                    ),
                  if (imageNames.isNotEmpty && imageWidgets.isEmpty)
                    const Card(
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Text(
                            'NÃO FOI POSSÍVEL RECUPERAR AS FOTOS DESTE ATIVO',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.lightBlue),
                          ),
                        ),
                      ),
                    ),
                  if (imageNames.isNotEmpty && imageWidgets.isNotEmpty && downloadedImageNames.length < imageNames.length)
                    const Card(
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Text(
                            'NÃO FOI POSSÍVEL RECUPERAR TODAS AS FOTOS DESTE ATIVO',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color.fromARGB(255, 222, 113, 241)),
                          ),
                        ),
                      ),
                    ),
                  */
                ],
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
      proposedTag    = proposedTag    + infoList[3].toString();
      codtipalp      = codtipalp      + infoList[4].toString();
      serial         = serial         + infoList[5].toString();
      model          = model          + infoList[6].toString();
      codfor         = codfor         + infoList[7].toString();
      numpat         = numpat         + infoList[8].toString();
      observation    = observation    + infoList[9].toString();
      imageNames.addAll(infoList[10]);
      
      tree = active[0].toString().split('[')[1].replaceAll(', ', ' || ');
      tree = tree.substring(0, tree.length - 4);

      if(description    == 'DESCRIÇÃO: '    || description    == 'DESCRIÇÃO: N/A'    || description    == 'DESCRIÇÃO: null'   ){ description    = 'DESCRIÇÃO: INDISPONÍVEL'   ;}
      if(localTag       == 'TAG LOCAL: '    || localTag       == 'TAG LOCAL: N/A'    || localTag       == 'TAG LOCAL: null'   ){ localTag       = 'TAG LOCAL: INDISPONÍVEL'   ;}
      if(engTag         == 'TAG ENGEMAN: '  || engTag         == 'TAG ENGEMAN: N/A'  || engTag         == 'TAG ENGEMAN: null' ){ engTag         = 'TAG ENGEMAN: INDISPONÍVEL' ;}
      if(proposedTag    == 'TAG PROPOSTA: ' || proposedTag    == 'TAG PROPOSTA: N/A' || proposedTag    == 'TAG PROPOSTA: null'){ proposedTag    = 'TAG PROPOSTA: INDISPONÍVEL';}
      if(codtipalp      == 'CODTIPAPL: '    || codtipalp      == 'CODTIPAPL: N/A'    || codtipalp      == 'CODTIPAPL: null'   ){ codtipalp      = 'CODTIPAPL: INDISPONÍVEL'   ;}
      if(serial         == 'NUMSER: '       || serial         == 'NUMSER: N/A'       || serial         == 'NUMSER: null'      ){ serial         = 'NUMSER: INDISPONÍVEL'      ;}
      if(model          == 'MODELO: '       || model          == 'MODELO: N/A'       || model          == 'MODELO: null'      ){ model          = 'MODELO: INDISPONÍVEL'      ;}
      if(codfor         == 'CODFOR: '       || codfor         == 'CODFOR: N/A'       || codfor         == 'CODFOR: null'      ){ codfor         = 'CODFOR: INDISPONÍVEL'      ;}
      if(numpat         == 'NUMPAT: '       || numpat         == 'NUMPAT: N/A'       || numpat         == 'NUMPAT: null'      ){ numpat         = 'NUMPAT: INDISPONÍVEL'      ;}
      if(observation    == 'OBSERVAÇÃO: '   || observation    == 'OBSERVAÇÃO: N/A'   || observation    == 'OBSERVAÇÃO: null'  ){ observation    = 'OBSERVAÇÃO: INDISPONÍVEL'  ;}

      await insertImageWidgets(imageNames);

      List<File>? pendingPhotos = await getDirectoryFiles(pendingFolder, downloadDir, 'jpg');
      if(pendingPhotos != null){
        for(File imageFile in pendingPhotos){
          String fileTag = imageFile.path.split('/').last.split('_').first.replaceAll('%', '/');
          if(fileTag == infoList[3].toString()){
            insertPendingWidget(imageFile);
          }
        }
      }
    }


    if(this.mounted){
      setState(() {
        containerHeight = getContainerHeight();
        loading = false;
      });
    }
  }

  insertPendingWidget(File imageFile){
    String fileName = 'IMG' + imageFile.path.split('/').last.split('IMG').last.replaceAll('.jpg', '').replaceAll('.jpeg', '').replaceAll('.png', '');
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
                    style: TextStyle(fontWeight: FontWeight.bold),
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
                    icon: Icon(CupertinoIcons.xmark_circle,
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

    if(this.mounted){
      setState(() {

      });
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
                        style: TextStyle(fontWeight: FontWeight.bold),
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
   
    if(this.mounted){
      setState(() {
        
      });
    }
  }



  Future<File?> getImageFile(var imgName) async {
    if(imgName == "null" || imgName == null || imgName == '' || imgName == ' '){
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

  Future<void> addPhoto() async {
    print('addPhoto() was called');
    
    if(proposedTag.contains('INDISPONÍVEL') && showTagDialog == false){
      showSnackbar(context, 'Este ativo não possui tag, ou não foi totalmente carregado');
      showTagDialog = true;
      return;

    }else if((infoList[3].toString() == '' || infoList[3].toString() == 'null' || infoList[3] == null) && showTagDialog == false){
      showSnackbar(context, 'Este ativo não possui tag, ou não foi totalmente carregado');
      showTagDialog = true;
      return;

    }else if(infoList.length < 3 && showTagDialog == false){
      showSnackbar(context, 'Este ativo não possui tag, ou não foi totalmente carregado');
      showTagDialog = true;
      return;
      
    }

    if(showTagDialog == true && (userTag == null || userTag == '')){
      bool shouldReturn = false;
      String tempTag = '';
      await showDialog(
        context: context, 
        builder: (BuildContext context) {
          return AlertDialog(
            actionsAlignment: MainAxisAlignment.spaceAround,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(20.0))),
            title: Text('Deseja adicionar tag proposta?'),
            actions: [
              TextField(
                onChanged: (value){
                  tempTag = value;
                },
                decoration: InputDecoration(
                  hintText: 'TAG PROPOSTA',
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

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  TextButton(
                    onPressed: (){
                      Navigator.pop(context, 'null');
                    }, 
                    child: Text('NÃO')
                  ),

                  TextButton(
                    onPressed: (){
                      if(tempTag == null || tempTag == '' || tempTag == 'null' || tempTag.toString().length < 3 ){
                        showSnackbar(context, 'Por favor digite uma tag');
                      }else{
                        Navigator.pop(context, tempTag);
                      }
                    }, 
                    child: Text('SIM')
                  )
                ],
              ),

            ],
          );
        }
      ).then((value){
          if(value != null && value != '' && value != 'null'){
            userTag = tempTag;
          }else{
            shouldReturn = true;
          }
        }
      );

      showTagDialog = false;
      if(shouldReturn){
        return;
      }

    }

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

          String photoName = '${userTag ?? infoList[3].toString()}_IMG_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.jpg';
          File? file = await storeFile(fileBytes, photoName.replaceAll('/', '%').replaceAll('"', '@'), pendingFolder, downloadDir);

          if (file == null) {
            return null;
          }

          insertPendingWidget(file);
          
          setState(() {
            containerHeight = getContainerHeight();
          });

          showSnackbar(context, 'Foto armazenada com sucesso');
        }
      }
    );
  } 
}
*/