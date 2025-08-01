import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // Application name
      title: 'Flutter Hello World',
      // Application theme data, you can set the colors for the application as
      // you want
      theme: ThemeData(
        // useMaterial3: false,
        primarySwatch: Colors.blue,
      ),
      // A widget which will be started on application startup
      home: MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  final String title;
  const MyHomePage({super.key, required this.title});  

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class InOutInfo {
  DateTime start;
  DateTime end;

  InOutInfo(this.start, this.end);

  // computed property - duration을 분 단위로 계산
  int get duration => end.difference(start).inMinutes;

  // JSON으로 변환
  Map<String, dynamic> toJson() {
    return {
      'start': start.millisecondsSinceEpoch,
      'end': end.millisecondsSinceEpoch,
    };
  }

  // JSON에서 객체로 변환
  factory InOutInfo.fromJson(Map<String, dynamic> json) {
    return InOutInfo(
      DateTime.fromMillisecondsSinceEpoch(json['start']),
      DateTime.fromMillisecondsSinceEpoch(json['end']),
    );
  }
}

class _MyHomePageState extends State<MyHomePage> {
  final START_TIME = 'start_time';
  final IS_IN = 'is_in';
  final INFOS = 'infos';

  bool _isIn = false;
  DateTime? _startTime = null;
  List<InOutInfo> _infos = [];
  int _totalTime = 0;

  @override
  void initState() {
    super.initState();
    _loadSavedValue();
  }

  void _calculateTotalTime() {
    var total = 0;
    for (var info in _infos) {
      total += info.duration;
    }
    _totalTime = total;
  }

  // SharedPreferences에서 저장된 값을 불러오는 함수
  Future<void> _loadSavedValue() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      // bool 값 불러오기
      _isIn = prefs.getBool(IS_IN) ?? false;
      
      // DateTime 불러오기 (millisecondsSinceEpoch로 저장됨)
      final startTimeMillis = prefs.getInt(START_TIME);
      _startTime = startTimeMillis != null 
          ? DateTime.fromMillisecondsSinceEpoch(startTimeMillis) 
          : null;
      
      // List<InOutInfo> 불러오기 (JSON 문자열로 저장됨)
      final infosJson = prefs.getString(INFOS);
      if (infosJson != null) {
        final List<dynamic> decodedList = jsonDecode(infosJson);
        _infos = decodedList.map((item) => InOutInfo.fromJson(item)).toList();
      } else {
        _infos = [];
      }

      _calculateTotalTime();
    });
  }

  void _toggleInOut() {
    setState(() {
      _isIn = !_isIn;
      
      if (_isIn) {
        // 입장할 때
        _startTime = DateTime.now();
      } else {
        // 퇴장할 때
        if (_startTime != null) {
          _infos.add(InOutInfo(_startTime!, DateTime.now()));
          _startTime = null;
        }
        _calculateTotalTime(); // 퇴장할 때 총 시간 재계산
      }
    });
    
    // 상태 변경 후 SharedPreferences에 저장
    _saveCurrentState();
  }

  // SharedPreferences에 현재 상태를 저장하는 함수
  Future<void> _saveCurrentState() async {
    final prefs = await SharedPreferences.getInstance();
    
    // bool 값 저장
    await prefs.setBool(IS_IN, _isIn);
    
    // DateTime 저장 (millisecondsSinceEpoch로 변환)
    if (_startTime != null) {
      await prefs.setInt(START_TIME, _startTime!.millisecondsSinceEpoch);
    } else {
      await prefs.remove(START_TIME);
    }
    
    // List<InOutInfo> 저장 (JSON 문자열로 변환)
    final infosJsonList = _infos.map((info) => info.toJson()).toList();
    await prefs.setString(INFOS, jsonEncode(infosJsonList));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _isIn ? '현재 입장 상태입니다' : '현재 퇴장 상태입니다',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            if (_startTime != null) ...[
              Text(
                '입장 시간: ${_startTime!.hour}:${_startTime!.minute.toString().padLeft(2, '0')}',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 10),
            ],
            Text(
              '총 출입 기록: ${_infos.length}건',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 10),
            Text(
              '총 체류 시간: ${_totalTime}분',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: _toggleInOut,
              child: Text(_isIn ? '퇴장' : '입장'),
            ),
          ],
        ),
      ),
    );
  }
}
