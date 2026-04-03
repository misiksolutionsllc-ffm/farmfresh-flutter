import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../theme/app_theme.dart';

// ============================================
// WELCOME ONBOARDING (3 slides)
// ============================================
class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});
  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  int _page = 0;
  final _controller = PageController();

  static const _slides = [
    {'emoji': '🥬', 'title': 'Welcome to FarmFresh Hub', 'sub': 'Farm-to-table, reimagined', 'desc': 'Connect directly with local farmers who grow clean, natural food — no GMOs, no synthetic pesticides, no artificial anything.'},
    {'emoji': '🚗', 'title': 'Fresh to Your Door', 'sub': 'Fast local delivery', 'desc': 'Our community drivers deliver straight from the farm to your table. Track your order in real-time with GPS.'},
    {'emoji': '🌾', 'title': 'Support Local Heroes', 'sub': 'Empower American farmers', 'desc': 'Every purchase supports independent Farmer American Heroes in your community. Know exactly where your food comes from.'},
  ];

  @override
  Widget build(BuildContext context) {
    final app = context.read<AppProvider>();
    return Scaffold(
      backgroundColor: AppColors.surface950,
      body: SafeArea(
        child: Column(children: [
          // Skip
          Align(alignment: Alignment.topRight, child: Padding(
            padding: const EdgeInsets.all(16),
            child: TextButton(
              onPressed: () => app.completeOnboarding(),
              child: Text('Skip', style: TextStyle(color: AppColors.textMuted)),
            ),
          )),

          // Pages
          Expanded(child: PageView.builder(
            controller: _controller,
            itemCount: _slides.length,
            onPageChanged: (i) => setState(() => _page = i),
            itemBuilder: (_, i) {
              final s = _slides[i];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Text(s['emoji']!, style: const TextStyle(fontSize: 96)),
                  const SizedBox(height: 32),
                  Text(s['title']!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  Text(s['sub']!, style: TextStyle(color: AppColors.emerald, fontSize: 15, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 16),
                  Text(s['desc']!, textAlign: TextAlign.center, style: TextStyle(color: AppColors.textMuted, fontSize: 14, height: 1.5)),
                ]),
              );
            },
          )),

          // Dots
          Row(mainAxisAlignment: MainAxisAlignment.center, children: List.generate(3, (i) =>
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: i == _page ? 28 : 8, height: 8,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                color: i == _page ? AppColors.emerald : Colors.white.withOpacity(0.1),
              ),
            ),
          )),
          const SizedBox(height: 24),

          // Button
          Padding(padding: const EdgeInsets.symmetric(horizontal: 24), child:
            SizedBox(width: double.infinity, height: 56, child: ElevatedButton(
              onPressed: () {
                if (_page < _slides.length - 1) {
                  _controller.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
                } else {
                  app.completeOnboarding();
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.emerald,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Text(_page < _slides.length - 1 ? 'Next' : 'Get Started', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                const SizedBox(width: 8),
                Icon(_page < _slides.length - 1 ? Icons.chevron_right : Icons.arrow_forward, size: 20),
              ]),
            )),
          ),
          const SizedBox(height: 12),
          if (_page > 0)
            TextButton(
              onPressed: () => _controller.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.easeOut),
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(Icons.chevron_left, size: 16, color: AppColors.textMuted),
                Text('Back', style: TextStyle(color: AppColors.textMuted)),
              ]),
            ),
          const SizedBox(height: 16),
          Text('MISIKSOLUTIONS LLC • Wellington, Florida', style: TextStyle(color: Colors.white.withOpacity(0.15), fontSize: 10)),
          const SizedBox(height: 16),
        ]),
      ),
    );
  }
}

// ============================================
// AUTH SCREEN (Email + OAuth)
// ============================================
class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});
  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool _isLogin = false;
  final _nameCtl = TextEditingController();
  final _emailCtl = TextEditingController();
  final _pwCtl = TextEditingController();
  bool _showPw = false;
  bool _agreed = false;
  bool _loading = false;

  bool get _valid => _isLogin
    ? _emailCtl.text.contains('@') && _pwCtl.text.length >= 6
    : _nameCtl.text.length >= 2 && _emailCtl.text.contains('@') && _pwCtl.text.length >= 8 && _agreed;

  void _submit() {
    if (!_valid) return;
    setState(() => _loading = true);
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (!mounted) return;
      context.read<AppProvider>().signIn(_emailCtl.text, 'email');
      setState(() => _loading = false);
    });
  }

  void _oauth(String provider) {
    setState(() => _loading = true);
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (!mounted) return;
      final email = provider == 'google' ? 'user@gmail.com' : 'user@icloud.com';
      context.read<AppProvider>().signIn(email, provider);
      context.read<AppProvider>().showToast('Signed in with ${provider == 'google' ? 'Google' : 'Apple'}!');
      setState(() => _loading = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface950,
      body: Center(child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          // Logo
          Container(
            width: 64, height: 64,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              color: AppColors.emerald.withOpacity(0.1),
              border: Border.all(color: AppColors.emerald.withOpacity(0.2)),
            ),
            child: const Center(child: Text('🥬', style: TextStyle(fontSize: 32))),
          ),
          const SizedBox(height: 20),
          Text(_isLogin ? 'Welcome Back' : 'Create Account',
            style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text(_isLogin ? 'Sign in to your FarmFresh Hub account' : 'Join the farm-to-table revolution',
            style: TextStyle(color: AppColors.textMuted, fontSize: 14)),
          const SizedBox(height: 28),

          // OAuth
          _OAuthButton(label: 'Continue with Google', icon: Icons.g_mobiledata, onTap: () => _oauth('google'), loading: _loading),
          const SizedBox(height: 10),
          _OAuthButton(label: 'Continue with Apple', icon: Icons.apple, onTap: () => _oauth('apple'), loading: _loading),
          const SizedBox(height: 20),

          // Divider
          Row(children: [
            Expanded(child: Divider(color: Colors.white.withOpacity(0.06))),
            Padding(padding: const EdgeInsets.symmetric(horizontal: 12), child: Text('or', style: TextStyle(color: AppColors.textMuted, fontSize: 12))),
            Expanded(child: Divider(color: Colors.white.withOpacity(0.06))),
          ]),
          const SizedBox(height: 20),

          // Form
          if (!_isLogin) ...[
            _InputField(ctl: _nameCtl, hint: 'Full name', icon: Icons.person_outline, onChanged: (_) => setState(() {})),
            const SizedBox(height: 12),
          ],
          _InputField(ctl: _emailCtl, hint: 'Email address', icon: Icons.email_outlined, keyboard: TextInputType.emailAddress, onChanged: (_) => setState(() {})),
          const SizedBox(height: 12),
          _InputField(
            ctl: _pwCtl,
            hint: _isLogin ? 'Password' : 'Password (min 8 characters)',
            icon: Icons.lock_outline,
            obscure: !_showPw,
            suffix: IconButton(
              icon: Icon(_showPw ? Icons.visibility_off : Icons.visibility, color: AppColors.textMuted, size: 18),
              onPressed: () => setState(() => _showPw = !_showPw),
            ),
            onChanged: (_) => setState(() {}),
          ),
          if (!_isLogin) ...[
            const SizedBox(height: 14),
            GestureDetector(
              onTap: () => setState(() => _agreed = !_agreed),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Container(
                  width: 22, height: 22, margin: const EdgeInsets.only(top: 1),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(6),
                    color: _agreed ? AppColors.emerald : Colors.transparent,
                    border: Border.all(color: _agreed ? AppColors.emerald : Colors.white.withOpacity(0.1), width: 2),
                  ),
                  child: _agreed ? const Icon(Icons.check, color: Colors.white, size: 14) : null,
                ),
                const SizedBox(width: 10),
                Expanded(child: Text.rich(TextSpan(children: [
                  TextSpan(text: 'I agree to the ', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                  TextSpan(text: 'Terms of Service', style: TextStyle(color: AppColors.emerald, fontSize: 12)),
                  TextSpan(text: ', ', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                  TextSpan(text: 'Privacy Policy', style: TextStyle(color: AppColors.emerald, fontSize: 12)),
                  TextSpan(text: ', and ', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                  TextSpan(text: 'Natural Food Standards', style: TextStyle(color: AppColors.emerald, fontSize: 12)),
                ]))),
              ]),
            ),
          ],
          const SizedBox(height: 24),

          // Submit
          SizedBox(width: double.infinity, height: 56, child: ElevatedButton(
            onPressed: _valid && !_loading ? _submit : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.emerald,
              disabledBackgroundColor: AppColors.emerald.withOpacity(0.2),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
            child: _loading
              ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
              : Text(_isLogin ? 'Sign In' : 'Create Account', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          )),
          const SizedBox(height: 20),

          // Toggle
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Text(_isLogin ? "Don't have an account? " : 'Already have an account? ', style: TextStyle(color: AppColors.textMuted, fontSize: 14)),
            GestureDetector(
              onTap: () => setState(() => _isLogin = !_isLogin),
              child: Text(_isLogin ? 'Sign Up' : 'Sign In', style: TextStyle(color: AppColors.emerald, fontWeight: FontWeight.w700, fontSize: 14)),
            ),
          ]),
          const SizedBox(height: 32),
          Text('MISIKSOLUTIONS LLC • Wellington, Florida', style: TextStyle(color: Colors.white.withOpacity(0.15), fontSize: 10)),
        ]),
      )),
    );
  }
}

class _OAuthButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool loading;
  const _OAuthButton({required this.label, required this.icon, required this.onTap, required this.loading});
  @override
  Widget build(BuildContext context) {
    return SizedBox(width: double.infinity, height: 52, child: OutlinedButton.icon(
      onPressed: loading ? null : onTap,
      icon: Icon(icon, color: Colors.white, size: 22),
      label: Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: Colors.white.withOpacity(0.08)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Colors.white.withOpacity(0.03),
      ),
    ));
  }
}

class _InputField extends StatelessWidget {
  final TextEditingController ctl;
  final String hint;
  final IconData icon;
  final bool obscure;
  final Widget? suffix;
  final TextInputType? keyboard;
  final ValueChanged<String>? onChanged;
  const _InputField({required this.ctl, required this.hint, required this.icon, this.obscure = false, this.suffix, this.keyboard, this.onChanged});
  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: ctl, obscureText: obscure, keyboardType: keyboard, onChanged: onChanged,
      style: const TextStyle(color: Colors.white, fontSize: 15),
      decoration: InputDecoration(
        hintText: hint, hintStyle: TextStyle(color: AppColors.textMuted.withOpacity(0.5)),
        prefixIcon: Icon(icon, color: AppColors.textMuted, size: 20),
        suffixIcon: suffix,
        filled: true, fillColor: Colors.white.withOpacity(0.03),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide(color: Colors.white.withOpacity(0.08))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide(color: Colors.white.withOpacity(0.08))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide(color: AppColors.emerald.withOpacity(0.3))),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }
}
