import 'package:pocketbase/pocketbase.dart';
import '../models/trafficSign.dart';

class TrafficSignService {
  final _pb = PocketBase('http://10.0.2.2:8090'); 

  Future<List<TrafficSign>> fetchAll() async {
    final records = await _pb.collection('trafficSign').getFullList();
    return records.map((rec) {
      // Thêm log để kiểm tra kiểu dữ liệu thực tế
      print('imagePath raw data: ${rec.data['imagePath']}');
      print('imagePath type: ${rec.data['imagePath'].runtimeType}');

      final file = rec.data['imagePath'] as String;
      final url = _pb.files.getUrl(rec, file).toString();
      return TrafficSign(
        id: rec.id,
        signId: rec.data['signId'] as String,
        title: rec.data['title'] as String,
        description: rec.data['description'] as String,
        imageUrl: url,
      );
    }).toList();
  }
}
