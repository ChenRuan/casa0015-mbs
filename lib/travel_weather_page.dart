import 'dart:math';

import 'package:eztour/google_api_secrets.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:eztour/data.dart';
import 'package:intl/intl.dart';

class WeatherPage extends StatefulWidget {
  final List<PlanItem> planItems;
  final String title;

  WeatherPage({Key? key, required this.planItems, required this.title}) : super(key: key);

  @override
  _WeatherPageState createState() => _WeatherPageState();
}

class _WeatherPageState extends State<WeatherPage> {
  List<WeatherData> weatherData = [];

  @override
  void initState() {
    super.initState();
    fetchWeatherForPlanItems(widget.planItems);
  }

  Future<void> fetchWeatherForPlanItems(List<PlanItem> planItems) async {
    var now = DateTime.now();
    var oneHourAgo = now.subtract(Duration(hours: 1));

    List<PlanItem> relevantItems = planItems.where((item) {
      DateTime itemStartTime = DateTime(now.year, now.month, now.day,
          int.parse(item.startTime!.split(':')[0]), int.parse(item.startTime!.split(':')[1]));

      bool hasEndTime = item.endTime != null && item.endTime!.isNotEmpty;
      DateTime itemEndTime = hasEndTime ? DateTime(now.year, now.month, now.day,
          int.parse(item.endTime!.split(':')[0]), int.parse(item.endTime!.split(':')[1])) : itemStartTime;
      print("now: ${now}, 1h ago:${oneHourAgo}, ItemStartTime:${item.startTime}, ItemEndTime:${item.endTime}");
      return itemStartTime.isAfter(oneHourAgo) || (hasEndTime && itemEndTime.isAfter(oneHourAgo));
    }).toList();

    List<WeatherData> fetchedWeatherData = [];

    for (var item in relevantItems) {
      print(item.location!);
      WeatherData weather = await fetchWeatherData(item.placeLat!, item.placeLng!, item, item.location!);
      fetchedWeatherData.add(weather);
      if(item.destination != null && item.destination!.isNotEmpty){
        WeatherData destinationWeather = await fetchWeatherData(item.destinationLat!, item.destinationLng!, item, item.destination!);
        fetchedWeatherData.add(destinationWeather);
      }
    }

    setState(() {
      weatherData = fetchedWeatherData;
    });
  }

  String extractPlaceName(String? place) {
    if (place == null) return '';
    var parts = place.split(RegExp(r'[,|-]'));
    return parts[0]
        .trim(); // Trim to remove any leading/trailing white spaces
  }

  Future<WeatherData> fetchWeatherData(double lat, double lon, PlanItem item, String locationName) async {
    String apiKey = Secrets.WeatherApiKey;
    String url = 'https://api.openweathermap.org/data/3.0/onecall?lat=$lat&lon=$lon&appid=$apiKey';
    DateTime now = DateTime.now();
    DateTime currentDate = DateTime(now.year, now.month, now.day);
    DateTime? itemStartTime;
    DateTime? itemEndTime;
    if (item.startTime != null && item.startTime!.isNotEmpty) {
      itemStartTime = currentDate.add(Duration(hours: _getHour(item.startTime), minutes: _getMinute(item.startTime)));
    }

    if (item.endTime != null && item.endTime!.isNotEmpty) {
      itemEndTime = currentDate.add(Duration(hours: _getHour(item.endTime), minutes: _getMinute(item.endTime)));
    }
    var response = await http.get(Uri.parse(url));
    var data = jsonDecode(response.body);
    print('Fetched weather data for location: $locationName');
    return WeatherData.fromJson(data, extractPlaceName(locationName) , _getHour(item.startTime) != 0 ? itemStartTime : null, _getHour(item.endTime) != 0 ? itemEndTime : null);
  }

  int _getHour(String? time) {
    if (time == null || time!.isEmpty) return 0;
    return int.parse(time.split(':')[0]);
  }

  int _getMinute(String? time) {
    if (time == null || time!.isEmpty) return 0;
    return int.parse(time.split(':')[1]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Column(
          mainAxisAlignment: MainAxisAlignment.center, // Center column content
          children: [
            Text("Weather of today", style: TextStyle(fontSize: 20)),
            Text("plan: ${widget.title}", style: TextStyle(fontSize: 14))
          ],
        ),
      ),
      body: ListView.builder(
        itemCount: weatherData.length,
        itemBuilder: (context, index) {
          return WeatherCard(weather: weatherData[index]);
        },
      ),
    );
  }
}

class WeatherCard extends StatefulWidget {
  final WeatherData weather;

  WeatherCard({Key? key, required this.weather}) : super(key: key);

  @override
  _WeatherCardState createState() => _WeatherCardState();
}

class _WeatherCardState extends State<WeatherCard> {
  bool isExpanded = false;
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController(); // Initialize scroll controller here
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (widget.weather != null) { // Add null check here
          setState(() {
            isExpanded = !isExpanded;
          });
        }
      },
      child: AnimatedContainer(
        duration: Duration(milliseconds: 500),
        curve: Curves.fastOutSlowIn,
        margin: EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.blue.shade200, Colors.blue.shade400],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.5),
              spreadRadius: 1,
              blurRadius: 5,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          '${widget.weather.locationName}',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, shadows: [Shadow(blurRadius: 3.0, color: Colors.white, offset: Offset(0.0, 0.0))]),
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${widget.weather.currentTemp.toStringAsFixed(0)}°C',
                            style: TextStyle(fontSize: 35, fontWeight: FontWeight.bold, shadows: [Shadow(blurRadius: 3.0, color: Colors.white, offset: Offset(0.0, 0.0))]),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Image.network(
                            'http://openweathermap.org/img/wn/${widget.weather.daily.icon}@2x.png',
                            width: 50,
                          ),
                        ],
                      ),
                      Text(
                        '${widget.weather.minTemp.toStringAsFixed(0)}°C - ${widget.weather.maxTemp.toStringAsFixed(0)}°C',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, shadows: [Shadow(blurRadius: 3.0, color: Colors.white, offset: Offset(0.0, 0.0))]),
                        textAlign: TextAlign.right,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (isExpanded) buildHourlyWeatherList(widget.weather.hourly, widget.weather.itemStartTime,widget.weather.itemEndTime),
          ],
        ),
      ),
    );
  }

  Widget buildHourlyWeatherList(List<WeatherHourly> hourlyData, DateTime? planStartTime, DateTime? planEndTime) {
    int displayCount = min(hourlyData.length, 24); // Limit to 24 hours
    print('Plan start time: $planStartTime');
    print('Plan end time: $planEndTime');
    print('Current time: ${DateTime.now()}');
    print('Checking for highlighted time range between $planStartTime and $planEndTime');

    WidgetsBinding.instance.addPostFrameCallback((_) {
      int? targetIndex;
      if (planStartTime != null && planEndTime != null) {
        targetIndex = max(0, hourlyData.indexWhere((hour) =>
        hour.dateTime.isAfter(planStartTime.subtract(Duration(hours: 1))) &&
            hour.dateTime.isBefore(planEndTime.add(Duration(hours: 1)))
        ));
      } else if (planStartTime != null) {
        targetIndex = max(0, hourlyData.indexWhere((hour) =>
            hour.dateTime.isAfter(planStartTime.subtract(Duration(hours: 1)))
        ));
      } else if (planEndTime != null) {
        targetIndex = max(0, hourlyData.indexWhere((hour) =>
            hour.dateTime.isBefore(planEndTime.add(Duration(hours: 1)))
        ));
      }
      if (targetIndex != null && targetIndex != -1 && _scrollController.hasClients) {
        _scrollController.animateTo((targetIndex * 60).toDouble(), // Assume each item is 100 pixels wide
            duration: Duration(seconds: 1),
            curve: Curves.easeInOut);
        print('Scrolled to index: $targetIndex');
      }
    });

    return Container(
      height: 120,
      child: ListView.builder(
        controller: _scrollController,
        scrollDirection: Axis.horizontal,
        itemCount: displayCount,
        itemBuilder: (context, index) {
          bool isHighlighted = false;
          if (planStartTime != null && planEndTime != null) {
            isHighlighted = hourlyData[index].dateTime.isAfter(planStartTime.subtract(Duration(hours: 1))) &&
                hourlyData[index].dateTime.isBefore(planEndTime.add(Duration(hours: 1)));
          } else if (planStartTime != null) {
            isHighlighted = hourlyData[index].dateTime.isAfter(planStartTime.subtract(Duration(hours: 1))) &&
                hourlyData[index].dateTime.isBefore(planStartTime.add(Duration(hours: 1)));
          } else if (planEndTime != null) {
            isHighlighted = hourlyData[index].dateTime.isAfter(planEndTime.subtract(Duration(hours: 1))) &&
                hourlyData[index].dateTime.isBefore(planEndTime.add(Duration(hours: 1)));
          }
          return Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                Text(
                  "${DateFormat('HH:mm').format(hourlyData[index].dateTime)}", // Shows day and time
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isHighlighted ? Colors.red : Colors.black, // Highlight if in the plan range
                  ),
                ),
                Image.network(
                  'http://openweathermap.org/img/wn/${hourlyData[index].icon}.png',
                  width: 50,
                ),
                Text("${hourlyData[index].temperature.toStringAsFixed(1)}°C"),
              ],
            ),
          );
        },
      ),
    );
  }
}

class WeatherData {
  String locationName;
  double currentTemp;
  double minTemp;
  double maxTemp;
  DateTime? itemStartTime;
  DateTime? itemEndTime;
  int timezoneOffset;
  List<WeatherHourly> hourly;
  WeatherDaily daily;

  WeatherData({
    required this.locationName,
    required this.currentTemp,
    required this.minTemp,
    required this.maxTemp,
    this.itemStartTime,
    this.itemEndTime,
    required this.timezoneOffset,
    required this.hourly,
    required this.daily,
  });

  factory WeatherData.fromJson(Map<String, dynamic> json, String location, DateTime? itemStartTime, DateTime? itemEndTime) {
    List<WeatherHourly> hourlyWeather = [];
    int timezoneOffset = json['timezone_offset'];
    for (var entry in json['hourly']) {
      hourlyWeather.add(WeatherHourly.fromJson(entry,timezoneOffset));
    }

    return WeatherData(
      locationName: location,
      currentTemp: json['current']['temp']-273.15,
      minTemp: json['daily'][0]['temp']['min']-273.15,
      maxTemp: json['daily'][0]['temp']['max']-273.15,
      itemStartTime: itemStartTime,
      itemEndTime: itemEndTime,
      timezoneOffset: timezoneOffset,
      hourly: hourlyWeather,
      daily: WeatherDaily.fromJson(json['daily'][0]),
    );
  }
}


class WeatherHourly {
  DateTime dateTime;
  String icon;
  double temperature;

  WeatherHourly({
    required this.dateTime,
    required this.icon,
    required this.temperature,
  });

  factory WeatherHourly.fromJson(Map<String, dynamic> json,int timezoneOffset) {
    return WeatherHourly(
      dateTime: DateTime.fromMillisecondsSinceEpoch(json['dt'] * 1000).add(Duration(seconds: timezoneOffset)),
      icon: json['weather'][0]['icon'],
      temperature: json['temp']-273.15,
    );
  }
}

class WeatherDaily {
  String description;
  String icon;

  WeatherDaily({
    required this.description,
    required this.icon,
  });

  factory WeatherDaily.fromJson(Map<String, dynamic> json) {
    return WeatherDaily(
      description: json['weather'][0]['description'],
      icon: json['weather'][0]['icon'],
    );
  }
}
