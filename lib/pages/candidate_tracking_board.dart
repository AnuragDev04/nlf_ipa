import 'package:flutter/material.dart';

import 'candidate_profile_page.dart';

class CandidateTrackingBoard extends StatefulWidget {
  const CandidateTrackingBoard({super.key});

  @override
  _CandidateTrackingBoardState createState() => _CandidateTrackingBoardState();
}

class _CandidateTrackingBoardState extends State<CandidateTrackingBoard> {
  int _currentIndex = 0; // 0: Screening, 1: Interview, 2: Hired

  // Sample data for candidates
  final List<Map<String, dynamic>> screeningCandidates = [
    {
      'name': 'Ethan Carter',
      'role': 'Software Engineer',
      'image': 'https://via.placeholder.com/60?text=EC',
    },
    {
      'name': 'Sophia Lee',
      'role': 'Product Manager',
      'image': 'https://via.placeholder.com/60?text=SL',
    },
    {
      'name': 'Noah Williams',
      'role': 'Data Analyst',
      'image': 'https://via.placeholder.com/60?text=NW',
    },
  ];

  final List<Map<String, dynamic>> interviewCandidates = [
    {
      'name': 'Emma Johnson',
      'role': 'UX Designer',
      'image': 'https://via.placeholder.com/60?text=EJ',
    },
    {
      'name': 'Liam Chen',
      'role': 'DevOps Engineer',
      'image': 'https://via.placeholder.com/60?text=LC',
    },
  ];

  final List<Map<String, dynamic>> hiredCandidates = [
    {
      'name': 'Olivia Smith',
      'role': 'Frontend Developer',
      'image': 'https://via.placeholder.com/60?text=OS',
    },
  ];

  List<Map<String, dynamic>> getCandidatesForTab(int index) {
    switch (index) {
      case 0:
        return screeningCandidates;
      case 1:
        return interviewCandidates;
      case 2:
        return hiredCandidates;
      default:
        return screeningCandidates;
    }
  }

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
          "CANDIDATE TRACKING",
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
      body: Column(
        children: [
          // Tabs for different stages
          Container(
            color: Colors.white,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _currentIndex = 0;
                    });
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 16.0,
                      horizontal: 8.0,
                    ),
                    child: Text(
                      'Screening',
                      style: TextStyle(
                        fontWeight: _currentIndex == 0
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color: _currentIndex == 0 ? Colors.black : Colors.grey,
                        fontFamily: 'serif',
                      ),
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _currentIndex = 1;
                    });
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 16.0,
                      horizontal: 8.0,
                    ),
                    child: Text(
                      'Interview',
                      style: TextStyle(
                        fontWeight: _currentIndex == 1
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color: _currentIndex == 1 ? Colors.black : Colors.grey,
                        fontFamily: 'serif',
                      ),
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _currentIndex = 2;
                    });
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 16.0,
                      horizontal: 8.0,
                    ),
                    child: Text(
                      'Hired',
                      style: TextStyle(
                        fontWeight: _currentIndex == 2
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color: _currentIndex == 2 ? Colors.black : Colors.grey,
                        fontFamily: 'serif',
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Divider between tabs and content
          Container(height: 1, color: Colors.grey[300]),

          // ListView for candidates
          Expanded(
            child: ListView.builder(
              itemCount: getCandidatesForTab(_currentIndex).length,
              itemBuilder: (context, index) {
                final candidate = getCandidatesForTab(_currentIndex)[index];
                return Card(
                  margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                      12.0,
                    ), // 👈 Set your desired radius here
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.red[50],
                      child: Icon(Icons.person, size: 36, color: Colors.red),
                    ),
                    title: Text(
                      candidate['name'],
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontFamily: 'serif', // 👈 serif font
                      ),
                    ),
                    subtitle: Text(
                      candidate['role'],
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontFamily: 'serif', // 👈 serif font
                      ),
                    ),
                    trailing: Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: Colors.grey,
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              CandidateProfilePage(candidate: candidate),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
