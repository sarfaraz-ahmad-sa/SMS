import 'package:flutter/material.dart';

import '../Widgets/solid_auth_shell.dart';
import '../theme/app_theme.dart';

class ProcessingRequest extends StatelessWidget {
  const ProcessingRequest({super.key});

  @override
  Widget build(BuildContext context) {
    return SolidAuthShell(
      icon: Icons.mark_email_read_rounded,
      eyebrow: 'Request received',
      title: 'Check your email',
      subtitle: 'Your access request has been processed. The username and temporary password have been sent to your registered email address.',
      showBack: false,
      footer: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Icon(Icons.schedule_rounded, color: AppColors.warning, size: 17),
          SizedBox(width: 7),
          Flexible(child: Text('Also check your spam or junk folder.', textAlign: TextAlign.center, style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary))),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.pastelGreen,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.success.withOpacity(0.22)),
            ),
            child: const Row(
              children: <Widget>[
                Icon(Icons.verified_rounded, color: AppColors.success),
                SizedBox(width: 10),
                Expanded(child: Text('Your school account is ready for first sign in.', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5))),
              ],
            ),
          ),
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: () => Navigator.pushNamedAndRemoveUntil(context, '/login', (Route<dynamic> _) => false),
            icon: const Icon(Icons.login_rounded, size: 18),
            label: const Text('Continue to Sign In'),
          ),
        ],
      ),
    );
  }
}
