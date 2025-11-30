import 'package:flutter/material.dart';
import 'package:terafy/common/app_colors.dart';
import 'package:terafy/core/dependencies/dependency_container.dart';
import 'package:terafy/features/home/bloc/home_bloc_models.dart';
import 'package:terafy/routes/app_routes.dart';

class HomeHeader extends StatelessWidget {
  final String userName;
  final String userRole;
  final String? userPhotoUrl;
  final int notificationCount;
  final TherapistPlan? plan;
  final int? patientCount;
  final int? patientLimit;
  final VoidCallback? onNotificationTap;

  const HomeHeader({
    super.key,
    required this.userName,
    required this.userRole,
    this.userPhotoUrl,
    this.notificationCount = 0,
    this.plan,
    this.patientCount,
    this.patientLimit,
    this.onNotificationTap,
  });

  String _getInitials() {
    if (userName.isEmpty) return 'U';

    final parts = userName.trim().split(' ');
    if (parts.length == 1) {
      return parts[0].substring(0, 1).toUpperCase();
    }

    // Primeira letra do nome + primeira letra do sobrenome
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }

  Future<void> _showLogoutDialog(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Sair'),
          content: const Text('Tem certeza que deseja sair?'),
          actions: [
            TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: const Text('Cancelar')),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Sair'),
            ),
          ],
        );
      },
    );

    if (result == true && context.mounted) {
      // Faz logout diretamente
      final secureStorage = DependencyContainer().secureStorageService;
      await secureStorage.deleteToken();
      await secureStorage.deleteRefreshToken();
      await secureStorage.deleteUserIdentifier();

      // Navega para login removendo todas as rotas anteriores
      if (context.mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil(AppRouter.loginRoute, (route) => false);
      }
    }
  }

  void _handleMenuAction(BuildContext context, String action) {
    switch (action) {
      case 'profile':
        Navigator.of(context).pushNamed(AppRouter.editProfileRoute);
        break;
      case 'settings':
        // TODO: Navegar para configurações
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Configurações em desenvolvimento')));
        break;
      case 'logout':
        _showLogoutDialog(context);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.backgroundGradientStart, AppColors.backgroundGradientEnd],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            // Avatar com menu dropdown
            PopupMenuButton<String>(
              offset: const Offset(0, 50),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              onSelected: (value) => _handleMenuAction(context, value),
              itemBuilder: (BuildContext context) => [
                const PopupMenuItem<String>(
                  value: 'profile',
                  child: Row(children: [Icon(Icons.person_outline, size: 20), SizedBox(width: 12), Text('Meu Perfil')]),
                ),
                const PopupMenuItem<String>(
                  value: 'settings',
                  child: Row(
                    children: [Icon(Icons.settings_outlined, size: 20), SizedBox(width: 12), Text('Configurações')],
                  ),
                ),
                const PopupMenuDivider(),
                const PopupMenuItem<String>(
                  value: 'logout',
                  child: Row(
                    children: [
                      Icon(Icons.logout, size: 20, color: Colors.red),
                      SizedBox(width: 12),
                      Text('Sair', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
              child: CircleAvatar(
                radius: 28,
                backgroundColor: Colors.white,
                backgroundImage: userPhotoUrl != null ? NetworkImage(userPhotoUrl!) : null,
                child: userPhotoUrl == null
                    ? Text(
                        _getInitials(),
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.primary),
                      )
                    : null,
              ),
            ),
            const SizedBox(width: 16),

            // Name and role
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    userName,
                    style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(userRole, style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 14)),
                      if (plan != null) ...[
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () {
                            Navigator.of(context).pushNamed(AppRouter.subscriptionRoute);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: plan!.id == 0 ? Colors.amber.withOpacity(0.2) : AppColors.primary.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: plan!.id == 0 ? Colors.amber : Colors.white.withOpacity(0.5),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  plan!.name.toUpperCase(),
                                  style: TextStyle(
                                    color: plan!.id == 0 ? Colors.amber : Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                if (patientCount != null && patientLimit != null) ...[
                                  const SizedBox(width: 4),
                                  Text(
                                    '($patientCount/$patientLimit)',
                                    style: TextStyle(
                                      color: plan!.id == 0 ? Colors.amber : Colors.white,
                                      fontSize: 9,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),

            // Notification bell
            Stack(
              children: [
                IconButton(
                  icon: const Icon(Icons.notifications_outlined, color: Colors.white, size: 28),
                  onPressed: onNotificationTap,
                ),
                if (notificationCount > 0)
                  Positioned(
                    right: 8,
                    top: 8,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                      constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                      child: Text(
                        notificationCount > 9 ? '9+' : notificationCount.toString(),
                        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
