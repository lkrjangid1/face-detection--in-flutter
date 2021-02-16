import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_ml_vision/firebase_ml_vision.dart';
import 'dart:ui' as ui;

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: FaceDetectorHome(),
    );
  }
}
class FaceDetectorHome extends StatefulWidget {
  FaceDetectorHome({Key key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _FaceDetectorHomeState();
}

class _FaceDetectorHomeState extends State<FaceDetectorHome> {
  File image;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        key: _scaffoldKey,
        appBar: AppBar(
          centerTitle: true,
          title: Text('Face Detection'),
        ),
        body: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                buildRowTitle(context, 'Pick Image'),
                buildSelectImageRowWidget(context)
              ],
            )
        )
    );
  }

  Widget buildRowTitle(BuildContext context, String title) {
    return Center(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 16.0),
          child: Text(
            title,
            style: Theme.of(context).textTheme.headline,
          ),
        )
    );
  }

  Widget buildSelectImageRowWidget(BuildContext context) {
    return Row(
      children: <Widget>[
        createButton('Camera'),
        createButton('Gallery')
      ],
    );
  }

  Widget createButton(String imgSource) {
    return Expanded(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 8.0),
          child: RaisedButton(
              color: Colors.blue,
              textColor: Colors.white,
              splashColor: Colors.blueGrey,
              onPressed: () {
                onPickImageSelected(imgSource);
              },
              child: new Text(imgSource)),
        )
    );
  }


  onPickImageSelected(String imgSource) async {
    var src;
    if(imgSource == 'Gallery')
      src = ImageSource.gallery;
    else
      src = ImageSource.camera;
    File img = await ImagePicker.pickImage(source: src);
    Navigator.push(
      context,
      new MaterialPageRoute(
          builder: (context) => FaceDetection(img)),
    );
  }
}


class FaceDetection extends StatefulWidget {

  File file;
  FaceDetection(File file) {
    this.file = file;
  }
  // FaceDetection(this.file);

  @override
  _FaceDetectionState createState() => _FaceDetectionState();
}

class _FaceDetectionState extends State<FaceDetection> {
  ui.Image image;
  List<Face> faces;
  var result = "";

  @override
  void initState() {
    super.initState();
    detectFaces();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text("Face Detection"),
        ),
        body: (image == null) ? Center(child: CircularProgressIndicator(),):
        Center(
          child: FittedBox(
            child: SizedBox(
                width: image.width.toDouble(),
                height: image.width.toDouble(),
                child: CustomPaint(painter: FacePainter(image, faces))
            ),
          ),
        )
    );
  }

  void loadImage(File file) async {
    final data = await file.readAsBytes();
    await decodeImageFromList(data).then(
          (value) => setState(() {
        image = value;
      }),
    );
  }


  void detectFaces() async{
    final FirebaseVisionImage visionImage = FirebaseVisionImage.fromFile(widget.file);
    final FaceDetector faceDetector = FirebaseVision.instance.faceDetector(FaceDetectorOptions(
        mode: FaceDetectorMode.accurate,
        enableLandmarks: true,
        enableClassification: true
    ));
    List<Face> detectedFaces = await faceDetector.processImage(visionImage);
    for (var i = 0; i < detectedFaces.length; i++) {
      final double smileProbablity = detectedFaces[i].smilingProbability;
      print("Smiling Probablity for $i: $smileProbablity");
    }
    faces = detectedFaces;
    loadImage(widget.file);
  }
}

class FacePainter extends CustomPainter {
  ui.Image image;
  List<Face> faces;
  final List<Rect> rects = [];

  FacePainter(ui.Image img, List<Face> faces) {
    this.image = img;
    this.faces = faces;
    for (var i = 0; i < faces.length; i++) {
      rects.add(faces[i].boundingBox);
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8.0
      ..color = Colors.red;

    canvas.drawImage(image, Offset.zero, Paint());
    for (var i = 0; i < faces.length; i++) {
      canvas.drawRect(rects[i], paint);
    }
  }

  @override
  bool shouldRepaint(FacePainter oldDelegate) {
    return image != oldDelegate.image || faces != oldDelegate.faces;
  }
}