import 'dart:convert';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:hekinav/icon/search_icons_icons.dart';
import 'package:hekinav/models/place.dart';
import 'package:hekinav/models/search_results.dart';
import 'package:http/http.dart' as http;

String timeToString(DateTime time) {
  return "${padNumber10(time.hour)}:${padNumber10(time.minute)}:${padNumber10(time.second)}";
}

String padNumber10(number) {
  return number < 10 ? "0$number" : number.toString();
}

Color colorFromRouteType(int? route_type) {
  switch (route_type) {
    case null: //walk
      return Colors.grey;
    case 0: //tram
      return const Color.fromRGBO(0, 152, 95, 1);
    case 1: //metro
      return const Color.fromRGBO(255, 99, 25, 1);
    case 4: //ferry
      return const Color.fromRGBO(0, 185, 228, 1);
    case 102: //long distance train
      return Colors.green;
    case 109: //short distance train
      return const Color.fromRGBO(140, 71, 153, 1);
    case 3: //bus
    case 700: //bus
    case 701: //bus
      return const Color.fromRGBO(0, 122, 201, 1);
    case 702: //trunk bus
      return const Color(0xffEA7000);
    case 704: //lähibussi
    case 712: //lähibussi
      return Colors.cyan;
    case 900: //speedtram
      return const Color.fromRGBO(0, 126, 121, 1);
    case 1104: //airplane
      return const Color(0xff00008B);
    default:
      return Colors.pink;
  }
}

Future<List<Place>> autocomplete(text) async {
  var response = await http.get(
    Uri.parse(
      'https://api.digitransit.fi/geocoding/v1/autocomplete?digitransit-subscription-key=bbc7a56df1674c59822889b1bc84e7ad&text=$text&size=1&boundary.rect.max_lat=61.6&boundary.rect.min_lat=59.95&boundary.rect.min_lon=23.8&boundary.rect.max_lon=27.2',
    ),
  );
  List results = jsonDecode(response.body)["features"];
  return results.map((e) => Place.fromJson(e)).toList();
}

Padding searchResults(stopInputString) {
  log(stopInputString);
  if (stopInputString == "") {
    return const Padding(
      padding: EdgeInsets.all(0.0),
      child: Center(child: Text("no fooba just yet")),
    );
  } else {
    var data = autocomplete(stopInputString);
    return Padding(
      padding: const EdgeInsets.only(top: 20.0),
      child: FutureBuilder(
        future: data,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return Flexible(
              flex: 1,
              child: ListView.builder(
                  primary: false,
                  physics: const AlwaysScrollableScrollPhysics(),
                  itemCount: snapshot.data?.length,
                  shrinkWrap: true,
                  scrollDirection: Axis.vertical,
                  itemBuilder: (BuildContext context, int index) {
                    return searchResult(snapshot.data?[index]);
                  }),
            );
          } else if (snapshot.hasError) {
            throw Exception(snapshot.error);
            /* return Center(child: Text('ERROR ${snapshot.error}')); */
          }
          // By default, show a loading spinner.
          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }
}

ListTile stopResult(Place data) {
  return ListTile(
    title: Row(
      children: [
        modeIcon(data.modes),
        const Text(" "),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(data.name),
              //stopExtraInfo(data),
            ],
          ),
        ),
      ],
    ),
  );
}

Widget searchResult(data) {
  switch (data.type) {
    case "stop":
    case "station":
      return stopResult(data);
    default:
      return const Text("wip");
  }
}

Widget modeIcons(modes) {
  if (modes.length == 1) {
    return modeIcon(modes[1]);
  } else {
    return Row(
      children: [for (var mode in modes) modeIcon(mode)],
    );
  }
}

Icon modeIcon(mode) {
  switch (mode) {
    case "BUS":
      return const Icon(Icons.directions_bus,
          color: Color.fromRGBO(0, 185, 228, 1));
    case "BUS-LOCAL":
      return const Icon(Icons.directions_bus,
          color: Color.fromRGBO(78, 222, 255, 1));
    case "BUS-EXPRESS":
      return const Icon(Icons.directions_bus,
          color: Color.fromRGBO(0, 111, 136, 1));
    case "RAIL":
      return const Icon(Icons.directions_train,
          color: Color.fromRGBO(140, 71, 153, 1));
    case "SPEEDTRAM":
      return const Icon(Icons.bolt, color: Color.fromRGBO(0, 126, 121, 1));
    case "TRAM":
      return const Icon(Icons.directions_railway,
          color: Color.fromRGBO(0, 152, 95, 1));
    case "FERRY":
      return const Icon(Icons.directions_boat,
          color: Color.fromRGBO(0, 185, 228, 1));
    case "AIRPLANE":
      return const Icon(Icons.airplanemode_active);

    default:
      return const Icon(SearchIcons.uusimaa);
    /* case "BUS":
      return const Icon(FirstIcons.bus);
    case "RAIL":
      return const Icon(FirstIcons.train);
    case "TRAM":
      return const Icon(FirstIcons.tram);
    case "FERRY":
      return const Icon(FirstIcons.directions_boat);
    case "AIRPLANE":
      return const Icon(FirstIcons.airplanemode_active);
    case "SPEEDTRAM":
      return const Icon(Icons.bolt);
    default:
      return const Icon(Icons.question_mark); */
  }
}

Wrap stopExtraInfo(data) {
  return Wrap(
    spacing: 5,
    children: [
      if (data.kunta != null)
        if (data.alue != null)
          Text("${data.kunta} (${data.alue})")
        else
          Text("${data.kunta}"),
      if (data.code != null)
        Container(
          decoration: const BoxDecoration(
            borderRadius: BorderRadius.all(Radius.circular(5)),
            color: Color.fromARGB(255, 204, 204, 204),
          ),
          child: Text(" ${data.code} "),
        ),
      if (data.platform != null)
        Wrap(
          children: [
            const Text("platform "),
            Container(
              decoration: const BoxDecoration(
                borderRadius: BorderRadius.all(Radius.circular(5)),
                color: Color.fromARGB(255, 204, 204, 204),
              ),
              child: Text(" ${data.platform} "),
            ),
          ],
        )
    ],
  );
}

Future<List> fetchStops(url) async {
  final response = await http.get(Uri.parse(url));

  if (response.statusCode == 200) {
    final data = json.decode(response.body);

    int length = data['features'].length;
    List resultsList = [];
    for (var i = 0; i < length; i++) {
      resultsList.add(ResultStop.fromJson(data['features'][i]));
    }
    return (resultsList);
  } else {
    throw Exception('Failed to fetch');
  }
}
