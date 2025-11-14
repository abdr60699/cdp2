import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';

class ContactUsPage extends StatelessWidget {
  const ContactUsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 800;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Hero Section
          // FadeIn(
          //   child: Container(
          //     height: 250,
          //     width: double.infinity,
          //     decoration: const BoxDecoration(
          //       color: Color.fromARGB(255, 255, 214, 184),
          //       image: DecorationImage(
          //         image: NetworkImage(
          //           'https://raw.githubusercontent.com/abdr60699/CPD/master/orange.png',
          //         ),
          //         fit: BoxFit.contain,
          //       ),
          //     ),
          //     child: Container(
          //       decoration: const BoxDecoration(),
          //       child: const Center(
          //         child: Column(
          //           mainAxisAlignment: MainAxisAlignment.center,
          //           children: [],
          //         ),
          //       ),
          //     ),
          //   ),
          // ),
        FadeIn(
  child: Container(
    height: 250,
    width: double.infinity,
    color: const Color.fromARGB(255, 255, 214, 184),
    child: Center(
      child: Image.network(
        'https://raw.githubusercontent.com/abdr60699/CPD/master/orange.png',
        fit: BoxFit.contain,
        loadingBuilder: (BuildContext context, Widget child, ImageChunkEvent? loadingProgress) {
          if (loadingProgress == null) {
            return child; // Image loaded
          }
          return Center(
            child: CircularProgressIndicator(
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded /
                      (loadingProgress.expectedTotalBytes ?? 1)
                  : null,
              color: Colors.orange,
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          return const Icon(Icons.error, color: Colors.red, size: 50);
        },
      ),
    ),
  ),
),


          // Contact Information and Form
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: isMobile
                ? Column(
                    children: [
                      _buildContactCard(context),
                      const SizedBox(height: 20),
                      // _buildFormCard(context),
                    ],
                  )
                : Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 2, child: _buildContactCard(context)),
                      const SizedBox(width: 20),
                      // Expanded(flex: 3, child: _buildFormCard(context)),
                    ],
                  ),
          ),

          // Footer
          Container(
            padding: const EdgeInsets.symmetric(vertical: 20),
            color: const Color(0xFF333333),
            child: Center(
              child: Text(
                '© ${DateTime.now().year} Check Dream Property.',
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactCard(BuildContext context) {
    return FadeInLeft(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Contact Information',
              style: GoogleFonts.playfairDisplay(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF333333),
              ),
            ),
            const SizedBox(height: 10),
            Container(
              width: 50,
              height: 3,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 25),
            // _buildContactInfo(context, Icons.location_on, 'Office Address',
            //     '123 Anna Salai, Chennai,\nTamil Nadu - 600002'),
            // const SizedBox(height: 20),
            _buildContactInfo(
                context, Icons.phone, 'Phone Number', '+91 7401399181'),
            const SizedBox(height: 20),
            _buildContactInfo(context, Icons.email, 'Email Address',
                'checkdreamproperties@gmail.com'),
          ],
        ),
      ),
    );
  }

  Widget _buildFormCard(BuildContext context) {
    return FadeInRight(
      child: Card(
        elevation: 5,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Send a Message',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF333333),
                ),
              ),
              const SizedBox(height: 10),
              Container(
                width: 50,
                height: 3,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 25),
              Wrap(
                spacing: 15,
                runSpacing: 15,
                children: [
                  SizedBox(
                    width: 300,
                    child: _buildInputField('Full Name', Icons.person),
                  ),
                  SizedBox(
                    width: 300,
                    child: _buildInputField('Email Address', Icons.email),
                  ),
                  SizedBox(
                    width: 300,
                    child: _buildInputField('Phone Number', Icons.phone),
                  ),
                  SizedBox(
                    width: 300,
                    child: _buildInputField('Subject', Icons.subject),
                  ),
                ],
              ),
              const SizedBox(height: 15),
              TextField(
                maxLines: 5,
                decoration: InputDecoration(
                  labelText: 'Your Message',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                            'Message sent successfully! We\'ll get back to you soon.'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    'SEND MESSAGE',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContactInfo(
      BuildContext context, IconData icon, String title, String content) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          backgroundColor:
              Theme.of(context).colorScheme.primary.withOpacity(0.1),
          radius: 25,
          child: Icon(icon,
              color: Theme.of(context).colorScheme.primary, size: 24),
        ),
        const SizedBox(width: 15),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 5),
              SelectableText(content,
                  style: TextStyle(
                      fontSize: 12, color: Colors.grey.shade700, height: 1.5)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInputField(String label, IconData icon) {
    return TextField(
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        prefixIcon: Icon(icon),
      ),
    );
  }
}
