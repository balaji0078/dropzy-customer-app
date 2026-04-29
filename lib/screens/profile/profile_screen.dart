import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../config/theme.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../../utils/helpers.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _phoneController;
  late TextEditingController _cityController;
  bool _isEditing = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final authProvider = context.read<AuthProvider>();
    _firstNameController = TextEditingController(text: authProvider.user?.firstName ?? '');
    _lastNameController = TextEditingController(text: authProvider.user?.lastName ?? '');
    _phoneController = TextEditingController(text: authProvider.user?.phone ?? '');
    _cityController = TextEditingController(text: authProvider.user?.city ?? '');
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    setState(() {
      _isSaving = true;
    });

    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.updateProfile(
      firstName: _firstNameController.text,
      lastName: _lastNameController.text,
      phone: _phoneController.text,
      city: _cityController.text,
    );

    setState(() {
      _isSaving = false;
      _isEditing = false;
    });

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success ? 'Profile updated successfully' : 'Failed to update profile'),
        backgroundColor: success ? Colors.green : Colors.red,
      ),
    );
  }

  Future<void> _logout() async {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Logout'),
          content: const Text('Are you sure you want to logout?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                final authProvider = context.read<AuthProvider>();
                await authProvider.logout();
                if (!mounted) return;
                Navigator.of(context).pushReplacementNamed('/login');
              },
              child: const Text(
                'Logout',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        centerTitle: true,
        actions: [
          if (!_isEditing)
            TextButton(
              onPressed: () {
                setState(() {
                  _isEditing = true;
                });
              },
              child: const Text('Edit'),
            ),
        ],
      ),
      body: Consumer<AuthProvider>(
        builder: (context, authProvider, _) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildProfileHeader(authProvider),
                const SizedBox(height: 32),
                if (_isEditing) _buildEditForm() else _buildProfileInfo(authProvider),
                const SizedBox(height: 32),
                _buildSettingsSection(),
                const SizedBox(height: 32),
                CustomButton(
                  text: 'Logout',
                  onPressed: _logout,
                  isSecondary: true,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildProfileHeader(AuthProvider authProvider) {
    return Column(
      children: [
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppTheme.primaryRed.withOpacity(0.2),
          ),
          child: Icon(
            Icons.person,
            size: 50,
            color: AppTheme.primaryRed,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          authProvider.user?.fullName ?? 'User',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 4),
        Text(
          authProvider.user?.email ?? '',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  Widget _buildProfileInfo(AuthProvider authProvider) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow('First Name', authProvider.user?.firstName ?? 'N/A'),
            const Divider(),
            _buildInfoRow('Last Name', authProvider.user?.lastName ?? 'N/A'),
            const Divider(),
            _buildInfoRow('Email', authProvider.user?.email ?? 'N/A'),
            const Divider(),
            _buildInfoRow('Phone', authProvider.user?.phone ?? 'N/A'),
            const Divider(),
            _buildInfoRow('City', authProvider.user?.city ?? 'N/A'),
            const Divider(),
            _buildInfoRow(
              'Account Status',
              authProvider.user?.isVerified == true ? 'Verified' : 'Unverified',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEditForm() {
    return Column(
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: CustomTextField(
                        label: 'First Name',
                        hint: 'Enter first name',
                        controller: _firstNameController,
                        validator: Helpers.validateName,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: CustomTextField(
                        label: 'Last Name',
                        hint: 'Enter last name',
                        controller: _lastNameController,
                        validator: Helpers.validateName,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  label: 'Phone Number',
                  hint: 'Enter phone number',
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  validator: Helpers.validatePhone,
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  label: 'City',
                  hint: 'Enter city',
                  controller: _cityController,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () {
                  setState(() {
                    _isEditing = false;
                  });
                },
                child: const Text('Cancel'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: CustomButton(
                text: 'Save Changes',
                onPressed: _saveProfile,
                isLoading: _isSaving,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.titleSmall,
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Settings',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 12),
        Card(
          child: Column(
            children: [
              _buildSettingTile(
                icon: Icons.notifications_outlined,
                title: 'Notifications',
                subtitle: 'Manage notification preferences',
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Notification settings'),
                    ),
                  );
                },
              ),
              const Divider(height: 0),
              _buildSettingTile(
                icon: Icons.payment_outlined,
                title: 'Payment Methods',
                subtitle: 'Add or remove payment methods',
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Payment methods'),
                    ),
                  );
                },
              ),
              const Divider(height: 0),
              _buildSettingTile(
                icon: Icons.location_on_outlined,
                title: 'Saved Addresses',
                subtitle: 'Manage your saved addresses',
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Saved addresses'),
                    ),
                  );
                },
              ),
              const Divider(height: 0),
              _buildSettingTile(
                icon: Icons.help_outline,
                title: 'Help & Support',
                subtitle: 'Contact us or view FAQs',
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Help & support'),
                    ),
                  );
                },
              ),
              const Divider(height: 0),
              _buildSettingTile(
                icon: Icons.info_outline,
                title: 'About',
                subtitle: 'App version and information',
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Dropzy v1.0.0'),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSettingTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: AppTheme.primaryRed),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      onTap: onTap,
    );
  }
}
