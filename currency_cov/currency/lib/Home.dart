import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _amountController = TextEditingController();
  String? _fromCurrency;
  String? _toCurrency;
  String _result = '';
  List<String> _currencies = [];
  Map<String, double> _conversionRates = {};
  Map<String, String> _currencyLogos = {};
  List<String> _filteredCurrencies = [];
  List<Map<String, dynamic>> _conversionHistory = [];

  @override
  void initState() {
    super.initState();
    _fetchCurrencies();
    _loadConversionHistory();
  }

  // Fetching currencies from the API
  Future<void> _fetchCurrencies() async {
    const apiUrl =
        'https://v6.exchangerate-api.com/v6/65cc929e9dee8f0efa9a9ced/latest/USD';
    try {
      final response = await http.get(Uri.parse(apiUrl));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['result'] == 'success') {
          setState(() {
            _currencies = (data['conversion_rates'] as Map<String, dynamic>)
                .keys
                .toSet()
                .toList();
            _currencies.sort();
            _filteredCurrencies = List.from(_currencies);
            _conversionRates =
                Map<String, double>.from(data['conversion_rates']);

            _currencyLogos = {
              'USD': 'https://flagcdn.com/w320/us.png',
              'EUR': 'https://flagcdn.com/w320/eu.png',
              'GBP': 'https://flagcdn.com/w320/gb.png',
              'INR': 'https://flagcdn.com/w320/in.png',
              'PAK': 'https://flagcdn.com/w320/pk.png',
            };
            _validateCurrencySelection();
          });
        } else {
          setState(() {
            _result = 'Failed to load currencies.';
          });
        }
      } else {
        setState(() {
          _result = 'Error fetching data.';
        });
      }
    } catch (e) {
      setState(() {
        _result = 'Error: $e';
      });
    }
  }

  void _validateCurrencySelection() {
    if (_fromCurrency == null || !_currencies.contains(_fromCurrency)) {
      _fromCurrency = _currencies.isNotEmpty ? _currencies.first : null;
    }
    if (_toCurrency == null || !_currencies.contains(_toCurrency)) {
      _toCurrency = _currencies.isNotEmpty ? _currencies.first : null;
    }
  }

  // Saving conversion history to shared preferences
  Future<void> _saveConversionHistory() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> historyList =
        _conversionHistory.map((e) => json.encode(e)).toList();
    await prefs.setStringList('conversion_history', historyList);
  }

  // Loading conversion history from shared preferences
  Future<void> _loadConversionHistory() async {
    final prefs = await SharedPreferences.getInstance();
    List<String>? historyList = prefs.getStringList('conversion_history');
    if (historyList != null) {
      setState(() {
        _conversionHistory = historyList
            .map((e) => json.decode(e) as Map<String, dynamic>)
            .toList();
      });
    }
  }

  double _convertCurrency(double amount, String from, String to) {
    if (from == to) return amount;
    double fromRate = _conversionRates[from] ?? 1;
    double toRate = _conversionRates[to] ?? 1;
    return amount * (toRate / fromRate);
  }

  void _performConversion() {
    final amount = double.tryParse(_amountController.text.trim());
    if (amount != null && _fromCurrency != null && _toCurrency != null) {
      final convertedAmount =
          _convertCurrency(amount, _fromCurrency!, _toCurrency!);
      final conversionHistoryItem = {
        'amount': amount,
        'fromCurrency': _fromCurrency,
        'toCurrency': _toCurrency,
        'result': convertedAmount.toStringAsFixed(2),
        'date': DateTime.now().toString(),
      };

      setState(() {
        _result = convertedAmount.toStringAsFixed(2);
        _conversionHistory.insert(
            0, conversionHistoryItem); // Add to the top of the history list
      });

      // Save the updated history
      _saveConversionHistory();
    } else {
      setState(() {
        _result = 'Invalid amount or currencies';
      });
    }
  }

  void _swapCurrencies() {
    setState(() {
      final temp = _fromCurrency;
      _fromCurrency = _toCurrency;
      _toCurrency = temp;
    });
  }

  void _filterCurrencies(String query) {
    setState(() {
      _filteredCurrencies = _currencies
          .where((currency) =>
              currency.toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    _validateCurrencySelection();

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Image.asset(
              'assets/logo.png',
              height: 50,
            ),
          ],
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            const DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.purple,
              ),
              child: Text(
                'Currency Converter',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                ),
              ),
            ),
            ListTile(
              title: const Text('Home'),
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const HomeScreen()),
                );
              },
            ),
            ListTile(
              title: const Text('Conversion History'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => HistoryScreen(
                      conversionHistory: _conversionHistory,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.purple, Colors.deepPurpleAccent],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),
              const Text(
                'Currency Converter',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _amountController,
                decoration: InputDecoration(
                  labelText: 'Enter Amount',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  prefixIcon: const Icon(Icons.attach_money),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: _buildSearchableCurrencyField(
                      label: 'From',
                      selectedCurrency: _fromCurrency,
                      onChanged: (String? newValue) {
                        setState(() {
                          _fromCurrency = newValue;
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  IconButton(
                    onPressed: _swapCurrencies,
                    icon: const Icon(Icons.swap_horiz),
                    color: Colors.white,
                    iconSize: 32,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildSearchableCurrencyField(
                      label: 'To',
                      selectedCurrency: _toCurrency,
                      onChanged: (String? newValue) {
                        setState(() {
                          _toCurrency = newValue;
                        });
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _performConversion,
                child: const Text('Convert'),
              ),
              const SizedBox(height: 20),
              Text(
                'Result: $_result',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  // Navigate to history screen
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => HistoryScreen(
                        conversionHistory: _conversionHistory,
                      ),
                    ),
                  );
                },
                child: const Text('View Conversion History'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchableCurrencyField({
    required String label,
    String? selectedCurrency,
    required ValueChanged<String?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: selectedCurrency ?? _currencies.first,
              isExpanded: true,
              onChanged: onChanged,
              items: [
                    DropdownMenuItem<String>(
                      value: null,
                      child: TextField(
                        onChanged: _filterCurrencies,
                        decoration: const InputDecoration(
                          labelText: 'Search Currency',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ] +
                  _filteredCurrencies
                      .map((currency) => DropdownMenuItem<String>(
                            value: currency,
                            child: Row(
                              children: [
                                if (_currencyLogos.containsKey(currency))
                                  Image.network(
                                    _currencyLogos[currency]!,
                                    width: 24,
                                    height: 24,
                                    errorBuilder: (context, error, stackTrace) {
                                      return const Icon(Icons.money, size: 24);
                                    },
                                  )
                                else
                                  const Icon(Icons.money, size: 24),
                                const SizedBox(width: 10),
                                Text(currency),
                              ],
                            ),
                          ))
                      .toList(),
            ),
          ),
        ),
      ],
    );
  }
}

class HistoryScreen extends StatelessWidget {
  final List<Map<String, dynamic>> conversionHistory;

  const HistoryScreen({Key? key, required this.conversionHistory})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Conversion History'),
        backgroundColor: Colors.purple,
      ),
      body: ListView.builder(
        itemCount: conversionHistory.length,
        itemBuilder: (context, index) {
          final history = conversionHistory[index];
          return ListTile(
            title: Text(
              '${history['amount']} ${history['fromCurrency']} = ${history['result']} ${history['toCurrency']}',
              style: const TextStyle(color: Colors.black),
            ),
            subtitle: Text(
              'Date: ${history['date']}',
              style: const TextStyle(color: Colors.black45),
            ),
          );
        },
      ),
    );
  }
}
