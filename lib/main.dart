import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const PurpleCoreApp());
}

const ink = Color(0xFFF5F0FF);
const violet = Color(0xFF9A7AFF);
const canvas = Color(0xFF100D18);
const surface = Color(0xFF1B1726);
const surfaceRaised = Color(0xFF241E32);
const violetWash = Color(0xFF32264A);
const muted = Color(0xFFB7AEC8);

Widget purpleCoreLogo({double iconSize = 36, double titleSize = 20}) => Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: iconSize,
          height: iconSize,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFA78BFA), Color(0xFF7847E8)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(iconSize * .31),
            boxShadow: [
              BoxShadow(
                color: violet.withValues(alpha: .25),
                blurRadius: 14,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Icon(Icons.account_balance_wallet_rounded,
              color: Colors.white, size: iconSize * .56),
        ),
        const SizedBox(width: 10),
        Text('PurpleCore',
            style: TextStyle(
                color: ink, fontSize: titleSize, fontWeight: FontWeight.w800)),
      ],
    );

Widget glassBarSurface() => ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0x66161020),
            border: Border(bottom: BorderSide(color: Colors.white.withValues(alpha: .08))),
          ),
        ),
      ),
    );

Future<void> logout(BuildContext context) async {
  await FirebaseAuth.instance.signOut();
  if (!context.mounted) return;
  Navigator.of(context).pushAndRemoveUntil(
    MaterialPageRoute(builder: (_) => const LoginPage()),
    (_) => false,
  );
}

class PurpleCoreApp extends StatelessWidget {
  const PurpleCoreApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'PurpleCore',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          scaffoldBackgroundColor: canvas,
          brightness: Brightness.dark,
          colorScheme: const ColorScheme.dark(
            primary: violet,
            onPrimary: Colors.white,
            secondary: Color(0xFFC4AEFF),
            onSecondary: Color(0xFF211633),
            surface: surface,
            onSurface: ink,
            error: Color(0xFFFF718A),
            onError: Color(0xFF35101A),
          ),
          fontFamily: 'Roboto',
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.transparent,
            foregroundColor: ink,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            scrolledUnderElevation: 0,
          ),
          cardTheme: CardThemeData(color: surface, surfaceTintColor: Colors.transparent),
          dividerColor: Colors.white12,
          popupMenuTheme: const PopupMenuThemeData(color: surfaceRaised, textStyle: TextStyle(color: ink)),
          bottomSheetTheme: const BottomSheetThemeData(backgroundColor: surface, surfaceTintColor: Colors.transparent),
          dialogTheme: const DialogThemeData(backgroundColor: surface, surfaceTintColor: Colors.transparent),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: surfaceRaised,
            hintStyle: const TextStyle(color: muted),
            labelStyle: const TextStyle(color: muted),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
        ),
        home: const LoginPage(),
      );
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final email = TextEditingController();
  final password = TextEditingController();
  bool hidePassword = true;
  bool signingIn = false;
  String? errorMessage;

  Future<void> signIn() async {
    if (email.text.trim().isEmpty || password.text.isEmpty) {
      setState(() => errorMessage = 'Informe seu e-mail e sua senha.');
      return;
    }
    setState(() {
      signingIn = true;
      errorMessage = null;
    });
    try {
      final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email.text.trim(),
        password: password.text,
      );
      final user = credential.user!;
      final profile = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      final role = profile.data()?['role'];
      if (!profile.exists || (role != 'admin' && role != 'client')) {
        await FirebaseAuth.instance.signOut();
        throw StateError(
            'Seu perfil ainda não está configurado. Peça ao administrador para liberar seu acesso.');
      }
      if (!mounted) return;
      Navigator.of(context).pushReplacement(MaterialPageRoute(
        builder: (_) => role == 'admin' ? const AdminShell() : const ClientShell(),
      ));
    } on FirebaseAuthException catch (error) {
      setState(() => errorMessage = switch (error.code) {
            'invalid-credential' || 'wrong-password' || 'user-not-found' =>
              'E-mail ou senha incorretos.',
            'too-many-requests' =>
              'Muitas tentativas. Aguarde alguns minutos e tente novamente.',
            'network-request-failed' =>
              'Sem conexão com a internet. Tente novamente.',
            _ => 'Não foi possível entrar. Confira seus dados e tente novamente.',
          });
    } on StateError catch (error) {
      setState(() => errorMessage = error.message.toString());
    } catch (_) {
      setState(() => errorMessage =
          'Não foi possível acessar seu perfil. Tente novamente.');
    } finally {
      if (mounted) setState(() => signingIn = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(28),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 430),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  purpleCoreLogo(iconSize: 54, titleSize: 30),
                  const SizedBox(height: 28),
                  const SizedBox(height: 8),
                  const Text('Seu patrimônio, com clareza.', style: TextStyle(color: muted, fontSize: 16)),
                  const SizedBox(height: 38),
                  const Text('Acesse sua conta', style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold, color: ink)),
                  const SizedBox(height: 20),
                  const Text('E-mail', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  TextField(controller: email, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(hintText: 'voce@email.com', prefixIcon: Icon(Icons.mail_outline))),
                  const SizedBox(height: 16),
                  const Text('Senha', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  TextField(controller: password, obscureText: hidePassword, decoration: InputDecoration(hintText: 'Sua senha', prefixIcon: const Icon(Icons.lock_outline), suffixIcon: IconButton(onPressed: () => setState(() => hidePassword = !hidePassword), icon: Icon(hidePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined)))),
                  const SizedBox(height: 24),
                  if (errorMessage != null) ...[
                    Text(errorMessage!, style: const TextStyle(color: Color(0xFFBC4352))),
                    const SizedBox(height: 12),
                  ],
                  SizedBox(width: double.infinity, height: 54, child: FilledButton(onPressed: signingIn ? null : signIn, style: FilledButton.styleFrom(backgroundColor: violet, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))), child: signingIn ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Entrar', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)))),
                  const SizedBox(height: 24),
                  const SizedBox(height: 14),
                  const Center(child: Text('Status do servidor: Online', textAlign: TextAlign.center, style: TextStyle(fontSize: 11, color: muted))),
                ]),
              ),
            ),
          ),
        ),
      );
}

class AdminShell extends StatefulWidget {
  const AdminShell({super.key});
  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  int index = 0;
  final titles = ['Visão geral', 'Clientes', 'Caixa', 'Solicitações'];
  @override
  Widget build(BuildContext context) {
    final pages = [const DashboardPage(), const ClientsPage(), const CashPage(), const RequestsPage()];
    return Scaffold(
      extendBody: true,
      extendBodyBehindAppBar: true,
      appBar: AppBar(flexibleSpace: glassBarSurface(), title: purpleCoreLogo(iconSize: 34, titleSize: 20), actions: [IconButton(onPressed: () => showDates(context), icon: const Icon(Icons.calendar_month_outlined)), IconButton(onPressed: () => logout(context), icon: const Icon(Icons.logout))]),
      body: SafeArea(top: false, child: IndexedStack(index: index, children: pages)),
      bottomNavigationBar: ClipRect(child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18), child: NavigationBar(backgroundColor: const Color(0x66161020), indicatorColor: violet.withValues(alpha: .22), selectedIndex: index, onDestinationSelected: (v) => setState(() => index = v), destinations: const [NavigationDestination(icon: Icon(Icons.grid_view_rounded), label: 'Início'), NavigationDestination(icon: Icon(Icons.people_outline), label: 'Clientes'), NavigationDestination(icon: Icon(Icons.swap_vert_rounded), label: 'Caixa'), NavigationDestination(icon: Icon(Icons.notifications_none), label: 'Saques')]))),
    );
  }
}

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});
  @override
  Widget build(BuildContext context) => StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
    stream: FirebaseFirestore.instance.collection('settings').doc('treasury').snapshots(),
    builder: (context, settingsSnapshot) {
      if (settingsSnapshot.hasError) return const Center(child: Text('Erro ao carregar configurações do caixa.'));
      if (!settingsSnapshot.hasData) return const Center(child: CircularProgressIndicator());
      final openingCapital = (settingsSnapshot.data!.data()?['initialCapital'] as num?)?.toDouble() ?? 0;
      return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance.collection('cash_movements').orderBy('date', descending: true).snapshots(),
        builder: (context, movementSnapshot) {
          if (movementSnapshot.hasError) return const Center(child: Padding(padding: EdgeInsets.all(24), child: Text('Erro ao carregar transações. Publique as regras atualizadas do Firestore.')));
          if (!movementSnapshot.hasData) return const Center(child: CircularProgressIndicator());
          final now = DateTime.now();
          final actual = movementSnapshot.data!.docs.where((doc) {
            final date = doc.data()['date'];
            return date is Timestamp && !date.toDate().isAfter(now);
          }).toList();
          final income = actual.where((d) => d.data()['type'] == 'receipt').fold<double>(0, (s, d) => s + ((d.data()['amount'] as num?)?.toDouble() ?? 0));
          final expenses = actual.where((d) => d.data()['type'] == 'expense').fold<double>(0, (s, d) => s + ((d.data()['amount'] as num?)?.toDouble() ?? 0));
          final currentCash = openingCapital + income - expenses;
          return ListView(padding: EdgeInsets.fromLTRB(20, MediaQuery.of(context).padding.top + kToolbarHeight + 12, 20, 28), children: [
            const Text('Bom dia, administrador 👋', style: TextStyle(color: muted)),
            const SizedBox(height: 4), const Text('Sua mesa hoje', style: TextStyle(fontSize: 25, fontWeight: FontWeight.w800, color: ink)),
            const SizedBox(height: 20),
            Container(padding: const EdgeInsets.all(22), decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF30225E), Color(0xFF7654E8)]), borderRadius: BorderRadius.circular(25)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('CAPITAL DISPONÍVEL', style: TextStyle(color: Colors.white70, letterSpacing: 1.2, fontSize: 11, fontWeight: FontWeight.bold)), const SizedBox(height: 12), Text(formatMoney(currentCash), style: const TextStyle(color: Colors.white, fontSize: 31, fontWeight: FontWeight.w800)), const SizedBox(height: 16), Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Capital inicial', style: TextStyle(color: Colors.white70)), Text(formatMoney(openingCapital), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))]), Align(alignment: Alignment.centerRight, child: TextButton(onPressed: () => editOpeningCapital(context, openingCapital), child: const Text('Ajustar capital inicial', style: TextStyle(color: Colors.white))))])),
            const SizedBox(height: 16),
            Row(children: [Expanded(child: metric('RECEITAS REALIZADAS', formatMoney(income), Icons.south_west, const Color(0xFF1D9A70))), const SizedBox(width: 12), Expanded(child: metric('DESPESAS REALIZADAS', formatMoney(expenses), Icons.north_east, const Color(0xFFE05D79)))]),
            const SizedBox(height: 16),
            card(Column(children: [cashLine('Capital inicial', formatMoney(openingCapital), true), cashLine('Receitas realizadas', '+ ${formatMoney(income)}', true), cashLine('Despesas realizadas', '− ${formatMoney(expenses)}', false), const Divider(height: 22), cashLine('Caixa disponível', formatMoney(currentCash), currentCash >= 0, bold: true)])),
            const SizedBox(height: 24),
            sectionTitle('Transações recentes', 'Até hoje'),
            const SizedBox(height: 12),
            if (actual.isEmpty) card(const Text('Ainda não há receitas ou despesas registradas.', style: TextStyle(color: muted)))
            else ...actual.take(5).map((doc) { final d = doc.data(); final expense = d['type'] == 'expense'; final amount = (d['amount'] as num?)?.toDouble() ?? 0; final date = (d['date'] as Timestamp).toDate(); return Padding(padding: const EdgeInsets.only(bottom: 10), child: card(Row(children: [Icon(expense ? Icons.north_east : Icons.south_west, color: expense ? const Color(0xFFE05D79) : const Color(0xFF1D9A70)), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(d['description'] as String? ?? (expense ? 'Despesa' : 'Receita'), style: const TextStyle(fontWeight: FontWeight.bold, color: ink)), Text('${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}', style: const TextStyle(fontSize: 11, color: muted))])), Text('${expense ? '−' : '+'} ${formatMoney(amount)}', style: TextStyle(fontWeight: FontWeight.bold, color: expense ? const Color(0xFFE05D79) : const Color(0xFF1D9A70)))]))); }),
          ]);
        },
      );
    },
  );
}

Future<void> editOpeningCapital(BuildContext context, double currentValue) async {
  final controller = TextEditingController(text: currentValue.toStringAsFixed(2).replaceAll('.', ','));
  final confirmed = await showDialog<bool>(context: context, builder: (dialogContext) => AlertDialog(title: const Text('Capital inicial da mesa'), content: TextField(controller: controller, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Valor em R\$')), actions: [TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancelar')), FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Salvar'))]));
  if (confirmed == true) {
    final value = double.tryParse(controller.text.trim().replaceAll('.', '').replaceAll(',', '.'));
    if (value != null && value >= 0) await FirebaseFirestore.instance.collection('settings').doc('treasury').set({'initialCapital': value, 'updatedAt': FieldValue.serverTimestamp()}, SetOptions(merge: true));
  }
  controller.dispose();
}

Widget metric(String label, String value, IconData icon, Color color) => Container(padding: const EdgeInsets.all(15), decoration: BoxDecoration(color: surface, borderRadius: BorderRadius.circular(19), border: Border.all(color: Colors.white.withValues(alpha: .055))), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Icon(icon, color: color, size: 20), const SizedBox(height: 13), Text(value, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17, color: ink)), const SizedBox(height: 4), Text(label, style: const TextStyle(fontSize: 10, letterSpacing: .7, color: muted, fontWeight: FontWeight.w600))]));
Widget sectionTitle(String title, String action) => Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: ink)), Text(action, style: const TextStyle(fontSize: 12, color: violet, fontWeight: FontWeight.w600))]);
Widget card(Widget child) => Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: surface, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white.withValues(alpha: .055))), child: child);
Widget cashLine(String label, String amount, bool positive, {bool bold = false}) => Padding(padding: const EdgeInsets.symmetric(vertical: 6), child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(label, style: TextStyle(color: bold ? ink : muted, fontWeight: bold ? FontWeight.bold : FontWeight.normal)), Text(amount, style: TextStyle(color: bold ? violet : (positive ? const Color(0xFF198768) : const Color(0xFFDD6770)), fontWeight: FontWeight.w700))]));
Widget clientRow(String name, String detail, String amount, String initials) => Row(children: [CircleAvatar(radius: 20, backgroundColor: violetWash, child: Text(initials, style: const TextStyle(color: violet, fontSize: 12, fontWeight: FontWeight.bold))), const SizedBox(width: 11), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(name, style: const TextStyle(fontWeight: FontWeight.bold, color: ink)), const SizedBox(height: 4), Text(detail, style: const TextStyle(fontSize: 11, color: muted))])), Text(amount, style: const TextStyle(fontWeight: FontWeight.bold, color: ink))]);

class ClientsPage extends StatelessWidget {
  const ClientsPage({super.key});
  @override
  Widget build(BuildContext context) => ListView(padding: EdgeInsets.fromLTRB(20, MediaQuery.of(context).padding.top + kToolbarHeight + 20, 20, 20), children: [
    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Clientes', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: ink)), FilledButton.icon(onPressed: () => editClient(context), icon: const Icon(Icons.add, size: 18), label: const Text('Novo'))]),
    const SizedBox(height: 8), const Text('Gerencie saldos, rendimento e condições.', style: TextStyle(color: muted)), const SizedBox(height: 20),
    StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('users').where('role', isEqualTo: 'client').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) return const Text('Não foi possível carregar clientes.');
        if (!snapshot.hasData) return const Center(child: Padding(padding: EdgeInsets.all(28), child: CircularProgressIndicator()));
        if (snapshot.data!.docs.isEmpty) return const Padding(padding: EdgeInsets.all(20), child: Text('Ainda não há clientes cadastrados.'));
        return Column(children: snapshot.data!.docs.map((doc) {
          final data = doc.data();
          final name = data['name'] as String? ?? 'Cliente';
          final principal = (data['principal'] as num?)?.toDouble() ?? 0;
          final balance = (data['balance'] as num?)?.toDouble() ?? principal;
          final totalDeposits = (data['totalDeposits'] as num?)?.toDouble() ?? principal;
          final immediateAvailable = (data['immediateAvailable'] as num?)?.toDouble() ?? 0;
          final rate = (data['monthlyRate'] as num?)?.toDouble() ?? 0;
          final earningStart = data['earningStartDate'] is Timestamp
              ? (data['earningStartDate'] as Timestamp).toDate()
              : null;
          return Padding(padding: const EdgeInsets.only(bottom: 12), child: card(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [CircleAvatar(backgroundColor: violetWash, child: Text(name.isEmpty ? '?' : name[0].toUpperCase(), style: const TextStyle(color: violet, fontWeight: FontWeight.bold))), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(name, style: const TextStyle(fontWeight: FontWeight.bold, color: ink)), Text(data['email'] as String? ?? '', style: const TextStyle(fontSize: 12, color: muted))]))]),
            const Divider(height: 22),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('SALDO ATUAL', style: TextStyle(fontSize: 9, color: muted, letterSpacing: .7)), Text(formatMoney(balance), style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: ink))]), Column(crossAxisAlignment: CrossAxisAlignment.end, children: [const Text('RENDIMENTO MENSAL', style: TextStyle(fontSize: 9, color: muted, letterSpacing: .7)), Text('${rate.toStringAsFixed(2)}% · ${formatMoney(principal * rate / 100)}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: violet))])]),
            const SizedBox(height: 8),
            Row(children: [const Icon(Icons.savings_outlined, size: 16, color: violet), const SizedBox(width: 6), const Expanded(child: Text('Total depositado (bruto)', style: TextStyle(fontSize: 12, color: muted))), Text(formatMoney(totalDeposits), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: ink)), const SizedBox(width: 6), IconButton(tooltip: 'Ajustar histórico de depósitos', visualDensity: VisualDensity.compact, onPressed: () => editClientGrossDeposits(context, doc, principal, totalDeposits), icon: const Icon(Icons.edit_outlined, size: 17, color: violet))]),
            const SizedBox(height: 10),
            Row(children: [const Icon(Icons.event_repeat, size: 17, color: violet), const SizedBox(width: 6), Expanded(child: Text(earningStart == null ? 'Virada do rendimento não configurada' : 'Virada mensal: dia ${earningStart.day.toString().padLeft(2, '0')}', style: const TextStyle(fontSize: 12, color: muted))), TextButton(onPressed: () => chooseClientEarningDate(context, doc), child: Text(earningStart == null ? 'Definir data' : 'Alterar'))]),
            const SizedBox(height: 8),
            Row(children: [const Icon(Icons.account_balance_outlined, size: 17, color: violet), const SizedBox(width: 6), Expanded(child: Text((data['position'] as String?)?.trim().isNotEmpty == true ? data['position'] as String : 'Posicionamento não informado', maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, color: muted))), TextButton(onPressed: () => editClientPosition(context, doc), child: const Text('Editar'))]),
            const SizedBox(height: 8),
            Row(children: [const Icon(Icons.flash_on_outlined, size: 17, color: violet), const SizedBox(width: 6), Expanded(child: Text('Disponível para saque imediato: ${formatMoney(immediateAvailable)}', style: const TextStyle(fontSize: 12, color: muted))), TextButton(onPressed: () => editImmediateAvailable(context, doc, balance), child: const Text('Definir'))]),
          ])));
        }).toList());
      },
    ),
  ]);
}

Future<void> editClientPosition(BuildContext context, QueryDocumentSnapshot<Map<String, dynamic>> client) async {
  final controller = TextEditingController(text: client.data()['position'] as String? ?? '');
  final saved = await showDialog<bool>(context: context, builder: (dialogContext) => AlertDialog(title: const Text('Onde o capital está posicionado?'), content: TextField(controller: controller, maxLines: 4, maxLength: 300, decoration: const InputDecoration(hintText: 'Ex.: operação, ativo ou finalidade')), actions: [TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancelar')), FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Salvar'))]));
  if (saved == true) {
    try { await client.reference.update({'position': controller.text.trim(), 'updatedAt': FieldValue.serverTimestamp()}); }
    catch (_) { if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Não foi possível salvar o posicionamento.'))); }
  }
  controller.dispose();
}

Future<void> editImmediateAvailable(BuildContext context, QueryDocumentSnapshot<Map<String, dynamic>> client, double balance) async {
  final current = (client.data()['immediateAvailable'] as num?)?.toDouble() ?? 0;
  final controller = TextEditingController(text: current.toStringAsFixed(2).replaceAll('.', ','));
  final saved = await showDialog<bool>(context: context, builder: (dialogContext) => AlertDialog(title: const Text('Saque imediato'), content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Saldo total do cliente: ${formatMoney(balance)}'), const SizedBox(height: 12), TextField(controller: controller, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Valor liberado para saque imediato (R\$)'))]), actions: [TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancelar')), FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Salvar'))]));
  if (saved == true) {
    final value = double.tryParse(controller.text.trim().replaceAll('.', '').replaceAll(',', '.'));
    if (value == null || value < 0 || value > balance) { if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('O limite deve estar entre zero e o saldo atual do cliente.'))); }
    else { try { await client.reference.update({'immediateAvailable': value, 'updatedAt': FieldValue.serverTimestamp()}); } catch (_) { if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Não foi possível atualizar o limite.'))); } }
  }
  controller.dispose();
}

Future<void> editClientGrossDeposits(BuildContext context, QueryDocumentSnapshot<Map<String, dynamic>> client, double principal, double current) async {
  final controller = TextEditingController(text: current.toStringAsFixed(2).replaceAll('.', ','));
  final saved = await showDialog<bool>(context: context, builder: (dialogContext) => AlertDialog(title: const Text('Total depositado acumulado'), content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('Informe a soma bruta do aporte inicial e de todos os depósitos. Saques não reduzem este indicador.'), const SizedBox(height: 12), TextField(controller: controller, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Total depositado (R\$)'))]), actions: [TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancelar')), FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Salvar'))]));
  if (saved == true) {
    final value = double.tryParse(controller.text.trim().replaceAll('.', '').replaceAll(',', '.'));
    if (value == null || value < principal) { if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('O total depositado precisa ser pelo menos o capital aplicado atual (${formatMoney(principal)}).'))); }
    else { try { await client.reference.update({'totalDeposits': value, 'updatedAt': FieldValue.serverTimestamp()}); } catch (_) { if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Não foi possível atualizar o total depositado.'))); } }
  }
  controller.dispose();
}

String formatMoney(num value) {
  final parts = value.toStringAsFixed(2).split('.');
  final whole = parts[0].replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => '.');
  return 'R\$ $whole,${parts[1]}';
}

DateTime nextMonthlyDate() {
  final now = DateTime.now();
  final nextMonth = DateTime(now.year, now.month + 1, 1);
  final lastDay = DateTime(nextMonth.year, nextMonth.month + 1, 0).day;
  final day = now.day > lastDay ? lastDay : now.day;
  return DateTime(nextMonth.year, nextMonth.month, day);
}

String formatDate(DateTime date) =>
    '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';

String shortDateLabel(DateTime date) {
  const months = ['jan', 'fev', 'mar', 'abr', 'mai', 'jun', 'jul', 'ago', 'set', 'out', 'nov', 'dez'];
  return '${date.day} ${months[date.month - 1]} ${date.year}';
}

DateTime nextEarningDate(int earningDay, DateTime firstEarningDate) {
  final today = DateUtils.dateOnly(DateTime.now());
  final firstDate = DateUtils.dateOnly(firstEarningDate);
  var year = today.year;
  var month = today.month;
  if (firstDate.isAfter(DateTime(year, month, 1))) {
    year = firstDate.year;
    month = firstDate.month;
  }
  for (var i = 0; i < 24; i++) {
    final lastDay = DateTime(year, month + 1, 0).day;
    final dueDate = DateTime(year, month, earningDay.clamp(1, lastDay).toInt());
    if (!dueDate.isBefore(today) && !dueDate.isBefore(firstDate)) return dueDate;
    month++;
    if (month > 12) { month = 1; year++; }
  }
  return DateTime(year, month, earningDay.clamp(1, DateTime(year, month + 1, 0).day).toInt());
}

Future<void> chooseClientEarningDate(
    BuildContext context, QueryDocumentSnapshot<Map<String, dynamic>> client) async {
  final existing = client.data()['earningStartDate'];
  var initial = existing is Timestamp ? DateUtils.dateOnly(existing.toDate()) : nextMonthlyDate();
  final today = DateUtils.dateOnly(DateTime.now());
  if (initial.isBefore(today)) initial = nextMonthlyDate();
  final picked = await showDatePicker(context: context, initialDate: initial, firstDate: today, lastDate: DateTime(2100));
  if (picked == null) return;
  try {
    await client.reference.update({
      'earningDay': picked.day,
      'earningStartDate': Timestamp.fromDate(DateUtils.dateOnly(picked)),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  } catch (_) {
    if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Não foi possível atualizar a data. Confira as regras do Firestore.')));
  }
}

void editClient(BuildContext context) => showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const _NewClientSheet(),
    );

class _NewClientSheet extends StatefulWidget {
  const _NewClientSheet();
  @override
  State<_NewClientSheet> createState() => _NewClientSheetState();
}

class _NewClientSheetState extends State<_NewClientSheet> {
  final name = TextEditingController();
  final email = TextEditingController();
  final password = TextEditingController();
  final principal = TextEditingController();
  final rate = TextEditingController();
  DateTime earningStartDate = nextMonthlyDate();
  bool saving = false;
  String? error;

  double? parseAmount(String raw) => double.tryParse(raw.trim().replaceAll('.', '').replaceAll(',', '.'));

  Future<void> save() async {
    final capital = parseAmount(principal.text);
    final monthlyRate = parseAmount(rate.text);
    if (name.text.trim().isEmpty || !email.text.contains('@') || password.text.length < 6 || capital == null || capital <= 0 || monthlyRate == null || monthlyRate < 0) {
      setState(() => error = 'Confira nome, e-mail, senha (mín. 6 caracteres), capital e taxa.');
      return;
    }
    setState(() { saving = true; error = null; });
    FirebaseApp? secondaryApp;
    UserCredential? created;
    try {
      secondaryApp = await Firebase.initializeApp(name: 'purplecore-client-creator', options: DefaultFirebaseOptions.currentPlatform);
      final secondaryAuth = FirebaseAuth.instanceFor(app: secondaryApp);
      created = await secondaryAuth.createUserWithEmailAndPassword(email: email.text.trim(), password: password.text);
      await FirebaseFirestore.instance.collection('users').doc(created.user!.uid).set({
        'role': 'client', 'name': name.text.trim(), 'email': email.text.trim(),
        'principal': capital, 'balance': capital, 'monthlyRate': monthlyRate,
        'totalDeposits': capital,
        'immediateAvailable': 0,
        'earningDay': earningStartDate.day,
        'earningStartDate': Timestamp.fromDate(earningStartDate),
        'createdAt': FieldValue.serverTimestamp(), 'active': true,
      });
      await secondaryAuth.signOut();
      await secondaryApp.delete();
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cliente cadastrado. Ele já pode entrar com o e-mail e a senha definidos.')));
    } on FirebaseAuthException catch (e) {
      if (created?.user != null) await created!.user!.delete();
      if (secondaryApp != null) await secondaryApp.delete();
      setState(() => error = e.code == 'email-already-in-use' ? 'Este e-mail já possui uma conta.' : 'Falha ao criar acesso: ${e.message ?? e.code}');
    } catch (e) {
      if (created?.user != null) await created!.user!.delete();
      if (secondaryApp != null) await secondaryApp.delete();
      setState(() => error = 'Não foi possível salvar o cliente: $e');
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  void dispose() { name.dispose(); email.dispose(); password.dispose(); principal.dispose(); rate.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.fromLTRB(22, 24, 22, MediaQuery.of(context).viewInsets.bottom + 22),
    child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Novo cliente', style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold)), const SizedBox(height: 16),
      TextField(controller: name, decoration: const InputDecoration(labelText: 'Nome completo')),
      const SizedBox(height: 10), TextField(controller: email, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'E-mail de acesso')),
      const SizedBox(height: 10), TextField(controller: password, obscureText: true, decoration: const InputDecoration(labelText: 'Senha inicial (mín. 6 caracteres)')),
      const SizedBox(height: 10), Row(children: [Expanded(child: TextField(controller: principal, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Capital (R\$)'))), const SizedBox(width: 10), Expanded(child: TextField(controller: rate, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Rendimento mensal (%)')))]),
      const SizedBox(height: 10),
      OutlinedButton.icon(onPressed: () async { final picked = await showDatePicker(context: context, initialDate: earningStartDate, firstDate: DateUtils.dateOnly(DateTime.now()), lastDate: DateTime(2100)); if (picked != null) setState(() => earningStartDate = DateUtils.dateOnly(picked)); }, icon: const Icon(Icons.event), label: Text('Primeira virada de rendimento: ${formatDate(earningStartDate)}')),
      if (error != null) Padding(padding: const EdgeInsets.only(top: 12), child: Text(error!, style: const TextStyle(color: Color(0xFFBC4352)))),
      const SizedBox(height: 18), SizedBox(width: double.infinity, child: FilledButton(onPressed: saving ? null : save, child: saving ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Criar cliente'))),
    ])),
  );
}

class CashPage extends StatefulWidget {
  const CashPage({super.key});
  @override
  State<CashPage> createState() => _CashPageState();
}
class _CashPageState extends State<CashPage> {
  DateTime selectedDay = DateUtils.dateOnly(DateTime.now());

  String dateLabel(DateTime day) {
    const months = ['jan', 'fev', 'mar', 'abr', 'mai', 'jun', 'jul', 'ago', 'set', 'out', 'nov', 'dez'];
    return '${day.day} ${months[day.month - 1]}';
  }

  @override
  Widget build(BuildContext context) => ListView(padding: EdgeInsets.fromLTRB(20, MediaQuery.of(context).padding.top + kToolbarHeight + 20, 20, 20), children: [
    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Movimentações', style: TextStyle(fontSize: 25, fontWeight: FontWeight.w800, color: ink)), PopupMenuButton<String>(onSelected: (type) => addMovement(context, type), itemBuilder: (_) => const [PopupMenuItem(value: 'receipt', child: Text('Lançar receita')), PopupMenuItem(value: 'expense', child: Text('Lançar despesa / retirada'))], child: Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10), decoration: BoxDecoration(color: violet, borderRadius: BorderRadius.circular(14)), child: const Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.add, size: 18, color: Colors.white), SizedBox(width: 4), Text('Adicionar', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))])))]),
    const SizedBox(height: 4), const Text('Registre receitas e navegue pelos lançamentos por dia.', style: TextStyle(color: muted)), const SizedBox(height: 16),
    card(Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [IconButton(onPressed: () => setState(() => selectedDay = selectedDay.subtract(const Duration(days: 1))), icon: const Icon(Icons.chevron_left)), Column(children: [const Text('LANÇAMENTOS DO DIA', style: TextStyle(fontSize: 9, letterSpacing: .8, color: muted)), const SizedBox(height: 4), Text(dateLabel(selectedDay), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: ink))]), IconButton(onPressed: () => setState(() => selectedDay = selectedDay.add(const Duration(days: 1))), icon: const Icon(Icons.chevron_right)), IconButton(onPressed: () async { final picked = await showDatePicker(context: context, initialDate: selectedDay, firstDate: DateTime(2020), lastDate: DateTime(2100)); if (picked != null) setState(() => selectedDay = DateUtils.dateOnly(picked)); }, icon: const Icon(Icons.calendar_month_outlined, color: violet))])),
    const SizedBox(height: 16),
    StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(stream: FirebaseFirestore.instance.collection('cash_movements').orderBy('date', descending: true).snapshots(), builder: (context, snapshot) {
      if (snapshot.hasError) return const Text('Não foi possível carregar o caixa. Confira as regras do Firestore.');
      if (!snapshot.hasData) return const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator()));
      final all = snapshot.data!.docs;
      final receipts = all.where((d) => d.data()['type'] == 'receipt').fold<double>(0, (sum, d) => sum + ((d.data()['amount'] as num?)?.toDouble() ?? 0));
      final expenses = all.where((d) => d.data()['type'] == 'expense').fold<double>(0, (sum, d) => sum + ((d.data()['amount'] as num?)?.toDouble() ?? 0));
      final dayDocs = all.where((d) { final value = d.data()['date']; if (value is! Timestamp) return false; return DateUtils.isSameDay(value.toDate(), selectedDay); }).toList();
      final dayTotal = dayDocs.where((d) => d.data()['type'] == 'receipt').fold<double>(0, (sum, d) => sum + ((d.data()['amount'] as num?)?.toDouble() ?? 0));
      final dayExpenses = dayDocs.where((d) => d.data()['type'] == 'expense').fold<double>(0, (sum, d) => sum + ((d.data()['amount'] as num?)?.toDouble() ?? 0));
      return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        card(Column(children: [cashLine('Receitas registradas', formatMoney(receipts), true), cashLine('Despesas registradas', formatMoney(expenses), false), const Divider(height: 18), cashLine('Receitas neste dia', formatMoney(dayTotal), true), cashLine('Despesas neste dia', formatMoney(dayExpenses), false)])),
        const SizedBox(height: 22), Text('Lançamentos · ${dateLabel(selectedDay)}', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: ink)), const SizedBox(height: 10),
        if (dayDocs.isEmpty) card(const Padding(padding: EdgeInsets.all(8), child: Text('Nenhum lançamento nesta data.', style: TextStyle(color: muted))))
        else ...dayDocs.map((doc) { final d = doc.data(); final amount = (d['amount'] as num?)?.toDouble() ?? 0; final expense = d['type'] == 'expense'; final tone = expense ? const Color(0xFFE05D79) : const Color(0xFF198768); return Padding(padding: const EdgeInsets.only(bottom: 10), child: card(Row(children: [CircleAvatar(backgroundColor: expense ? const Color(0xFF3A202C) : const Color(0xFF1D342D), child: Icon(expense ? Icons.north_east : Icons.south_west, color: tone)), const SizedBox(width: 12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(d['description'] as String? ?? (expense ? 'Despesa' : 'Receita'), style: const TextStyle(fontWeight: FontWeight.bold, color: ink)), Text('${expense ? 'Despesa' : 'Receita'} · ${dateLabel(selectedDay)}', style: const TextStyle(fontSize: 11, color: muted))])), Text('${expense ? '−' : '+'} ${formatMoney(amount)}', style: TextStyle(fontWeight: FontWeight.bold, color: tone))]))); }),
      ]);
    }),
    const SizedBox(height: 24),
    const FutureYieldSchedule(),
  ]);
}

class _MonthlyRow {
  const _MonthlyRow({required this.date, required this.description, required this.category, required this.account, required this.amount, required this.expense, required this.status, this.clientId, this.dueMonth, this.projected = false});
  final DateTime date;
  final String description;
  final String category;
  final String account;
  final double amount;
  final bool expense;
  final String status;
  final String? clientId;
  final String? dueMonth;
  final bool projected;
}

class FutureYieldSchedule extends StatefulWidget {
  const FutureYieldSchedule({super.key});
  @override
  State<FutureYieldSchedule> createState() => _FutureYieldScheduleState();
}

class _FutureYieldScheduleState extends State<FutureYieldSchedule> {
  DateTime month = DateTime(DateTime.now().year, DateTime.now().month);

  DateTime _dueDate(int year, int month, int requestedDay) {
    final lastDay = DateTime(year, month + 1, 0).day;
    return DateTime(year, month, requestedDay > lastDay ? lastDay : requestedDay);
  }

  String _monthLabel() {
    const months = ['Janeiro', 'Fevereiro', 'Março', 'Abril', 'Maio', 'Junho', 'Julho', 'Agosto', 'Setembro', 'Outubro', 'Novembro', 'Dezembro'];
    return '${months[month.month - 1]} ${month.year}';
  }

  Future<void> _markAsPaid(BuildContext context, _MonthlyRow row) async {
    final confirmed = await showDialog<bool>(context: context, builder: (dialogContext) => AlertDialog(title: const Text('Confirmar pagamento'), content: Text('Registrar ${formatMoney(row.amount)} como pago para ${row.description.replaceFirst('Dividendo · ', '')}?'), actions: [TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancelar')), FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Marcar como pago'))]));
    if (confirmed != true || row.clientId == null || row.dueMonth == null) return;
    try {
      final movementId = 'yield_${row.clientId}_${row.dueMonth}';
      final movementRef = FirebaseFirestore.instance.collection('cash_movements').doc(movementId);
      final clientRef = FirebaseFirestore.instance.collection('users').doc(row.clientId);
      final ledgerRef = clientRef.collection('ledger').doc('yield_${row.dueMonth}');
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final existingPayment = await transaction.get(movementRef);
        if (existingPayment.exists) throw StateError('Este rendimento já foi registrado como pago.');
        final clientSnapshot = await transaction.get(clientRef);
        final data = clientSnapshot.data();
        if (!clientSnapshot.exists || data == null) throw StateError('Cliente não encontrado.');
        final currentBalance = (data['balance'] as num?)?.toDouble() ?? (data['principal'] as num?)?.toDouble() ?? 0;
        transaction.set(movementRef, {
        'type': 'expense', 'kind': 'yield_payment', 'description': row.description,
        'category': 'Dividendos', 'account': 'Mesa Principal', 'amount': row.amount,
        'date': Timestamp.fromDate(DateUtils.dateOnly(DateTime.now())),
        'createdAt': FieldValue.serverTimestamp(), 'createdBy': FirebaseAuth.instance.currentUser!.uid,
        'clientId': row.clientId, 'dueMonth': row.dueMonth,
      });
        transaction.update(clientRef, {'balance': currentBalance + row.amount, 'updatedAt': FieldValue.serverTimestamp()});
        transaction.set(ledgerRef, {'type': 'credit', 'title': 'Rendimento creditado', 'description': row.description, 'amount': row.amount, 'balanceAfter': currentBalance + row.amount, 'date': Timestamp.fromDate(DateUtils.dateOnly(DateTime.now())), 'createdAt': FieldValue.serverTimestamp(), 'source': 'yield', 'dueMonth': row.dueMonth});
      });
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pagamento registrado no caixa.')));
    } catch (_) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Não foi possível registrar o pagamento. Confira as regras do Firestore.')));
    }
  }

  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    const Text('Transações do caixa', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: ink)),
    const SizedBox(height: 10),
    card(Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [IconButton(onPressed: () => setState(() => month = DateTime(month.year, month.month - 1)), icon: const Icon(Icons.chevron_left, color: violet)), Text(_monthLabel(), style: const TextStyle(fontWeight: FontWeight.bold, color: violet)), IconButton(onPressed: () => setState(() => month = DateTime(month.year, month.month + 1)), icon: const Icon(Icons.chevron_right, color: violet))])),
    const SizedBox(height: 12),
    StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(stream: FirebaseFirestore.instance.collection('cash_movements').orderBy('date', descending: true).snapshots(), builder: (context, movementSnapshot) {
      if (movementSnapshot.hasError) return const Text('Não foi possível carregar as transações do caixa.');
      if (!movementSnapshot.hasData) return const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()));
      return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(stream: FirebaseFirestore.instance.collection('users').where('role', isEqualTo: 'client').snapshots(), builder: (context, clientSnapshot) {
        if (clientSnapshot.hasError) return const Text('Não foi possível gerar a previsão dos clientes.');
        if (!clientSnapshot.hasData) return const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()));
        final today = DateUtils.dateOnly(DateTime.now());
        final monthStart = DateTime(month.year, month.month);
        final nextMonth = DateTime(month.year, month.month + 1);
        final rows = <_MonthlyRow>[];
        final paidYields = <String>{};
        for (final doc in movementSnapshot.data!.docs) {
          final data = doc.data();
          if (data['clientId'] is String && data['dueMonth'] is String) paidYields.add('${data['clientId']}_${data['dueMonth']}');
          final dateValue = data['date'];
          if (dateValue is! Timestamp) continue;
          final date = dateValue.toDate();
          if (date.isBefore(monthStart) || !date.isBefore(nextMonth)) continue;
          final expense = data['type'] == 'expense';
          rows.add(_MonthlyRow(date: date, description: data['description'] as String? ?? (expense ? 'Despesa' : 'Receita'), category: data['category'] as String? ?? (expense ? 'Despesas' : 'Receitas'), account: data['account'] as String? ?? 'Mesa Principal', amount: (data['amount'] as num?)?.toDouble() ?? 0, expense: expense, status: 'Realizada'));
        }
        for (final client in clientSnapshot.data!.docs) {
          final data = client.data();
          if (data['active'] == false || data['earningDay'] is! num || data['earningStartDate'] is! Timestamp) continue;
          final earningDay = (data['earningDay'] as num).toInt();
          if (earningDay < 1 || earningDay > 31) continue;
          final dueDate = _dueDate(month.year, month.month, earningDay);
          final start = DateUtils.dateOnly((data['earningStartDate'] as Timestamp).toDate());
          if (dueDate.isBefore(start)) continue;
          final dueMonth = '${month.year}-${month.month.toString().padLeft(2, '0')}';
          if (paidYields.contains('${client.id}_$dueMonth')) continue;
          final principal = (data['principal'] as num?)?.toDouble() ?? 0;
          final rate = (data['monthlyRate'] as num?)?.toDouble() ?? 0;
          final projectedAmount = principal * rate / 100;
          rows.add(_MonthlyRow(date: dueDate, description: 'Dividendo · ${data['name'] as String? ?? 'Cliente'}', category: 'Dividendos', account: 'Mesa Principal', amount: projectedAmount, expense: true, status: dueDate.isBefore(today) ? 'Atrasada' : DateUtils.isSameDay(dueDate, today) ? 'Vence hoje' : 'Prevista', clientId: client.id, dueMonth: dueMonth, projected: true));
        }
        rows.sort((a, b) => b.date.compareTo(a.date));
        final monthIncome = rows.where((r) => !r.projected && !r.expense).fold<double>(0, (s, r) => s + r.amount);
        final monthPaidExpenses = rows.where((r) => !r.projected && r.expense).fold<double>(0, (s, r) => s + r.amount);
        final monthForecast = rows.where((r) => r.projected).fold<double>(0, (s, r) => s + r.amount);
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          card(Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('RECEITAS', style: TextStyle(fontSize: 10, color: muted)), const SizedBox(height: 5), Text(formatMoney(monthIncome), style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF198768)))]), Column(crossAxisAlignment: CrossAxisAlignment.center, children: [const Text('DESPESAS PAGAS', style: TextStyle(fontSize: 10, color: muted)), const SizedBox(height: 5), Text(formatMoney(monthPaidExpenses), style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFE05D79)))]), Column(crossAxisAlignment: CrossAxisAlignment.end, children: [const Text('DIVIDENDOS PREVISTOS', style: TextStyle(fontSize: 10, color: muted)), const SizedBox(height: 5), Text(formatMoney(monthForecast), style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFE05D79)))])])),
          const SizedBox(height: 12),
          if (rows.isEmpty) card(const Text('Nenhuma transação ou dividendo previsto para este mês.', style: TextStyle(color: muted)))
          else Container(decoration: BoxDecoration(color: surface, borderRadius: BorderRadius.circular(18)), child: SingleChildScrollView(scrollDirection: Axis.horizontal, child: DataTable(headingRowColor: MaterialStateProperty.all(violetWash), columns: const [DataColumn(label: Text('Situação')), DataColumn(label: Text('Data')), DataColumn(label: Text('Descrição')), DataColumn(label: Text('Categoria')), DataColumn(label: Text('Conta')), DataColumn(label: Text('Valor'), numeric: true), DataColumn(label: Text('Ações'))], rows: rows.map((row) {
            final tone = row.projected ? const Color(0xFFEA8A3A) : row.expense ? const Color(0xFFE05D79) : const Color(0xFF1D9A70);
            return DataRow(cells: [
              DataCell(Row(children: [Icon(row.projected ? Icons.schedule : Icons.check_circle, size: 16, color: tone), const SizedBox(width: 6), Text(row.status, style: TextStyle(color: tone, fontSize: 12))])),
              DataCell(Text(formatDate(row.date))), DataCell(Text(row.description)), DataCell(Text(row.category)), DataCell(Text(row.account)),
              DataCell(Text('${row.expense ? '−' : '+'} ${formatMoney(row.amount)}', style: TextStyle(color: row.expense ? const Color(0xFFE05D79) : const Color(0xFF1D9A70), fontWeight: FontWeight.bold))),
              DataCell(row.projected ? PopupMenuButton<String>(tooltip: 'Ações', onSelected: (action) { if (action == 'paid') _markAsPaid(context, row); }, itemBuilder: (_) => [PopupMenuItem(value: 'paid', enabled: !row.date.isAfter(today), child: const Text('Marcar como pago'))]) : IconButton(tooltip: 'Detalhes', onPressed: () => showDialog<void>(context: context, builder: (_) => AlertDialog(title: Text(row.description), content: Text('${row.category}\n${row.account}\n${formatDate(row.date)}\n${formatMoney(row.amount)}'), actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Fechar'))])), icon: const Icon(Icons.more_vert))),
            ]);
          }).toList()))),
        ]);
      });
    }),
  ]);
}

Widget cashBox(String label, String value, Color color) => Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: surfaceRaised, borderRadius: BorderRadius.circular(14)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label, style: const TextStyle(fontSize: 11, color: muted)), const SizedBox(height: 4), Text(value, style: TextStyle(fontWeight: FontWeight.bold, color: color))]));
void addMovement(BuildContext context, String type) => showModalBottomSheet<void>(context: context, isScrollControlled: true, builder: (_) => _NewMovementSheet(type: type));

class _NewMovementSheet extends StatefulWidget {
  const _NewMovementSheet({required this.type});
  final String type;
  @override
  State<_NewMovementSheet> createState() => _NewMovementSheetState();
}
class _NewMovementSheetState extends State<_NewMovementSheet> {
  final description = TextEditingController();
  final amount = TextEditingController();
  String? selectedClientId;
  String? selectedClientName;
  bool saving = false;
  String? error;
  Future<void> save() async {
    final value = double.tryParse(amount.text.trim().replaceAll('.', '').replaceAll(',', '.'));
    if (description.text.trim().isEmpty || value == null || value <= 0) { setState(() => error = 'Informe uma descrição e um valor válido.'); return; }
    setState(() { saving = true; error = null; });
    final now = DateTime.now();
    try {
      final firestore = FirebaseFirestore.instance;
      final movementRef = firestore.collection('cash_movements').doc();
      final movement = <String, dynamic>{
        'type': widget.type, 'description': description.text.trim(), 'amount': value,
        'date': Timestamp.fromDate(DateTime(now.year, now.month, now.day)),
        'createdAt': FieldValue.serverTimestamp(), 'createdBy': FirebaseAuth.instance.currentUser!.uid,
        'category': selectedClientId == null ? (widget.type == 'expense' ? 'Despesas' : 'Receitas') : (widget.type == 'expense' ? 'Saque de cliente' : 'Depósito de cliente'),
        'account': selectedClientName ?? 'Mesa Principal',
      };
      if (selectedClientId != null) {
        final clientRef = firestore.collection('users').doc(selectedClientId);
        final isDeposit = widget.type == 'receipt';
        final ledgerRef = clientRef.collection('ledger').doc('${isDeposit ? 'manual_deposit' : 'manual_withdrawal'}_${movementRef.id}');
        await firestore.runTransaction((transaction) async {
          final client = await transaction.get(clientRef);
          final data = client.data();
          if (!client.exists || data == null || data['role'] != 'client') throw StateError('Cliente não encontrado.');
          final balance = (data['balance'] as num?)?.toDouble() ?? (data['principal'] as num?)?.toDouble() ?? 0;
          final principal = (data['principal'] as num?)?.toDouble() ?? balance;
          final totalDeposits = (data['totalDeposits'] as num?)?.toDouble() ?? principal;
          final newBalance = isDeposit ? balance + value : balance - value;
          if (!isDeposit && value > balance) throw StateError('O valor ultrapassa o saldo atual do cliente (${formatMoney(balance)}).');
          final newPrincipal = isDeposit ? principal + value : (principal - value).clamp(0.0, principal).toDouble();
          final newTotalDeposits = isDeposit ? totalDeposits + value : totalDeposits;
          final ledgerTitle = isDeposit ? 'Novo depósito' : 'Retirada lançada pelo administrador';
          final ledgerType = isDeposit ? 'credit' : 'debit';
          transaction.set(movementRef, {...movement, 'kind': isDeposit ? 'client_deposit' : 'manual_client_withdrawal', 'clientId': selectedClientId});
          transaction.update(clientRef, {'balance': newBalance, 'principal': newPrincipal, 'totalDeposits': newTotalDeposits, if (!isDeposit) 'immediateAvailable': (((data['immediateAvailable'] as num?)?.toDouble() ?? 0) - value).clamp(0.0, newBalance).toDouble(), 'updatedAt': FieldValue.serverTimestamp()});
          transaction.set(ledgerRef, {'type': ledgerType, 'title': ledgerTitle, 'description': description.text.trim(), 'amount': value, 'balanceAfter': newBalance, 'date': Timestamp.fromDate(DateUtils.dateOnly(now)), 'createdAt': FieldValue.serverTimestamp(), 'source': isDeposit ? 'manual_deposit' : 'manual_withdrawal'});
        });
      } else {
        await movementRef.set(movement);
      }
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(selectedClientId != null ? (widget.type == 'receipt' ? 'Depósito registrado. O capital e o saldo de $selectedClientName foram atualizados.' : 'Retirada registrada no caixa e descontada do saldo de $selectedClientName.') : '${widget.type == 'receipt' ? 'Receita' : 'Despesa'} lançada com a data de hoje.')));
    } catch (e) { setState(() => error = e is StateError ? e.message.toString() : 'Não foi possível salvar. Verifique se as regras do Firestore foram publicadas.'); }
    finally { if (mounted) setState(() => saving = false); }
  }
  @override
  void dispose() { description.dispose(); amount.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    return Padding(padding: EdgeInsets.fromLTRB(22, 24, 22, MediaQuery.of(context).viewInsets.bottom + 22), child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(widget.type == 'receipt' ? 'Lançar receita' : 'Lançar despesa', style: const TextStyle(fontSize: 21, fontWeight: FontWeight.bold)), const SizedBox(height: 8),
      Text('Data do lançamento: ${today.day.toString().padLeft(2, '0')}/${today.month.toString().padLeft(2, '0')}/${today.year} · hoje', style: const TextStyle(color: muted)), const SizedBox(height: 16),
      ...[
        StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(stream: FirebaseFirestore.instance.collection('users').where('role', isEqualTo: 'client').snapshots(), builder: (context, snapshot) {
          if (!snapshot.hasData) return const LinearProgressIndicator();
          final clients = snapshot.data!.docs;
          return DropdownButtonFormField<String>(value: selectedClientId ?? '', decoration: const InputDecoration(labelText: 'Carteira / cliente (opcional)'), items: [DropdownMenuItem(value: '', child: Text(widget.type == 'expense' ? 'Despesa geral da mesa' : 'Receita geral da mesa')), ...clients.map((client) => DropdownMenuItem(value: client.id, child: Text(client.data()['name'] as String? ?? 'Cliente')))], onChanged: (id) { setState(() { selectedClientId = id == null || id.isEmpty ? null : id; selectedClientName = id == null || id.isEmpty ? null : clients.firstWhere((client) => client.id == id).data()['name'] as String? ?? 'Cliente'; if (selectedClientId != null && description.text.trim().isEmpty) description.text = widget.type == 'expense' ? 'Retirada · $selectedClientName' : 'Depósito · $selectedClientName'; }); });
        }),
        const SizedBox(height: 12),
        if (selectedClientId != null) Text(widget.type == 'expense' ? 'Ao salvar, o valor será descontado do saldo e do limite de saque imediato do cliente.' : 'Ao salvar, o valor será somado ao saldo e ao capital aplicado; o rendimento futuro usará o novo capital.', style: const TextStyle(fontSize: 12, color: muted)),
        const SizedBox(height: 12),
      ],
      TextField(controller: description, decoration: InputDecoration(labelText: widget.type == 'receipt' ? 'Descrição da receita' : 'Descrição da despesa')),
      const SizedBox(height: 12), TextField(controller: amount, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Valor (R\$)')),
      if (error != null) Padding(padding: const EdgeInsets.only(top: 12), child: Text(error!, style: const TextStyle(color: Color(0xFFBC4352)))),
      const SizedBox(height: 18), SizedBox(width: double.infinity, child: FilledButton(onPressed: saving ? null : save, child: saving ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : Text('Salvar ${widget.type == 'receipt' ? 'receita' : 'despesa'}'))),
    ]));
  }
}

class RequestsPage extends StatelessWidget {
  const RequestsPage({super.key});
  @override
  Widget build(BuildContext context) => StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
    stream: FirebaseFirestore.instance.collection('withdrawal_requests').orderBy('createdAt', descending: true).snapshots(),
    builder: (context, snapshot) {
      if (snapshot.hasError) return const Center(child: Text('Não foi possível carregar os saques.'));
      if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
      final requests = snapshot.data!.docs;
      final pending = requests.where((d) => d.data()['status'] == 'pending').toList();
      return ListView(padding: EdgeInsets.fromLTRB(20, MediaQuery.of(context).padding.top + kToolbarHeight + 20, 20, 20), children: [const Text('Solicitações', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: ink)), const SizedBox(height: 5), const Text('Revise os pedidos e registre os pagamentos.', style: TextStyle(color: muted)), const SizedBox(height: 20), card(Row(children: [const Icon(Icons.info_outline, color: Color(0xFFFFC266)), const SizedBox(width: 10), Expanded(child: Text('${pending.length} solicitações aguardando análise.', style: const TextStyle(color: Color(0xFFFFD08A), fontWeight: FontWeight.w600)))])), const SizedBox(height: 14), if (requests.isEmpty) card(const Text('Ainda não há solicitações de saque.')),
        ...requests.map((doc) { final data = doc.data(); final uid = data['userId'] as String? ?? ''; final amount = (data['amount'] as num?)?.toDouble() ?? 0; final created = data['createdAt']; final date = data['requestedDate'] as String? ?? (created is Timestamp ? formatDate(created.toDate()) : ''); final status = data['status'] as String? ?? 'pending'; final pendingRequest = status == 'pending'; final statusText = status == 'completed' ? 'Concluído' : status == 'rejected' ? 'Recusado' : 'Pendente'; final statusColor = status == 'completed' ? const Color(0xFF198768) : status == 'rejected' ? const Color(0xFFE05D79) : muted; return Padding(padding: const EdgeInsets.only(bottom: 12), child: FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(future: FirebaseFirestore.instance.collection('users').doc(uid).get(), builder: (context, userSnapshot) { final name = userSnapshot.data?.data()?['name'] as String? ?? 'Cliente'; return card(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(children: [const CircleAvatar(backgroundColor: violetWash, child: Icon(Icons.person_outline, color: violet)), const SizedBox(width: 11), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(name, style: const TextStyle(fontWeight: FontWeight.bold, color: ink)), Text('$date · $statusText', style: TextStyle(fontSize: 11, color: statusColor))])), Text(formatMoney(amount), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: ink))]), if (status == 'completed') ...[const SizedBox(height: 8), Text('Pago: ${formatMoney((data['paidAmount'] as num?)?.toDouble() ?? amount)}${data['partial'] == true ? ' · Parcial' : ''}', style: const TextStyle(color: Color(0xFF198768), fontWeight: FontWeight.w600))] else if (pendingRequest) ...[const SizedBox(height: 15), Row(children: [Expanded(child: OutlinedButton(onPressed: () => updateWithdrawalStatus(context, doc, 'rejected'), child: const Text('Recusar'))), const SizedBox(width: 10), Expanded(child: FilledButton(onPressed: () => completeWithdrawal(context, doc, name), style: FilledButton.styleFrom(backgroundColor: violet), child: const Text('Concluir saque')))])]])); })); })
      ]);
    },
  );
}

Future<void> updateWithdrawalStatus(BuildContext context, QueryDocumentSnapshot<Map<String, dynamic>> request, String status) async {
  await request.reference.update({'status': status, 'reviewedAt': FieldValue.serverTimestamp(), 'reviewedBy': FirebaseAuth.instance.currentUser!.uid});
}

Future<void> completeWithdrawal(BuildContext context, QueryDocumentSnapshot<Map<String, dynamic>> request, String name) async {
  final data = request.data();
  final uid = data['userId'] as String?;
  if (uid == null) return;
  final requested = (data['amount'] as num?)?.toDouble() ?? 0;
  final controller = TextEditingController(text: requested.toStringAsFixed(2).replaceAll('.', ','));
  final amount = await showDialog<double>(context: context, builder: (dialogContext) => AlertDialog(title: const Text('Concluir saque'), content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Pedido de ${formatMoney(requested)} para $name. Informe o valor efetivamente retirado; pode ser parcial.'), const SizedBox(height: 12), TextField(controller: controller, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Valor pago (R\$)'))]), actions: [TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancelar')), FilledButton(onPressed: () { final value = double.tryParse(controller.text.trim().replaceAll('.', '').replaceAll(',', '.')); Navigator.pop(dialogContext, value); }, child: const Text('Registrar pagamento'))]));
  controller.dispose();
  if (amount == null) return;
  if (amount <= 0 || amount > requested) { if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('O valor precisa ser maior que zero e não pode superar o solicitado.'))); return; }
  final firestore = FirebaseFirestore.instance;
  final userRef = firestore.collection('users').doc(uid);
  final movementRef = firestore.collection('cash_movements').doc('withdrawal_${request.id}');
  final ledgerRef = userRef.collection('ledger').doc('withdrawal_${request.id}');
  try {
    await firestore.runTransaction((transaction) async {
      final user = await transaction.get(userRef);
      final req = await transaction.get(request.reference);
      final userData = user.data();
      if (!user.exists || userData == null || req.data()?['status'] != 'pending') throw StateError('O pedido já foi processado ou o cliente não existe.');
      final balance = (userData['balance'] as num?)?.toDouble() ?? (userData['principal'] as num?)?.toDouble() ?? 0;
      final immediateAvailable = (userData['immediateAvailable'] as num?)?.toDouble() ?? 0;
      if (amount > balance) throw StateError('O valor supera o saldo disponível do cliente.');
      if (amount > immediateAvailable) throw StateError('O valor supera o limite de saque imediato configurado.');
      final newBalance = balance - amount;
      final principal = (userData['principal'] as num?)?.toDouble() ?? balance;
      final newPrincipal = (principal - amount).clamp(0.0, principal).toDouble();
      final newImmediateAvailable = (immediateAvailable - amount).clamp(0.0, newBalance).toDouble();
      final now = DateUtils.dateOnly(DateTime.now());
      transaction.update(userRef, {'balance': newBalance, 'principal': newPrincipal, 'immediateAvailable': newImmediateAvailable, 'updatedAt': FieldValue.serverTimestamp()});
      transaction.update(request.reference, {'status': 'completed', 'paidAmount': amount, 'partial': amount < requested, 'reviewedAt': FieldValue.serverTimestamp(), 'reviewedBy': FirebaseAuth.instance.currentUser!.uid});
      transaction.set(movementRef, {'type': 'expense', 'kind': 'withdrawal', 'description': 'Saque · $name', 'category': 'Saques', 'account': 'Mesa Principal', 'amount': amount, 'date': Timestamp.fromDate(now), 'createdAt': FieldValue.serverTimestamp(), 'createdBy': FirebaseAuth.instance.currentUser!.uid, 'clientId': uid, 'withdrawalRequestId': request.id});
      transaction.set(ledgerRef, {'type': 'debit', 'title': amount < requested ? 'Saque parcial concluído' : 'Saque concluído', 'description': 'Solicitação de saque', 'amount': amount, 'balanceAfter': newBalance, 'date': Timestamp.fromDate(now), 'createdAt': FieldValue.serverTimestamp(), 'source': 'withdrawal', 'requestId': request.id});
    });
    if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Saque concluído e saldo atualizado.')));
  } catch (e) { if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Não foi possível concluir o saque: $e'))); }
}

void showDates(BuildContext context) => showModalBottomSheet<void>(
      context: context,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(22),
        child: Column(mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Datas disponíveis para saque',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('Selecione os dias liberados para seus clientes.',
              style: TextStyle(color: muted)),
          const SizedBox(height: 18),
          Wrap(spacing: 8, children: [2, 5, 10, 15, 20, 25]
              .map((d) => FilterChip(
                    label: Text('Dia $d'),
                    selected: [5, 15].contains(d),
                    onSelected: (_) {},
                  )).toList()),
          const SizedBox(height: 12),
          SizedBox(width: double.infinity,
              child: FilledButton(onPressed: () => Navigator.pop(context),
                  child: const Text('Salvar datas'))),
        ]),
      ),
    );

class ClientShell extends StatelessWidget {
  const ClientShell({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(extendBodyBehindAppBar: true, appBar: AppBar(flexibleSpace: glassBarSurface(), title: purpleCoreLogo(iconSize: 34, titleSize: 20), actions: [IconButton(onPressed: () => logout(context), icon: const Icon(Icons.logout))]), body: const ClientHome());
}
class ClientHome extends StatelessWidget {
  const ClientHome({super.key});
  @override
  Widget build(BuildContext context) => StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance.collection('users').doc(FirebaseAuth.instance.currentUser!.uid).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return const Center(child: Padding(padding: EdgeInsets.all(24), child: Text('Não foi possível carregar seu saldo. Confira as regras do Firestore.')));
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final data = snapshot.data!.data() ?? <String, dynamic>{};
          final name = data['name'] as String? ?? 'Cliente';
          final principal = (data['principal'] as num?)?.toDouble() ?? 0;
          final balance = (data['balance'] as num?)?.toDouble() ?? principal;
          final immediateAvailable = (data['immediateAvailable'] as num?)?.toDouble() ?? 0;
          final totalDeposits = (data['totalDeposits'] as num?)?.toDouble() ?? principal;
          final rate = (data['monthlyRate'] as num?)?.toDouble() ?? 0;
          final earningStartDate = data['earningStartDate'] is Timestamp ? (data['earningStartDate'] as Timestamp).toDate() : null;
          final earningDay = (data['earningDay'] as num?)?.toInt() ?? earningStartDate?.day;
          final nextYield = earningDay != null && earningStartDate != null && earningDay >= 1 && earningDay <= 31 ? nextEarningDate(earningDay, earningStartDate) : null;
          return _dashboard(context, name, principal, balance, totalDeposits, immediateAvailable, rate, data['position'] as String? ?? '', nextYield);
        },
      );

  Widget _dashboard(BuildContext context, String name, double principal, double balance, double totalDeposits, double immediateAvailable, double rate, String position, DateTime? nextYield) => ListView(
        padding: EdgeInsets.fromLTRB(20, MediaQuery.of(context).padding.top + kToolbarHeight + 20, 20, 20),
        children: [
          Text('Olá, $name 👋',
              style: TextStyle(color: muted)),
          const SizedBox(height: 4),
          const Text('Seu patrimônio',
              style: TextStyle(
                  fontSize: 25, fontWeight: FontWeight.w800, color: ink)),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                  colors: [Color(0xFF30225E), Color(0xFF7654E8)]),
              borderRadius: BorderRadius.circular(25),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('SALDO TOTAL',
                    style: TextStyle(
                        color: Colors.white70,
                        letterSpacing: 1.2,
                        fontSize: 11,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                Text(formatMoney(balance),
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 31,
                        fontWeight: FontWeight.w800)),
                const SizedBox(height: 20),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                  decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: .15),
                      borderRadius: BorderRadius.circular(13)),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.trending_up,
                          color: Color(0xFFBFF4DB), size: 18),
                      SizedBox(width: 7),
                      Text('+ ${formatMoney(principal * rate / 100)} neste mês',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          card(Row(children: [const Icon(Icons.savings_outlined, color: violet), const SizedBox(width: 10), const Expanded(child: Text('Total depositado (bruto)', style: TextStyle(color: muted))), Text(formatMoney(totalDeposits), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: ink))])),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(
                child: metric('VALOR INVESTIDO', formatMoney(principal),
                    Icons.savings_outlined, violet)),
            const SizedBox(width: 12),
            Expanded(
                child: metric('RENDIMENTO', '${rate.toStringAsFixed(2)}% ao mês', Icons.percent,
                    const Color(0xFF1D9A70))),
          ]),
          const SizedBox(height: 16),
          card(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('POSICIONAMENTO DO CAPITAL', style: TextStyle(fontSize: 10, letterSpacing: .7, fontWeight: FontWeight.bold, color: muted)), const SizedBox(height: 8), Text(position.trim().isEmpty ? 'Esperando alocação.' : position, style: const TextStyle(color: ink))])),
          const SizedBox(height: 12),
          card(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('DISPONÍVEL PARA SAQUE IMEDIATO', style: TextStyle(fontSize: 10, letterSpacing: .7, fontWeight: FontWeight.bold, color: muted)), const SizedBox(height: 8), Text(formatMoney(immediateAvailable.clamp(0.0, balance)), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: violet)), const SizedBox(height: 4), const Text('Para solicitar um valor maior, fale diretamente com o administrador.', style: TextStyle(fontSize: 12, color: muted))])),
          const SizedBox(height: 24),
          sectionTitle('Próximo rendimento', nextYield == null ? 'Data não definida' : shortDateLabel(nextYield)),
          const SizedBox(height: 12),
          card(Row(children: [
            Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                    color: violetWash,
                    borderRadius: BorderRadius.circular(14)),
                child: const Icon(Icons.event_available_outlined,
                    color: violet)),
            const SizedBox(width: 12),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(nextYield == null ? 'Rendimento mensal' : 'Crédito em ${formatDate(nextYield)}',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, color: ink)),
                  Text(nextYield == null ? 'Data não configurada pelo administrador' : 'Previsão de crédito',
                      style:
                          TextStyle(fontSize: 12, color: muted)),
                ])),
            Text('+ ${formatMoney(principal * rate / 100)}',
                style: const TextStyle(
                    fontWeight: FontWeight.bold, color: Color(0xFF198768))),
          ])),
          const SizedBox(height: 24),
          const Text('Movimentações recentes',
              style: TextStyle(
                  fontSize: 17, fontWeight: FontWeight.w800, color: ink)),
          const SizedBox(height: 12),
          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(stream: FirebaseFirestore.instance.collection('users').doc(FirebaseAuth.instance.currentUser!.uid).collection('ledger').orderBy('date', descending: true).limit(20).snapshots(), builder: (context, history) {
            if (history.hasError) return card(const Text('Não foi possível carregar o histórico de saldo.'));
            if (!history.hasData) return card(const Center(child: CircularProgressIndicator()));
            if (history.data!.docs.isEmpty) return card(Column(children: [cashLine('Rendimento mensal estimado', formatMoney(principal * rate / 100), true), const Divider(height: 18), const Text('Os créditos e saques concluídos aparecerão aqui.', style: TextStyle(color: muted, fontSize: 12))]));
            return card(Column(children: history.data!.docs.map((doc) { final entry = doc.data(); final dateValue = entry['date']; final date = dateValue is Timestamp ? formatDate(dateValue.toDate()) : ''; final credit = entry['type'] == 'credit'; final amount = (entry['amount'] as num?)?.toDouble() ?? 0; return Padding(padding: const EdgeInsets.symmetric(vertical: 7), child: Row(children: [Icon(credit ? Icons.add_circle_outline : Icons.remove_circle_outline, color: credit ? const Color(0xFF198768) : const Color(0xFFE05D79), size: 19), const SizedBox(width: 9), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(entry['title'] as String? ?? 'Movimentação', style: const TextStyle(fontWeight: FontWeight.bold, color: ink)), Text(date, style: const TextStyle(fontSize: 11, color: muted))])), Text('${credit ? '+' : '−'} ${formatMoney(amount)}', style: TextStyle(color: credit ? const Color(0xFF198768) : const Color(0xFFE05D79), fontWeight: FontWeight.bold))])); }).toList()));
          }),
          const SizedBox(height: 24),
          SizedBox(
            height: 54,
            child: FilledButton.icon(
              onPressed: immediateAvailable <= 0 ? null : () => requestWithdraw(context, balance, immediateAvailable),
              style: FilledButton.styleFrom(
                  backgroundColor: violet,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16))),
              icon: const Icon(Icons.north_east),
              label: const Text('Solicitar saque',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          ),
          const SizedBox(height: 10),
          const Text('Solicitações sujeitas à aprovação do seu assessor (Junior).',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11, color: muted)),
        ],
      );
}
void requestWithdraw(BuildContext context, double balance, double immediateAvailable) => showModalBottomSheet<void>(context: context, isScrollControlled: true, builder: (_) => _WithdrawalSheet(balance: balance, immediateAvailable: immediateAvailable));

class _WithdrawalSheet extends StatefulWidget {
  const _WithdrawalSheet({required this.balance, required this.immediateAvailable});
  final double balance;
  final double immediateAvailable;
  @override
  State<_WithdrawalSheet> createState() => _WithdrawalSheetState();
}

class _WithdrawalSheetState extends State<_WithdrawalSheet> {
  final amountController = TextEditingController();
  bool saving = false;
  String? error;
  double get allowedAmount => widget.immediateAvailable.clamp(0.0, widget.balance).toDouble();
  Future<void> submit() async {
    final amount = double.tryParse(amountController.text.trim().replaceAll('.', '').replaceAll(',', '.'));
    if (amount == null || amount <= 0 || amount > allowedAmount) { setState(() => error = 'Informe um valor positivo até ${formatMoney(allowedAmount)}. Para solicitar acima desse limite, fale diretamente com o seu assessor (Junior).'); return; }
    setState(() { saving = true; error = null; });
    try {
      await FirebaseFirestore.instance.collection('withdrawal_requests').add({'userId': FirebaseAuth.instance.currentUser!.uid, 'amount': amount, 'status': 'pending', 'createdAt': FieldValue.serverTimestamp()});
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Solicitação enviada para análise.')));
    } catch (_) { setState(() => error = 'Não foi possível enviar a solicitação.'); }
    finally { if (mounted) setState(() => saving = false); }
  }
  @override
  void dispose() { amountController.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => Padding(padding: EdgeInsets.fromLTRB(22, 24, 22, MediaQuery.of(context).viewInsets.bottom + 22), child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('Solicitar saque', style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold)), const SizedBox(height: 8), Text('Saldo total: ${formatMoney(widget.balance)}', style: const TextStyle(color: muted)), Text('Disponível para saque imediato: ${formatMoney(allowedAmount)}', style: const TextStyle(color: violet, fontWeight: FontWeight.w600)), const SizedBox(height: 18), TextField(controller: amountController, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: 'Valor do saque (máx. ${formatMoney(allowedAmount)})', prefixIcon: const Icon(Icons.payments_outlined))), const SizedBox(height: 8), const Text('Para solicitar acima do valor liberado para saque imediato, fale diretamente com o administrador.', style: TextStyle(fontSize: 12, color: muted)), if (error != null) Padding(padding: const EdgeInsets.only(top: 10), child: Text(error!, style: const TextStyle(color: Color(0xFFBC4352)))), const SizedBox(height: 14), SizedBox(width: double.infinity, child: FilledButton(onPressed: saving || allowedAmount <= 0 ? null : submit, child: saving ? const CircularProgressIndicator() : const Text('Enviar solicitação')))]));
}
