import 'dart:io';
import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';


class DateString {
  late String day;
  late String month;
  late String year;
  late String hour;
  late String minute;
  late String time;
  late String date;

  DateString(DateTime dateTime) {
    day = dateTime.day.toString();
    month = dateTime.month.toString();
    year = dateTime.year.toString();
    hour = dateTime.hour.toString();
    if (hour.length < 2) {
      hour = '0' + hour;
    }
    minute = dateTime.minute.toString();
    if(minute.length < 2){
      minute = '0' + minute;
    }
    time = hour + ':' + minute;
    date = day + '/' + month + '/' + year;
  }

  @override
  String toString() {
    return '$time - $date';
  }
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
