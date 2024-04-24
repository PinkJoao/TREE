import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'infoPage.dart';
/*
class SearchPage extends StatefulWidget {
  final String token;
  final List level_list;
  final String search_term;
  final String folder_name;
  final drive_id;
  final folder_id;

  const SearchPage({
    Key? key,
    required this.token,
    required this.level_list,
    required this.search_term,
    required this.folder_name,
    required this.drive_id,
    required this.folder_id,
  }) : super(key: key);

  @override
  _SearchPageState createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  List<Widget> displayed_elements = [];

  @override
  void initState() {
    super.initState();
    search_actives();
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

  void search_actives() { setState(() {
    List already_added = [];
    
    for (var item in widget.level_list[7]){
      List active_info = item[1];
      var active_name = item[0][5];
      List active_tags = [active_info[1], active_info[2], active_info[3]].nonNulls.toList();

      if(active_name == 'null' || active_name == 'N/A' || active_name == '#N/A'){
        active_name = null;
      }

      for(var tag in active_tags){
        if((tag.contains(widget.search_term) || tag.contains(widget.search_term.toUpperCase())) && (active_name != null)){
          if(!already_added.contains(active_tags.toString())){
            displayed_elements.add(
              Padding(
                padding: EdgeInsets.symmetric(vertical: 5),
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      new MaterialPageRoute(
                        builder: (context) => InfoPage(
                          token: widget.token!,
                          level_list: widget.level_list,
                          father: [[item[0][0], item[0][1], item[0][2],item[0][3],item[0][4]],item[0][5]],
                          folder_name: widget.folder_name,
                          driveId: widget.drive_id,
                          folderId: widget.folder_id,
                        )
                      )
                    );
                  },
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text('\n' + active_name.toString() + '\nTAG: [' + active_tags.last.toString() + ']\n'))
                )
              )
            );
            already_added.add(active_tags.toString());
          }
        }
      }  
    }
    if(displayed_elements.isEmpty){
      displayed_elements.add(
        Card(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            child: Text(
              'Nenhum ativo encontrado',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            )
          )
        )
      );
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
        title: Text(widget.search_term)
      ),
      body: Center(
          child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: displayed_elements
        ),
      )),
    );
  }
}
*/