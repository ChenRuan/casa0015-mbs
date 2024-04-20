import 'dart:async';
import 'dart:convert';
import 'dart:math' show min,max;
import 'package:eztour/plans_add_new_item_forms.dart';
import 'package:eztour/plans_add_new_item_tdl.dart';
import 'package:eztour/travel_weather_page.dart';
import 'package:flutter/material.dart';
import 'package:eztour/data.dart'; // Assuming PlanItem and other models are defined here
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:location/location.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:eztour/get_location.dart';
import 'google_api_secrets.dart';

class TravelModePage extends StatefulWidget {
  final Plan plan;

  TravelModePage({Key? key, required this.plan}) : super(key: key);

  @override
  _TravelModePageState createState() => _TravelModePageState();
}

class _TravelModePageState extends State<TravelModePage> {
  late int _currentDay;
  late int _totalDays;
  final double arrowButtonPadding = 16.0;
  List<PlanItem> _planItems = [];
  List<Map<String, dynamic>> _todoLists = [];
  PlanItem? _highlightedItem;
  PlanItem? _selectedItem;
  GoogleMapController? _mapController;
  Set<Polyline> _polylines = {};
  Set<Marker> _markers = {};
  LatLng _currentPosition = LatLng(0.0,0.0);
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    _currentDay = 1;
    _totalDays = widget.plan.travelDays;
    _loadPlanItems();
    _loadToDoLists().then((data) {
      setState(() {
        _todoLists = data;
      });
    });
    print(_planItems);
    print(widget.plan.id);
    _timer = Timer.periodic(Duration(minutes: 1), (Timer t) {
      if (_selectedItem != null) {
        _moveCameraToSelectedLocation(_selectedItem!);
      } else{
        _moveCameraToSelectedLocation(_highlightedItem!);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  Future<List<Map<String, dynamic>>> _loadToDoLists() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final keys = prefs
        .getKeys()
        .where((key) => key.startsWith('todo_${widget.plan.id}_$_currentDay'))
        .toList();
    List<Map<String, dynamic>> allLists = [];

    for (String key in keys) {
      String? savedData = prefs.getString(key);
      if (savedData != null) {
        try {
          var decodedData = jsonDecode(savedData);
          if (decodedData is Map) {
            allLists.add({
              'uid': decodedData['uid'],
              'title': decodedData['title'],
              'tasks': decodedData['tasks'],
            });
          } else {
            print("Unexpected JSON format for key $key");
          }
        } catch (e) {
          print("Error parsing ToDo list data for key $key: $e");
        }
      }
    }
    return allLists;
  }

  Widget _buildHorizontalToDoLists() {
    // Directly build the list view if data is already loaded
    if(_todoLists.isNotEmpty){
      return SizedBox(
        height: 80,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: _todoLists.length,
          itemBuilder: (context, index) {
            var listData = _todoLists[index];
            List<dynamic> tasks = listData['tasks'] as List<dynamic>;
            int completedCount = tasks.where((t) => t['completed'] as bool).length;
            bool allCompleted = completedCount == tasks.length;
            return InkWell(
              onTap: () {
                var listData = _todoLists[index];
                List<String> tasks = listData['tasks'].map<String>((t) => t['task'].toString()).toList();
                List<String> taskCompletionStatus = listData['tasks'].map<String>((t) => t['completed'].toString()).toList();
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => ToDoListPage(
                          planId: widget.plan.id,
                          day: _currentDay,
                          uid: listData['uid'],
                          title: listData['title'],
                          tasks: tasks,
                          taskCompletionStatus: taskCompletionStatus,
                        )
                    )
                );
              },
              child: Card(
                child: Container(
                  width: MediaQuery.of(context).size.width - 20,
                  child: ListTile(
                    title: Text("${listData['title']} (To Do List)"),
                    subtitle: Text(
                      allCompleted ? "All completed!" : "Already done: $completedCount/${tasks.length}",
                      style: TextStyle(color: allCompleted ? Colors.green : Colors.red),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      );
    }else{
      return SizedBox(height: 0,);
    }
  }

  String _getCurrentDate() {
    if (_currentDay >= 0) {
      DateTime startDate = widget.plan.startDate;
      DateTime currentDate = startDate.add(Duration(days: _currentDay -1));
      print(currentDate);
      return DateFormat('MMMM dd, yyyy')
          .format(currentDate); // format the date as needed
    }
    return '';
  }

  void _loadPlanItems() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String itemsKey = 'items_${widget.plan.id}';
    List<String>? itemsJson = prefs.getStringList(itemsKey);
    if (itemsJson != null) {
      List<PlanItem> items = itemsJson
          .map((itemJson) => PlanItem.fromJson(json.decode(itemJson)))
          .toList();

      items.sort((a, b) {
        int startCompare = _compareTime(a.startTime, b.startTime);
        if (startCompare != 0) return startCompare;
        return _compareTime(a.endTime, b.endTime);
      });

      setState(() {
        _planItems = items;
      });
      _highlightItemBasedOnCurrentTime();
    }
  }

  int _compareTime(String? a, String? b) {
    if (a == null || a.isEmpty) return (b == null || b.isEmpty) ? 0 : 1;
    if (b == null || b.isEmpty) return -1;
    return a.compareTo(b);
  }

  void _goToNextDay() {
    if (_currentDay < _totalDays) {
      setState(() {
        _currentDay++;
        _loadToDoLists().then((data) {
          setState(() {
            _todoLists = data;
            _moveCameraToSelectedLocation(_highlightedItem!);
          });
        });
      });
    }
  }

  void _goToPreviousDay() {
    if (_currentDay > 0) {
      setState(() {
        _currentDay--;
        _loadToDoLists().then((data) {
          setState(() {
            _todoLists = data;
            _moveCameraToSelectedLocation(_highlightedItem!);
          });
        });
      });
    }
  }

  void _editItem(String itemId) {
    final index = _planItems.indexWhere((item) => item.id == itemId);
    if (index != -1) {
      Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => DetailFormPage(
                planItem: _planItems[index],
                planId: _planItems[index].planId,
                type: _planItems[index].type,
                day: _planItems[index].day)),
      ).then((_) => _loadPlanItems());
    }
  }

  void _deleteItem(String itemId) async {
    final index = _planItems.indexWhere((item) => item.id == itemId);
    if (index != -1) {
      setState(() {
        _planItems.removeAt(index);
      });

      final prefs = await SharedPreferences.getInstance();
      final String itemsKey = 'items_${widget.plan.id}';
      await prefs.setStringList(
        itemsKey,
        _planItems.map((item) => json.encode(item.toJson())).toList(),
      );
    }
  }

  String _formatSubtitle({
    String? startTime,
    String? endTime,
    String? location,
    String? destination,
  }) {
    String timeText = '';
    if (startTime != '' || endTime != '') {
      if (startTime != '' && endTime != '') {
        timeText = '$startTime - $endTime';
      } else if (startTime != '') {
        timeText = startTime ?? '';
      } else {
        timeText = 'endTime: $endTime';
      }
    }

    String extractPlaceName(String? place) {
      if (place == null) return '';
      var parts = place.split(RegExp(r'[,|-]'));
      return parts[0]
          .trim(); // Trim to remove any leading/trailing white spaces
    }

    String locationText = '';
    if (location != "" || destination != "") {
      if (location != "" && destination != "") {
        locationText =
        '${extractPlaceName(location)} - ${extractPlaceName(destination)}';
      } else if (location != "") {
        locationText = extractPlaceName(location);
      } else {
        locationText = 'Destination: ${extractPlaceName(destination)}';
      }
    }

    if (timeText.isNotEmpty && locationText.isNotEmpty) {
      return '$timeText\n$locationText';
    } else if (timeText.isNotEmpty) {
      return timeText;
    } else if (locationText.isNotEmpty) {
      return locationText;
    }

    return '';
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    _moveCameraToSelectedLocation(_highlightedItem!); // Assumes _highlightedItem is set correctly on init

    if (_highlightedItem != null) {
      _drawInitialRoutesAndMarkers(_highlightedItem!);
    }
  }

  Future<void> _drawInitialRoutesAndMarkers(PlanItem item) async {
    // Add markers
    _updateMarkersForItem(item);

    // If there's a destination, draw the route
    if (item.destinationLat != null && item.destinationLng != null && item.placeLat != null && item.placeLng != null) {
      await _drawRoute(_mapController!, LatLng(item.placeLat!, item.placeLng!), LatLng(item.destinationLat!, item.destinationLng!), Colors.yellow, 3, "loc_to_dest");
      await _drawRoute(_mapController!, _currentPosition, LatLng(item.destinationLat!, item.destinationLng!), Colors.red, 5, "current_to_dest");
    }
  }

  void _updateMarkersForItem(PlanItem item) {
    Set<Marker> markers = {};

    // Add current position marker
    markers.add(Marker(
      markerId: MarkerId("user"),
      position: _currentPosition,
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
    ));

    // Add item's location marker
    if (item.placeLat != null && item.placeLng != null) {
      markers.add(Marker(
        markerId: MarkerId("location"),
        position: LatLng(item.placeLat!, item.placeLng!),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        infoWindow: InfoWindow(title: '${item.title}: ${item.location} '),
      ));
    }

    // Update markers on the map
    setState(() {
      _markers = markers;
    });
  }

  void _selectItem(PlanItem item) {
    setState(() {
      _selectedItem = item;
      _polylines.clear();  // Clear existing routes
      _moveCameraToSelectedLocation(item);  // Ensure map updates to new selection
    });
  }

  void _moveCameraToSelectedLocation(PlanItem item) async {
    Set<Marker> markers = {};
    List<LatLng> points = [];

    // Check for current location
    LocationData? _currentLocation = await getLocation();
    print('get current location:$_currentLocation');
    _currentPosition = _currentLocation != null ? LatLng(_currentLocation.latitude!, _currentLocation.longitude!) : _currentPosition;

    // Update markers for all plan items
    for (var planItem in _planItems) {
      if (planItem.location!.isNotEmpty && planItem.placeLat != null && planItem.placeLng != null) {
        LatLng position = LatLng(planItem.placeLat!, planItem.placeLng!);
        if (position.latitude != 0 && position.longitude != 0) {
          markers.add(Marker(
            markerId: MarkerId(planItem.id),
            position: position,
            icon: BitmapDescriptor.defaultMarkerWithHue(
                planItem == item ? BitmapDescriptor.hueRed : BitmapDescriptor
                    .hueBlue),
            infoWindow: InfoWindow(title: '${item.title}: ${item.location} '),
          ));
          points.add(position);
        }
      }
      // Add destination marker if exists
      if (planItem.destination!.isNotEmpty && planItem.destinationLat != null && planItem.destinationLng != null) {
        LatLng destPosition = LatLng(planItem.destinationLat!, planItem.destinationLng!);
        if (destPosition.latitude != 0 && destPosition.longitude != 0){
          markers.add(Marker(
            markerId: MarkerId('${planItem.id}_dest'),
            position: destPosition,
            icon: BitmapDescriptor.defaultMarkerWithHue(planItem == item ? BitmapDescriptor.hueRed : BitmapDescriptor.hueBlue),
            infoWindow: InfoWindow(title: 'Destination of ${item.title}: ${item.location} '),
          ));
          points.add(destPosition);
        }
      }
    }

    // Draw route if destination exists
    if(item.location!.isNotEmpty && item.placeLat!=null && item.placeLng!=null){
      if (item.destination!.isNotEmpty && item.destinationLat != null && item.destinationLng != null) {
        LatLng destinationPosition = LatLng(item.destinationLat!, item.destinationLng!);
        await _drawRoute(_mapController!, _currentPosition, destinationPosition, Colors.red, 5, "current_to_dest");
        await _drawRoute(_mapController!, LatLng(item.placeLat!, item.placeLng!), destinationPosition, (_selectedItem == _highlightedItem || _selectedItem == null) ? Colors.yellow : Colors.blue, 3, "loc_to_dest");
        points.add(destinationPosition);
      } else {
        await _drawRoute(_mapController!, _currentPosition, LatLng(item.placeLat ?? 0, item.placeLng ?? 0), Colors.blue, 5, "current_to_dest");
      }
    }
    // Calculate bounds to include all markers and user's current location
    if (points.isNotEmpty) {
      double minLat = points.map((p) => p.latitude).reduce(min);
      double maxLat = points.map((p) => p.latitude).reduce(max);
      double minLng = points.map((p) => p.longitude).reduce(min);
      double maxLng = points.map((p) => p.longitude).reduce(max);
      LatLngBounds bounds = LatLngBounds(
          southwest: LatLng(minLat, minLng),
          northeast: LatLng(maxLat, maxLng)
      );
      _mapController?.animateCamera(CameraUpdate.newLatLngBounds(bounds, 50.0));
      print("points: ${points}");
    } else{
      _mapController?.animateCamera(CameraUpdate.newCameraPosition(CameraPosition(target: _currentPosition, zoom: 15)));
      print("no location");
    }

    setState(() {
      _markers = markers; // Update markers
    });
  }



  Future<void> _drawRoute(GoogleMapController mapController, LatLng start, LatLng destination, Color color, int width, String routeId) async {
    String url = 'https://maps.googleapis.com/maps/api/directions/json?origin=${start.latitude},${start.longitude}&destination=${destination.latitude},${destination.longitude}&key=${Secrets.googleMapsApiKey}';
    var response = await http.get(Uri.parse(url));
    var json = jsonDecode(response.body);
    print('Route $routeId: $json'); // Debugging output

    if (json['routes'] != null && json['routes'].isNotEmpty) {
      var encodedPoly = json['routes'][0]['overview_polyline']['points'];
      var points = _decodePoly(encodedPoly);
      var line = Polyline(
        polylineId: PolylineId(routeId), // Unique ID for each polyline
        points: points,
        color: color,
        width: width,
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

  void _highlightItemBasedOnCurrentTime() {
    DateTime now = DateTime.now();
    PlanItem? closestPastItem;
    PlanItem? nextUpcomingItem;
    DateTime latestPastEndTime = DateTime(1900);  // Very old initial value for comparison.
    DateTime soonestUpcomingStartTime = DateTime(3000);  // Distant future initial value for comparison.

    for (var item in _planItems) {
      DateTime currentDate = DateTime(now.year, now.month, now.day); // Current date at midnight
      var itemStartTime = currentDate.add(Duration(hours: _getHour(item.startTime), minutes: _getMinute(item.startTime)));
      var itemEndTime = currentDate.add(Duration(hours: _getHour(item.endTime), minutes: _getMinute(item.endTime)));

      if (itemStartTime.isBefore(now) && itemEndTime.isAfter(now)) {
        _highlightedItem = item;  // Found an ongoing item
        break;
      } else if (itemStartTime.isAfter(now) && (nextUpcomingItem == null || itemStartTime.isBefore(soonestUpcomingStartTime))) {
        soonestUpcomingStartTime = itemStartTime;
        nextUpcomingItem = item;  // This will ensure the item is the nearest upcoming one.
      } else if (itemEndTime.isBefore(now) && (closestPastItem == null || itemEndTime.isAfter(latestPastEndTime))) {
        latestPastEndTime = itemEndTime;
        closestPastItem = item;  // This will ensure the item is the most recently ended one.
      }
    }

    if (_highlightedItem == null) {
      _highlightedItem = nextUpcomingItem ?? closestPastItem;  // Prioritize upcoming item if no ongoing item, otherwise the most recent past item.
    }
    print('items:${_planItems} time:${now} item:${_highlightedItem}');
  }

  int _getHour(String? time) {
    if (time == null || time.isEmpty) return 0;
    return int.parse(time.split(':')[0]);
  }

  int _getMinute(String? time) {
    if (time == null || time.isEmpty) return 0;
    return int.parse(time.split(':')[1]);
  }

  DateTime _getTime(String? time) {
    return DateTime.now().add(Duration(hours: _getHour(time), minutes: _getMinute(time)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text('Plan with Map', style: TextStyle(fontSize: 20)),
            Text('plan: ${widget.plan.name}', style: TextStyle(fontSize: 14)),
          ],
        ),
        centerTitle: true,
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.wb_sunny),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => WeatherPage(planItems: _planItems
                    .where((item) => item.day == _currentDay)
                    .toList(), title: widget.plan.name)),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
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
          _buildHorizontalToDoLists(),
          Expanded(
            child: ListView.builder(
              itemCount:
              _planItems.where((item) => item.day == _currentDay).length,
              itemBuilder: (context, index) {
                final filteredItems = _planItems
                    .where((item) => item.day == _currentDay)
                    .toList();
                final item = filteredItems[index];
                return Card(
                  color: item == _highlightedItem ? Colors.yellow[100] : (_selectedItem == item ? Colors.blue[50] : null),
                  child: ListTile(
                    title: Text('${item.title} (${item.type})'),
                    subtitle: Text(_formatSubtitle(
                      startTime: item.startTime,
                      endTime: item.endTime,
                      location: item.location,
                      destination: item.destination,
                    )),
                    onTap: () => _selectItem(item),
                    trailing: PopupMenuButton<String>(
                      onSelected: (String result) {
                        if (result == 'modify') {
                          _editItem(item.id);
                        } else if (result == 'delete') {
                          _deleteItem(item.id);
                        }
                      },
                      itemBuilder: (BuildContext context) =>
                      <PopupMenuEntry<String>>[
                        const PopupMenuItem<String>(
                          value: 'modify',
                          child: Text('Modify'),
                        ),
                        const PopupMenuItem<String>(
                          value: 'delete',
                          child: Text('Delete',
                              style: TextStyle(color: Colors.red)),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomAppBar(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 3.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Padding(
                padding: EdgeInsets.only(left: arrowButtonPadding),
                child: IconButton(
                  icon: Icon(Icons.chevron_left),
                  onPressed: _currentDay > 0 ? _goToPreviousDay : null,
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Day $_currentDay/${_totalDays}',
                      style: Theme.of(context).textTheme.titleLarge),
                  Text(_getCurrentDate()) // Displaying the date here
                ],
              ),
              Padding(
                padding: EdgeInsets.only(right: arrowButtonPadding),
                child: IconButton(
                  icon: Icon(Icons.chevron_right),
                  onPressed: _currentDay < _totalDays ? _goToNextDay : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
