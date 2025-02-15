import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

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
          color: Colors.red.withAlpha(80),
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 16),
          child: const Icon(Icons.delete, color: Colors.white),
        ),
        child: ListTile(
          leading: SvgPicture.asset(
            'packages/presentation/assets/icon_standing_order.svg',
            width: 24,
            height: 24,
          ),
          title: isEditing
              ? TextField(
                  onChanged: onNameChanged,
                  decoration: InputDecoration(
                    hintText: 'Order name',
                    hintStyle: TextStyle(
                      color: Theme.of(context).hintColor.withOpacity(0.5),
                    ),
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
                          decoration: InputDecoration(
                            hintText: 'Amount',
                            hintStyle: TextStyle(
                              color:
                                  Theme.of(context).hintColor.withOpacity(0.5),
                            ),
                          ),
                        ),
                      ),
                      IconButton(
                        icon: SvgPicture.asset(
                          'packages/presentation/assets/icon_tick.svg',
                          width: 24,
                          height: 24,
                        ),
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
