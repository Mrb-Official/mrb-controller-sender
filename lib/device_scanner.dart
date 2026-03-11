import 'dart:async';
import 'dart:io';

class DeviceScanner {
  static const int udpPort = 9876;
  static const int discoveryPort = 9877;

  // Scan karke receiver dhundho
  static Future<String?> findReceiver() async {
    try {
      // Apna IP nikalo
      final interfaces = await NetworkInterface.list(
        type: InternetAddressType.IPv4,
      );

      for (var interface in interfaces) {
        for (var addr in interface.addresses) {
          final ip = addr.address;
          // WiFi/hotspot interface dhundho
          if (ip.startsWith('192.168') || ip.startsWith('10.')) {
            final found = await _scanSubnet(ip);
            if (found != null) return found;
          }
        }
      }
    } catch (e) {}
    return null;
  }

  static Future<String?> _scanSubnet(String myIp) async {
    // e.g. 192.168.43.XXX scan karo
    final subnet = myIp.substring(0, myIp.lastIndexOf('.'));
    
    // Discovery UDP socket banao
    RawDatagramSocket? listenSocket;
    String? foundIp;

    try {
      listenSocket = await RawDatagramSocket.bind(
        InternetAddress.anyIPv4,
        discoveryPort,
      );

      // DISCOVER bhejo broadcast pe
      final sendSocket = await RawDatagramSocket.bind(
        InternetAddress.anyIPv4,
        0,
      );
      
      final msg = 'TILT_DISCOVER'.codeUnits;
      
      // 1-254 sab IPs pe bhejo
      for (int i = 1; i <= 254; i++) {
        final targetIp = '$subnet.$i';
        try {
          sendSocket.send(msg, InternetAddress(targetIp), discoveryPort);
        } catch (_) {}
      }

      // 2 second wait karo reply ke liye
      final completer = Completer<String?>();
      
      Timer(const Duration(seconds: 2), () {
        if (!completer.isCompleted) completer.complete(null);
      });

      listenSocket.listen((event) {
        if (event == RawSocketEvent.read) {
          final datagram = listenSocket!.receive();
          if (datagram != null) {
            final response = String.fromCharCodes(datagram.data);
            if (response == 'TILT_RECEIVER') {
              if (!completer.isCompleted) {
                completer.complete(datagram.address.address);
              }
            }
          }
        }
      });

      foundIp = await completer.future;
      sendSocket.close();
    } catch (e) {} finally {
      listenSocket?.close();
    }

    return foundIp;
  }
}
