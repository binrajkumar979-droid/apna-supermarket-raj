import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supermarket_app/core/models/user_model.dart';
import 'package:supermarket_app/features/customer/home/presentation/customer_home_screen.dart';
import 'package:supermarket_app/features/owner/dashboard/presentation/owner_dashboard_screen.dart';
import 'package:supermarket_app/features/delivery/presentation/delivery_boy_orders_screen.dart';
import 'package:supermarket_app/features/auth/presentation/auth_controller.dart';
import 'package:supermarket_app/features/auth/presentation/login_screen.dart';

class RoleRouterScreen extends ConsumerWidget {
  const RoleRouterScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateStreamProvider);

    return authState.when(
      data: (user) {
        if (user == null) {
          return const LoginScreen();
        }

        final profileState = ref.watch(userProfileStreamProvider);
        return profileState.when(
          data: (userProfile) {
            if (userProfile == null) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            switch (userProfile.role) {
              case UserRole.owner:
              case UserRole.manager:
                return const OwnerDashboardScreen();
              case UserRole.deliveryBoy:
                return const DeliveryBoyOrdersScreen();
              case UserRole.customer:
              default:
                return const CustomerHomeScreen();
            }
          },
          loading: () => const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          ),
          error: (err, stack) => Scaffold(
            body: Center(child: Text("Error loading profile: $err")),
          ),
        );
      },
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (err, stack) => Scaffold(
        body: Center(child: Text("Authentication Error: $err")),
      ),
    );
  }
}
