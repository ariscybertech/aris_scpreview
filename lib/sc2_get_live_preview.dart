import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

void sc2GetLivePreview(controller, {int frames = 5}) async {
  Map<String, String> header = {
    'Content-Type': 'application/json; charset=utf-8',
    'X-XSRF-Protected': '1',
    'Accept': 'multipart/x-mixed-replace'
  };
  Map<String, dynamic> body = {'name': 'camera.getLivePreview'};
  Uri url = Uri.parse('http://192.168.1.1/osc/commands/execute');

  http.Client client = http.Client();
  var request = http.Request('POST', url);
  request.body = jsonEncode(body);
  client.head(url, headers: header);

  http.StreamedResponse response = await client.send(request);

  StreamSubscription? videoStream;

  List<int> buffer = [];
  int startIndex = -1;
  int endIndex = -1;
  int frameCount = 0;
  const int frameDelay = 67;

  bool keepRunning = true;

  // frame delay useful for testing SC2. milliseconds
  Stopwatch frameTimer = Stopwatch();
  frameTimer.start();

  videoStream = response.stream.listen((chunkOfStream) {
    if (frameCount > frames) {
      if (videoStream != null) {
        print('cancelling video stream');
        videoStream.cancel();
        keepRunning = false;
        frameTimer.stop();
        controller.close();
        client.close();
      }
    }
    if (keepRunning) {
      buffer.addAll(chunkOfStream);
      // print('current chunk of stream is ${chunkOfStream.length} bytes long');

      for (var i = 1; i < chunkOfStream.length; i++) {
        if (chunkOfStream[i - 1] == 0xff && chunkOfStream[i] == 0xd8) {
          startIndex = i - 1;
        }
        if (chunkOfStream[i - 1] == 0xff && chunkOfStream[i] == 0xd9) {
          endIndex = buffer.length;
        }

        if (startIndex != -1 && endIndex != -1) {
          var frame = buffer.sublist(startIndex, endIndex);
          if (frameTimer.elapsedMilliseconds > frameDelay) {
            if (frameCount > 0) {
              controller.add(frame);
              print('framecount $frameCount');
              frameTimer.reset();
            }

            frameCount++;
          }
          // print(frame);
          startIndex = -1;
          endIndex = -1;
          buffer = [];
        }
      }
    }
  });
}
