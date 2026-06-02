import 'package:flutter/material.dart';
import '../utils/colors.dart';

class CandidateProfilePage extends StatelessWidget {
  final Map<String, dynamic> candidate;

  const CandidateProfilePage({super.key, required this.candidate});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Text(
          "PROFILE DETAILS",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontFamily: 'serif',
            fontSize: 18,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        toolbarHeight: 40,
        titleSpacing: 0,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Header
            Center(
              child: Column(
                children: [
                  Icon(Icons.person, color: Colors.red, size: 100),
                  SizedBox(height: 16),
                  Text(
                    candidate['name'],
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'serif',
                      color: Colors
                          .black, // ← Name is black (not blue → unchanged)
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    candidate['role'],
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600], // ← Grey (unchanged)
                      fontFamily: 'serif',
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 32),

            // Contact Information
            _buildSectionTitle1('Contact Information'),
            _buildInfoCard([
              _buildInfoRow(
                Icons.email,
                'Email',
                '${candidate['name'].toLowerCase().replaceAll(' ', '.')}@email.com',
              ),
              _buildInfoRow(Icons.phone, 'Phone', '+1 (555) 123-4567'),
              _buildInfoRow(Icons.location_on, 'Location', 'New York, NY'),
            ]),

            SizedBox(height: 24),

            // Experience
            _buildSectionTitle1('Experience'),
            _buildInfoCard([
              _buildInfoRow(
                Icons.work,
                'Experience Level',
                'Senior (5+ years)',
              ),
              _buildInfoRow(
                Icons.school,
                'Education',
                'Bachelor\'s in Computer Science',
              ),
              _buildInfoRow(
                Icons.star,
                'Skills',
                'Flutter, Dart, React, Node.js',
              ),
            ]),

            SizedBox(height: 24),

            // Application Status
            _buildSectionTitle1('Application Status'),
            _buildInfoCard([
              _buildInfoRow(
                Icons.calendar_today,
                'Applied Date',
                'March 15, 2024',
              ),
              _buildInfoRow(
                Icons.timeline,
                'Current Stage',
                _getCurrentStage(),
              ),
              _buildInfoRow(Icons.score, 'Rating', '4.5/5.0'),
            ]),

            SizedBox(height: 24),

            // Notes Section
            _buildSectionTitle1('Notes'),
            Card(
              elevation: 2,
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Strong technical background with excellent communication skills. '
                  'Demonstrated leadership experience in previous roles. '
                  'Good cultural fit for the team.',
                  style: TextStyle(
                    fontSize: 16,
                    height: 1.5,
                    fontFamily: 'serif',
                    color: Colors
                        .black, // ← Notes are black/grey (not blue → unchanged)
                  ),
                ),
              ),
            ),

            SizedBox(height: 32),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Interview scheduled for ${candidate['name']}',
                            style: TextStyle(fontFamily: 'serif'),
                          ),
                        ),
                      );
                    },
                    icon: Icon(Icons.calendar_month, color: Colors.white),
                    label: Text(
                      'Schedule Interview',
                      style: TextStyle(
                        fontFamily: 'serif',
                        color: Colors.white,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryText, // 🔴 Red button
                      padding: EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Message sent to ${candidate['name']}',
                            style: TextStyle(fontFamily: 'serif'),
                          ),
                        ),
                      );
                    },
                    icon: Icon(Icons.message, color: AppColors.primaryText),
                    // 🔴 Red icon
                    label: Text(
                      'Send Message',
                      style: TextStyle(
                        fontFamily: 'serif',
                        color: AppColors.primaryText, // 🔴 Red text
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: AppColors.primaryText),
                      // 🔴 Red border
                      padding: EdgeInsets.symmetric(vertical: 12),
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

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: AppColors.primaryText, // 🔴 Was blue[800] → now red
          fontFamily: 'serif',
        ),
      ),
    );
  }

  Widget _buildSectionTitle1(String title) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.black, // 🔴 Was blue[800] → now red
          fontFamily: 'serif',
        ),
      ),
    );
  }

  Widget _buildInfoCard(List<Widget> children) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(children: children),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primaryText, size: 20),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'serif',
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'serif',
                    color:
                        Colors.black, // ← Value is black (was black, not blue)
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getCurrentStage() {
    return candidate['role'].contains('Software')
        ? 'Technical Interview'
        : 'HR Interview';
  }
}
