import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/theme/app_theme.dart';
import '../../core/services/notification_service.dart';
import '../../services/auth_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _authService = AuthService();
  final _notificationService = NotificationService();

  bool _notificationsEnabled = true;
  bool _dailyReminderEnabled = true;
  bool _goalRemindersEnabled = true;
  TimeOfDay _reminderTime = const TimeOfDay(hour: 20, minute: 0);
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final settings = await _notificationService.getNotificationSettings();
      setState(() {
        _notificationsEnabled = settings['enabled'];
        _dailyReminderEnabled = settings['dailyReminder'];
        _goalRemindersEnabled = settings['goalReminders'];
        _reminderTime = TimeOfDay(
          hour: settings['reminderHour'],
          minute: settings['reminderMinute'],
        );
        _loading = false;
      });
    } catch (e) {
      print('Error loading settings: $e');
      setState(() => _loading = false);
    }
  }

  Future<void> _saveSettings() async {
    try {
      await _notificationService.saveNotificationSettings(
        enabled: _notificationsEnabled,
        dailyReminder: _dailyReminderEnabled,
        goalReminders: _goalRemindersEnabled,
        reminderHour: _reminderTime.hour,
        reminderMinute: _reminderTime.minute,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Settings saved successfully'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving settings: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  Future<void> _selectReminderTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _reminderTime,
    );

    if (picked != null) {
      setState(() {
        _reminderTime = picked;
      });
      await _saveSettings();
    }
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _authService.logout();
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/');
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(e.toString().replaceAll('Exception: ', '')),
              backgroundColor: AppTheme.errorColor,
            ),
          );
        }
      }
    }
  }

  Future<void> _clearAllData() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Data'),
        content: const Text(
          'This will delete all your transactions and settings. This action cannot be undone. Are you sure?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
            ),
            child: const Text('Delete All'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      // Implement data clearing logic here
      // This would typically involve calling your database service
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Data clearing feature coming soon'),
            backgroundColor: AppTheme.infoColor,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: [
                // Notifications Section
                _buildSectionHeader('Notifications'),
                SwitchListTile(
                  secondary: const Icon(Icons.notifications),
                  title: const Text('Enable Notifications'),
                  subtitle: const Text('Receive reminders and alerts'),
                  value: _notificationsEnabled,
                  onChanged: (value) {
                    setState(() => _notificationsEnabled = value);
                    _saveSettings();
                  },
                ),
                if (_notificationsEnabled) ...[
                  SwitchListTile(
                    secondary: const Icon(Icons.event_repeat),
                    title: const Text('Daily Expense Reminder'),
                    subtitle: const Text('Daily reminder to track expenses'),
                    value: _dailyReminderEnabled,
                    onChanged: (value) {
                      setState(() => _dailyReminderEnabled = value);
                      _saveSettings();
                    },
                  ),
                  if (_dailyReminderEnabled)
                    ListTile(
                      leading: const Icon(Icons.access_time),
                      title: const Text('Reminder Time'),
                      subtitle: Text(_reminderTime.format(context)),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: _selectReminderTime,
                    ),
                  SwitchListTile(
                    secondary: const Icon(Icons.flag),
                    title: const Text('Goal Reminders'),
                    subtitle: const Text('Updates on savings goal progress'),
                    value: _goalRemindersEnabled,
                    onChanged: (value) {
                      setState(() => _goalRemindersEnabled = value);
                      _saveSettings();
                    },
                  ),
                ],
                const Divider(),

                // Account Section
                _buildSectionHeader('Account'),
                ListTile(
                  leading: const Icon(Icons.person),
                  title: const Text('Profile'),
                  subtitle: const Text('View and edit your profile'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Profile feature coming soon'),
                      ),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.lock),
                  title: const Text('Change Password'),
                  subtitle: const Text('Update your password'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Password change feature coming soon'),
                      ),
                    );
                  },
                ),
                const Divider(),

                // Data Section
                _buildSectionHeader('Data & Storage'),
                ListTile(
                  leading: const Icon(Icons.download),
                  title: const Text('Export Data'),
                  subtitle: const Text('Download your financial data'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Export feature coming soon'),
                      ),
                    );
                  },
                ),
                ListTile(
                  leading: Icon(
                    Icons.delete_forever,
                    color: AppTheme.errorColor,
                  ),
                  title: Text(
                    'Clear All Data',
                    style: TextStyle(color: AppTheme.errorColor),
                  ),
                  subtitle: const Text('Delete all transactions and settings'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: _clearAllData,
                ),
                const Divider(),

                // App Information
                _buildSectionHeader('About'),
                ListTile(
                  leading: const Icon(Icons.info),
                  title: const Text('App Version'),
                  subtitle: const Text('1.0.0'),
                ),
                ListTile(
                  leading: const Icon(Icons.policy),
                  title: const Text('Privacy Policy'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Privacy policy coming soon'),
                      ),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.description),
                  title: const Text('Terms of Service'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Terms of service coming soon'),
                      ),
                    );
                  },
                ),
                const Divider(),

                // Logout Button
                const SizedBox(height: AppTheme.spacingM),
                Padding(
                  padding: const EdgeInsets.all(AppTheme.spacingM),
                  child: ElevatedButton.icon(
                    onPressed: _logout,
                    icon: const Icon(Icons.logout),
                    label: const Text('Logout'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.errorColor,
                      minimumSize: const Size(double.infinity, 50),
                    ),
                  ),
                ),
                const SizedBox(height: AppTheme.spacingXl),
              ],
            ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppTheme.spacingM,
        AppTheme.spacingL,
        AppTheme.spacingM,
        AppTheme.spacingS,
      ),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppTheme.primaryColor,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
