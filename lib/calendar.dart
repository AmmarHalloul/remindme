import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'event_model.dart';

var calendarFirstDate = DateTime(2020);
var calendarLastDate = DateTime(2040);


class Calendar extends StatefulWidget {
  const Calendar({super.key});

  @override
  State<Calendar> createState() => _CalendarState();
}

class _CalendarState extends State<Calendar> {
  late DateTime selectedDay;
  late DateTime focusedDay;


  @override
  void initState() {
    super.initState();  
    selectedDay = focusedDay = DateTime.now();
  }
  void onDaySelected(DateTime day, DateTime focusedDay) {
    setState(() {
      selectedDay = day;
      this.focusedDay = focusedDay;
    });
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          toolbarHeight: 50,
          backgroundColor: Colors.blue,
          title: Center(child:Text("RemindMe", style: TextStyle(color: Colors.white),))
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.add),
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) {
              return AlertDialog(
                scrollable: true,
                title: Text("Add Event"),
                content: EventCreate(selectedDay: selectedDay,),
              );
            }
          );
        }
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Consumer<EventModel>(builder: (context, events, child) {
          return Column(
            children: [ 
              TableCalendar(
                headerStyle: HeaderStyle(titleCentered: true, formatButtonVisible: false),
                firstDay: calendarFirstDate,
                lastDay: calendarLastDate,
                focusedDay: focusedDay,
                selectedDayPredicate: (day) => isSameDay(day, selectedDay),
                onDaySelected: onDaySelected,
                rowHeight: 40,
                eventLoader: (day) {
                  var day2 = stripTime(day);
                  return events.perDayCount[day2] ?? [];
                },
              ),
              Divider(
                color: Colors.blue,
              ),
              Align(
                alignment: Alignment.topLeft,
                child: Text(formatDate(selectedDay))
              ),
              Expanded(
                child: FutureBuilder(future: events.selectDay(selectedDay), builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.done) {
                    var data = snapshot.data!;
                    return ListView.builder(itemCount: data.length, itemBuilder: (context, index) {
                      return Container(
                        margin: EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          border: Border.all(),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: ListTile(
                          leading: Text(formatTime(data[index].date)),
                          title: Text(data[index].name),
                          trailing: IconButton(
                            onPressed: () {
                              events.delete(data[index]);
                            },
                            icon: Icon(Icons.highlight_remove, size: 35),
                          ),
                        )
                      );
                    });
                  } else {
                    return Container();
                  }
                })
              )
            ]
          );
        },)
      )
    );
  }
}


class EventCreate extends StatefulWidget {
  final DateTime selectedDay;
  EventCreate({super.key, required this.selectedDay});

  @override
  State<EventCreate> createState() => _EventCreateState(selectedDay);
}

class _EventCreateState extends State<EventCreate> {
  DateTime date;
  late TimeOfDay time;
  var nameController = TextEditingController();

  _EventCreateState(this.date);

  @override
  initState() {
    super.initState();
    time = TimeOfDay.now();
  }
  
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal:5),
      child: Column(
        children: [
          TextField(
            controller: nameController,
            decoration: InputDecoration(
              hintText: "Name"
            ),
          ),
          SizedBox(height: 16,),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(1), // Adjust the border radius as needed
                ),
              ),
              child: Text(formatDate(date)),
              onPressed: () async {
                DateTime? newDate = await showDatePicker(
                  context: context, 
                  initialDate: date,
                  firstDate: calendarFirstDate,
                  lastDate: calendarLastDate,
                );
                if (newDate != null) {
                  setState(() {
                    this.date = newDate;
                  });
                }
              },
            ),
          ),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(1), // Adjust the border radius as needed
                ),
              ),
              child: Text(formatTime2(time)),
              onPressed: () async {
                TimeOfDay? newTime = await showTimePicker(
                  context: context,
                  initialTime: this.time
                );
                if (newTime != null) {
                  setState(() {
                    this.time = newTime;
                  });
                }
              },
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              child: Text("Confirm"),
              onPressed: () {
                var name = nameController.text.trim();
                if (name.isNotEmpty) {
                  var fullDate = DateTime(date.year, date.month, date.day, time.hour, time.minute);
                  context.read<EventModel>().insert(Event(name, fullDate));
                } 
                Navigator.of(context).pop();
              },
            ),
          )
          
        ],
      )
    );
  }
}


String formatDate(DateTime date) {
  return "${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}";
}

String formatTime(DateTime date) {
  return "${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}";
}


String formatTime2(TimeOfDay time) {
  return "${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}";
}