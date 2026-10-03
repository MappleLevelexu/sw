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
  bool refreshing = false;
  final titles = ['Visão geral', 'Clientes', 'Caixa', 'Solicitações'];

  Future<void> _refreshData() async {
    if (refreshing) return;
    setState(() => refreshing = true);
    try {
      final db = FirebaseFirestore.instance;
      await Future.wait([
        db.collection('settings').doc('treasury').get(const GetOptions(source: Source.server)),
        db.collection('cash_movements').get(const GetOptions(source: Source.server)),
        db.collection('users').where('role', isEqualTo: 'client').get(const GetOptions(source: Source.server)),
        db.collection('cash_recurring').where('active', isEqualTo: true).get(const GetOptions(source: Source.server)),
        db.collection('withdrawal_requests').get(const GetOptions(source: Source.server)),
      ]);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Dados atualizados.')));
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Não foi possível atualizar. Verifique sua conexão.')));
    } finally {
      if (mounted) setState(() => refreshing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final pages = [const DashboardPage(), const ClientsPage(), const CashPage(), const RequestsPage()];
    return Scaffold(
      extendBody: true,
      extendBodyBehindAppBar: true,
      appBar: AppBar(flexibleSpace: glassBarSurface(), title: purpleCoreLogo(iconSize: 34, titleSize: 20), actions: [IconButton(tooltip: 'Atualizar dados', onPressed: refreshing ? null : _refreshData, icon: Icon(refreshing ? Icons.sync : Icons.refresh)), IconButton(onPressed: () => showDates(context), icon: const Icon(Icons.calendar_month_outlined)), IconButton(onPressed: () => logout(context), icon: const Icon(Icons.logout))]),
      body: RefreshIndicator(onRefresh: _refreshData, child: SafeArea(top: false, child: IndexedStack(index: index, children: pages))),
      bottomNavigationBar: ClipRect(child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18), child: NavigationBar(backgroundColor: const Color(0x66161020), indicatorColor: violet.withValues(alpha: .22), selectedIndex: index, onDestinationSelected: (v) => setState(() => index = v), destinations: const [NavigationDestination(icon: Icon(Icons.grid_view_rounded), label: 'Início'), NavigationDestination(icon: Icon(Icons.people_outline), label: 'Clientes'), NavigationDestination(icon: Icon(Icons.swap_vert_rounded), label: 'Transações'), NavigationDestination(icon: Icon(Icons.notifications_none), label: 'Saques')]))),
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
          return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance.collection('users').where('role', isEqualTo: 'client').snapshots(),
            builder: (context, clientSnapshot) {
              if (clientSnapshot.hasError) return const Center(child: Text('Erro ao carregar previsões dos clientes.'));
              if (!clientSnapshot.hasData) return const Center(child: CircularProgressIndicator());
              return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: FirebaseFirestore.instance.collection('cash_recurring').where('active', isEqualTo: true).snapshots(),
                builder: (context, recurringSnapshot) {
                  if (recurringSnapshot.hasError) return const Center(child: Text('Erro ao carregar previsões recorrentes.'));
                  if (!recurringSnapshot.hasData) return const Center(child: CircularProgressIndicator());
          final now = DateTime.now();
          final actual = movementSnapshot.data!.docs.where((doc) {
            final data = doc.data();
            final date = data['date'];
            return date is Timestamp && !date.toDate().isAfter(now) && data['status'] != 'scheduled';
          }).toList();
          final income = actual.where((d) => d.data()['type'] == 'receipt').fold<double>(0, (s, d) => s + ((d.data()['amount'] as num?)?.toDouble() ?? 0));
          final expenses = actual.where((d) => d.data()['type'] == 'expense').fold<double>(0, (s, d) => s + ((d.data()['amount'] as num?)?.toDouble() ?? 0));
          final currentCash = openingCapital + income - expenses;
          final planned = movementSnapshot.data!.docs.where((doc) {
            final data = doc.data();
            final date = data['date'];
            return date is Timestamp && (date.toDate().isAfter(now) || data['status'] == 'scheduled');
          }).toList();
          var plannedIncome = planned.where((d) => d.data()['type'] == 'receipt').fold<double>(0, (s, d) => s + ((d.data()['amount'] as num?)?.toDouble() ?? 0));
          var plannedExpenses = planned.where((d) => d.data()['type'] == 'expense').fold<double>(0, (s, d) => s + ((d.data()['amount'] as num?)?.toDouble() ?? 0));
          final monthStart = DateTime(now.year, now.month);
          final nextMonth = DateTime(now.year, now.month + 1);
          final paidYieldKeys = <String>{};
          final paidRecurringKeys = <String>{};
          for (final doc in movementSnapshot.data!.docs) {
            final data = doc.data();
            if (data['clientId'] is String && data['dueMonth'] is String) paidYieldKeys.add('${data['clientId']}_${data['dueMonth']}');
            if (data['recurrenceId'] is String && data['dueMonth'] is String) paidRecurringKeys.add('${data['recurrenceId']}_${data['dueMonth']}');
          }
          int dueDay(int year, int month, int day) => DateTime(year, month + 1, 0).day < day ? DateTime(year, month + 1, 0).day : day;
          final dueMonth = '${now.year}-${now.month.toString().padLeft(2, '0')}';
          for (final clientDoc in clientSnapshot.data!.docs) {
            final data = clientDoc.data();
            if (data['active'] == false || data['earningDay'] is! num || data['earningStartDate'] is! Timestamp || paidYieldKeys.contains('${clientDoc.id}_$dueMonth')) continue;
            final earningDay = (data['earningDay'] as num).toInt();
            if (earningDay < 1 || earningDay > 31) continue;
            final dueDate = DateTime(now.year, now.month, dueDay(now.year, now.month, earningDay));
            if (dueDate.isBefore(DateUtils.dateOnly((data['earningStartDate'] as Timestamp).toDate())) || dueDate.isBefore(monthStart) || !dueDate.isBefore(nextMonth)) continue;
            final principal = (data['principal'] as num?)?.toDouble() ?? 0;
            final rate = (data['monthlyRate'] as num?)?.toDouble() ?? 0;
            plannedExpenses += principal * rate / 100;
          }
          for (final recurringDoc in recurringSnapshot.data!.docs) {
            final data = recurringDoc.data();
            final startValue = data['date'];
            if (startValue is! Timestamp) continue;
            final start = DateUtils.dateOnly(startValue.toDate());
            final offset = (now.year - start.year) * 12 + now.month - start.month;
            final mode = data['repeatMode'] as String? ?? 'temporary';
            final count = (data['occurrenceCount'] as num?)?.toInt();
            if (offset < 0 || (mode == 'temporary' && (count == null || offset >= count))) continue;
            final day = dueDay(now.year, now.month, start.day);
            final dueDate = DateTime(now.year, now.month, day);
            final key = '${recurringDoc.id}_$dueMonth';
            final cancelledMonths = data['cancelledMonths'] as List? ?? const [];
            if (dueDate.isBefore(start) || dueDate.isBefore(monthStart) || !dueDate.isBefore(nextMonth) || paidRecurringKeys.contains(key) || cancelledMonths.contains(dueMonth)) continue;
            final amount = (data['amount'] as num?)?.toDouble() ?? 0;
            if (data['type'] == 'expense') {
              plannedExpenses += amount;
            } else {
              plannedIncome += amount;
            }
          }
          final projectedCash = currentCash + plannedIncome - plannedExpenses;
          return ListView(padding: EdgeInsets.fromLTRB(20, MediaQuery.of(context).padding.top + kToolbarHeight + 12, 20, 28), children: [
            const Text('Bom dia, administrador 👋', style: TextStyle(color: muted)),
            const SizedBox(height: 4), const Text('Sua mesa hoje', style: TextStyle(fontSize: 25, fontWeight: FontWeight.w800, color: ink)),
            const SizedBox(height: 20),
            Container(padding: const EdgeInsets.all(22), decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF30225E), Color(0xFF7654E8)]), borderRadius: BorderRadius.circular(25)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const Text('CAPITAL DISPONÍVEL', style: TextStyle(color: Colors.white70, letterSpacing: 1.2, fontSize: 11, fontWeight: FontWeight.bold)), const SizedBox(height: 12), Text(formatMoney(currentCash), style: const TextStyle(color: Colors.white, fontSize: 31, fontWeight: FontWeight.w800)), const SizedBox(height: 16), Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [const Text('Capital inicial', style: TextStyle(color: Colors.white70)), Text(formatMoney(openingCapital), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))]), Align(alignment: Alignment.centerRight, child: TextButton(onPressed: () => editOpeningCapital(context, openingCapital), child: const Text('Ajustar capital inicial', style: TextStyle(color: Colors.white))))])),
            const SizedBox(height: 16),
            Row(children: [Expanded(child: metric('RECEITAS REALIZADAS', formatMoney(income), Icons.south_west, const Color(0xFF1D9A70))), const SizedBox(width: 12), Expanded(child: metric('DESPESAS REALIZADAS', formatMoney(expenses), Icons.north_east, const Color(0xFFE05D79)))]),
            const SizedBox(height: 16),
            card(Column(children: [cashLine('Entradas previstas', '+ ${formatMoney(plannedIncome)}', true), cashLine('Saídas previstas', '− ${formatMoney(plannedExpenses)}', false), const Divider(height: 18), cashLine('Saldo após lançamentos previstos', formatMoney(projectedCash), projectedCash >= 0, bold: true)])),
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

class CashPage extends StatelessWidget {
  const CashPage({super.key});
  @override
  Widget build(BuildContext context) => ListView(
        padding: EdgeInsets.fromLTRB(20, MediaQuery.of(context).padding.top + kToolbarHeight + 20, 20, 28),
        children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Text('Transações', style: TextStyle(fontSize: 25, fontWeight: FontWeight.w800, color: ink)),
            PopupMenuButton<String>(
              onSelected: (type) => addMovement(context, type),
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'receipt', child: Text('Lançar receita')),
                PopupMenuItem(value: 'expense', child: Text('Lançar despesa / retirada')),
              ],
              child: Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10), decoration: BoxDecoration(color: violet, borderRadius: BorderRadius.circular(14)), child: const Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.add, size: 18, color: Colors.white), SizedBox(width: 4), Text('Adicionar', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))])),
            ),
          ]),
          const SizedBox(height: 4),
          const Text('Acompanhe receitas, despesas e repasses por data.', style: TextStyle(color: muted)),
          const SizedBox(height: 16),
          const FutureYieldSchedule(),
        ],
      );
}

class _MonthlyRow {
  const _MonthlyRow({required this.date, required this.description, required this.category, required this.account, required this.amount, required this.expense, required this.status, this.clientId, this.dueMonth, this.movementId, this.recurringId, this.notes, this.projected = false});
  final DateTime date;
  final String description;
  final String category;
  final String account;
  final double amount;
  final bool expense;
  final String status;
  final String? clientId;
  final String? dueMonth;
  final String? movementId;
  final String? recurringId;
  final String? notes;
  final bool projected;
  String get selectionKey => movementId ?? (recurringId != null ? 'repeat:$recurringId:$dueMonth' : 'yield:$clientId:$dueMonth');
}

class FutureYieldSchedule extends StatefulWidget {
  const FutureYieldSchedule({super.key});
  @override
  State<FutureYieldSchedule> createState() => _FutureYieldScheduleState();
}

class _FutureYieldScheduleState extends State<FutureYieldSchedule> {
  DateTime month = DateTime(DateTime.now().year, DateTime.now().month);
  final Set<String> selectedRows = <String>{};

  DateTime _dueDate(int year, int month, int requestedDay) {
    final lastDay = DateTime(year, month + 1, 0).day;
    return DateTime(year, month, requestedDay > lastDay ? lastDay : requestedDay);
  }

  String _monthLabel() {
    const months = ['Janeiro', 'Fevereiro', 'Março', 'Abril', 'Maio', 'Junho', 'Julho', 'Agosto', 'Setembro', 'Outubro', 'Novembro', 'Dezembro'];
    return '${months[month.month - 1]} ${month.year}';
  }

  String _weekdayLabel(DateTime date) {
    const weekdays = ['Segunda-feira', 'Terça-feira', 'Quarta-feira', 'Quinta-feira', 'Sexta-feira', 'Sábado', 'Domingo'];
    return '${weekdays[date.weekday - 1]}, ${date.day}';
  }

  Future<void> _markAsPaid(BuildContext context, _MonthlyRow row) async {
    if (row.recurringId != null && row.dueMonth != null) {
      await _settleRecurring(context, row);
      return;
    }
    final isEarly = DateUtils.dateOnly(row.date).isAfter(DateUtils.dateOnly(DateTime.now()));
    final clientName = row.description.replaceFirst('Dividendo · ', '');
    final actionLabel = isEarly ? 'Fazer repasse agora' : 'Marcar como pago';
    final confirmed = await showDialog<bool>(context: context, builder: (dialogContext) => AlertDialog(title: Text(isEarly ? 'Antecipar repasse?' : 'Confirmar repasse'), content: Text('Registrar ${formatMoney(row.amount)} para $clientName agora? A previsão original é ${formatDate(row.date)}.'), actions: [TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancelar')), FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: Text(actionLabel))]));
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

  Future<void> _settleRecurring(BuildContext context, _MonthlyRow row) async {
    final isEarly = DateUtils.dateOnly(row.date).isAfter(DateUtils.dateOnly(DateTime.now()));
    final action = row.expense ? 'Marcar como pago' : 'Marcar como recebido';
    final confirmed = await showDialog<bool>(context: context, builder: (dialogContext) => AlertDialog(
      title: Text(isEarly ? 'Concluir lançamento antes da data?' : 'Concluir lançamento?'),
      content: Text('Registrar ${formatMoney(row.amount)} de “${row.description}” ${row.expense ? 'como pago' : 'como recebido'} agora? A data prevista era ${formatDate(row.date)}.'),
      actions: [TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancelar')), FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: Text(action))],
    ));
    if (confirmed != true || row.recurringId == null || row.dueMonth == null) return;
    try {
      final movementRef = FirebaseFirestore.instance.collection('cash_movements').doc('repeat_${row.recurringId}_${row.dueMonth}');
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final existing = await transaction.get(movementRef);
        if (existing.exists) throw StateError('Este lançamento recorrente já foi concluído.');
        transaction.set(movementRef, {
          'type': row.expense ? 'expense' : 'receipt', 'kind': 'recurring_payment',
          'description': row.description, 'category': row.category, 'account': row.account,
          'amount': row.amount, 'date': Timestamp.fromDate(DateUtils.dateOnly(DateTime.now())),
          'scheduledDate': Timestamp.fromDate(DateUtils.dateOnly(row.date)),
          'createdAt': FieldValue.serverTimestamp(), 'createdBy': FirebaseAuth.instance.currentUser!.uid,
          'recurrenceId': row.recurringId, 'dueMonth': row.dueMonth,
          'status': row.expense ? 'paid' : 'received',
        });
      });
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(row.expense ? 'Despesa recorrente paga.' : 'Receita recorrente recebida.')));
    } catch (error) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Não foi possível concluir o lançamento: $error')));
    }
  }

  Future<void> _stopRecurring(BuildContext context, String recurringId) async {
    final confirmed = await showDialog<bool>(context: context, builder: (dialogContext) => AlertDialog(
      title: const Text('Encerrar repetição?'),
      content: const Text('Os próximos lançamentos deixarão de aparecer. Os que já foram pagos permanecem no histórico.'),
      actions: [TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Continuar repetindo')), FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Encerrar'))],
    ));
    if (confirmed != true) return;
    try {
      await FirebaseFirestore.instance.collection('cash_recurring').doc(recurringId).update({'active': false, 'endedAt': FieldValue.serverTimestamp()});
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Repetição encerrada.')));
    } catch (error) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Não foi possível encerrar a repetição: $error')));
    }
  }

  Future<void> _settleScheduledMovement(BuildContext context, _MonthlyRow row) async {
    if (row.movementId == null) return;
    final today = DateUtils.dateOnly(DateTime.now());
    final isReceipt = !row.expense;
    final action = isReceipt ? 'Confirmar recebimento' : 'Marcar como pago';
    final confirmed = await showDialog<bool>(context: context, builder: (dialogContext) => AlertDialog(
      title: Text(isReceipt ? 'Confirmar recebimento?' : 'Confirmar pagamento?'),
      content: Text('Registrar ${formatMoney(row.amount)} de “${row.description}” como ${isReceipt ? 'recebido' : 'pago'} hoje? A data prevista era ${formatDate(row.date)}.'),
      actions: [TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancelar')), FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: Text(action))],
    ));
    if (confirmed != true) return;
    try {
      final ref = FirebaseFirestore.instance.collection('cash_movements').doc(row.movementId);
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final snapshot = await transaction.get(ref);
        if (!snapshot.exists) throw StateError('Lançamento não encontrado.');
        final data = snapshot.data() ?? <String, dynamic>{};
        if (data['status'] == 'paid' || data['status'] == 'received') throw StateError('Este lançamento já foi concluído.');
        final clientId = data['clientId'] as String?;
        final kind = data['kind'] as String?;
        final isClientDeposit = clientId != null && kind == 'client_deposit';
        final isClientWithdrawal = clientId != null && kind == 'manual_client_withdrawal';
        DocumentSnapshot<Map<String, dynamic>>? clientSnapshot;
        if (isClientDeposit || isClientWithdrawal) {
          clientSnapshot = await transaction.get(FirebaseFirestore.instance.collection('users').doc(clientId));
          if (!clientSnapshot.exists || clientSnapshot.data() == null) throw StateError('Cliente não encontrado.');
        }
        if (clientSnapshot != null) {
          final clientRef = FirebaseFirestore.instance.collection('users').doc(clientId);
          final clientData = clientSnapshot.data()!;
          final balance = (clientData['balance'] as num?)?.toDouble() ?? (clientData['principal'] as num?)?.toDouble() ?? 0;
          final principal = (clientData['principal'] as num?)?.toDouble() ?? balance;
          final immediate = (clientData['immediateAvailable'] as num?)?.toDouble() ?? 0;
          final newBalance = isClientDeposit ? balance + row.amount : balance - row.amount;
          if (isClientWithdrawal && row.amount > balance) throw StateError('O valor ultrapassa o saldo atual do cliente.');
          final newPrincipal = isClientDeposit ? principal + row.amount : (principal - row.amount).clamp(0.0, principal).toDouble();
          transaction.update(clientRef, {
            'balance': newBalance, 'principal': newPrincipal,
            if (isClientDeposit) 'totalDeposits': ((clientData['totalDeposits'] as num?)?.toDouble() ?? principal) + row.amount,
            if (isClientWithdrawal) 'immediateAvailable': (immediate - row.amount).clamp(0.0, newBalance).toDouble(),
            'updatedAt': FieldValue.serverTimestamp(),
          });
          final ledgerId = '${isClientDeposit ? 'manual_deposit' : 'manual_withdrawal'}_${row.movementId}';
          transaction.set(clientRef.collection('ledger').doc(ledgerId), {
            'type': isClientDeposit ? 'credit' : 'debit',
            'title': isClientDeposit ? 'Depósito recebido' : 'Retirada paga pelo administrador',
            'description': row.description, 'amount': row.amount, 'balanceAfter': newBalance,
            'date': Timestamp.fromDate(today), 'createdAt': FieldValue.serverTimestamp(),
            'source': isClientDeposit ? 'manual_deposit' : 'manual_withdrawal',
          });
        }
        transaction.update(ref, {
          'scheduledDate': Timestamp.fromDate(DateUtils.dateOnly(row.date)),
          'date': Timestamp.fromDate(today),
          'status': isReceipt ? 'received' : 'paid',
          'settledAt': FieldValue.serverTimestamp(),
          'settledBy': FirebaseAuth.instance.currentUser!.uid,
        });
      });
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(isReceipt ? 'Recebimento confirmado no caixa.' : 'Despesa marcada como paga no caixa.')));
    } catch (error) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Não foi possível concluir o lançamento: $error')));
    }
  }

  Future<void> _editReceiptAmount(BuildContext context, _MonthlyRow row) async {
    final movementId = row.movementId;
    if (movementId == null) return;
    final controller = TextEditingController(text: row.amount.toStringAsFixed(2).replaceAll('.', ','));
    final newAmount = await showDialog<double>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Editar valor da receita'),
        content: TextField(controller: controller, autofocus: true, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Novo valor (R\$)')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancelar')),
          FilledButton(onPressed: () {
            final value = double.tryParse(controller.text.trim().replaceAll('.', '').replaceAll(',', '.'));
            Navigator.pop(dialogContext, value);
          }, child: const Text('Salvar')),
        ],
      ),
    );
    controller.dispose();
    if (newAmount == null || !newAmount.isFinite || newAmount <= 0 || (newAmount - row.amount).abs() < 0.005) return;

    try {
      final db = FirebaseFirestore.instance;
      final movementRef = db.collection('cash_movements').doc(movementId);
      await db.runTransaction((transaction) async {
        final movementSnapshot = await transaction.get(movementRef);
        if (!movementSnapshot.exists) throw StateError('Transação não encontrada.');
        final movement = movementSnapshot.data()!;
        if (movement['type'] != 'receipt' || movement['status'] == 'scheduled') throw StateError('Só é possível editar receitas já recebidas.');
        final oldAmount = (movement['amount'] as num?)?.toDouble() ?? 0;
        final delta = newAmount - oldAmount;
        final clientId = movement['clientId'] as String?;
        final isClientDeposit = clientId != null && movement['kind'] == 'client_deposit';
        DocumentReference<Map<String, dynamic>>? clientRef;
        DocumentReference<Map<String, dynamic>>? ledgerRef;
        DocumentSnapshot<Map<String, dynamic>>? clientSnapshot;
        DocumentSnapshot<Map<String, dynamic>>? ledgerSnapshot;

        if (isClientDeposit) {
          clientRef = db.collection('users').doc(clientId);
          ledgerRef = clientRef.collection('ledger').doc('manual_deposit_$movementId');
          clientSnapshot = await transaction.get(clientRef);
          ledgerSnapshot = await transaction.get(ledgerRef);
          if (!clientSnapshot.exists || clientSnapshot.data() == null) throw StateError('Cliente vinculado não encontrado.');
        }

        if (clientSnapshot != null && clientRef != null) {
          final client = clientSnapshot.data()!;
          final balance = (client['balance'] as num?)?.toDouble() ?? (client['principal'] as num?)?.toDouble() ?? 0;
          final principal = (client['principal'] as num?)?.toDouble() ?? balance;
          final totalDeposits = (client['totalDeposits'] as num?)?.toDouble() ?? principal;
          final updatedBalance = balance + delta;
          final updatedPrincipal = principal + delta;
          final updatedTotalDeposits = totalDeposits + delta;
          if (updatedBalance < -0.005 || updatedPrincipal < -0.005 || updatedTotalDeposits < updatedPrincipal - 0.005) throw StateError('Esse ajuste deixaria os valores do cliente inconsistentes.');
          transaction.update(clientRef, {'balance': updatedBalance, 'principal': updatedPrincipal, 'totalDeposits': updatedTotalDeposits, 'updatedAt': FieldValue.serverTimestamp()});
          if (ledgerSnapshot?.exists == true && ledgerRef != null) {
            final balanceAfter = (ledgerSnapshot!.data()!['balanceAfter'] as num?)?.toDouble();
            transaction.update(ledgerRef, {'amount': newAmount, if (balanceAfter != null) 'balanceAfter': balanceAfter + delta, 'updatedAt': FieldValue.serverTimestamp()});
          }
        }

        transaction.update(movementRef, {'amount': newAmount, 'updatedAt': FieldValue.serverTimestamp()});
      });
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Valor da receita atualizado.')));
    } catch (error) {
      if (context.mounted) {
        final message = error is StateError ? error.message : 'Não foi possível salvar. Confira sua conexão e as regras do Firestore.';
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Não foi possível editar a receita: $message')));
      }
    }
  }

  Future<void> _showTransactionDetails(BuildContext context, _MonthlyRow row) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 24, 22, 22),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(row.description, style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w800, color: ink)),
            const SizedBox(height: 6),
            Text('${row.expense ? 'Despesa' : 'Receita'} · ${row.status}', style: const TextStyle(color: muted)),
            const SizedBox(height: 18),
            _transactionDetailLine('Valor', formatMoney(row.amount), row.expense ? const Color(0xFFFF718A) : const Color(0xFF58D6A0)),
            _transactionDetailLine('Data', formatDate(row.date)),
            _transactionDetailLine('Categoria', row.category),
            _transactionDetailLine('Conta / carteira', row.account),
            const SizedBox(height: 12),
            const Text('Observações', style: TextStyle(fontWeight: FontWeight.bold, color: ink)),
            const SizedBox(height: 6),
            Text(row.notes?.trim().isNotEmpty == true ? row.notes!.trim() : 'Nenhuma observação registrada.', style: const TextStyle(color: muted)),
            if (row.movementId != null) ...[
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFFFF718A), side: const BorderSide(color: Color(0x66FF718A))),
                  onPressed: () async {
                    final confirmed = await showDialog<bool>(
                      context: sheetContext,
                      builder: (dialogContext) => AlertDialog(
                        title: const Text('Excluir transação?'),
                        content: Text('Deseja excluir “${row.description}”? Esta ação não pode ser desfeita.'),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancelar')),
                          FilledButton(onPressed: () => Navigator.pop(dialogContext, true), style: FilledButton.styleFrom(backgroundColor: const Color(0xFFB8324B)), child: const Text('Excluir')),
                        ],
                      ),
                    );
                    if (confirmed != true) return;
                    try {
                      await _deleteTransaction(row);
                      if (sheetContext.mounted) Navigator.pop(sheetContext);
                      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Transação excluída.')));
                    } catch (error) {
                      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Não foi possível excluir: $error')));
                    }
                  },
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Excluir transação'),
                ),
              ),
            ],
          ]),
        ),
      ),
    );
  }

  Future<void> _deleteTransaction(_MonthlyRow row) async {
    final movementId = row.movementId;
    if (movementId == null) return;
    final db = FirebaseFirestore.instance;
    final movementRef = db.collection('cash_movements').doc(movementId);
    await db.runTransaction((transaction) async {
      final movementSnapshot = await transaction.get(movementRef);
      if (!movementSnapshot.exists) throw StateError('A transação já foi removida.');
      final movement = movementSnapshot.data()!;
      final clientId = movement['clientId'] as String?;
      final kind = movement['kind'] as String?;
      final completed = movement['status'] != 'scheduled';
      final amount = (movement['amount'] as num?)?.toDouble() ?? 0;
      DocumentReference<Map<String, dynamic>>? clientRef;
      DocumentSnapshot<Map<String, dynamic>>? clientSnapshot;
      DocumentReference<Map<String, dynamic>>? ledgerRef;
      DocumentSnapshot<Map<String, dynamic>>? ledgerSnapshot;
      DocumentReference<Map<String, dynamic>>? requestRef;
      DocumentSnapshot<Map<String, dynamic>>? requestSnapshot;
      DocumentReference<Map<String, dynamic>>? recurringRef;
      DocumentSnapshot<Map<String, dynamic>>? recurringSnapshot;

      if (kind == 'recurring_payment' && movement['recurrenceId'] is String && movement['dueMonth'] is String) {
        recurringRef = db.collection('cash_recurring').doc(movement['recurrenceId'] as String);
        recurringSnapshot = await transaction.get(recurringRef);
      }

      if (completed && clientId != null && ['client_deposit', 'manual_client_withdrawal', 'yield_payment', 'withdrawal'].contains(kind)) {
        clientRef = db.collection('users').doc(clientId);
        String? ledgerId;
        if (kind == 'client_deposit') ledgerId = 'manual_deposit_$movementId';
        if (kind == 'manual_client_withdrawal') ledgerId = 'manual_withdrawal_$movementId';
        if (kind == 'yield_payment' && movement['dueMonth'] is String) ledgerId = 'yield_${movement['dueMonth']}';
        if (kind == 'withdrawal' && movement['withdrawalRequestId'] is String) {
          final requestId = movement['withdrawalRequestId'] as String;
          ledgerId = 'withdrawal_$requestId';
          requestRef = db.collection('withdrawal_requests').doc(requestId);
        }
        clientSnapshot = await transaction.get(clientRef);
        if (ledgerId != null) {
          ledgerRef = clientRef.collection('ledger').doc(ledgerId);
          ledgerSnapshot = await transaction.get(ledgerRef);
        }
        if (requestRef != null) requestSnapshot = await transaction.get(requestRef);
        if (!clientSnapshot.exists || clientSnapshot.data() == null) throw StateError('O cliente vinculado não foi encontrado; a transação foi mantida para proteger o saldo.');
      }

      if (clientSnapshot != null && clientRef != null) {
        final client = clientSnapshot.data()!;
        final balance = (client['balance'] as num?)?.toDouble() ?? (client['principal'] as num?)?.toDouble() ?? 0;
        final principal = (client['principal'] as num?)?.toDouble() ?? balance;
        final totalDeposits = (client['totalDeposits'] as num?)?.toDouble() ?? principal;
        final immediate = (client['immediateAvailable'] as num?)?.toDouble() ?? 0;
        if (kind == 'client_deposit') {
          final newBalance = balance - amount;
          final newPrincipal = principal - amount;
          final newTotalDeposits = totalDeposits - amount;
          if (newBalance < -0.005 || newPrincipal < -0.005 || newTotalDeposits < newPrincipal - 0.005) throw StateError('Não é seguro excluir: o cliente já usou parte desse depósito. Ajuste o saldo do cliente primeiro.');
          transaction.update(clientRef, {'balance': newBalance, 'principal': newPrincipal, 'totalDeposits': newTotalDeposits, 'immediateAvailable': immediate.clamp(0.0, newBalance < 0 ? 0.0 : newBalance), 'updatedAt': FieldValue.serverTimestamp()});
        } else if (kind == 'manual_client_withdrawal' || kind == 'withdrawal') {
          final newBalance = balance + amount;
          final newPrincipal = (principal + amount).clamp(0.0, totalDeposits).toDouble();
          transaction.update(clientRef, {'balance': newBalance, 'principal': newPrincipal, 'immediateAvailable': (immediate + amount).clamp(0.0, newBalance), 'updatedAt': FieldValue.serverTimestamp()});
          if (kind == 'withdrawal' && requestRef != null && requestSnapshot?.exists == true) {
            transaction.update(requestRef, {'status': 'pending', 'paidAmount': FieldValue.delete(), 'partial': FieldValue.delete(), 'reviewedAt': FieldValue.delete(), 'reviewedBy': FieldValue.delete()});
          }
        } else if (kind == 'yield_payment') {
          final newBalance = balance - amount;
          if (newBalance < -0.005) throw StateError('Não é seguro excluir: o cliente já utilizou esse rendimento.');
          transaction.update(clientRef, {'balance': newBalance, 'immediateAvailable': immediate.clamp(0.0, newBalance), 'updatedAt': FieldValue.serverTimestamp()});
        }
        if (ledgerSnapshot?.exists == true && ledgerRef != null) transaction.delete(ledgerRef);
      }
      if (recurringRef != null && recurringSnapshot?.exists == true) {
        transaction.update(recurringRef, {'cancelledMonths': FieldValue.arrayUnion([movement['dueMonth']])});
      }
      transaction.delete(movementRef);
    });
  }

  Widget _daySection(BuildContext context, DateTime date, List<_MonthlyRow> rows, DateTime today) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, right: 4, bottom: 8),
          child: LayoutBuilder(builder: (context, constraints) {
            final dailyOutflow = rows.where((row) => row.expense).fold<double>(0, (total, row) => total + row.amount);
            final selectedForDay = rows.where((row) => selectedRows.contains(row.selectionKey)).toList();
            final selectedTotal = selectedForDay.fold<double>(0, (total, row) => total + row.amount);
            final dateLabel = Text(_weekdayLabel(date), style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: ink));
            final amountLabel = Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(color: const Color(0x1AFF718A), borderRadius: BorderRadius.circular(10)),
              child: Text('Saídas do dia: ${formatMoney(dailyOutflow)}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFFFF718A))),
            );
            final selectedLabel = selectedForDay.isNotEmpty ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(color: violetWash, borderRadius: BorderRadius.circular(10)),
              child: Text('Selecionados: ${formatMoney(selectedTotal)}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: violet)),
            ) : const SizedBox.shrink();
            if (constraints.maxWidth < 500) {
              return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [dateLabel, const SizedBox(height: 6), Wrap(spacing: 8, runSpacing: 6, children: [amountLabel, selectedLabel])]);
            }
            return Row(children: [Expanded(child: dateLabel), if (selectedForDay.isNotEmpty) ...[selectedLabel, const SizedBox(width: 8)], amountLabel]);
          }),
        ),
        ...rows.map((row) {
          final tone = row.expense ? const Color(0xFFFF718A) : const Color(0xFF58D6A0);
          final iconBackground = row.expense ? const Color(0xFF3A202C) : const Color(0xFF1D342D);
          final futureDate = DateUtils.dateOnly(row.date).isAfter(today);
          final canEditReceipt = !row.expense && !row.projected && row.status != 'Programada' && row.movementId != null && !futureDate;
          final hasAction = row.projected || ((futureDate || row.status == 'Programada') && row.movementId != null);
          final actionLabel = row.recurringId != null
              ? (row.expense ? (futureDate ? 'Pagar antes' : 'Marcar como pago') : 'Marcar como recebido')
              : row.projected
                  ? (futureDate ? 'Fazer repasse antes' : 'Marcar como pago')
                  : (row.expense ? 'Marcar como pago' : 'Confirmar recebimento');
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () => _showTransactionDetails(context, row),
              child: card(Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              SizedBox(width: 36, child: Checkbox(value: selectedRows.contains(row.selectionKey), visualDensity: VisualDensity.compact, materialTapTargetSize: MaterialTapTargetSize.shrinkWrap, activeColor: violet, onChanged: (checked) => setState(() { if (checked == true) { selectedRows.add(row.selectionKey); } else { selectedRows.remove(row.selectionKey); } }))),
              const SizedBox(width: 4),
              CircleAvatar(backgroundColor: row.projected ? violetWash : iconBackground, child: Icon(row.projected ? Icons.payments_outlined : row.expense ? Icons.north_east : Icons.south_west, color: row.projected ? violet : tone)),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(row.description, style: const TextStyle(fontWeight: FontWeight.bold, color: ink)),
                const SizedBox(height: 3),
                Text('${row.category} · ${row.status}', style: const TextStyle(fontSize: 11, color: muted)),
                if (hasAction) Wrap(spacing: 4, children: [
                  TextButton.icon(
                    onPressed: () => row.projected ? _markAsPaid(context, row) : _settleScheduledMovement(context, row),
                    icon: Icon(row.projected && DateUtils.dateOnly(row.date).isAfter(today) ? Icons.bolt : Icons.check_circle_outline, size: 16),
                    label: Text(actionLabel),
                    style: TextButton.styleFrom(foregroundColor: violet, visualDensity: VisualDensity.compact, padding: const EdgeInsets.only(left: 0, right: 8)),
                  ),
                  if (row.recurringId != null) TextButton(onPressed: () => _stopRecurring(context, row.recurringId!), style: TextButton.styleFrom(foregroundColor: muted, visualDensity: VisualDensity.compact, padding: const EdgeInsets.symmetric(horizontal: 4)), child: const Text('Encerrar repetição')),
                ]),
              ])),
              const SizedBox(width: 8),
              Row(mainAxisSize: MainAxisSize.min, children: [
                Text('${row.expense ? '−' : '+'} ${formatMoney(row.amount)}', style: TextStyle(fontWeight: FontWeight.w800, color: row.expense ? const Color(0xFFFF718A) : const Color(0xFF58D6A0))),
                if (canEditReceipt) IconButton(tooltip: 'Editar valor da receita', visualDensity: VisualDensity.compact, padding: EdgeInsets.zero, constraints: const BoxConstraints(minWidth: 32, minHeight: 32), onPressed: () => _editReceiptAmount(context, row), icon: const Icon(Icons.edit_outlined, size: 17, color: violet)),
              ]),
            ])),
            ),
          );
        }),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    const SizedBox(height: 4),
    card(Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [IconButton(onPressed: () => setState(() { month = DateTime(month.year, month.month - 1); selectedRows.clear(); }), icon: const Icon(Icons.chevron_left, color: violet)), Text(_monthLabel(), style: const TextStyle(fontWeight: FontWeight.bold, color: violet)), IconButton(onPressed: () => setState(() { month = DateTime(month.year, month.month + 1); selectedRows.clear(); }), icon: const Icon(Icons.chevron_right, color: violet))])),
    const SizedBox(height: 12),
    StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(stream: FirebaseFirestore.instance.collection('cash_movements').orderBy('date', descending: true).snapshots(), builder: (context, movementSnapshot) {
      if (movementSnapshot.hasError) return const Text('Não foi possível carregar as transações do caixa.');
      if (!movementSnapshot.hasData) return const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()));
      return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(stream: FirebaseFirestore.instance.collection('users').where('role', isEqualTo: 'client').snapshots(), builder: (context, clientSnapshot) {
        if (clientSnapshot.hasError) return const Text('Não foi possível gerar a previsão dos clientes.');
        if (!clientSnapshot.hasData) return const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()));
        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(stream: FirebaseFirestore.instance.collection('cash_recurring').where('active', isEqualTo: true).snapshots(), builder: (context, recurringSnapshot) {
        if (recurringSnapshot.hasError) return const Text('Não foi possível carregar os lançamentos recorrentes.');
        if (!recurringSnapshot.hasData) return const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()));
        final today = DateUtils.dateOnly(DateTime.now());
        final monthStart = DateTime(month.year, month.month);
        final nextMonth = DateTime(month.year, month.month + 1);
        final rows = <_MonthlyRow>[];
        final paidYields = <String>{};
        final paidRecurring = <String>{};
        for (final doc in movementSnapshot.data!.docs) {
          final data = doc.data();
          if (data['clientId'] is String && data['dueMonth'] is String) paidYields.add('${data['clientId']}_${data['dueMonth']}');
          if (data['recurrenceId'] is String && data['dueMonth'] is String) paidRecurring.add('${data['recurrenceId']}_${data['dueMonth']}');
          final dateValue = data['date'];
          if (dateValue is! Timestamp) continue;
          final date = dateValue.toDate();
          if (date.isBefore(monthStart) || !date.isBefore(nextMonth)) continue;
          final expense = data['type'] == 'expense';
          final completed = data['status'] == 'paid' || data['status'] == 'received';
          final isScheduled = data['status'] == 'scheduled' || (date.isAfter(today) && !completed);
          rows.add(_MonthlyRow(date: date, description: data['description'] as String? ?? (expense ? 'Despesa' : 'Receita'), category: data['category'] as String? ?? (expense ? 'Despesas' : 'Receitas'), account: data['account'] as String? ?? 'Mesa Principal', amount: (data['amount'] as num?)?.toDouble() ?? 0, expense: expense, status: completed ? (expense ? 'Pago' : 'Recebida') : isScheduled ? 'Programada' : 'Realizada', notes: data['notes'] as String?, movementId: doc.id));
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
        for (final recurring in recurringSnapshot.data!.docs) {
          final data = recurring.data();
          final startValue = data['date'];
          if (startValue is! Timestamp) continue;
          final start = DateUtils.dateOnly(startValue.toDate());
          final monthOffset = (month.year - start.year) * 12 + month.month - start.month;
          if (monthOffset < 0) continue;
          final mode = data['repeatMode'] as String? ?? 'temporary';
          final count = (data['occurrenceCount'] as num?)?.toInt();
          if (mode == 'temporary' && (count == null || monthOffset >= count)) continue;
          final dueDate = _dueDate(month.year, month.month, start.day);
          if (dueDate.isBefore(start)) continue;
          final dueMonth = '${month.year}-${month.month.toString().padLeft(2, '0')}';
          final cancelledMonths = data['cancelledMonths'] as List? ?? const [];
          if (paidRecurring.contains('${recurring.id}_$dueMonth') || cancelledMonths.contains(dueMonth)) continue;
          final expense = data['type'] == 'expense';
          rows.add(_MonthlyRow(date: dueDate, description: data['description'] as String? ?? (expense ? 'Despesa recorrente' : 'Receita recorrente'), category: data['category'] as String? ?? (expense ? 'Despesas' : 'Receitas'), account: data['account'] as String? ?? 'Mesa Principal', amount: (data['amount'] as num?)?.toDouble() ?? 0, expense: expense, status: mode == 'fixed' ? 'Fixa · prevista' : 'Parcela ${monthOffset + 1}/$count', dueMonth: dueMonth, recurringId: recurring.id, notes: data['notes'] as String?, projected: true));
        }
        rows.sort((a, b) => a.date.compareTo(b.date));
        final monthIncome = rows.where((r) => !r.projected && !r.expense && r.status != 'Programada' && !DateUtils.dateOnly(r.date).isAfter(today)).fold<double>(0, (s, r) => s + r.amount);
        final monthPlannedIncome = rows.where((r) => !r.expense && ((r.projected && r.recurringId != null) || (!r.projected && (r.status == 'Programada' || DateUtils.dateOnly(r.date).isAfter(today))))).fold<double>(0, (s, r) => s + r.amount);
        final monthPaidExpenses = rows.where((r) => !r.projected && r.expense && r.status != 'Programada' && !r.date.isAfter(today)).fold<double>(0, (s, r) => s + r.amount);
        final monthForecast = rows.where((r) => r.expense && (r.projected || r.status == 'Programada' || r.date.isAfter(today))).fold<double>(0, (s, r) => s + r.amount);
        final groupedRows = <DateTime, List<_MonthlyRow>>{};
        for (final row in rows) {
          final day = DateUtils.dateOnly(row.date);
          groupedRows.putIfAbsent(day, () => <_MonthlyRow>[]).add(row);
        }
        final groupedDays = groupedRows.keys.toList()..sort();
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          SizedBox(
            width: double.infinity,
            child: card(LayoutBuilder(builder: (context, constraints) {
              final columns = constraints.maxWidth >= 760 ? 4 : constraints.maxWidth >= 420 ? 2 : 1;
              final itemWidth = (constraints.maxWidth - (columns - 1) * 16) / columns;
              Widget metricItem(String label, double value, Color color) => SizedBox(
                width: itemWidth,
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(label, style: const TextStyle(fontSize: 10, color: muted)),
                  const SizedBox(height: 6),
                  Text(formatMoney(value), style: TextStyle(fontWeight: FontWeight.bold, color: color)),
                ]),
              );
              return Wrap(spacing: 16, runSpacing: 16, children: [
                metricItem('RECEITAS REALIZADAS', monthIncome, const Color(0xFF58D6A0)),
                metricItem('ENTRADAS PREVISTAS', monthPlannedIncome, const Color(0xFF58D6A0)),
                metricItem('DESPESAS PAGAS', monthPaidExpenses, const Color(0xFFFF718A)),
                metricItem('SAÍDAS PREVISTAS', monthForecast, const Color(0xFFFF718A)),
              ]);
            })),
          ),
          const SizedBox(height: 12),
          StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance.collection('settings').doc('treasury').snapshots(),
            builder: (context, settingsSnapshot) {
              if (settingsSnapshot.hasError || !settingsSnapshot.hasData) return const SizedBox.shrink();
              final openingCapital = (settingsSnapshot.data!.data()?['initialCapital'] as num?)?.toDouble() ?? 0;
              final now = DateTime.now();
              final completedMovements = movementSnapshot.data!.docs.where((doc) {
                final data = doc.data();
                final date = data['date'];
                return date is Timestamp && !date.toDate().isAfter(now) && data['status'] != 'scheduled';
              });
              final cashNow = completedMovements.fold<double>(openingCapital, (cash, doc) {
                final data = doc.data();
                final amount = (data['amount'] as num?)?.toDouble() ?? 0;
                return cash + (data['type'] == 'receipt' ? amount : -amount);
              });
              final selectedMonthEnd = DateTime(month.year, month.month + 1);
              final currentMonthStart = DateTime(now.year, now.month);
              final isHistoricalMonth = !selectedMonthEnd.isAfter(currentMonthStart);
              double projectedCash;
              if (isHistoricalMonth) {
                projectedCash = movementSnapshot.data!.docs.where((doc) {
                  final data = doc.data();
                  final date = data['date'];
                  return date is Timestamp && date.toDate().isBefore(selectedMonthEnd) && data['status'] != 'scheduled';
                }).fold<double>(openingCapital, (cash, doc) {
                  final data = doc.data();
                  final amount = (data['amount'] as num?)?.toDouble() ?? 0;
                  return cash + (data['type'] == 'receipt' ? amount : -amount);
                });
              } else {
                projectedCash = cashNow;
                for (final doc in movementSnapshot.data!.docs) {
                  final data = doc.data();
                  final dateValue = data['date'];
                  if (dateValue is! Timestamp) continue;
                  final date = dateValue.toDate();
                  final completed = data['status'] == 'paid' || data['status'] == 'received';
                  final pending = data['status'] == 'scheduled' || (date.isAfter(now) && !completed);
                  if (!pending || !date.isBefore(selectedMonthEnd)) continue;
                  final amount = (data['amount'] as num?)?.toDouble() ?? 0;
                  projectedCash += data['type'] == 'receipt' ? amount : -amount;
                }
                int monthDay(int year, int monthNumber, int day) {
                  final lastDay = DateTime(year, monthNumber + 1, 0).day;
                  return day > lastDay ? lastDay : day;
                }
                for (var cursor = currentMonthStart; cursor.isBefore(selectedMonthEnd); cursor = DateTime(cursor.year, cursor.month + 1)) {
                  final dueMonth = '${cursor.year}-${cursor.month.toString().padLeft(2, '0')}';
                  for (final clientDoc in clientSnapshot.data!.docs) {
                    final data = clientDoc.data();
                    if (data['active'] == false || data['earningDay'] is! num || data['earningStartDate'] is! Timestamp || paidYields.contains('${clientDoc.id}_$dueMonth')) continue;
                    final earningDay = (data['earningDay'] as num).toInt();
                    if (earningDay < 1 || earningDay > 31) continue;
                    final dueDate = DateTime(cursor.year, cursor.month, monthDay(cursor.year, cursor.month, earningDay));
                    final start = DateUtils.dateOnly((data['earningStartDate'] as Timestamp).toDate());
                    if (dueDate.isBefore(start) || !dueDate.isBefore(selectedMonthEnd)) continue;
                    final principal = (data['principal'] as num?)?.toDouble() ?? 0;
                    final rate = (data['monthlyRate'] as num?)?.toDouble() ?? 0;
                    projectedCash -= principal * rate / 100;
                  }
                  for (final recurringDoc in recurringSnapshot.data!.docs) {
                    final data = recurringDoc.data();
                    final startValue = data['date'];
                    if (startValue is! Timestamp) continue;
                    final start = DateUtils.dateOnly(startValue.toDate());
                    final offset = (cursor.year - start.year) * 12 + cursor.month - start.month;
                    final mode = data['repeatMode'] as String? ?? 'temporary';
                    final count = (data['occurrenceCount'] as num?)?.toInt();
                    if (offset < 0 || (mode == 'temporary' && (count == null || offset >= count))) continue;
                    final dueDate = DateTime(cursor.year, cursor.month, monthDay(cursor.year, cursor.month, start.day));
                    final cancelledMonths = data['cancelledMonths'] as List? ?? const [];
                    if (dueDate.isBefore(start) || !dueDate.isBefore(selectedMonthEnd) || paidRecurring.contains('${recurringDoc.id}_$dueMonth') || cancelledMonths.contains(dueMonth)) continue;
                    final amount = (data['amount'] as num?)?.toDouble() ?? 0;
                    projectedCash += data['type'] == 'receipt' ? amount : -amount;
                  }
                }
              }
              final positive = projectedCash >= 0;
              final status = isHistoricalMonth
                  ? 'Fechamento registrado do mês selecionado.'
                  : positive
                      ? 'Com as operações previstas, o caixa fecha positivo.'
                      : 'Faltam ${formatMoney(projectedCash.abs())} para cobrir as operações previstas.';
              final tone = positive ? const Color(0xFF58D6A0) : const Color(0xFFFF718A);
              return SizedBox(
                width: double.infinity,
                child: card(Row(children: [
                  Icon(positive ? Icons.trending_up : Icons.warning_amber_rounded, color: tone, size: 24),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('${isHistoricalMonth ? 'FECHAMENTO REGISTRADO' : 'SALDO PREVISTO'} · ${_monthLabel().toUpperCase()}', style: const TextStyle(fontSize: 10, color: muted, letterSpacing: .4)),
                    const SizedBox(height: 5),
                    Text(status, style: TextStyle(fontWeight: FontWeight.w600, color: tone)),
                  ])),
                  const SizedBox(width: 12),
                  Text(formatMoney(projectedCash), style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: tone)),
                ])),
              );
            },
          ),
          const SizedBox(height: 12),
          if (rows.isEmpty) card(const Text('Nenhuma transação ou repasse previsto para este mês.', style: TextStyle(color: muted)))
          else ...groupedDays.map((day) => _daySection(context, day, groupedRows[day]!, today)),
        ]);
        });
      });
    }),
  ]);
}

Widget cashBox(String label, String value, Color color) => Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: surfaceRaised, borderRadius: BorderRadius.circular(14)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label, style: const TextStyle(fontSize: 11, color: muted)), const SizedBox(height: 4), Text(value, style: TextStyle(fontWeight: FontWeight.bold, color: color))]));
Widget _transactionDetailLine(String label, String value, [Color color = ink]) => Padding(padding: const EdgeInsets.only(bottom: 10), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [SizedBox(width: 125, child: Text(label, style: const TextStyle(color: muted))), Expanded(child: Text(value, style: TextStyle(color: color, fontWeight: FontWeight.w600)))]));
void addMovement(BuildContext context, String type) => showModalBottomSheet<void>(context: context, isScrollControlled: true, builder: (_) => _NewMovementSheet(type: type));

class _NewMovementSheet extends StatefulWidget {
  const _NewMovementSheet({required this.type});
  final String type;
  @override
  State<_NewMovementSheet> createState() => _NewMovementSheetState();
}
class _NewMovementSheetState extends State<_NewMovementSheet> {
  final description = TextEditingController();
  final notes = TextEditingController();
  final amount = TextEditingController();
  final occurrences = TextEditingController(text: '3');
  DateTime selectedDate = DateUtils.dateOnly(DateTime.now());
  String repeatMode = 'none';
  bool isCompleted = true;
  String? selectedClientId;
  String? selectedClientName;
  String? selectedCategory;
  bool saving = false;
  String? error;
  List<String> get categories => widget.type == 'expense'
      ? const ['Despesas', 'Impostos', 'Alimentação', 'Compras', 'Assinaturas', 'Saques', 'Outros']
      : const ['Receitas', 'Dividendos', 'Bonificação', 'Vendas', 'Serviços', 'Outros'];
  String _selectedDateLabel() => '${selectedDate.day.toString().padLeft(2, '0')}/${selectedDate.month.toString().padLeft(2, '0')}/${selectedDate.year}';

  void _setDate(DateTime date) => setState(() {
        selectedDate = DateUtils.dateOnly(date);
        if (selectedDate.isAfter(DateUtils.dateOnly(DateTime.now()))) isCompleted = false;
      });

  Future<void> _chooseDate() async {
    final picked = await showDatePicker(context: context, initialDate: selectedDate, firstDate: DateTime(2020), lastDate: DateTime(2100));
    if (picked != null && mounted) _setDate(picked);
  }

  Future<void> save() async {
    final value = double.tryParse(amount.text.trim().replaceAll('.', '').replaceAll(',', '.'));
    if (description.text.trim().isEmpty || value == null || value <= 0) { setState(() => error = 'Informe uma descrição e um valor válido.'); return; }
    if (selectedClientId != null && repeatMode != 'none') { setState(() => error = 'Repetição mensal é para lançamentos gerais da mesa.'); return; }
    final occurrenceCount = repeatMode == 'temporary' ? int.tryParse(occurrences.text.trim()) : null;
    if (repeatMode == 'temporary' && (occurrenceCount == null || occurrenceCount < 2 || occurrenceCount > 120)) { setState(() => error = 'Informe de 2 a 120 ocorrências para uma repetição temporária.'); return; }
    setState(() { saving = true; error = null; });
    final now = DateTime.now();
    try {
      final firestore = FirebaseFirestore.instance;
      final movementRef = firestore.collection('cash_movements').doc();
      final nowDate = DateUtils.dateOnly(now);
      final isFuture = selectedDate.isAfter(nowDate);
      final movementDate = isCompleted && isFuture ? nowDate : selectedDate;
      final movement = <String, dynamic>{
        'type': widget.type, 'description': description.text.trim(), 'amount': value,
        if (notes.text.trim().isNotEmpty) 'notes': notes.text.trim(),
        'date': Timestamp.fromDate(movementDate),
        'createdAt': FieldValue.serverTimestamp(), 'createdBy': FirebaseAuth.instance.currentUser!.uid,
        'category': selectedClientId == null ? (selectedCategory ?? categories.first) : (widget.type == 'expense' ? 'Saque de cliente' : 'Depósito de cliente'),
        'account': selectedClientName ?? 'Mesa Principal',
        'status': isCompleted ? (widget.type == 'expense' ? 'paid' : 'received') : 'scheduled',
      };
      if (isCompleted && isFuture) movement['scheduledDate'] = Timestamp.fromDate(selectedDate);
      if (repeatMode != 'none') {
        final recurringRef = firestore.collection('cash_recurring').doc();
        final dueMonth = '${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}';
        final recurringMovementRef = firestore.collection('cash_movements').doc('repeat_${recurringRef.id}_$dueMonth');
        final recurringMovement = <String, dynamic>{
          ...movement, 'kind': 'recurring_payment', 'recurrenceId': recurringRef.id, 'dueMonth': dueMonth,
        };
        await firestore.runTransaction((transaction) async {
          transaction.set(recurringRef, {
            'type': widget.type, 'description': description.text.trim(), 'amount': value,
            if (notes.text.trim().isNotEmpty) 'notes': notes.text.trim(),
            'date': Timestamp.fromDate(selectedDate), 'createdAt': FieldValue.serverTimestamp(),
            'createdBy': FirebaseAuth.instance.currentUser!.uid,
            'category': selectedCategory ?? categories.first, 'account': 'Mesa Principal',
            'repeatMode': repeatMode, 'occurrenceCount': occurrenceCount, 'active': true,
          });
          if (isCompleted) transaction.set(recurringMovementRef, recurringMovement);
        });
        if (!mounted) return;
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(repeatMode == 'fixed' ? 'Repetição mensal fixa criada.' : 'Repetição criada para $occurrenceCount ocorrências.')));
        return;
      }
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
          if (isCompleted) {
            transaction.update(clientRef, {'balance': newBalance, 'principal': newPrincipal, 'totalDeposits': newTotalDeposits, if (!isDeposit) 'immediateAvailable': (((data['immediateAvailable'] as num?)?.toDouble() ?? 0) - value).clamp(0.0, newBalance).toDouble(), 'updatedAt': FieldValue.serverTimestamp()});
            transaction.set(ledgerRef, {'type': ledgerType, 'title': ledgerTitle, 'description': description.text.trim(), 'amount': value, 'balanceAfter': newBalance, 'date': Timestamp.fromDate(movementDate), 'createdAt': FieldValue.serverTimestamp(), 'source': isDeposit ? 'manual_deposit' : 'manual_withdrawal'});
          }
        });
      } else {
        await movementRef.set(movement);
      }
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(selectedClientId != null ? (widget.type == 'receipt' ? 'Depósito registrado. O capital e o saldo de $selectedClientName foram atualizados.' : 'Retirada registrada no caixa e descontada do saldo de $selectedClientName.') : selectedDate.isAfter(DateUtils.dateOnly(now)) ? 'Lançamento programado para ${_selectedDateLabel()}; será contado no caixa somente quando for concluído.' : '${widget.type == 'receipt' ? 'Receita' : 'Despesa'} lançada em ${_selectedDateLabel()}.')));
    } catch (e) { setState(() => error = e is StateError ? e.message.toString() : 'Não foi possível salvar. Verifique se as regras do Firestore foram publicadas.'); }
    finally { if (mounted) setState(() => saving = false); }
  }
  @override
  void dispose() { description.dispose(); notes.dispose(); amount.dispose(); occurrences.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    return Padding(padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom), child: SingleChildScrollView(child: Padding(padding: const EdgeInsets.fromLTRB(22, 24, 22, 22), child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(widget.type == 'receipt' ? 'Lançar receita' : 'Lançar despesa', style: const TextStyle(fontSize: 21, fontWeight: FontWeight.bold)), const SizedBox(height: 8),
      Wrap(spacing: 8, children: [
        ChoiceChip(label: const Text('Hoje'), selected: DateUtils.isSameDay(selectedDate, DateUtils.dateOnly(DateTime.now())), onSelected: (_) => _setDate(DateTime.now())),
        ChoiceChip(label: const Text('Ontem'), selected: DateUtils.isSameDay(selectedDate, DateUtils.dateOnly(DateTime.now().subtract(const Duration(days: 1)))), onSelected: (_) => _setDate(DateTime.now().subtract(const Duration(days: 1)))),
        ChoiceChip(label: Text('Outros · ${_selectedDateLabel()}'), selected: !DateUtils.isSameDay(selectedDate, DateUtils.dateOnly(DateTime.now())) && !DateUtils.isSameDay(selectedDate, DateUtils.dateOnly(DateTime.now().subtract(const Duration(days: 1)))), onSelected: (_) => _chooseDate()),
      ]),
      if (selectedDate.isAfter(DateUtils.dateOnly(DateTime.now())) && selectedClientId == null) const Padding(padding: EdgeInsets.only(bottom: 8), child: Text('Este lançamento ficará previsto e entrará no saldo realizado quando você confirmar o pagamento/recebimento.', style: TextStyle(color: muted, fontSize: 12))),
      const SizedBox(height: 8),
      SwitchListTile(contentPadding: EdgeInsets.zero, title: Text(widget.type == 'expense' ? 'Pago' : 'Recebido'), value: isCompleted, onChanged: (value) => setState(() => isCompleted = value)),
      DropdownButtonFormField<String>(initialValue: repeatMode, decoration: const InputDecoration(labelText: 'Repetição'), items: const [DropdownMenuItem(value: 'none', child: Text('Não se repete')), DropdownMenuItem(value: 'fixed', child: Text('Fixa · todo mês')), DropdownMenuItem(value: 'temporary', child: Text('Temporária · por quantidade'))], onChanged: (value) { if (value != null) setState(() => repeatMode = value); }),
      if (repeatMode == 'temporary') Padding(padding: const EdgeInsets.only(top: 10), child: TextField(controller: occurrences, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Quantidade de ocorrências', helperText: 'De 2 a 120 repetições mensais.'))),
      ...[
        StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(stream: FirebaseFirestore.instance.collection('users').where('role', isEqualTo: 'client').snapshots(), builder: (context, snapshot) {
          if (!snapshot.hasData) return const LinearProgressIndicator();
          final clients = snapshot.data!.docs;
          return DropdownButtonFormField<String>(initialValue: selectedClientId ?? '', decoration: const InputDecoration(labelText: 'Carteira / cliente (opcional)'), items: [DropdownMenuItem(value: '', child: Text(widget.type == 'expense' ? 'Despesa geral da mesa' : 'Receita geral da mesa')), ...clients.map((client) => DropdownMenuItem(value: client.id, child: Text(client.data()['name'] as String? ?? 'Cliente')))], onChanged: (id) { setState(() { selectedClientId = id == null || id.isEmpty ? null : id; selectedClientName = id == null || id.isEmpty ? null : clients.firstWhere((client) => client.id == id).data()['name'] as String? ?? 'Cliente'; if (selectedClientId != null && description.text.trim().isEmpty) description.text = widget.type == 'expense' ? 'Retirada · $selectedClientName' : 'Depósito · $selectedClientName'; }); });
        }),
        const SizedBox(height: 12),
      if (selectedClientId != null) Text(isCompleted ? (widget.type == 'expense' ? 'Ao salvar, o valor será descontado do saldo e do limite de saque imediato do cliente.' : 'Ao salvar, o valor será somado ao saldo e ao capital aplicado.') : 'O saldo do cliente só será atualizado quando você confirmar como pago/recebido.', style: const TextStyle(fontSize: 12, color: muted)),
        const SizedBox(height: 12),
      ],
      TextField(controller: description, decoration: InputDecoration(labelText: widget.type == 'receipt' ? 'Descrição da receita' : 'Descrição da despesa')),
      const SizedBox(height: 12),
      TextField(controller: notes, maxLines: 3, maxLength: 500, decoration: const InputDecoration(labelText: 'Observações (opcional)', hintText: 'Detalhes adicionais sobre este lançamento')),
      const SizedBox(height: 12),
      DropdownButtonFormField<String>(initialValue: selectedCategory ?? categories.first, decoration: const InputDecoration(labelText: 'Categoria'), items: categories.map((category) => DropdownMenuItem(value: category, child: Text(category))).toList(), onChanged: (value) => setState(() => selectedCategory = value)),
      const SizedBox(height: 12), TextField(controller: amount, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Valor (R\$)')),
      if (error != null) Padding(padding: const EdgeInsets.only(top: 12), child: Text(error!, style: const TextStyle(color: Color(0xFFBC4352)))),
      const SizedBox(height: 18), SizedBox(width: double.infinity, child: FilledButton(onPressed: saving ? null : save, child: saving ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : Text('Salvar ${widget.type == 'receipt' ? 'receita' : 'despesa'}'))),
    ]))));
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

class ClientShell extends StatefulWidget {
  const ClientShell({super.key});
  @override
  State<ClientShell> createState() => _ClientShellState();
}

class _ClientShellState extends State<ClientShell> {
  bool refreshing = false;

  Future<void> _refreshData() async {
    if (refreshing) return;
    setState(() => refreshing = true);
    try {
      final userId = FirebaseAuth.instance.currentUser!.uid;
      final userRef = FirebaseFirestore.instance.collection('users').doc(userId);
      await Future.wait([
        userRef.get(const GetOptions(source: Source.server)),
        userRef.collection('ledger').orderBy('date', descending: true).limit(20).get(const GetOptions(source: Source.server)),
      ]);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Dados atualizados.')));
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Não foi possível atualizar. Verifique sua conexão.')));
    } finally {
      if (mounted) setState(() => refreshing = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(extendBodyBehindAppBar: true, appBar: AppBar(flexibleSpace: glassBarSurface(), title: purpleCoreLogo(iconSize: 34, titleSize: 20), actions: [IconButton(tooltip: 'Atualizar dados', onPressed: refreshing ? null : _refreshData, icon: Icon(refreshing ? Icons.sync : Icons.refresh)), IconButton(onPressed: () => logout(context), icon: const Icon(Icons.logout))]), body: RefreshIndicator(onRefresh: _refreshData, child: const ClientHome()));
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
