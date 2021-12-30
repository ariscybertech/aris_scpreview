import 'dart:async';
import 'dart:io';

import 'package:sc2_stream/sc2_get_live_preview.dart';

void main(List<String> arguments) async {
  StreamController controller = StreamController();
  int frames = 200;
  if (arguments.isNotEmpty) {
    print('frames  ${arguments[0]}');
    frames = int.parse(arguments[0]);
  }

  List<File> fileList = [];

  for (int fileNumber = 1; fileNumber < frames + 1; fileNumber++) {
    var tempFile =
        await File('frames/frame$fileNumber.jpg').create(recursive: true);

    fileList.add(tempFile);
  }
  sc2GetLivePreview(controller, frames: frames);
  int frameCount = 0;
  controller.stream.listen((frameData) {
    fileList[frameCount].writeAsBytes(frameData);
    frameCount++;
  });
}
