import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

void main() {
  runApp(const MyApp());
}

// ─────────────────────────────────────────
// MODÈLES
// ─────────────────────────────────────────

class Transaction {
  String id;
  String type; // "dette" | "paiement"
  double montant;
  String date;
  String? note;

  Transaction(this.id, this.type, this.montant, this.date, {this.note});

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type,
        'montant': montant,
        'date': date,
        'note': note,
      };

  factory Transaction.fromJson(Map<String, dynamic> json) => Transaction(
        json['id'] ?? UniqueKey().toString(),
        json['type'],
        (json['montant'] as num).toDouble(),
        json['date'],
        note: json['note'],
      );
}

class Client {
  String id;
  String nom;
  List<Transaction> transactions;

  Client(this.id, this.nom, this.transactions);

  double get dette => transactions.fold(
      0, (sum, t) => t.type == "dette" ? sum + t.montant : sum - t.montant);

  Map<String, dynamic> toJson() => {
        'id': id,
        'nom': nom,
        'transactions': transactions.map((t) => t.toJson()).toList(),
      };

  factory Client.fromJson(Map<String, dynamic> json) => Client(
        json['id'] ?? UniqueKey().toString(),
        json['nom'],
        (json['transactions'] as List)
            .map((e) => Transaction.fromJson(e))
            .toList(),
      );
}

// ─────────────────────────────────────────
// THÈME
// ─────────────────────────────────────────

const Color kPrimary = Color(0xFF1E3A5F);
const Color kAccent = Color(0xFF2ECC71);
const Color kDanger = Color(0xFFE74C3C);
const Color kBg = Color(0xFFF4F6F9);
const Color kCard = Colors.white;

ThemeData appTheme() => ThemeData(
      primaryColor: kPrimary,
      scaffoldBackgroundColor: kBg,
      colorScheme: ColorScheme.fromSeed(
        seedColor: kPrimary,
        primary: kPrimary,
        secondary: kAccent,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: kPrimary,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: kPrimary,
        foregroundColor: Colors.white,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: kPrimary,
          foregroundColor: Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.white,
      ),
    );

// ─────────────────────────────────────────
// APP
// ─────────────────────────────────────────

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Carnet Crédit',
      theme: appTheme(),
      home: const PinPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

// ─────────────────────────────────────────
// PAGE PIN
// ─────────────────────────────────────────

class PinPage extends StatefulWidget {
  const PinPage({super.key});

  @override
  State<PinPage> createState() => _PinPageState();
}

class _PinPageState extends State<PinPage> {
  String input = "";
  String savedPin = "";
  bool erreur = false;

  @override
  void initState() {
    super.initState();
    _loadPin();
  }

  Future<void> _loadPin() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => savedPin = prefs.getString('pin') ?? "");
  }

  Future<void> _savePin(String pin) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('pin', pin);
  }

  void _onPress(String number) {
    if (input.length >= 4) return;
    setState(() {
      input += number;
      erreur = false;
    });

    if (input.length == 4) {
      Future.delayed(const Duration(milliseconds: 150), () {
        if (savedPin.isEmpty) {
          _savePin(input);
          _goHome();
        } else if (input == savedPin) {
          _goHome();
        } else {
          setState(() {
            input = "";
            erreur = true;
          });
        }
      });
    }
  }

  void _onDelete() {
    if (input.isNotEmpty) setState(() => input = input.substring(0, input.length - 1));
  }

  void _goHome() {
    Navigator.pushReplacement(
        context, MaterialPageRoute(builder: (_) => const HomePage()));
  }

  @override
  Widget build(BuildContext context) {
    final bool creation = savedPin.isEmpty;
    return Scaffold(
      backgroundColor: kPrimary,
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.lock_outline, size: 64, color: Colors.white),
            const SizedBox(height: 16),
            Text(
              creation ? "Créer votre PIN" : "Entrer votre PIN",
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(4, (i) {
                final filled = i < input.length;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 10),
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: erreur
                        ? kDanger
                        : filled
                            ? Colors.white
                            : Colors.white30,
                  ),
                );
              }),
            ),
            if (erreur) ...[
              const SizedBox(height: 12),
              const Text("PIN incorrect",
                  style: TextStyle(color: kDanger, fontSize: 14)),
            ],
            const SizedBox(height: 40),
            _buildPad(),
          ],
        ),
      ),
    );
  }

  Widget _buildPad() {
    final keys = [
      ['1', '2', '3'],
      ['4', '5', '6'],
      ['7', '8', '9'],
      ['', '0', '⌫'],
    ];
    return Column(
      children: keys.map((row) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: row.map((k) {
            if (k.isEmpty) return const SizedBox(width: 80, height: 80);
            return GestureDetector(
              onTap: () => k == '⌫' ? _onDelete() : _onPress(k),
              child: Container(
                width: 80,
                height: 80,
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white12,
                  border: Border.all(color: Colors.white24),
                ),
                alignment: Alignment.center,
                child: Text(k,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w500)),
              ),
            );
          }).toList(),
        );
      }).toList(),
    );
  }
}

// ─────────────────────────────────────────
// PAGE ACCUEIL
// ─────────────────────────────────────────

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Client> clients = [];
  String recherche = "";

  @override
  void initState() {
    super.initState();
    _charger();
  }

  Future<void> _sauvegarder() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
        'clients', clients.map((c) => jsonEncode(c.toJson())).toList());
  }

  Future<void> _charger() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getStringList('clients');
    if (data != null) {
      setState(
          () => clients = data.map((e) => Client.fromJson(jsonDecode(e))).toList());
    }
  }

  void _ajouterClient(String nom) {
    setState(() => clients
        .add(Client(DateTime.now().millisecondsSinceEpoch.toString(), nom, [])));
    _sauvegarder();
  }

  void _supprimerClient(int index) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Supprimer ce client ?"),
        content: Text(
            "Toutes les transactions de ${clients[index].nom} seront supprimées."),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Annuler")),
          TextButton(
            onPressed: () {
              setState(() => clients.removeAt(index));
              _sauvegarder();
              Navigator.pop(context);
            },
            child: const Text("Supprimer", style: TextStyle(color: kDanger)),
          ),
        ],
      ),
    );
  }

  void _dialogAjouterClient() {
    String nom = "";
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Nouveau client"),
        content: TextField(
          autofocus: true,
          onChanged: (v) => nom = v,
          decoration: const InputDecoration(
              labelText: "Nom du client", prefixIcon: Icon(Icons.person)),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Annuler")),
          ElevatedButton(
            onPressed: () {
              if (nom.trim().isNotEmpty) {
                _ajouterClient(nom.trim());
                Navigator.pop(context);
              }
            },
            child: const Text("Ajouter"),
          ),
        ],
      ),
    );
  }

  double _totalGlobal() => clients.fold(0, (s, c) => s + c.dette);

  List<Client> get _clientsFiltres => clients
      .where((c) => c.nom.toLowerCase().contains(recherche.toLowerCase()))
      .toList();

  @override
  Widget build(BuildContext context) {
    final total = _totalGlobal();
    return Scaffold(
      appBar: AppBar(
        title: const Text("Carnet Crédit"),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            tooltip: "Exporter",
            onPressed: _exporterTexte,
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            color: kPrimary,
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Total des créances",
                    style: TextStyle(color: Colors.white60, fontSize: 13)),
                Text(
                  "${total.toStringAsFixed(2)} €",
                  style: TextStyle(
                      color: total > 0 ? Colors.orange[200] : kAccent,
                      fontSize: 34,
                      fontWeight: FontWeight.bold),
                ),
                Text("${clients.length} client(s)",
                    style: const TextStyle(color: Colors.white54, fontSize: 12)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              onChanged: (v) => setState(() => recherche = v),
              decoration: const InputDecoration(
                hintText: "Rechercher un client…",
                prefixIcon: Icon(Icons.search),
                contentPadding:
                    EdgeInsets.symmetric(vertical: 0, horizontal: 12),
              ),
            ),
          ),
          Expanded(
            child: _clientsFiltres.isEmpty
                ? const Center(
                    child: Text("Aucun client",
                        style: TextStyle(color: Colors.grey)))
                : ListView.builder(
                    itemCount: _clientsFiltres.length,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemBuilder: (context, i) {
                      final client = _clientsFiltres[i];
                      final realIndex = clients.indexOf(client);
                      return _ClientCard(
                        client: client,
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => DetailPage(
                                client: client,
                                onUpdate: () {
                                  setState(() {});
                                  _sauvegarder();
                                },
                              ),
                            ),
                          );
                          setState(() {});
                        },
                        onLongPress: () => _dialogAction(realIndex),
                        onDelete: () => _supprimerClient(realIndex),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _dialogAjouterClient,
        icon: const Icon(Icons.person_add),
        label: const Text("Nouveau client"),
      ),
    );
  }

  void _dialogAction(int index) {
    String montant = "";
    String note = "";
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("Transaction — ${clients[index].nom}"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              autofocus: true,
              onChanged: (v) => montant = v,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))
              ],
              decoration: const InputDecoration(
                  labelText: "Montant (€)", prefixIcon: Icon(Icons.euro)),
            ),
            const SizedBox(height: 12),
            TextField(
              onChanged: (v) => note = v,
              decoration: const InputDecoration(
                  labelText: "Note (optionnel)",
                  prefixIcon: Icon(Icons.note_outlined)),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Annuler")),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: kDanger),
            onPressed: () {
              final m = double.tryParse(montant.replaceAll(',', '.')) ?? 0;
              if (m > 0) {
                setState(() => clients[index].transactions.add(Transaction(
                    DateTime.now().millisecondsSinceEpoch.toString(),
                    "dette",
                    m,
                    DateTime.now().toIso8601String(),
                    note: note.isEmpty ? null : note)));
                _sauvegarder();
              }
              Navigator.pop(context);
            },
            icon: const Icon(Icons.add),
            label: const Text("Dette"),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: kAccent),
            onPressed: () {
              final m = double.tryParse(montant.replaceAll(',', '.')) ?? 0;
              if (m > 0) {
                setState(() => clients[index].transactions.add(Transaction(
                    DateTime.now().millisecondsSinceEpoch.toString(),
                    "paiement",
                    m,
                    DateTime.now().toIso8601String(),
                    note: note.isEmpty ? null : note)));
                _sauvegarder();
              }
              Navigator.pop(context);
            },
            icon: const Icon(Icons.check),
            label: const Text("Paiement"),
          ),
        ],
      ),
    );
  }

  void _exporterTexte() {
    final sb = StringBuffer();
    sb.writeln("=== CARNET CRÉDIT ===");
    sb.writeln("Exporté le ${_dateFormatee(DateTime.now().toIso8601String())}");
    sb.writeln("Total global : ${_totalGlobal().toStringAsFixed(2)} €");
    sb.writeln();
    for (final c in clients) {
      sb.writeln("── ${c.nom} : ${c.dette.toStringAsFixed(2)} €");
      for (final t in c.transactions) {
        final signe = t.type == "dette" ? "+" : "-";
        sb.writeln(
            "   $signe${t.montant.toStringAsFixed(2)} € | ${_dateFormatee(t.date)}${t.note != null ? ' | ${t.note}' : ''}");
      }
      sb.writeln();
    }

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Export Carnet"),
        content: SingleChildScrollView(
          child: SelectableText(sb.toString(),
              style: const TextStyle(fontFamily: 'monospace', fontSize: 12)),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Fermer")),
          ElevatedButton.icon(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: sb.toString()));
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Copié dans le presse-papier")));
            },
            icon: const Icon(Icons.copy),
            label: const Text("Copier"),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────
// CARTE CLIENT
// ─────────────────────────────────────────

class _ClientCard extends StatelessWidget {
  final Client client;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final VoidCallback onDelete;

  const _ClientCard({
    required this.client,
    required this.onTap,
    required this.onLongPress,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final dette = client.dette;
    final color = dette > 0 ? kDanger : kAccent;
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        onLongPress: onLongPress,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: color.withOpacity(0.15),
                child: Text(
                  client.nom.substring(0, 1).toUpperCase(),
                  style: TextStyle(
                      color: color, fontWeight: FontWeight.bold, fontSize: 18),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(client.nom,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16)),
                    Text(
                        "${client.transactions.length} transaction(s)",
                        style: const TextStyle(
                            color: Colors.grey, fontSize: 12)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    "${dette >= 0 ? '+' : ''}${dette.toStringAsFixed(2)} €",
                    style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.bold,
                        fontSize: 16),
                  ),
                  Text(
                    dette > 0 ? "doit" : dette < 0 ? "en avance" : "soldé",
                    style: TextStyle(color: color, fontSize: 11),
                  ),
                ],
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.grey),
                onPressed: onDelete,
                tooltip: "Supprimer",
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────
// PAGE DÉTAIL
// ─────────────────────────────────────────

class DetailPage extends StatefulWidget {
  final Client client;
  final VoidCallback onUpdate;

  const DetailPage({super.key, required this.client, required this.onUpdate});

  @override
  State<DetailPage> createState() => _DetailPageState();
}

class _DetailPageState extends State<DetailPage> {
  Client get client => widget.client;

  void _supprimerTransaction(int index) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Supprimer cette transaction ?"),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Annuler")),
          TextButton(
            onPressed: () {
              setState(() => client.transactions.removeAt(index));
              widget.onUpdate();
              Navigator.pop(context);
            },
            child:
                const Text("Supprimer", style: TextStyle(color: kDanger)),
          ),
        ],
      ),
    );
  }

  void _modifierTransaction(int index) {
    final t = client.transactions[index];
    String montant = t.montant.toString();
    String note = t.note ?? "";
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Modifier la transaction"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: TextEditingController(text: montant),
              onChanged: (v) => montant = v,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                  labelText: "Montant (€)", prefixIcon: Icon(Icons.euro)),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: TextEditingController(text: note),
              onChanged: (v) => note = v,
              decoration: const InputDecoration(
                  labelText: "Note", prefixIcon: Icon(Icons.note_outlined)),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Annuler")),
          ElevatedButton(
            onPressed: () {
              final m =
                  double.tryParse(montant.replaceAll(',', '.')) ?? t.montant;
              setState(() {
                client.transactions[index] = Transaction(
                    t.id, t.type, m, t.date,
                    note: note.isEmpty ? null : note);
              });
              widget.onUpdate();
              Navigator.pop(context);
            },
            child: const Text("Enregistrer"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dette = client.dette;
    return Scaffold(
      appBar: AppBar(title: Text(client.nom)),
      body: Column(
        children: [
          Container(
            color: kPrimary,
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Solde actuel",
                    style: TextStyle(color: Colors.white60, fontSize: 13)),
                Text(
                  "${dette >= 0 ? '+' : ''}${dette.toStringAsFixed(2)} €",
                  style: TextStyle(
                      color: dette > 0 ? Colors.orange[200] : kAccent,
                      fontSize: 34,
                      fontWeight: FontWeight.bold),
                ),
                Text(
                  dette > 0
                      ? "Doit de l'argent"
                      : dette < 0
                          ? "En avance"
                          : "Compte soldé ✓",
                  style: const TextStyle(color: Colors.white54, fontSize: 13),
                ),
              ],
            ),
          ),
          Expanded(
            child: client.transactions.isEmpty
                ? const Center(
                    child: Text("Aucune transaction",
                        style: TextStyle(color: Colors.grey)))
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: client.transactions.length,
                    itemBuilder: (context, i) {
                      final t = client.transactions[
                          client.transactions.length - 1 - i];
                      final realIndex = client.transactions.length - 1 - i;
                      final isDette = t.type == "dette";
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: isDette
                                ? kDanger.withOpacity(0.15)
                                : kAccent.withOpacity(0.15),
                            child: Icon(
                              isDette ? Icons.arrow_upward : Icons.arrow_downward,
                              color: isDette ? kDanger : kAccent,
                              size: 20,
                            ),
                          ),
                          title: Row(
                            children: [
                              Text(
                                "${isDette ? '+' : '-'}${t.montant.toStringAsFixed(2)} €",
                                style: TextStyle(
                                    color: isDette ? kDanger : kAccent,
                                    fontWeight: FontWeight.bold),
                              ),
                              if (t.note != null) ...[
                                const SizedBox(width: 8),
                                Expanded(
                                    child: Text(t.note!,
                                        style: const TextStyle(
                                            color: Colors.grey,
                                            fontSize: 13),
                                        overflow: TextOverflow.ellipsis)),
                              ]
                            ],
                          ),
                          subtitle: Text(
                              _dateFormatee(t.date),
                              style: const TextStyle(fontSize: 12)),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit_outlined,
                                    size: 20, color: Colors.grey),
                                onPressed: () =>
                                    _modifierTransaction(realIndex),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline,
                                    size: 20, color: Colors.grey),
                                onPressed: () =>
                                    _supprimerTransaction(realIndex),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────
// UTILITAIRES
// ─────────────────────────────────────────

String _dateFormatee(String isoDate) {
  try {
    final d = DateTime.parse(isoDate);
    return "${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year} ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}";
  } catch (_) {
    return isoDate;
  }
}
