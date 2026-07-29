import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../data/models/enums.dart';
import '../../state/session_controller.dart';
import '../shell/app_shell.dart';
import '../widgets/common.dart';

class RoleMeta {
  final UserRole role;
  final IconData icon;
  final String summary;
  const RoleMeta(this.role, this.icon, this.summary);
}

const kRoleMeta = <RoleMeta>[
  RoleMeta(UserRole.landowner, Icons.agriculture,
      'Sell your crops, hire workers, find investors'),
  RoleMeta(UserRole.buyer, Icons.shopping_basket,
      'Buy from farmers, resell to exporters, hire crews'),
  RoleMeta(UserRole.laborer, Icons.engineering,
      'Find work — alone or as a group'),
  RoleMeta(UserRole.broker, Icons.handshake,
      'Facilitate deals and earn commission'),
  RoleMeta(UserRole.transport, Icons.local_shipping,
      'Offer goods and passenger vehicles'),
  RoleMeta(UserRole.foreignInvestor, Icons.trending_up,
      'Invest in local agricultural projects'),
  RoleMeta(UserRole.globalExporter, Icons.public,
      'Registered company buying and shipping produce'),
];

class RoleSelectionScreen extends StatefulWidget {
  const RoleSelectionScreen({super.key});

  @override
  State<RoleSelectionScreen> createState() => _RoleSelectionScreenState();
}

class _RoleSelectionScreenState extends State<RoleSelectionScreen> {
  UserRole? _selected;

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionController>();

    return Scaffold(
      appBar: AppBar(title: Text(session.t('choose_role'))),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  session.t('role_hint'),
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: kRoleMeta.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final meta = kRoleMeta[index];
                  final selected = _selected == meta.role;
                  return InkWell(
                    onTap: () => setState(() => _selected = meta.role),
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: selected
                            ? AppColors.primarySoft
                            : AppColors.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color:
                              selected ? AppColors.primary : AppColors.border,
                          width: selected ? 2 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 46,
                            height: 46,
                            decoration: BoxDecoration(
                              color: selected
                                  ? AppColors.primary
                                  : AppColors.primarySoft,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              meta.icon,
                              color: selected
                                  ? Colors.white
                                  : AppColors.primary,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        meta.role.label,
                                        style: const TextStyle(
                                          fontSize: 16.5,
                                          fontWeight: FontWeight.w800,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                    ),
                                    if (meta.role.requiresApproval) ...[
                                      const SizedBox(width: 8),
                                      const StatusPill(
                                        label: 'Verified',
                                        color: AppColors.warning,
                                        background: AppColors.pendingSoft,
                                      ),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  meta.summary,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    height: 1.3,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: ElevatedButton(
                onPressed: _selected == null
                    ? null
                    : () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) =>
                                ProfileSetupScreen(role: _selected!),
                          ),
                        ),
                child: Text(session.t('continue_label')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Collects role-specific profile details before creating the account.
class ProfileSetupScreen extends StatefulWidget {
  final UserRole role;
  const ProfileSetupScreen({super.key, required this.role});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _district = TextEditingController();
  final _company = TextEditingController();
  final _registration = TextEditingController();
  final _country = TextEditingController();
  LaborerType _laborerType = LaborerType.singleWorker;
  bool _saving = false;

  bool get _isLaborer => widget.role == UserRole.laborer;
  bool get _isExporter => widget.role == UserRole.globalExporter;
  bool get _isInvestor => widget.role == UserRole.foreignInvestor;

  @override
  void dispose() {
    _name.dispose();
    _district.dispose();
    _company.dispose();
    _registration.dispose();
    _country.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);
    final session = context.read<SessionController>();
    await session.register(
      name: _name.text,
      role: widget.role,
      district: _district.text,
      laborerType: _isLaborer ? _laborerType : null,
      companyName: _company.text.trim().isEmpty ? null : _company.text.trim(),
      registrationNo:
          _registration.text.trim().isEmpty ? null : _registration.text.trim(),
      country: _country.text.trim().isEmpty ? null : _country.text.trim(),
    );
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => const AppShell()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionController>();

    return Scaffold(
      appBar: AppBar(title: Text(widget.role.label)),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (widget.role.requiresApproval) ...[
                  const InfoBanner(
                    icon: Icons.verified_user_outlined,
                    message:
                        'This account type needs approval by the BLOB team. '
                        'You can sign in immediately, with full access unlocked once approved.',
                    color: AppColors.warning,
                    background: AppColors.pendingSoft,
                  ),
                  const SizedBox(height: 18),
                ],
                TextFormField(
                  controller: _name,
                  textCapitalization: TextCapitalization.words,
                  decoration: InputDecoration(
                    labelText: session.t('your_name'),
                    prefixIcon: const Icon(Icons.person_outline),
                  ),
                  validator: (v) =>
                      (v?.trim().isEmpty ?? true) ? 'Enter your name' : null,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _district,
                  textCapitalization: TextCapitalization.words,
                  decoration: InputDecoration(
                    labelText: session.t('district'),
                    prefixIcon: const Icon(Icons.location_on_outlined),
                    hintText: 'e.g. Mandya',
                  ),
                  validator: (v) =>
                      (v?.trim().isEmpty ?? true) ? 'Enter your district' : null,
                ),
                if (_isLaborer) ...[
                  const SizedBox(height: 22),
                  const Text(
                    'What kind of work?',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  ...LaborerType.values.map(
                    (type) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: InkWell(
                        onTap: () => setState(() => _laborerType = type),
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: _laborerType == type
                                ? AppColors.primarySoft
                                : AppColors.surface,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: _laborerType == type
                                  ? AppColors.primary
                                  : AppColors.border,
                              width: _laborerType == type ? 2 : 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                type == LaborerType.singleWorker
                                    ? Icons.person
                                    : Icons.groups,
                                color: AppColors.primary,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      type.label,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 15,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      type.description,
                                      style: const TextStyle(
                                        fontSize: 12.5,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(
                                _laborerType == type
                                    ? Icons.radio_button_checked
                                    : Icons.radio_button_unchecked,
                                color: _laborerType == type
                                    ? AppColors.primary
                                    : AppColors.border,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
                if (_isExporter || _isInvestor) ...[
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _company,
                    textCapitalization: TextCapitalization.words,
                    decoration: InputDecoration(
                      labelText: _isExporter
                          ? 'Registered company name'
                          : 'Entity / fund name (optional)',
                      prefixIcon: const Icon(Icons.business_outlined),
                    ),
                    validator: (v) {
                      if (_isExporter && (v?.trim().isEmpty ?? true)) {
                        return 'Company name is required';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _country,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: 'Country',
                      prefixIcon: Icon(Icons.public),
                    ),
                    validator: (v) =>
                        (v?.trim().isEmpty ?? true) ? 'Enter your country' : null,
                  ),
                ],
                if (_isExporter) ...[
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _registration,
                    decoration: const InputDecoration(
                      labelText: 'Company registration number',
                      prefixIcon: Icon(Icons.badge_outlined),
                    ),
                    validator: (v) => (v?.trim().isEmpty ?? true)
                        ? 'Registration number is required'
                        : null,
                  ),
                ],
                if (_isInvestor || _isExporter) ...[
                  const SizedBox(height: 18),
                  const InfoBanner(
                    icon: Icons.currency_rupee,
                    message:
                        'All transactions on BLOB are conducted in Indian Rupees (INR) only.',
                  ),
                ],
                const SizedBox(height: 26),
                ElevatedButton(
                  onPressed: _saving ? null : _create,
                  child: _saving
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : Text(session.t('create_account')),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
