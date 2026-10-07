import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class BatteryOptimizationHelper {
  /// Shows owner an unmissable bottom sheet explaining how to allow unrestricted background activity
  static void showBatteryOptimizationDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: const [
                  Icon(Icons.battery_alert, color: Colors.orange, size: 30),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      "Alert: Battery Saver Band Karein",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                "Naye order ka loud siren aane ke liye, phone ke settings me jakar is app ke liye 'No Restrictions / Battery Optimization Off' select karein, taaki screen band hone par bhi order miss na ho.",
                style: TextStyle(fontSize: 14, height: 1.4, color: Colors.black87),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text("Maine Samajh Liya (Got it)"),
              ),
            ],
          ),
        );
      },
    );
  }
}
