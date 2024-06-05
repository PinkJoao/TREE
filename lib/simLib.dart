import 'dart:io';
import 'dart:convert' show json, utf8;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:developer';


class OneDriveIDs{
  String token;
  String folder;
  String? driveID;
  String? folderID;
  bool initialized = false;

  OneDriveIDs(this.token, this.folder, [this.driveID, this.folderID]);

  Future<OneDriveIDs?> initialize() async {
    if(initialized){
      return OneDriveIDs(token, folder, driveID, folderID);
    }
    http.Response? response = await requestAccess("https://graph.microsoft.com/v1.0/me/drive/sharedWithMe", token);
    if (response == null) {
      log('Failed to initialize OneDriveIDs');
      return null;
    }

    if (response.statusCode != 200) {
      log('Request error: ${response.statusCode}');
      return null;
    }

    var sharedItems = json.decode(response.body)['value'];

    for (var item in sharedItems) {
      if (item['name'] == folder) {
        var remoteItem = item['remoteItem'];
        var parentReference = remoteItem['parentReference'];
        driveID = parentReference['driveId'];
        folderID = remoteItem['id'];
        initialized = true;
        return OneDriveIDs(token, folder, driveID, folderID);
      }
    }
    log('Folder named [$folder] was NOT found');
    return null;
  }

  bool check() {
    if(initialized != true){
      log('OneDriveIDs was not initialized yet');
      return false;

    }else if (folderID != null && driveID != null) {
      return true;

    } else {
      log('OneDrive IDs are not available');
      return false;
    }
  }

  Future<http.Response?> requestAccess(String url, var token) async {
    try {
      http.Response? response = await http.get(Uri.parse(url), headers: {"Authorization": "Bearer $token"});
      return response;

    } catch (error) {
      log('Request error: ${error.toString()}');
      return null;
    }
  }
}



class OneDriveManager{
  OneDriveIDs oneDriveIDs;
  Key? key;
  String? token;
  List<String> filesToDownload = [];
  List<Map<String, String>> filesToUpload = [];
  Directory downloadFolder;
  bool pauseDown = false;
  bool cancelDown = false;
  bool pauseUp = false;
  bool cancelUp = false;

  OneDriveManager(this.oneDriveIDs, this.downloadFolder, [this.key]){
    if(!oneDriveIDs.initialized){
      oneDriveIDs.initialize().then((value) => token = oneDriveIDs.token);
    }
  }

  void showSnackbar(BuildContext context, String message, [int? time]) {
    final snackBar = SnackBar(
      content: Container(
        padding: const EdgeInsets.all(12),
        height: 40,
        decoration: BoxDecoration(
          color: Colors.grey[700],
          borderRadius: const BorderRadius.all(Radius.circular(10)),
        ),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(
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

  // ------------------------------------- DOWNLOAD --------------------------------------------- //

  addFileListToDownload(List<String> fileNames, [bool debugPrint = true]){
    for(String fileName in fileNames.reversed){
      addFileToDownload(fileName, false);
    }
    if(debugPrint){
      log('The files $fileNames were added to the download list');
    }
  }

  addFileToDownload(String fileName, [bool debugPrint = true]){
    filesToDownload.insert(0, fileName);
    if(debugPrint){
      log('File [$fileName] added to the download list');
    }
  }

  pauseDownload([bool? showSnackBar, BuildContext? context]){
    if(!pauseDown){
      pauseDown = true;
    }
    if(showSnackBar == true && context != null){
      showSnackbar(context, 'Pausando download');
    }
  }
  
  cancelDowload([bool? showSnackBar, BuildContext? context]){
    pauseDownload();
    if(!cancelDown){
      cancelDown = true;
      if(showSnackBar == true && context != null){
        showSnackbar(context, 'Cancelando download');
      }
    }
  }

  Future startDownload([bool? showSnackBar, BuildContext? context]) async { // IN PROGRESS
    if(!oneDriveIDs.initialized){
      return;
    }
    while(filesToDownload.isNotEmpty && pauseDown == false){
      log('Downloading file [${filesToDownload.first}]');
      Uint8List? fileBytes = await downloadFile(filesToDownload.first);
      if(fileBytes != null){
        log('file [${filesToDownload.first}] was successfully downloaded');
        File? file = await storeFile(fileBytes, filesToDownload.first);
        if(file != null){
          filesToDownload.remove(filesToDownload.first);
        }
      }
    }
    if(pauseDown){
      pauseDown = false;
    }
    if(cancelDown){
      filesToDownload.clear();
      cancelDown = false;
    }
  }

  // ------------------------------------- UPLOAD --------------------------------------------- //

  addFileListToUpload(List<Map<String, String>> files, [bool debugPrint = true]){
    for(Map<String, String> file in files.reversed){
      if(file['name'] != null && file['path'] != null){
        addFileToUpload(file['name']!, file['path']!, false);
      }
    }
    if(debugPrint){
      log('The files $files were added to the upload list');
    }
  }

  addFileToUpload(String fileName, String filePath, [bool debugPrint = true]){
    filesToUpload.insert(0, {'file': fileName, 'path': filePath});
    if(debugPrint){
      log('File [$fileName] added to the upload list');
    }
  }

  pauseUpload([bool? showSnackBar, BuildContext? context]){
    if(!pauseUp){
      pauseUp = true;
    }
    if(showSnackBar == true && context != null){
      showSnackbar(context, 'Pausando upload');
    }
  }
  
  cancelUpload([bool? showSnackBar, BuildContext? context]){
    pauseDownload();
    if(!cancelUp){
      cancelUp = true;
      if(showSnackBar == true && context != null){
        showSnackbar(context, 'Cancelando download');
      }
    }
  }

  Future startUpload([bool? showSnackBar, BuildContext? context]) async { // IN PROGRESS
    if(!oneDriveIDs.initialized){
      return;
    }
    while(filesToUpload.isNotEmpty && pauseUp == false){
      log('Uploading file [${filesToUpload.first['file']}]');

      bool wasUploaded = await uploadFile(File(filesToUpload.first['path']!), filesToUpload.first['file']!) ?? false;

      if(wasUploaded){
        log('file [${filesToUpload.first['file']}] was successfully uploaded');
        filesToUpload.remove(filesToUpload.first);
      }
    }
    if(pauseUp){
      pauseUp = false;
    }
    if(cancelUp){
      filesToUpload.clear();
      cancelUp = false;
    }
  }

  // ------------------------------------- OTHER --------------------------------------------- //
  
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
      log('Request error: ${error.toString()}');
      return null;
    }
  }

  Future<Uint8List?> downloadFile(String fileName, [bool? showSnackBar, BuildContext? context]) async {
    if (!oneDriveIDs.check()) {
      return null;
    }

    String url = "https://graph.microsoft.com/v1.0/drives/${oneDriveIDs.driveID}/items/${oneDriveIDs.folderID}:/$fileName:/content";

    var response = await request(url, oneDriveIDs.token);
    if (response == null) {
      return null;
    }

    if (response.statusCode == 200) {
      log("File [$fileName] was successfully downloaded");
      if (showSnackBar == true && context != null) {
        showSnackbar(context, 'Download concluído com sucesso');
      }
      return response.bodyBytes;

    }else {
      log("Failed to download the file [$fileName]");
      log('Status code:[${response.statusCode}]');
      log('Response body:[${response.body}]');
      if (showSnackBar == true && context != null) {
        showSnackbar(context, 'Falha no download, tente novamente');
      }
      return null;
    }
  }

  Future<bool?> uploadFile(File file, String fileName, [bool? showSnackBar, BuildContext? context]) async {
    if (!oneDriveIDs.check()) {
      return null;
    }

    Uint8List fileBytes = file.readAsBytesSync();
    String url = "https://graph.microsoft.com/v1.0/drives/${oneDriveIDs.driveID}/items/${oneDriveIDs.folderID}:/$fileName:/content";

    var response = await request(url, oneDriveIDs.token, fileName.split('.').last, fileBytes);
    if (response == null) {
      return null;
    }

    if (response.statusCode == 200) {
      log("File [$fileName] already exists on OneDrive");
      if (showSnackBar == true && context != null) {
        showSnackbar(context, 'Arquivo já foi enviado antreriormente');
      }
      return false;
    }
    if (response.statusCode != 201) {
      log("File [$fileName] upload failed");
      log('Status code:[${response.statusCode}]');
      log('Response body:[${response.body}]');
      if (showSnackBar == true && context != null) {
        showSnackbar(context, 'Falha no envio, tente novamente');
      }
      return null;
    }
    log("File [$fileName] uploaded successfully");
    if (showSnackBar == true && context != null) {
      showSnackbar(context, 'Arquivo enviado com sucesso');
    }
    return true;
  }

  Future<bool?> uploadText(String fileName, String text, [bool? showSnackBar, BuildContext? context]) async {
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
      log("File [$fileName] already exists on OneDrive");
      if (showSnackBar == true && context != null) {
        showSnackbar(context, 'Arquivo já foi enviado antreriormente');
      }
      return false;
    }
    if (response.statusCode != 201) {
      log("File [$fileName] upload failed");
      log('Status code:[${response.statusCode}]');
      log('Response body:[${response.body}]');
      if (showSnackBar == true && context != null) {
        showSnackbar(context, 'Falha no envio, tente novamente');
      }
      return null;
    }
    log("File [$fileName] uploaded successfully");
    if (showSnackBar == true && context != null) {
      showSnackbar(context, 'Arquivo enviado com sucesso');
    }
    return true;
  }

  Future<File?> storeText(String fileName, String text) async {
    Uint8List fileBytes = Uint8List.fromList(utf8.encode(text));
    File? storedFile = await storeFile(fileBytes, fileName.split('.').first + '.txt');
    return storedFile;
  }

  Future<String?> createFolder() async {
    try {
      if (await downloadFolder.exists()) {
        return downloadFolder.path;
      } else {
        final Directory newFolder = await downloadFolder.create(recursive: true);
        return newFolder.path;
      }
    } catch (error) {
      log('Error creating folder: $error');
      return null;
    }
  }

  Future<File?> storeFile(Uint8List fileBytes, String fileName) async {
    await createFolder();
    String filePath = '${downloadFolder.path}/$fileName';
    File newFile = File(filePath);

    try {
      await newFile.writeAsBytes(fileBytes);
      log('File was stored successfully at: [$filePath]');
      return newFile;
    } catch (error) {
      log('Error storing file: $error');
      return null;
    }
  }
  
}







  