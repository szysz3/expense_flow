import 'package:flutter/material.dart';

class StandingOrderItem extends StatelessWidget {
  final String orderId;
  final String name;
  final double amount;
  final bool isEditing;
  final ValueChanged<String>? onNameChanged;
  final ValueChanged<String>? onAmountChanged;
  final VoidCallback? onConfirmed;
  final VoidCallback onDelete;

  const StandingOrderItem({
    required this.orderId,
    required this.name,
    required this.amount,
    this.isEditing = false,
    this.onNameChanged,
    this.onAmountChanged,
    this.onConfirmed,
    required this.onDelete,
    super.key,
  });

  @override
  Widget build(BuildContext context) => Dismissible(
        key: Key(orderId),
        direction: DismissDirection.endToStart,
        onDismissed: (_) => onDelete(),
        background: Container(
          color: Colors.red,
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 16),
          child: const Icon(Icons.delete, color: Colors.white),
        ),
        child: ListTile(
          leading: const Icon(Icons.payment),
          title: isEditing
              ? TextField(
                  onChanged: onNameChanged,
                  decoration: const InputDecoration(
                    hintText: 'Order name',
                  ),
                )
              : Text(name),
          trailing: SizedBox(
            width: 120,
            child: isEditing
                ? Row(
                    children: [
                      Expanded(
                        child: TextField(
                          onChanged: onAmountChanged,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            hintText: 'Amount',
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.check),
                        onPressed: onConfirmed,
                      ),
                    ],
                  )
                : Text(
                    amount.toStringAsFixed(2),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
          ),
        ),
      );
}
