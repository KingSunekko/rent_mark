import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'theme/app_theme.dart';
import 'state/auth_state.dart';
import 'state/rental_requests_state.dart';
import 'state/reviews_state.dart';
import 'state/notifications_state.dart';
import 'state/admin_state.dart';
import 'state/favorites_state.dart';
import 'screens/splash_screen.dart';

void main() {
  runApp(const RentMarkApp());
}

class RentMarkApp extends StatelessWidget {
  const RentMarkApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthState()),
        ChangeNotifierProxyProvider<AuthState, RentalRequestsState>(
          create: (_) => RentalRequestsState(),
          update: (_, auth, requests) {
            final state = requests ?? RentalRequestsState();
            state.configureSession(auth.accessToken, auth.currentUser?.id);
            return state;
          },
        ),
        ChangeNotifierProxyProvider<AuthState, ReviewsState>(
          create: (_) => ReviewsState(),
          update: (_, auth, reviews) {
            final state = reviews ?? ReviewsState();
            state.configureSession(auth.accessToken, auth.currentUser?.id);
            return state;
          },
        ),
        ChangeNotifierProxyProvider<AuthState, NotificationsState>(
          create: (_) => NotificationsState(),
          update: (_, auth, notifications) {
            final state = notifications ?? NotificationsState();
            state.configureSession(
              auth.accessToken,
              auth.currentUser?.id,
              auth.currentUser?.role,
            );
            return state;
          },
        ),
        ChangeNotifierProxyProvider<AuthState, AdminState>(
          create: (_) => AdminState(),
          update: (_, auth, admin) {
            final state = admin ?? AdminState();
            state.configureSession(auth.accessToken, auth.currentUser?.role);
            return state;
          },
        ),
        ChangeNotifierProvider(create: (_) => FavoritesState()),
      ],
      child: MaterialApp(
        title: 'RentMark',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        home: const SplashScreen(),
      ),
    );
  }
}
