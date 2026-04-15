import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../theme/app_theme.dart';

// ============================================
// WELCOME ONBOARDING SCREEN
// ============================================
class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});
  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  final _controller = PageController();
  int _page = 0;

  static const _slides = [
    {'emoji': '🥬', 'title': 'Welcome to EdemFarm', 'subtitle': 'Farm-to-table, reimagined', 'desc': 'Connect directly with local farmers who grow clean, natural food — no GMOs, no synthetic pesticides, no artificial anything.'},
    {'emoji': '🚗', 'title': 'Fresh to Your Door', 'subtitle': 'Fast local delivery', 'desc': 'Our community drivers deliver straight from the farm to your table. Track your order in real-time with GPS.'},
    {'emoji': '🌾', 'title': 'Support Local Heroes', 'subtitle': 'Empower American farmers', 'desc': 'Every purchase supports independent Farmer American Heroes in your community. Know exactly where your food comes from.'},
  ];

  @override
  Widget build(BuildContext context) {
    final app = context.read<AppProvider>();
    return Scaffold(
      backgroundColor: AppColors.surface950,
      body: SafeArea(
        child: Column(children: [
          // Skip
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => app.completeOnboarding(),
              child: const Text('Skip', style: TextStyle(color: AppColors.textMuted, fontSize: 14)),
            ),
          ),
          // Pages
          Expanded(
            child: PageView.builder(
              controller: _controller,
              onPageChanged: (i) => setState(() => _page = i),
              itemCount: _slides.length,
              itemBuilder: (_, i) {
                final s = _slides[i];
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Text(s['emoji']!, style: const TextStyle(fontSize: 100)),
                    const SizedBox(height: 32),
                    Text(s['title']!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 8),
                    Text(s['subtitle']!, textAlign: TextAlign.center, style: TextStyle(color: AppColors.emerald, fontSize: 14, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 16),
                    Text(s['desc']!, textAlign: TextAlign.center, style: TextStyle(color: AppColors.textMuted, fontSize: 14, height: 1.6)),
                  ]),
                );
              },
            ),
          ),
          // Dots
          Row(mainAxisAlignment: MainAxisAlignment.center, children: List.generate(3, (i) =>
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: _page == i ? 32 : 8,
              height: 8,
              decoration: BoxDecoration(
                color: _page == i ? AppColors.emerald : Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          )),
          const SizedBox(height: 24),
          // Button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () {
                  if (_page < _slides.length - 1) {
                    _controller.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
                  } else {
                    app.completeOnboarding();
                  }
                },
                child: Text(_page < _slides.length - 1 ? 'Next' : 'Get Started', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text('MISIKSOLUTIONS LLC • Wellington, Florida', style: TextStyle(color: Colors.white.withOpacity(0.15), fontSize: 10)),
          const SizedBox(height: 16),
        ]),
      ),
    );
  }
}

// ============================================
// AUTH SCREEN
// ============================================
class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});
  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool _isLogin = false;
  bool _showPw = false;
  bool _agreed = false;
  bool _loading = false;
  final _nameCtl = TextEditingController();
  final _emailCtl = TextEditingController();
  final _pwCtl = TextEditingController();

  bool get _valid => _isLogin
      ? _emailCtl.text.contains('@') && _pwCtl.text.length >= 6
      : _nameCtl.text.length >= 2 && _emailCtl.text.contains('@') && _pwCtl.text.length >= 8 && _agreed;

  void _submit() {
    if (!_valid || _loading) return;
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
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              // Logo
              Container(
                width: 64, height: 64,
                decoration: BoxDecoration(color: AppColors.emerald.withOpacity(0.1), borderRadius: BorderRadius.circular(18), border: Border.all(color: AppColors.emerald.withOpacity(0.2))),
                child: const Center(child: Text('🥬', style: TextStyle(fontSize: 32))),
              ),
              const SizedBox(height: 16),
              Text(_isLogin ? 'Welcome Back' : 'Create Account', style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Text(_isLogin ? 'Sign in to your EdemFarm account' : 'Join the farm-to-table revolution', style: TextStyle(color: AppColors.textMuted, fontSize: 14)),
              const SizedBox(height: 28),

              // OAuth
              _OAuthButton(label: 'Continue with Google', icon: Icons.g_mobiledata, onTap: () => _oauth('google'), loading: _loading),
              const SizedBox(height: 10),
              _OAuthButton(label: 'Continue with Apple', icon: Icons.apple, onTap: () => _oauth('apple'), loading: _loading),
              const SizedBox(height: 20),

              // Divider
              Row(children: [
                Expanded(child: Divider(color: Colors.white.withOpacity(0.06))),
                Padding(padding: const EdgeInsets.symmetric(horizontal: 12), child: Text('or', style: TextStyle(color: Colors.white.withOpacity(0.15), fontSize: 12))),
                Expanded(child: Divider(color: Colors.white.withOpacity(0.06))),
              ]),
              const SizedBox(height: 20),

              // Form
              if (!_isLogin) ...[
                _AuthField(controller: _nameCtl, hint: 'Full name', icon: Icons.person_outline),
                const SizedBox(height: 10),
              ],
              _AuthField(controller: _emailCtl, hint: 'Email address', icon: Icons.email_outlined, type: TextInputType.emailAddress),
              const SizedBox(height: 10),
              _AuthField(
                controller: _pwCtl,
                hint: _isLogin ? 'Password' : 'Password (min 8 characters)',
                icon: Icons.lock_outline,
                obscure: !_showPw,
                suffix: IconButton(icon: Icon(_showPw ? Icons.visibility_off : Icons.visibility, color: AppColors.textMuted, size: 18), onPressed: () => setState(() => _showPw = !_showPw)),
              ),
              if (!_isLogin) ...[
                const SizedBox(height: 14),
                GestureDetector(
                  onTap: () => setState(() => _agreed = !_agreed),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 20, height: 20,
                      decoration: BoxDecoration(
                        color: _agreed ? AppColors.emerald : Colors.transparent,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: _agreed ? AppColors.emerald : Colors.white.withOpacity(0.1), width: 2),
                      ),
                      child: _agreed ? const Icon(Icons.check, size: 14, color: Colors.white) : null,
                    ),
                    const SizedBox(width: 10),
                    Expanded(child: Text.rich(TextSpan(style: TextStyle(color: AppColors.textMuted, fontSize: 12, height: 1.5), children: [
                      const TextSpan(text: 'I agree to the '),
                      TextSpan(text: 'Terms of Service', style: TextStyle(color: AppColors.emerald)),
                      const TextSpan(text: ', '),
                      TextSpan(text: 'Privacy Policy', style: TextStyle(color: AppColors.emerald)),
                      const TextSpan(text: ', and '),
                      TextSpan(text: 'Natural Food Standards', style: TextStyle(color: AppColors.emerald)),
                    ]))),
                  ]),
                ),
              ],
              const SizedBox(height: 20),

              // Submit
              SizedBox(
                width: double.infinity, height: 56,
                child: ElevatedButton(
                  onPressed: _valid && !_loading ? _submit : null,
                  child: _loading
                      ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                      : Text(_isLogin ? 'Sign In' : 'Create Account', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(height: 20),

              // Toggle
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Text(_isLogin ? "Don't have an account? " : 'Already have an account? ', style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
                GestureDetector(
                  onTap: () => setState(() => _isLogin = !_isLogin),
                  child: Text(_isLogin ? 'Sign Up' : 'Sign In', style: TextStyle(color: AppColors.emerald, fontSize: 13, fontWeight: FontWeight.w700)),
                ),
              ]),
            ]),
          ),
        ),
      ),
    );
  }
}

class _OAuthButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool loading;
  const _OAuthButton({required this.label, required this.icon, required this.onTap, this.loading = false});
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity, height: 52,
      child: OutlinedButton.icon(
        onPressed: loading ? null : onTap,
        icon: Icon(icon, size: 22),
        label: Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.white,
          side: BorderSide(color: Colors.white.withOpacity(0.08)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
    );
  }
}

class _AuthField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final bool obscure;
  final Widget? suffix;
  final TextInputType? type;
  const _AuthField({required this.controller, required this.hint, required this.icon, this.obscure = false, this.suffix, this.type});
  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller, obscureText: obscure, keyboardType: type,
      style: const TextStyle(color: Colors.white, fontSize: 14),
      decoration: InputDecoration(
        hintText: hint, hintStyle: TextStyle(color: Colors.white.withOpacity(0.2)),
        prefixIcon: Icon(icon, color: AppColors.textMuted, size: 18),
        suffixIcon: suffix,
        filled: true, fillColor: Colors.white.withOpacity(0.03),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.white.withOpacity(0.08))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Colors.white.withOpacity(0.08))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: AppColors.emerald.withOpacity(0.3))),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }
}
