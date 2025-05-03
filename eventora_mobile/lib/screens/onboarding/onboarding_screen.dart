import 'package:flutter/material.dart';
import 'package:introduction_screen/introduction_screen.dart';
import 'package:eventora_app/screens/auth/login_screen.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return IntroductionScreen(
      pages: [
        // Page 1: Discover Vendors
        PageViewModel(
          title: "Discover Perfect Vendors",
          body: "Find the ideal vendors for your special event with our curated listings and detailed profiles.",
          image: _buildImage('assets/images/onboarding_vendors.png'),
          decoration: _getPageDecoration(),
        ),
        
        // Page 2: Easy Booking
        PageViewModel(
          title: "Easy Event Booking",
          body: "Book vendors, schedule appointments, and manage all your event details in one place.",
          image: _buildImage('assets/images/onboarding_booking.png'),
          decoration: _getPageDecoration(),
        ),
        
        // Page 3: Chat with Vendors
        PageViewModel(
          title: "Chat with Vendors",
          body: "Communicate directly with vendors to discuss details, ask questions, and finalize arrangements.",
          image: _buildImage('assets/images/onboarding_chat.png'),
          decoration: _getPageDecoration(),
        ),
        
        // Page 4: Event Management
        PageViewModel(
          title: "Complete Event Management",
          body: "From planning to execution, manage every aspect of your event with our intuitive mobile app.",
          image: _buildImage('assets/images/onboarding_management.png'),
          decoration: _getPageDecoration(),
        ),
      ],
      
      onDone: () => _onIntroEnd(context),
      onSkip: () => _onIntroEnd(context),
      showSkipButton: true,
      skipOrBackFlex: 0,
      nextFlex: 0,
      skip: const Text('Skip'),
      next: const Icon(Icons.arrow_forward),
      done: const Text('Get Started', style: TextStyle(fontWeight: FontWeight.w600)),
      curve: Curves.fastLinearToSlowEaseIn,
      controlsMargin: const EdgeInsets.all(16),
      controlsPadding: const EdgeInsets.fromLTRB(8.0, 4.0, 8.0, 4.0),
      dotsDecorator: const DotsDecorator(
        size: Size(10.0, 10.0),
        color: Color(0xFFBDBDBD),
        activeSize: Size(22.0, 10.0),
        activeShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(25.0)),
        ),
        activeColor: Color(0xFF6366F1),
      ),
      dotsContainerDecorator: const ShapeDecoration(
        color: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(8.0)),
        ),
      ),
    );
  }

  Widget _buildImage(String assetName) {
    return Padding(
      padding: const EdgeInsets.only(top: 60.0),
      child: Image.asset(
        assetName,
        width: 300,
        height: 300,
        fit: BoxFit.contain,
      ),
    );
  }

  PageDecoration _getPageDecoration() {
    return const PageDecoration(
      titleTextStyle: TextStyle(fontSize: 28.0, fontWeight: FontWeight.bold),
      bodyTextStyle: TextStyle(fontSize: 16.0, color: Colors.black54),
      pageColor: Colors.white,
      imagePadding: EdgeInsets.zero,
      titlePadding: EdgeInsets.only(top: 30.0, bottom: 16.0),
      bodyPadding: EdgeInsets.fromLTRB(16.0, 0.0, 16.0, 16.0),
    );
  }

  void _onIntroEnd(BuildContext context) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }
}