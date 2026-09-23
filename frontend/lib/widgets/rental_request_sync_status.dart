import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/rental_requests_state.dart';

class RentalRequestSyncStatus extends StatelessWidget {
  const RentalRequestSyncStatus({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<RentalRequestsState>();
    if (!state.usesBackend) return const SizedBox.shrink();
    return Column(
      children: [
        if (state.isLoading) const LinearProgressIndicator(),
        Row(
          children: [
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                state.error ?? 'Your saved rental requests',
                style: TextStyle(
                  color: state.error == null
                      ? null
                      : Theme.of(context).colorScheme.error,
                ),
              ),
            ),
            TextButton(
              onPressed: state.isLoading ? null : state.reload,
              child: Text(state.error == null ? 'REFRESH' : 'RETRY'),
            ),
          ],
        ),
      ],
    );
  }
}
