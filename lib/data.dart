import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

class Todolist {
  String uid;
  String title;
  List<Task> tasks;

  Todolist({
    required this.uid,
    required this.title,
    required this.tasks,
  });

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'title': title,
      'tasks': tasks.map((task) => task.toJson()).toList(),
    };
  }

  factory Todolist.fromJson(Map<String, dynamic> json) {
    return Todolist(
      uid: json['uid'],
      title: json['title'],
      tasks: List<Task>.from(json['tasks']?.map((x) => Task.fromJson(x)) ?? []),
    );
  }

}

class Task {
  String task;
  bool completed;

  Task({
    required this.task,
    required this.completed,
  });

  Map<String, dynamic> toJson() {
    return {
      'task': task,
      'completed': completed,
    };
  }

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      task: json['task'],
      completed: json['completed'],
    );
  }
}

class Plan {
  String id;
  String name;
  DateTime startDate;
  DateTime endDate;
  int travelDays;
  String notes;

  Plan(
      {
        String? id,
        required this.name,
        required this.startDate,
        required this.endDate,
        required this.travelDays,
        required this.notes,
      }
  ): this.id = id ?? Uuid().v4();

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'startDate': startDate.toIso8601String(),
    'endDate': endDate.toIso8601String(),
    'travelDays': travelDays,
    'notes': notes,
  };

  factory Plan.fromJson(Map<String, dynamic> json) => Plan(
    id: json['id'] as String? ?? Uuid().v4(),
    name: json['name'],
    startDate: DateTime.parse(json['startDate']),
    endDate: DateTime.parse(json['endDate']),
    travelDays: json['travelDays'] != null ? json['travelDays'] as int : 0,
    notes: json['notes'] != null ? json['notes'] as String : '',
  );
}

class PlanItem {
  String id;
  String planId;
  int day;
  String type;
  String title;
  String? startTime;
  String? endTime;
  String? location;
  double? placeLat;
  double? placeLng;
  String? destination;
  double? placeDesLat;
  double? placeDesLng;
  double? destinationLat;
  double? destinationLng;
  String? notes;

  PlanItem({
    required this.id,
    required this.planId,
    required this.day,
    required this.type,
    required this.title,
    this.startTime,
    this.endTime,
    this.location,
    this.placeLat,
    this.placeLng,
    this.destination,
    this.placeDesLat,
    this.placeDesLng,
    this.destinationLat,
    this.destinationLng,
    this.notes,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'planId': planId,
    'day': day,
    'type': type,
    'title': title,
    'startTime': startTime,
    'endTime': endTime,
    'location': location,
    'placeLat': placeLat,
    'placeLng': placeLng,
    'destination': destination,
    'placeLatDes': placeDesLat,
    'placeLngDes': placeDesLng,
    'destinationLat': destinationLat,
    'destinationLng': destinationLng,
    'notes': notes,
  };

  factory PlanItem.fromJson(Map<String, dynamic> json) => PlanItem(
    id: json['id'],
    planId: json['planId'],
    day: json['day'] as int,
    type: json['type'],
    title: json['title'],
    startTime: json['startTime'] as String? ?? '',
    endTime: json['endTime'] as String? ?? '',
    location: json['location'] as String? ?? '',
    placeLat: json['placeLat'] as double? ?? 0.0,
    placeLng: json['placeLng'] as double? ?? 0.0,
    destination: json['destination'] as String? ?? '',
    placeDesLat: json['placeDesLat'] as double? ?? 0.0,
    placeDesLng: json['placeDesLng'] as double? ?? 0.0,
      destinationLat: json['destinationLat'] as double? ?? 0.0,
      destinationLng: json['destinationLng'] as double? ?? 0.0,
    notes: json['notes'] as String? ?? ''
  );
}