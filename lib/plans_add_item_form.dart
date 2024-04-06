import 'package:eztour/data.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_places_flutter/google_places_flutter.dart';
import 'package:google_places_flutter/model/prediction.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:uuid/uuid.dart';

class DetailFormPage extends StatefulWidget {
  final String planId;
  final String type;
  final int day;
  PlanItem? planItem;

  DetailFormPage({Key? key, this.planItem, required this.planId, required this.type, required this.day}) : super(key: key);

  @override
  _DetailFormPageState createState() => _DetailFormPageState();
}

class _DetailFormPageState extends State<DetailFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _locationController = TextEditingController();
  final _startTimeController = TextEditingController();
  final _endTimeController = TextEditingController();
  final _notesController = TextEditingController();
  late GoogleMapController mapController;
  final LatLng _initialPosition = LatLng(-34.397, 150.644);
  LatLng _currentPosition = LatLng(-34.397, 150.644);

  @override
  void initState() {
    super.initState();
    if (widget.planItem != null) {
      _titleController.text = widget.planItem!.title;
      _startTimeController.text = widget.planItem!.startTime ?? '';
      _endTimeController.text = widget.planItem!.endTime ?? '';
      _locationController.text = widget.planItem!.location ?? '';
      if (widget.planItem!.placeLat != null && widget.planItem!.placeLng != null) {
        _currentPosition = LatLng(widget.planItem!.placeLat!, widget.planItem!.placeLng!);
      }
      _notesController.text = widget.planItem!.notes ?? '';
    }
  }

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
  }

  Future<void> _saveItem() async {
    if (_formKey.currentState!.validate()) {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String itemsKey = 'items_${widget.planId}';
      List<String> itemsList = prefs.getStringList(itemsKey) ?? [];
      Uuid uuid = Uuid();

      Map<String, dynamic> newItem = {
        'id': uuid.v4(),
        'planId': widget.planId,
        'day': widget.day, // 示例，根据实际逻辑设置
        'type': widget.type,
        'title': _titleController.text,

        // 以下是条件性添加的属性

        if (_startTimeController.text.isNotEmpty) 'startTime': _startTimeController.text,
        if (_endTimeController.text.isNotEmpty) 'endTime': _endTimeController.text,
        if (_locationController.text.isNotEmpty) 'location': _locationController.text,
        if (_currentPosition != null) 'placeLat': _currentPosition.latitude,
        if (_currentPosition != null) 'placeLng': _currentPosition.longitude,
        // 添加更多属性...
      };

      // 如果有额外的可选属性，根据是否有值决定是否添加到newItem中
      // 例如：if (time != null) newItem['time'] = time.format(context);

      itemsList.add(json.encode(newItem));
      await prefs.setStringList(itemsKey, itemsList);
      if (widget.planItem == null){
        Navigator.pop(context);
      }
      Navigator.pop(context);
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
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: EdgeInsets.all(16.0),
          children: <Widget>[
            Container(
              height: 150.0,
              child: GoogleMap(
                onMapCreated: _onMapCreated,
                initialCameraPosition: CameraPosition(
                  target: _initialPosition,
                  zoom: 10.0,
                ),
                markers: {
                  Marker(
                    markerId: MarkerId("currentLocation"),
                    position: _currentPosition,
                  ),
                },
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
            placesAutoCompleteTextField(),
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
                        _endTimeController.text = picked.format(context); // 格式化并更新显示
                      }
                    },
                    controller: _endTimeController, // 添加这行
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

  placesAutoCompleteTextField() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 0),
      child: GooglePlaceAutoCompleteTextField(
        textEditingController: _locationController,
        googleAPIKey: "AIzaSyDYNlNZuGDeZat8C1x8nfNgC8mVQM7ELBE",
        inputDecoration: InputDecoration(
          labelText: "Location", // 与Title表单字段样式保持一致
        ),
        boxDecoration: NewBoxDecoration(),
        debounceTime: 500,
        countries: null,
        isLatLngRequired: true,
        getPlaceDetailWithLatLng: (Prediction prediction) {
          setState(() {
            _currentPosition = LatLng(double.parse(prediction.lat!), double.parse(prediction.lng!));
            mapController.animateCamera(CameraUpdate.newLatLng(_currentPosition));
          });
        },

        itemClick: (Prediction prediction) {
          _locationController.text = prediction.description ?? "";
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


