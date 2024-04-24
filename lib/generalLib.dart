import 'dart:io';
import 'dart:convert' show json, utf8;
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:photo_view/photo_view.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

void showSnackbar(BuildContext context, String message, [int? time]) {
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
    duration: Duration(seconds: time ?? 3),
    backgroundColor: Colors.transparent,
    elevation: 0,
  );
  ScaffoldMessenger.of(context).showSnackBar(snackBar);
}

class OneDriveIDs {
  var token;
  var driveID;
  var folderID;
  bool? downloading;

  OneDriveIDs(this.token, this.driveID, this.folderID);

  bool check() {
    if (folderID != null && driveID != null) {
      return true;
    } else {
      print('OneDrive IDs are not available');
      return false;
    }
  }

  bool setDownloading(bool set){
    downloading = set;
    return downloading ?? false;
  }

  bool getDownloading(){
    return downloading ?? false;
  }
}

Future<http.Response?> request(String url, var token, [String? extension, Uint8List? body]) async {
  try {
    http.Response? response;
    
    if(extension != null && body != null){
      if(extension == 'jpg' || extension == 'png' || extension == 'jpeg'){
        response = await http.put(Uri.parse(url), headers: {"Authorization": "Bearer $token","Content-Type": "Image/$extension"}, body: body);
      }else if(extension == 'txt'){
        response = await http.put(Uri.parse(url), headers: {"Authorization": "Bearer $token","Content-Type": "Text/$extension"}, body: body);
      }
    }else{
      response = await http.get(Uri.parse(url), headers: {"Authorization": "Bearer $token"});
    }
    
    return response;
  } catch (error) {
    print('Request error:' + error.toString());
    return null;
  }
}

Future<OneDriveIDs?> getOneDriveIDs(var token, String folder) async {
  var response = await request("https://graph.microsoft.com/v1.0/me/drive/sharedWithMe", token);
  if (response == null) {
    return null;
  }
  if (response.statusCode != 200) {
    print('Request error: ${response.statusCode}');
    return null;
  }
  var sharedItens = json.decode(response.body)['value'];

  for (var item in sharedItens) {
    if (item['name'] == folder) {
      var remoteItem = item['remoteItem'];
      var parentReference = remoteItem['parentReference'];
      OneDriveIDs oneDriveIDs =
          OneDriveIDs(token, parentReference['driveId'], remoteItem['id']);
      return oneDriveIDs;
    }
  }
  print("Folder named [$folder] was NOT found");
  return null;
}

Future<Uint8List?> downloadFile(String fileName, OneDriveIDs oneDriveIDs, [bool? showSnackBar, BuildContext? context]) async {
  if (!oneDriveIDs.check()) {
    return null;
  }

  String url = "https://graph.microsoft.com/v1.0/drives/${oneDriveIDs.driveID}/items/${oneDriveIDs.folderID}:/$fileName:/content";

  var response = await request(url, oneDriveIDs.token);
  if (response == null) {
    return null;
  }

  if (response.statusCode == 200) {
    print("File [$fileName] was successfully downloaded");
    if (showSnackBar == true && context != null) {
      showSnackbar(context, 'Download concluído com sucesso');
    }
    return response.bodyBytes;

  }else {
    print("File [$fileName] download failed");
    print('Status code:[${response.statusCode}]');
    print('Response body:[${response.body}]');
    if (showSnackBar == true && context != null) {
      showSnackbar(context, 'Falha no download, tente novamente');
    }
    return null;
  }
}

Future<bool?> uploadFile(File file, String fileName, String extension, OneDriveIDs oneDriveIDs, [bool? showSnackBar, BuildContext? context]) async {
  if (!oneDriveIDs.check()) {
    return null;
  } // ONE DRIVE IDS CHECK

  Uint8List fileBytes = File(file.path).readAsBytesSync();
  String url = "https://graph.microsoft.com/v1.0/drives/${oneDriveIDs.driveID}/items/${oneDriveIDs.folderID}:/${fileName + '.' + extension}:/content";

  var response = await request(url, oneDriveIDs.token, extension, fileBytes);
  if (response == null) {
    return null;
  }

  if (response.statusCode == 200) {
    print("File [$fileName] already exists on OneDrive");
    if (showSnackBar == true && context != null) {
      showSnackbar(context, 'Arquivo já foi enviado antreriormente');
    }
    return false;
  }
  if (response.statusCode != 201) {
    print("File [$fileName] upload failed");
    print('Status code:[${response.statusCode}]');
    print('Response body:[${response.body}]');
    if (showSnackBar == true && context != null) {
      showSnackbar(context, 'Falha no envio, tente novamente');
    }
    return null;
  }
  print("File [$fileName] uploaded successfully");
  if (showSnackBar == true && context != null) {
    showSnackbar(context, 'Arquivo enviado com sucesso');
  }
  return true;
}

Future<bool?> uploadText(String fileName, String text, OneDriveIDs oneDriveIDs, [bool? showSnackBar, BuildContext? context]) async {
  if (!oneDriveIDs.check()) {
    return null;
  } // ONE DRIVE IDS CHECK
  Uint8List fileBytes = Uint8List.fromList(utf8.encode(text));

  String url = "https://graph.microsoft.com/v1.0/drives/${oneDriveIDs.driveID}/items/${oneDriveIDs.folderID}:/${fileName + '.txt'}:/content";

  var response = await request(url, oneDriveIDs.token, 'txt', fileBytes);
  if (response == null) {
    return null;
  }

  if (response.statusCode == 200) {
    print("File [$fileName] already exists on OneDrive");
    if (showSnackBar == true && context != null) {
      showSnackbar(context, 'Arquivo já foi enviado antreriormente');
    }
    return false;
  }
  if (response.statusCode != 201) {
    print("File [$fileName] upload failed");
    print('Status code:[${response.statusCode}]');
    print('Response body:[${response.body}]');
    if (showSnackBar == true && context != null) {
      showSnackbar(context, 'Falha no envio, tente novamente');
    }
    return null;
  }
  print("File [$fileName] uploaded successfully");
  if (showSnackBar == true && context != null) {
    showSnackbar(context, 'Arquivo enviado com sucesso');
  }
  return true;
}

Future<String?> createFolder(String folderName, Directory directory) async {
  final Directory folder = Directory('${directory.path}/$folderName/');

  try {
    if (await folder.exists()) {
      return folder.path;
    } else {
      final Directory newFolder = await folder.create(recursive: true);
      return newFolder.path;
    }
  } catch (error) {
    print('Error creating folder: $error');
    return null;
  }
}

Future<File?> storeFile(Uint8List fileBytes, String fileName, String folder, Directory directory) async {
  await createFolder(folder, directory);
  String filePath = '${directory.path}/$folder/$fileName';
  File newFile = File(filePath);

  try {
    await newFile.writeAsBytes(fileBytes);
    print('File was stored successfully at: [$filePath]');
    return newFile;
  } catch (error) {
    print('Error storing file: $error');
    return null;
  }
}

Future<bool?> deleteFile(String fileName, String folder, Directory directory) async {
  String filePath = '${directory.path}/$folder/$fileName';
  File fileToDelete = File(filePath);

  try {
    if (await fileToDelete.exists()) {
      await fileToDelete.delete();
      print('File [$fileName] deleted successfully from: [$filePath]');
      return true;
    } else {
      print('File [$fileName] does not exist');
      return null;
    }
  } catch (error) {
    print('Error deleting file: $error');
    return false;
  }
}

Future<File?> moveFile(String fileName, String sourceFolder, String destinationFolder, Directory directory) async {
  // Create source and destination folder paths
  String sourcePath = '${directory.path}/$sourceFolder/$fileName';
  String destinationPath = '${directory.path}/$destinationFolder/$fileName';

  // Create a File instance for the source file
  File sourceFile = File(sourcePath);

  try {
    // Check if the source file exists
    if (await sourceFile.exists()) {

      // Ensure the destination folder exists
      await createFolder(destinationFolder, directory);

      // Construct a File instance for the destination file
      File destinationFile = File(destinationPath);

      // Perform the file move by renaming the file
      await sourceFile.rename(destinationPath);

      print('File moved successfully');
      return destinationFile;
    } else {
      print('Source file does not exist');
      return null;
    }
  } catch (error) {
    print('Error moving file: $error');
    return null;
  }
}

Future<List<File>?> getDirectoryFiles(String folder, Directory directory, [String? extension]) async {
  try {
    String folderPath = '${directory.path}/$folder/';
    Directory targetFolder = Directory(folderPath);

    // Check if the target folder exists
    if (await targetFolder.exists()) {
      List<File> files = [];

      // List all files in the folder
      List<FileSystemEntity> entities = targetFolder.listSync(recursive: true, followLinks: false);

      // Iterate through each file and filter by extension
      for (var entity in entities) {
        if (entity is File) {
          if (extension != null) {
            // Check if the file has the specified extension
            if (entity.path.endsWith('.$extension')) {
              files.add(entity);
            }
          } else {
            // If no extension specified, include all files
            files.add(entity);
          }
        }
      }

      return files;
    } else {
      print('Folder [${targetFolder.path}] does not exist');
      return null;
    }
  } catch (error) {
    print('Error retrieving files: $error');
    return null;
  }
}

Future<List<String>?> getDirectoryFileNames(String folder, Directory directory, [String? extension]) async {
  try {
    String folderPath = '${directory.path}/$folder/';
    Directory targetFolder = Directory(folderPath);

    // Check if the target folder exists
    if (await targetFolder.exists()) {
      List<String> fileNames = [];

      // List all files in the folder
      List<FileSystemEntity> entities = targetFolder.listSync(recursive: true, followLinks: false);

      // Iterate through each file and filter by extension
      for (var entity in entities) {
        if (entity is File) {
          if (extension != null) {
            // Check if the file has the specified extension
            if (entity.path.endsWith('.$extension')) {
              fileNames.add(entity.path.split('/').last);
            }
          } else {
            // If no extension specified, include all files
            fileNames.add(entity.path.split('/').last);
          }
        }
      }

      return fileNames;
    } else {
      print('Folder [${targetFolder.path}] does not exist');
      return null;
    }
  } catch (error) {
    print('Error retrieving files: $error');
    return null;
  }
}

double getTotalHeight(BuildContext context) {
  return MediaQuery.of(context).size.height;
}

double getTotalWidth(BuildContext context) {
  return MediaQuery.of(context).size.width;
}

void showInFullScreen(String imagePath, BuildContext context) {
  Navigator.push(
    context,
    new MaterialPageRoute(
      builder: (context) => FullScreenImage(imagePath: imagePath),
    ),
  );
}

class FullScreenImage extends StatelessWidget {
  final String imagePath;

  const FullScreenImage({required this.imagePath});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
        onTap: () {
          Navigator.pop(context);
        },
        child: Center(
          child: Hero(
            tag: imagePath,
            child: PhotoView(
              imageProvider: FileImage(File(imagePath)),
              enableRotation: true,
              tightMode: true,
              backgroundDecoration: BoxDecoration(color: Colors.transparent),
            ),
          ),
        ),
      ),
    );
  }
}

class SafeMenuButton extends StatefulWidget {
  final String defaultItem;
  final List<String> items;
  final Function(String)? onChanged;
  final String recoveryKey;

  SafeMenuButton({
    required this.defaultItem,
    required this.items,
    this.onChanged,
    required this.recoveryKey,
  });

  @override
  _SafeMenuButtonState createState() => _SafeMenuButtonState();
}

class _SafeMenuButtonState extends State<SafeMenuButton> {
  late String selectedItem;
  late bool _isLoading;

  @override
  void initState() {
    super.initState();
    _isLoading = true;
    _loadSelectedItem();
  }

  Future<void> _loadSelectedItem() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      selectedItem = prefs.getString(widget.recoveryKey) ?? widget.defaultItem;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return _isLoading
    ? CircularProgressIndicator() // Show a loading indicator while loading from SharedPreferences
    : ElevatedButton(
      style: selectedItem == widget.defaultItem
          ? ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
            )
          : null,
      onPressed: () {
        _showDropdownMenu(context);
      },
      child: Text(selectedItem),
    );
  }

  void _showDropdownMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          child: ListView.builder(
            itemCount: widget.items.length,
            itemBuilder: (BuildContext context, int index) {
              return ListTile(
                title: Text(widget.items[index]),
                onTap: () {
                  _updateSelectedItem(widget.items[index]);
                  Navigator.pop(context);
                },
              );
            },
          ),
        );
      },
    );
  }

  Future<void> _updateSelectedItem(String newItem) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(widget.recoveryKey, newItem);
    setState(() {
      selectedItem = newItem;
    });
    if (widget.onChanged != null) {
      widget.onChanged!(selectedItem);
    }
  }
}

String formatTimeOfDay(TimeOfDay timeOfDay) {
  //return 0925 for 9h25m
  return '${timeOfDay.hour.toString().padLeft(2, '0')}${timeOfDay.minute.toString().padLeft(2, '0')}';
}

String formatDateTime(DateTime dateTime) {
  //return 092532 for 9h25m32s
  return '${dateTime.hour.toString().padLeft(2, '0')}${dateTime.minute.toString().padLeft(2, '0')}${dateTime.second.toString().padLeft(2, '0')}';
}

String formatTimeOfDayAlt(TimeOfDay timeOfDay) {
  //return 09h25m
  return '${timeOfDay.hour.toString().padLeft(2, '0')}h${timeOfDay.minute.toString().padLeft(2, '0')}m';
}

String formatDateTimeAlt(DateTime dateTime) {
  //return 09h25m32s
  return '${dateTime.hour.toString().padLeft(2, '0')}h${dateTime.minute.toString().padLeft(2, '0')}m${dateTime.second.toString().padLeft(2, '0')}s';
}

Future<void> requestPermissions() async {
  await requestPermission(Permission.storage);
  await requestPermission(Permission.manageExternalStorage);
  await requestPermission(Permission.mediaLibrary);
  await requestPermission(Permission.camera);
  await requestPermission(Permission.photos);
}

Future<void> requestPermission(Permission permission) async {
  if (!await permission.status.isGranted) {
    await permission.request();
  }
}

MaterialColor orangeColor = MaterialColor(
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

//.replaceAll('á', 'a').replaceAll('é', 'e').replaceAll('í', 'i').replaceAll('ó', 'o').replaceAll('ú', 'u').replaceAll('à', 'a').replaceAll('è', 'e').replaceAll('ì', 'i').replaceAll('ò', 'o').replaceAll('ù', 'u').replaceAll('â', 'a').replaceAll('ê', 'e').replaceAll('î', 'i').replaceAll('ô', 'o').replaceAll('û', 'u').replaceAll('ã', 'a').replaceAll('õ', 'o')
//.replaceAll('Á', 'A').replaceAll('É', 'E').replaceAll('Í', 'I').replaceAll('Ó', 'O').replaceAll('Ú', 'U').replaceAll('À', 'A').replaceAll('È', 'E').replaceAll('Ì', 'I').replaceAll('Ò', 'O').replaceAll('Ù', 'U').replaceAll('Â', 'A').replaceAll('Ê', 'E').replaceAll('Î', 'I').replaceAll('Ô', 'O').replaceAll('Û', 'U').replaceAll('Ã', 'A').replaceAll('Õ', 'O')