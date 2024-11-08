import 'package:flutter/material.dart';
import 'package:hekinav/main.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:provider/provider.dart';

class RoutingPage extends StatefulWidget {
  const RoutingPage({super.key});

  @override
  State<RoutingPage> createState() => _RoutingPageState();
}

class _RoutingPageState extends State<RoutingPage> {
  CameraOptions camera = CameraOptions(
    center: Point(coordinates: Position(24.941430272857485, 60.17185691732062)),
    zoom: 12,
    bearing: 0,
    pitch: 0,
  );

  @override
  Widget build(BuildContext context) {
    var themeState = context.watch<ThemeProvider>();
    return Stack(
      children: [
        MapWidget(
          cameraOptions: camera,
          styleUri: themeState.theme == ThemeMode.dark
              ? MapboxStyles.DARK
              : MapboxStyles.STANDARD,
        ),
        DraggableScrollableSheet(builder: (context, scrollController) {
          return const SingleChildScrollView(
            child: Text("Lorem ipsum dolor sit amet, consectetur adipiscing elit. Pellentesque sodales, leo sed porttitor cursus, libero lacus vulputate magna, a porttitor odio libero a nulla. Fusce libero nisl, sollicitudin ut auctor quis, euismod ut nibh. Morbi et eleifend felis. Nulla ut tempor velit. Sed vel vestibulum ipsum, vel tincidunt justo. Morbi sed dictum enim. Curabitur ornare posuere lorem ac vehicula. Maecenas gravida leo sed nisi interdum posuere. Curabitur a ligula non quam placerat maximus. Mauris semper nibh ac diam dapibus commodo. Praesent lobortis nibh lorem, a feugiat nisi faucibus id. In rutrum id libero non porta. Integer non purus ut magna ultrices ultrices. Mauris dapibus erat ac massa semper, eu pharetra metus pulvinar. Pellentesque luctus diam ut sem tempus iaculis. Nunc libero mi, semper at consectetur ut, interdum cursus neque.Proin neque ipsum, auctor accumsan leo ut, blandit viverra dolor. Nam in congue nulla. Donec vitae lacus eget mi ultricies condimentum. Nam vel hendrerit nisl. Quisque aliquet erat a sollicitudin varius. Integer sollicitudin volutpat suscipit. Phasellus sagittis eleifend gravida. Donec efficitur, leo a dapibus tempor, odio leo venenatis purus, eget sodales nibh quam non lectus. In hac habitasse platea dictumst. Vestibulum quis ligula id erat vulputate suscipit. In vel vulputate enim, sit amet venenatis nunc.Pellentesque a lectus enim. Praesent efficitur dolor ornare, pulvinar risus quis, congue dui. Sed luctus, enim sit amet porttitor elementum, elit nibh facilisis nunc, at iaculis orci erat ac elit. Sed purus magna, mollis in ullamcorper id, sagittis et urna. Etiam lacinia metus quis dictum imperdiet. Donec aliquam turpis dolor, quis rhoncus libero ultrices scelerisque. Nulla tempus ante ut urna volutpat auctor vel sed odio. Sed facilisis, sem quis imperdiet rutrum, ligula est iaculis mauris, nec commodo lacus ante ac purus. Vivamus a orci sollicitudin, ultricies nunc a, euismod eros. Vestibulum a mauris eu leo dictum lobortis id a libero. Nullam vestibulum ut turpis nec fringilla. Nulla laoreet risus tellus, eu lacinia justo accumsan a. Ut in nisl porttitor, tincidunt metus sit amet, efficitur velit.Morbi turpis tellus, efficitur eget vulputate a, interdum vitae erat. Nunc vitae pharetra augue. Sed placerat, ex id viverra cursus, dui neque hendrerit ex, vel maximus quam nisi sed nunc. Maecenas lobortis quam posuere nunc dictum consectetur. Nulla ac ultricies elit. Nulla ac libero sed urna imperdiet molestie. Vestibulum commodo nisl nunc, id fringilla ante suscipit in. Cras quis justo dolor. Maecenas sit amet diam eu massa mattis dignissim. Curabitur eleifend tempor mattis. Nulla erat elit, pretium eu congue ut, tincidunt a dolor. Phasellus accumsan dapibus metus, ut iaculis felis malesuada sed. Cras placerat orci eros, in ornare ligula molestie gravida.Aenean varius id risus quis aliquet. Nullam at cursus diam, non aliquet odio. In hac habitasse platea dictumst. Praesent lorem ipsum, lacinia eu tellus vitae, cursus sollicitudin erat. Praesent sed tellus tristique, commodo turpis eu, congue nibh. Maecenas eu tempor lectus. Pellentesque habitant morbi tristique senectus et netus et malesuada fames ac turpis egestas. In pretium vel eros et consequat. Suspendisse tortor tortor, scelerisque vel fringilla ut, accumsan in velit. Maecenas tristique nulla ut lacus vestibulum, efficitur euismod augue tincidunt. Aenean semper ipsum eget ipsum mollis, eget cursus tellus fringilla. Fusce non nulla quis mi semper dignissim. "),
          );
        })
      ],
    );
  }
}
