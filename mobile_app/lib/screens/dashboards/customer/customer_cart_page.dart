import 'package:flutter/material.dart';
import '../../../models/api_product.dart';
import '../../../utils/bankily_split.dart';
import '../../../widgets/bankily_pay_button.dart';

class CustomerCartLine {
  final ApiProduct product;
  int quantity;

  CustomerCartLine({required this.product, this.quantity = 1});

  int get subtotal => product.priceMru * quantity;
}

class CustomerCartPage extends StatelessWidget {
  final List<CustomerCartLine> cart;
  final VoidCallback onChanged;
  final Future<void> Function() onBankilyCheckout;

  const CustomerCartPage({
    super.key,
    required this.cart,
    required this.onChanged,
    required this.onBankilyCheckout,
  });

  int get totalMru => cart.fold(0, (s, l) => s + l.subtotal);

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Scaffold(
        appBar: AppBar(title: const Text('Panier')),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            ...cart.map(
              (line) => Card(
                child: ListTile(
                  title: Text(line.product.name),
                  subtitle: Text(formatMru(line.subtotal)),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline),
                        onPressed: () {
                          if (line.quantity > 1) {
                            line.quantity--;
                          } else {
                            cart.remove(line);
                          }
                          onChanged();
                        },
                      ),
                      Text('${line.quantity}'),
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline),
                        onPressed: () {
                          line.quantity++;
                          onChanged();
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (cart.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                'Total : ${formatMru(totalMru)}',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ],
        ),
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: BankilyPayButton(
              amountMru: totalMru,
              onPressed: cart.isEmpty ? null : () => onBankilyCheckout(),
            ),
          ),
        ),
      ),
    );
  }
}
