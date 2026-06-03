import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/queue_provider.dart';
import 'screens/admin/admin_dashboard_screen.dart';
import 'screens/customer/counter_selection_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Resilient Firebase initialization
  try {
    await Firebase.initializeApp();
  } catch (e) {
    // If Firebase isn't configured yet, log the error rather than crashing
    // so designers and developers can still verify the UI elements.
    debugPrint('Firebase initialization warning: $e');
  }

  // Production-grade error boundary overrides (Prevents Grey Screens of Death)
  ErrorWidget.builder = (FlutterErrorDetails details) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: const Color(0xFF1E1E2E), // Slate dark
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(28.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.error_outline_rounded,
                  color: Color(0xFFFF5555), // Dracula red
                  size: 64,
                ),
                const SizedBox(height: 20),
                const Text(
                  'Application Error Intercepted',
                  style: TextStyle(
                    color: Color(0xFFF8F8F2),
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  details.exceptionAsString(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFF6272A4), // Dracula comment grey
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    // Try to recover by rebuilding
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFBD93F9), // Purple
                    foregroundColor: const Color(0xFF1E1E2E),
                  ),
                  child: const Text('Attempt Recovery'),
                )
              ],
            ),
          ),
        ),
      ),
    );
  };

  runApp(const QueueManagerApp());
}

/// The root application widget.
class QueueManagerApp extends StatelessWidget {
  const QueueManagerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => QueueProvider()),
      ],
      child: MaterialApp(
        title: 'Q-Flow AI',
        debugShowCheckedModeBanner: false,
        
        // Custom Premium Dracula Slate Blue Theme System
        theme: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(
            primary: Color(0xFFBD93F9), // Dracula Purple
            secondary: Color(0xFFFF79C6), // Dracula Pink
            surface: Color(0xFF282A36), // Dracula dark surface
            background: Color(0xFF1E1E2E), // Custom slate background
            onPrimary: Color(0xFF1E1E2E),
            onSecondary: Color(0xFF1E1E2E),
            onSurface: Color(0xFFF8F8F2),
            onBackground: Color(0xFFF8F8F2),
            outlineVariant: Color(0xFF44475A), // Dracula selection grey
          ),
          scaffoldBackgroundColor: const Color(0xFF1E1E2E),
          cardTheme: CardTheme(
            color: const Color(0xFF282A36),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
          ),
        ),
        
        initialRoute: '/',
        routes: {
          '/': (context) => const QueueGatewayPortal(),
          '/customer': (context) => const CounterSelectionScreen(),
          '/admin': (context) => const AdminDashboardScreen(),
        },
      ),
    );
  }
}

/// Home gateway landing portal offering customer and administrator routing paths.
class QueueGatewayPortal extends StatelessWidget {
  const QueueGatewayPortal({super.key});

  // Mock global fallback user device parameter
  static const String fallbackDeviceId = 'SHIVANI_DEVICE_ID_101';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0F101A), Color(0xFF1E1E2E)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Spacer(),
                
                // Brand Header
                Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withOpacity(0.1),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: theme.colorScheme.primary.withOpacity(0.3),
                          width: 2,
                        ),
                      ),
                      child: Icon(
                        Icons.insights_rounded,
                        size: 56,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Q-FLOW AI',
                      style: theme.textTheme.displaySmall?.copyWith(
                        fontWeight: FontWeight.w900,
                        letterSpacing: 3.0,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'AI-Powered Live Queue Orchestrator',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.colorScheme.secondary,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ],
                ),
                
                const Spacer(),
                
                // Operational Gate Selection Cards
                Column(
                  children: [
                    // Card A: Customer Entrance
                    _buildPortalCard(
                      context: context,
                      theme: theme,
                      title: 'Customer Entrance',
                      subtitle: 'Generate token and track wait times',
                      icon: Icons.people_alt_rounded,
                      color: theme.colorScheme.primary,
                      onTap: () => Navigator.of(context).pushNamed('/customer'),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Card B: Admin Desk
                    _buildPortalCard(
                      context: context,
                      theme: theme,
                      title: 'Operations Admin Desk',
                      subtitle: 'Call waiting clients and clear sessions',
                      icon: Icons.admin_panel_settings_rounded,
                      color: theme.colorScheme.secondary,
                      onTap: () => Navigator.of(context).pushNamed('/admin'),
                    ),
                  ],
                ),
                
                const Spacer(),
                
                // Footer details
                Column(
                  children: [
                    Text(
                      'REGISTERED DEVICE ID',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.outlineVariant,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: theme.colorScheme.outlineVariant),
                      ),
                      child: const Text(
                        fallbackDeviceId,
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 12,
                          color: Color(0xFFF8F8F2),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPortalCard({
    required BuildContext context,
    required ThemeData theme,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.colorScheme.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            splashColor: color.withOpacity(0.1),
            highlightColor: color.withOpacity(0.05),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(icon, color: color, size: 28),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: theme.colorScheme.outlineVariant,
                    size: 16,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
