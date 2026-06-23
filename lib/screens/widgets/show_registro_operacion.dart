import 'package:flutter/material.dart';

Future<Map<String, dynamic>?> showRegistroOperacionDialog({
  required BuildContext context,
  required Widget dialog,
}) {
  return showDialog<Map<String, dynamic>>(
    context: context,
    builder: (BuildContext context) => dialog,
  );
}
