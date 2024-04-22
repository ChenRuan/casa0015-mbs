import 'package:EzTour/data.dart';
import 'package:EzTour/get_location.dart';
import 'package:EzTour/google_api_secrets.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_places_flutter/google_places_flutter.dart';
import 'package:google_places_flutter/model/prediction.dart';
import 'package:location/location.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:uuid/uuid.dart';
import 'package:http/http.dart' as http;

class DetailFormPage extends StatefulWidget {
  final String planId;
  final String type;
  final int day;
  String? id;
  PlanItem? planItem;

  DetailFormPage({Key? key, this.planItem, this.id, required this.planId, required this.type, required this.day}) : super(key: key);

  @override
  _DetailFormPageState createState() => _DetailFormPageState();
}

class _DetailFormPageState extends State<DetailFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _locationController = TextEditingController();
  final _destinationController = TextEditingController();
  final _startTimeController = TextEditingController();
  final _endTimeController = TextEditingController();
  final _notesController = TextEditingController();
  late GoogleMapController mapController;
  late LatLng _currentPosition;
  LatLng? _destinationPosition;
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};
  final FocusNode _locationFocusNode = FocusNode();
  final FocusNode _destinationFocusNode = FocusNode();

  @override
  void dispose() {
    mapController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _initializePage();
  }

  void _initializePage() async {
    LocationData? currentLocation = await getLocation(); // Get current location
    if (currentLocation != null) {
      _currentPosition = LatLng(currentLocation.latitude!, currentLocation.longitude!);
    } else {
      _currentPosition = LatLng(51.508530, -0.076132);
    }

    if (widget.planItem != null) {
      _titleController.text = widget.planItem!.title;
      _startTimeController.text = widget.planItem!.startTime ?? '';
      _endTimeController.text = widget.planItem!.endTime ?? '';
      _locationController.text = widget.planItem!.location ?? '';
      _destinationController.text = widget.planItem!.destination ?? '';
      if (widget.planItem!.placeLat != null && widget.planItem!.placeLng != null) {
        _currentPosition = LatLng(widget.planItem!.placeLat!, widget.planItem!.placeLng!);
      }
      if (widget.planItem!.destinationLat != null && widget.planItem!.destinationLng != null) {
        _destinationPosition = LatLng(widget.planItem!.destinationLat!, widget.planItem!.destinationLng!);
      }
      _notesController.text = widget.planItem!.notes ?? '';
    }
    setState(() {});
  }

  void _loadAndDrawRoute() {
    if (_currentPosition != null && _destinationPosition != null) {
      _updateMarkers();
      _drawRoute(mapController, _currentPosition, _destinationPosition!);
    }
  }

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
    _updateMapLocation();
    mapController.animateCamera(CameraUpdate.newLatLng(_currentPosition!));
    if (_currentPosition != null && _destinationPosition != null) {
      _loadAndDrawRoute();
    }
  }

  void _updateMapLocation() {
    print('enter update function');
    _updateMarkers();
    if (_currentPosition != null && _destinationPosition == null) {
      mapController.animateCamera(CameraUpdate.newLatLng(_currentPosition!));
    }else if(_currentPosition == null && _destinationPosition != null){
      mapController.animateCamera(CameraUpdate.newLatLng(_destinationPosition!));
    }else if(_currentPosition != null && _destinationPosition != null){
      print('drawing...');
      _drawRoute(mapController,_currentPosition,_destinationPosition!);
      print('draw succeed');
    }
  }

  void _updateMarkers() {
    _markers.clear();  // Clear existing markers
    // Add start location marker
    if (_currentPosition != null) {
      _markers.add(Marker(
        markerId: MarkerId("start"),
        position: _currentPosition,
        infoWindow: InfoWindow(title: "Start", snippet: "Start Location"),
      ));
    }

    // Add destination location marker
    if (_destinationPosition != null) {
      _markers.add(Marker(
        markerId: MarkerId("destination"),
        position: _destinationPosition!,
        infoWindow: InfoWindow(title: "Destination", snippet: "Destination Location"),
      ));
    }
  }

  Future<void> _drawRoute(GoogleMapController mapController, LatLng start, LatLng destination) async {
    String url = 'https://maps.googleapis.com/maps/api/directions/json?origin=${start.latitude},${start.longitude}&destination=${destination.latitude},${destination.longitude}&key=${Secrets.googleMapsApiKey}';
    var response = await http.get(Uri.parse(url));
    var json = jsonDecode(response.body);
    print(json);

    if (json['routes'] != null && json['routes'].isNotEmpty) {
      var encodedPoly = json['routes'][0]['overview_polyline']['points'];
      var points = _decodePoly(encodedPoly);
      var line = Polyline(
        polylineId: PolylineId('route'),
        points: points,
        color: Colors.blue,
        width: 5,
      );
      setState(() {
        _polylines.add(line);
      });
      LatLngBounds bounds = _bounds(points);
      CameraUpdate update = CameraUpdate.newLatLngBounds(bounds, 30);
      mapController.animateCamera(update);
    }
  }

  List<LatLng> _decodePoly(String encoded) {
    List<LatLng> points = [];
    int index = 0, len = encoded.length;
    int lat = 0, lng = 0;

    while (index < len) {
      int b, shift = 0, result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;

      LatLng p = LatLng((lat / 1E5).toDouble(), (lng / 1E5).toDouble());
      points.add(p);
    }
    return points;
  }

  LatLngBounds _bounds(List<LatLng> points) {
    double? south, west, north, east;
    for (LatLng point in points) {
      if (south == null || point.latitude < south) south = point.latitude;
      if (north == null || point.latitude > north) north = point.latitude;
      if (west == null || point.longitude < west) west = point.longitude;
      if (east == null || point.longitude > east) east = point.longitude;
    }
    return LatLngBounds(southwest: LatLng(south!, west!), northeast: LatLng(north!, east!));
  }


  Future<void> _saveItem() async {
    if (_formKey.currentState!.validate()) {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String itemsKey = 'items_${widget.planId}';
      List<String> itemsList = prefs.getStringList(itemsKey) ?? [];
      Uuid uuid = Uuid();

      PlanItem newItem = PlanItem(
        id: widget.planItem != null ? widget.planItem!.id : uuid.v4(),
        planId: widget.planId,
        day: widget.day,
        type: widget.type,
        title: _titleController.text,
        startTime: _startTimeController.text.isNotEmpty ? _startTimeController.text : null,
        endTime: _endTimeController.text.isNotEmpty ? _endTimeController.text : null,
        location: _locationController.text.isNotEmpty ? _locationController.text : null,
        destination: _destinationController.text.isNotEmpty ? _destinationController.text : null, // Save destination
        placeLat: _currentPosition?.latitude,
        placeLng: _currentPosition?.longitude,
        destinationLat: _destinationPosition?.latitude,
        destinationLng: _destinationPosition?.longitude,
        notes: _notesController.text,
      );
      String itemJson = json.encode(newItem.toJson());
      if (widget.planItem != null){
        // 修改现有计划
        final index = itemsList.indexWhere((planItem) =>
        PlanItem.fromJson(json.decode(planItem)).id == widget.planItem!.id);
        if (index != -1) {
          itemsList[index] = itemJson;
        }
        await prefs.setStringList(itemsKey, itemsList);
      }else{
        itemsList.add(itemJson);
        await prefs.setStringList(itemsKey, itemsList);
        Navigator.pop(context);
      }
      Future.delayed(Duration(milliseconds: 300), () {
        Navigator.pop(context);
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Item saved!')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Add ${widget.type} Item'),
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.check),
            onPressed: _saveItem,
            //onPressed: manualUpdate,
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: EdgeInsets.all(16.0),
          children: <Widget>[
            Visibility(
              visible: widget.type!='To Do List',
              child: Container(
                height: 150.0,
                child: GoogleMap(
                  onMapCreated: _onMapCreated,
                  initialCameraPosition: CameraPosition(
                    target: _currentPosition,
                    zoom: 10.0,
                  ),
                  markers: Set.from(_markers),  // Ensure you're using the correct Set of markers
                  polylines: _polylines,  // Ensure this Set is being updated correctly
                  mapType: MapType.normal,
                  myLocationEnabled: true,
                ),
              ),
            ),
            TextFormField(
              controller: _titleController,
              decoration: InputDecoration(labelText: 'Item Name'),
              validator: (value) {
                if (value?.isEmpty ?? true) {
                  return 'Please enter the item name';
                }
                return null;
              },
            ),
            placesAutoCompleteTextField(widget.type,true),
            Visibility(
                visible: widget.type == 'Transportation',
                child:placesAutoCompleteTextField(widget.type,false),
            ),
            Row(
              children: <Widget>[
                Expanded(
                  child: TextFormField(
                    onTap: () async {
                      TimeOfDay? picked = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay.now(),
                      );
                      if (picked != null) {
                        _startTimeController.text = picked.format(context); // 格式化并更新显示
                      }
                    },
                    controller: _startTimeController,
                    decoration: InputDecoration(labelText: 'Start Time'),
                  ),
                ),
                Text('_       '),
                Expanded(
                  child: TextFormField(
                    onTap: () async {
                      TimeOfDay? picked = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay.now(),
                      );
                      if (picked != null) {
                        _endTimeController.text = picked.format(context);
                      }
                    },
                    controller: _endTimeController,
                    decoration: InputDecoration(labelText: 'End Time'),
                  ),
                ),
              ],
            ),
            TextFormField(
              controller: _notesController,
              decoration: InputDecoration(labelText: 'Notes'),
            ),
          ],
        ),
      ),
    );
  }

  placesAutoCompleteTextField(String type, bool? isStart) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 0),
      child: GooglePlaceAutoCompleteTextField(
        textEditingController: isStart! ? _locationController : _destinationController,
        googleAPIKey: Secrets.googleMapsApiKey,
        focusNode: isStart ? _locationFocusNode : _destinationFocusNode,
        inputDecoration: InputDecoration(
          labelText: widget.type == 'Transportation' ? (isStart! ? "Departure" : "Destination") : "Location",
        ),
        boxDecoration: NewBoxDecoration(),
        debounceTime: 500,
        countries: null,
        isLatLngRequired: true,
        getPlaceDetailWithLatLng: (Prediction prediction) {
          setState(() {
            LatLng newPosition = LatLng(double.parse(prediction.lat!), double.parse(prediction.lng!));
            if (isStart) {
              _currentPosition = newPosition;
            } else {
              _destinationPosition = newPosition;
            }
            _updateMarkers();
            if (_currentPosition != null && _destinationPosition != null) {
              _drawRoute(mapController, _currentPosition, _destinationPosition!);
            }
            mapController.animateCamera(CameraUpdate.newLatLng(newPosition));
          });
        },

        itemClick: (Prediction prediction) {
          TextEditingController controller = isStart ? _locationController : _destinationController;
          controller.text = prediction.description ?? "";
          FocusNode focusNode = isStart ? _locationFocusNode : _destinationFocusNode;
          focusNode.unfocus();
        },
        seperatedBuilder: Divider(),
        containerHorizontalPadding: 0,

        // OPTIONAL// If you want to customize list view item builder
        itemBuilder: (context, index, Prediction prediction) {
          return Container(
            //padding: EdgeInsets.all(0.01),
            child: Row(
              children: [
                //Icon(Icons.location_on),
                SizedBox(
                  width: 5,
                ),
                Expanded(child: Text("${prediction.description ?? ""}"))
              ],
            ),
          );
        },
        isCrossBtnShown: false,
        // default 600 ms ,
      ),
    );
  }
}

NewBoxDecoration(){
  return BoxDecoration(
    shape: BoxShape.rectangle,
  );
}


