import 'dart:convert';

import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:barcode_scan/barcode_scan.dart';
import 'package:flutter/services.dart';
import 'package:location/location.dart';
//LatLng camera = LatLng(46.549453, 15.6357814);
//

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter map',
      theme: ThemeData(
        primarySwatch: Colors.green,
      ),
      home: HomePage(),
    );
  }
}

Completer<GoogleMapController> _controller = Completer();
LatLng pos = new LatLng(46.543413151792215, 15.633560679852962);


List<String> izpisiX = new List<String>();
List<String> izpisiY = new List<String>();
List<String> izpisiQR = new List<String>();

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

String result = "Električni skiroji v Mariboru";

class _HomePageState extends State<HomePage> {
  BitmapDescriptor customIcon;
  Set<Marker> markers;



  @override
  void initState() {
    super.initState();

    markers = Set.from([]);
    
    getData();
  }

Future getData() async{
      var urlX = 'https://flutterappskiro.000webhostapp.com/getX.php';
      var urlY = 'https://flutterappskiro.000webhostapp.com/getY.php';
      http.Response responseX = await http.get(urlX);
      http.Response responseY = await http.get(urlY);
      String dataX = responseX.body.toString();
      String dataY = responseY.body.toString();
      izpisiX = dataX.split(",");
      izpisiX.removeLast();




      izpisiY = dataY.split(",");
      izpisiY.removeLast();
      print("hello izpisi length v getData: " + izpisiX.length.toString());

      print("test" + izpisiY[0]);



      for(int i=0;i<izpisiX.length;i++){
        print("zdravo" + i.toString());

        var corX =   double.parse(izpisiX[i]);
        var corY =   double.parse(izpisiY[i]);
        pos = new LatLng(corX, corY);

        print("Delam marker na poziciji X: " + corX.toString() + " in Y: " + corY.toString());

        setState(() {
          markers.add(
              Marker(
                  markerId: MarkerId(i.toString()),
                  position: new LatLng(corX, corY),
                  icon: customIcon
              )
          );
        });

      }





    }


  createMarker(context) {
    if (customIcon == null) {
      ImageConfiguration configuration = createLocalImageConfiguration(context);
      BitmapDescriptor.fromAssetImage(configuration, 'assets/skuterLogo.png')
          .then((icon) {
        setState(() {
          customIcon = icon;
        });
      });
    }
  }

  

  Future _scanQR() async{
    try{
      var qrResult = await BarcodeScanner.scan();

      String bazaQR = qrResult.rawContent;

      //preveri v bazi
      var urlQR = 'https://flutterappskiro.000webhostapp.com/getQR.php';
      http.Response responseQR = await http.get(urlQR);
      String dataQR = responseQR.body.toString();
      
      izpisiQR = dataQR.split(",");
      izpisiQR.removeLast();

      bool obstajaQR = false;

     if(izpisiQR.contains(bazaQR)){
          obstajaQR = true;
        }
        else{
          obstajaQR = false;
        }
      
      //

      if(obstajaQR){
        
      
      setState(() {
      result = qrResult.rawContent;

        Navigator.push(context, MaterialPageRoute(builder: (context) => UporabaSkiroja()));
        print("Skeniral sem: " + result);
      });

      }
      else{
        setState(() {
          return showDialog(context: context,
          builder: (BuildContext context) {
             return AlertDialog(
        title: Text('Opozorilo'),
        content: SingleChildScrollView(
          child: ListBody(
            children: <Widget>[
              Text('Skiro s QR kodo: ' + result + ' ne ostaja'),
            ],
          ),
        ));
          });
          
        });
      }
    }on PlatformException catch(ex){
      if(ex.code == BarcodeScanner.cameraAccessDenied){
        setState(() {
          result = "Camera permission was denied";
        });
        
      }else{
        setState(() {
          result = "Uknown Error $ex";
        });
      }
    } on FormatException{
      setState(() {
        result = "You pressed the back button before scanning";
      });
    } catch(ex){

    }

  }


  @override
  Widget build(BuildContext context) {

      ImageConfiguration configuration = createLocalImageConfiguration(context);
      BitmapDescriptor.fromAssetImage(configuration, 'assets/skuterLogo.png')
          .then((icon) {
        setState(() {
          customIcon = icon;
        });
      });

    //getData();

  CameraPosition initialLocation = CameraPosition(
      zoom: 14,
      bearing: 30,
      target: LatLng(46.549453, 15.6357814)
   );

  return Scaffold(
    appBar: AppBar(
      title: Text("Električni skiroji v Mariboru"),
    ),
    body: GoogleMap(
        myLocationEnabled: true,
        markers: markers,
        initialCameraPosition: initialLocation,
        onMapCreated: (GoogleMapController controller) {
        _controller.complete(controller);

   }),
   floatingActionButton: FloatingActionButton.extended(
     icon: Icon(Icons.camera_alt),
     label: Text("Scan QR"),
     onPressed: _scanQR,
     
     ),
     floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
  );

    
}}

class UporabaSkiroja extends StatelessWidget {
  
  bool nevidnostStart = true;

  bool nevidnostStop = true;

  String testLoc = "Dodaj lokacijo";
  
  void dodajLokacijo() async{

    Location location = new Location();

    bool _serviceEnabled;
    PermissionStatus _permissionGranted;
    LocationData _locationData;

_serviceEnabled = await location.serviceEnabled();
if (!_serviceEnabled) {
  _serviceEnabled = await location.requestService();
  if (!_serviceEnabled) {
    return;
  }
}

_permissionGranted = await location.hasPermission();
if (_permissionGranted == PermissionStatus.denied) {
  _permissionGranted = await location.requestPermission();
  if (_permissionGranted != PermissionStatus.granted) {
    return;
  }
}

_locationData = await location.getLocation();

if(_locationData!=null){
  print("LOKACIJA JE");

  String latitude = _locationData.latitude.toString();
  String longitude = _locationData.longitude.toString();
  
  var url = 'https://flutterappskiro.000webhostapp.com/updateLocation.php';
 
  // Store all data with Param Name.
  var data = {'latitude': latitude, 'longitude': longitude, 'qrCode' : result};
 
  // Starting Web API Call.
  var response = await http.post(url, body: json.encode(data));
}


  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Skiro #" + result),
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            new Image.asset("assets/location-png-4.png"),
            /*Visibility(visible: nevidnostStart, child:  RaisedButton(
              color: Colors.green,
            onPressed: () {


            },
            child: Text('Start', style: TextStyle(fontSize: 20)),
          ),),
            
          
          const SizedBox(height: 30),
          Visibility(
            visible: nevidnostStop,
            child: RaisedButton(
            color: Colors.yellow,
            onPressed: () {
              
              
                nevidnostStart = true;
                nevidnostStop = true;
              
      },
            child: const Text('Pause', style: TextStyle(fontSize: 20)),
          ),),*/
          Visibility(
            visible: nevidnostStop,
            child: RaisedButton(
            color: Colors.green,
            onPressed: () {
              
        dodajLokacijo();
              
      },
            child: const Text('Dodaj novo lokacijo', style: TextStyle(fontSize: 20)),
          ),),
          
          const SizedBox(height: 30),
          
          new Image.asset("assets/skuterLogo.png")
          ],
        )

      ),
    );
  }
}