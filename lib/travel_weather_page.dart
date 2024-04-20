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

      bool hasEndTime = item.endTime!.isNotEmpty;
      DateTime itemEndTime = hasEndTime ? DateTime(now.year, now.month, now.day,
          int.parse(item.endTime!.split(':')[0]), int.parse(item.endTime!.split(':')[1])) : itemStartTime;
      print("now: ${now}, 1h ago:${oneHourAgo}, ItemStartTime:${item.startTime}, ItemEndTime:${item.endTime}");
      return itemStartTime.isAfter(oneHourAgo) || (hasEndTime && itemEndTime.isAfter(oneHourAgo));
    }).toList();

    List<WeatherData> fetchedWeatherData = [];

    for (var item in relevantItems) {
      print(item.location!);
      WeatherData weather = await fetchWeatherData(item.placeLat!, item.placeLng!, item.location!);
      fetchedWeatherData.add(weather);
      if(item.destination != null){
        WeatherData destinationWeather = await fetchWeatherData(item.destinationLat!, item.destinationLng!, item.destination!);
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

  Future<WeatherData> fetchWeatherData(double lat, double lon, String Location) async {
    String apiKey = Secrets.WeatherApiKey;
    String url = 'https://api.openweathermap.org/data/3.0/onecall?lat=$lat&lon=$lon&appid=$apiKey';
    var response = await http.get(Uri.parse(url));
    var data = jsonDecode(response.body);
    return WeatherData.fromJson(data, extractPlaceName(Location));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Center(child: Column(
          children: [
            Text("Weather of today",style: TextStyle(fontSize: 20),)  ,
            Text("plan: ${widget.title}", style: TextStyle(fontSize: 14))
          ],
        )),
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

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        setState(() {
          isExpanded = !isExpanded;
        });
      },
      child: AnimatedContainer(
        duration: Duration(milliseconds: 500),
        curve: Curves.fastOutSlowIn,
        margin: EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${widget.weather.locationName}',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            'Max Temp: ${widget.weather.maxTemp.toStringAsFixed(1)}°C',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            'Min Temp: ${widget.weather.minTemp.toStringAsFixed(1)}°C',
                            style: TextStyle(fontSize: 18),
                          ),
                        ],
                      ),
                      Image.network(
                        'http://openweathermap.org/img/wn/${widget.weather.daily.icon}@2x.png',
                        width: 50,
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text(
                    widget.weather.daily.description,
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            if (isExpanded) buildHourlyWeatherList(widget.weather.hourly),
          ],
        ),
      ),
    );
  }

  Widget buildHourlyWeatherList(List<WeatherHourly> hourlyData) {
    return Container(
      height: 120,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: hourlyData.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                Text(
                  "${DateFormat('jm').format(hourlyData[index].dateTime)}",
                  style: TextStyle(fontWeight: FontWeight.bold),
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
  double minTemp;
  double maxTemp;
  List<WeatherHourly> hourly;
  WeatherDaily daily;

  WeatherData({
    required this.locationName,
    required this.minTemp,
    required this.maxTemp,
    required this.hourly,
    required this.daily,
  });

  factory WeatherData.fromJson(Map<String, dynamic> json, String location) {
    List<WeatherHourly> hourlyWeather = [];
    for (var entry in json['hourly']) {
      hourlyWeather.add(WeatherHourly.fromJson(entry));
    }

    return WeatherData(
      locationName: location,
      minTemp: json['daily'][0]['temp']['min']-273.15,
      maxTemp: json['daily'][0]['temp']['max']-273.15,
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

  factory WeatherHourly.fromJson(Map<String, dynamic> json) {
    return WeatherHourly(
      dateTime: DateTime.fromMillisecondsSinceEpoch(json['dt'] * 1000),
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

