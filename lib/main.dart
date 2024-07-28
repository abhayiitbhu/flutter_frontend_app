import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter GitHub App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  TextEditingController _usernameController = TextEditingController();
  List<dynamic> _repos = [];
  int _page = 1; // Initial page number
  bool _isLoading = false;
  String _loadingRepo = '';

  Future<void> _fetchGitHubRepos(String username, int page) async {
    setState(() {
      _isLoading = true;
    });

    try {
      var response = await http.get(Uri.parse(
          'http://127.0.0.1:8000/github-repos/$username?page=$page&per_page=10'));

      if (response.statusCode == 200) {
        var repos = jsonDecode(response.body);
        setState(() {
          _repos = repos;
          _isLoading = false;
        });
      } else {
        throw Exception('Failed to load repositories');
      }
    } catch (e) {
      print('Error: $e');
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Error'),
          content: Text(
              'Failed to load repositories. Please check your username and try again.'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _repos = [];
              },
              child: Text('OK'),
            ),
          ],
        ),
      );
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<Map<String, dynamic>> _fetchLastCommit(
      String username, String repo) async {
    try {
      var response = await http.get(
          Uri.parse('http://127.0.0.1:8000/github-commits/$username/$repo'));

      if (response.statusCode == 200) {
        var commitDetails = jsonDecode(response.body);
        return commitDetails;
      } else {
        throw Exception('Failed to load last commit');
      }
    } catch (e) {
      print('Error: $e');
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Error'),
          content: Text('Failed to load last commit details.'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('OK'),
            ),
          ],
        ),
      );
      return {};
    }
  }

  Future<void> _loadNextPage(String username) async {
    setState(() {
      _page++;
    });
    await _fetchGitHubRepos(username, _page);
  }

  Future<void> _loadPreviousPage(String username) async {
    if (_page > 1) {
      setState(() {
        _page--;
      });
      await _fetchGitHubRepos(username, _page);
    }
  }

  Future<void> _handleRepoTap(String username, String repoName) async {
    setState(() {
      _loadingRepo = repoName;
    });

    var commitDetails = await _fetchLastCommit(username, repoName);

    setState(() {
      _loadingRepo = '';
    });

    if (commitDetails.isNotEmpty) {
      // Show commit details in a dialog or navigate to a new screen
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Last Commit Details'),
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text('Repository: $repoName'),
              SizedBox(height: 10),
              Text('Author: ${commitDetails["last_commit_author"]}'),
              SizedBox(height: 5),
              Text('Message: ${commitDetails["last_commit_message"]}'),
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Flutter GitHub App'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            TextField(
              controller: _usernameController,
              decoration: InputDecoration(
                labelText: 'Enter GitHub username',
              ),
            ),
            SizedBox(height: 10.0),
            ElevatedButton(
              onPressed: () {
                _page = 1;
                if (_usernameController.text.isNotEmpty) {
                  _fetchGitHubRepos(_usernameController.text, _page);
                }
              },
              child: Text('Fetch Repositories'),
            ),
            SizedBox(height: 20.0),
            Text('Repositories:'),
            Expanded(
              child: ListView.builder(
                itemCount: _repos.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text(_repos[index]['name']),
                    trailing: _loadingRepo == _repos[index]['name']
                        ? CircularProgressIndicator()
                        : null,
                    onTap: () {
                      if (_loadingRepo.isEmpty) {
                        _handleRepoTap(
                            _usernameController.text, _repos[index]['name']);
                      }
                    },
                  );
                },
              ),
            ),
            if (_isLoading) CircularProgressIndicator(),
            SizedBox(height: 20.0),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                ElevatedButton(
                  onPressed: () {
                    _loadPreviousPage(_usernameController.text);
                  },
                  child: Text('Previous'),
                ),
                SizedBox(width: 10.0),
                ElevatedButton(
                  onPressed: () {
                    _loadNextPage(_usernameController.text);
                  },
                  child: Text('Next'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
