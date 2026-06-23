import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:i_miner/config/data/database_helper.dart';
import 'package:i_miner/screens/Dash/reporte_sreen.dart';
import 'package:i_miner/services/api_service.dart';
import 'package:i_miner/services/get%20nube/llamadas/api_service_usuario_directorio.dart';
import 'package:i_miner/services/mis_labores_service.dart';
import 'package:i_miner/services/user_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool remember = true;
  bool obscureText = true;

  final TextEditingController dniController = TextEditingController();
  final TextEditingController passController = TextEditingController();
  bool isLoading = false;

  String errorMsg = '';

  Future<bool> _checkUserInSharedDb(String dni) async {
    try {
      final sharedDb = await DatabaseHelper().sharedCatalogDatabase;
      final rows = await sharedDb.query(
        'usuario_directorio',
        columns: ['codigo_dni'],
        where: 'codigo_dni = ?',
        whereArgs: [dni],
        limit: 1,
      );
      return rows.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  Future<void> handleLogin() async {
    setState(() => isLoading = true);
    final dni = dniController.text;
    final pass = passController.text;
    errorMsg = '';

    try {
      final enShared = await _checkUserInSharedDb(dni);

      if (!enShared) {
        _showUserNotFoundDialog(dni, pass);
        return;
      }

      // Usuario existe en shared DB → flujo normal
      try {
        final token = await ApiService().login(dni, pass);
        await UserService().syncOfflineProfileSnapshot(
          dni: dni,
          token: token,
          password: pass,
        );
        await MisLaboresService().prefetchAssignedLaboresForDate(
          fecha: DateFormat('yyyy-MM-dd').format(DateTime.now()),
        );

        if (!context.mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => DashboardScreen(token: token, dni: dni),
          ),
        );
        return;
      } on UserProfileContractException catch (e, stack) {
        errorMsg = 'LOGIN ONLINE CONTRACT ERROR:\n$e\n\n$stack';
        print(errorMsg);
        _showLoginError(errorMsg);
        return;
      } catch (e, stack) {
        errorMsg = "LOGIN ONLINE:\n$e\n\n$stack";
        print(errorMsg);
      }

      // Offline fallback
      try {
        await DatabaseHelper().setCurrentUserDni(dni);
        if (await DatabaseHelper().loginOffline(dni, pass)) {
          if (!context.mounted) return;
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => DashboardScreen(
                token: "offline",
                dni: dni,
              ),
            ),
          );
          return;
        }
      } catch (offlineError, stack) {
        errorMsg += "\n\nOFFLINE:\n$offlineError\n\n$stack";
        print(errorMsg);
      }

      _showLoginError(
        errorMsg.isNotEmpty
            ? errorMsg
            : "Contraseña incorrecta. Verifique sus credenciales.",
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _showLoginError(String error) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Error completo"),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: SelectableText(
              error.isNotEmpty
                  ? error
                  : "Inicio de sesión fallido. Verifique sus credenciales.",
              style: const TextStyle(fontSize: 12),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: error));
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text("Error copiado")));
            },
            child: const Text("Copiar"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cerrar"),
          ),
        ],
      ),
    );
  }

  Future<void> _downloadUsers(String dni, String pass) async {
    setState(() => isLoading = true);
    try {
      final token = await ApiService().login(dni, pass);
      await ApiServiceUsuarioDirectorio().fetchAll(token);

      if (!context.mounted) return;
      Navigator.pop(context); // cerrar dialogo
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Usuarios descargados correctamente. Intente ingresar de nuevo."),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("No se pudo descargar. Verifique conexión e credenciales."),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _showUserNotFoundDialog(String dni, String pass) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text("Usuario no encontrado"),
        content: const Text(
          "El usuario no está registrado en el dispositivo. "
          "Toque 'Actualizar datos' para descargar la información de usuarios desde el servidor.",
        ),
        actions: [
          TextButton(
            onPressed: () => _downloadUsers(dni, pass),
            child: const Text("Actualizar datos"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancelar"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF2B8C99),

      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            /// LOGO
            Image.asset('assets/images/logo.png', height: 70, width: 70),

            const SizedBox(height: 10),

            const Text(
              "Continuar con su usuario para iniciar sesión en la aplicación",
              style: TextStyle(color: Colors.white70),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 40),

            /// USUARIO
            inputField(
              icon: Icons.email,
              hint: "Ingrese Usuario o id",
              controller: dniController,
              isPassword: false,
            ),

            const SizedBox(height: 15),

            /// PASSWORD
            inputField(
              icon: Icons.lock,
              hint: "Ingrese la contraseña",
              controller: passController,
              isPassword: true,
            ),

            const SizedBox(height: 15),

            /// RECORDARME
            Row(
              children: [
                Checkbox(
                  value: remember,
                  onChanged: (value) {
                    setState(() {
                      remember = value!;
                    });
                  },
                  activeColor: Colors.white,
                ),

                const Text("Recordarme", style: TextStyle(color: Colors.white)),
              ],
            ),

            const SizedBox(height: 30),

            /// SEPARADOR
            Row(
              children: const [
                Expanded(child: Divider(color: Colors.white70)),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 10),
                  child: Text(
                    "SELECCIONE",
                    style: TextStyle(color: Colors.white70),
                  ),
                ),
                Expanded(child: Divider(color: Colors.white70)),
              ],
            ),

            const SizedBox(height: 40),

            /// BOTONES
            Row(
              children: [
                Expanded(
                  child: button("Salir", () {
                    Navigator.pop(context);
                  }),
                ),

                const SizedBox(width: 20),

                Expanded(
                  child: button(
                    isLoading ? "Ingresando..." : "Ingresar",
                    isLoading ? () {} : handleLogin,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget inputField({
    required IconData icon,
    required String hint,
    required TextEditingController controller,
    required bool isPassword,
  }) {
    return Container(
      height: 55,
      decoration: BoxDecoration(
        color: const Color(0xFF4FA4AE),
        borderRadius: BorderRadius.circular(10),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 15),

      child: Row(
        children: [
          Icon(icon, color: Colors.white70),

          const SizedBox(width: 10),

          Expanded(
            child: TextField(
              controller: controller,
              obscureText: isPassword ? obscureText : false,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: hint,
                hintStyle: const TextStyle(color: Colors.white70),
              ),
            ),
          ),

          if (isPassword)
            GestureDetector(
              onTap: () {
                setState(() {
                  obscureText = !obscureText;
                });
              },
              child: Icon(
                obscureText ? Icons.visibility : Icons.visibility_off,
                color: Colors.white70,
              ),
            ),
        ],
      ),
    );
  }

  Widget button(String text, VoidCallback onPressed) {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          child: Center(
            child: Text(
              text,
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
          ),
        ),
      ),
    );
  }
}
