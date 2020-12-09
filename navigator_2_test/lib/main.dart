import 'package:flutter/material.dart';
import 'gradient_slider.dart';

void main() {
  runApp(BooksApp());
}

class Book {
  final String title;
  final String author;

  Book(this.title, this.author);
}

class BooksApp extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _BooksAppState();
}

class _BooksAppState extends State<BooksApp> {
  BookRouterDelegate _routerDelegate = BookRouterDelegate();
  BookRouteInformationParser _routeInformationParser =
  BookRouteInformationParser();

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Books App',
      routerDelegate: _routerDelegate,
      routeInformationParser: _routeInformationParser,
    );
  }
}

class BookRouteInformationParser extends RouteInformationParser<BookRoutePath> {
  @override
  Future<BookRoutePath> parseRouteInformation(
      RouteInformation routeInformation) async {
    final uri = Uri.parse(routeInformation.location);
    // Handle '/'
    if (uri.pathSegments.length == 0) {
      return BookRoutePath.home();
    }

    // Handle '/book/:id'
    if (uri.pathSegments.length == 2) {
      if (uri.pathSegments[0] != 'book') return BookRoutePath.unknown();
      var remaining = uri.pathSegments[1];
      var id = int.tryParse(remaining);
      if (id == null) return BookRoutePath.unknown();
      return BookRoutePath.details(id);
    }

    // Handle unknown routes
    return BookRoutePath.unknown();
  }

  @override
  RouteInformation restoreRouteInformation(BookRoutePath path) {
    if (path.isUnknown) {
      return RouteInformation(location: '/404');
    }
    if (path.isHomePage) {
      return RouteInformation(location: '/');
    }
    if (path.isDetailsPage) {
      return RouteInformation(location: '/book/${path.id}');
    }
    return null;
  }
}

class BookRouterDelegate extends RouterDelegate<BookRoutePath>
    with ChangeNotifier, PopNavigatorRouterDelegateMixin<BookRoutePath> {
  final GlobalKey<NavigatorState> navigatorKey;

  Book _selectedBook;
  bool show404 = true;
  bool lastScreen = false;
  double anxiety;
  String _selectedReason;

  List<Book> books = [
    Book('Stranger in a Strange Land', 'Robert A. Heinlein'),
    Book('Foundation', 'Isaac Asimov'),
    Book('Fahrenheit 451', 'Ray Bradbury'),
  ];

  BookRouterDelegate() : navigatorKey = GlobalKey<NavigatorState>();

  BookRoutePath get currentConfiguration {
    if (show404) {
      return BookRoutePath.unknown();
    }
    return _selectedBook == null
        ? BookRoutePath.home()
        : BookRoutePath.details(books.indexOf(_selectedBook));
  }

  @override
  Widget build(BuildContext context) {
    return Navigator(
      key: navigatorKey,
      pages: [
        MaterialPage(
          key: ValueKey('BooksListPage'),
          child: BooksListScreen(
            books: books,
            onTapped: _handleReasonTapped,
          ),
        ),
        if (show404)
          MaterialPage(key: ValueKey('UnknownPage'), child: UnknownScreen())
        else if (_selectedReason != null && lastScreen == false)
          AnxietyValuePage(_selectedReason, updateAnxiety, _proceedLastPage)
        else if (lastScreen == true)
            EndDistressDeciderPage(_selectedReason, anxiety)
      ],
      onPopPage: (route, result) {
        if (!route.didPop(result)) {
          return false;
        }

        // Update the list of pages by setting _selectedBook to null
        _selectedReason = null;
        show404 = false;
        notifyListeners();
        return true;
      },
    );
  }

  @override
  Future<void> setNewRoutePath(BookRoutePath path) async {
    if (path.isUnknown) {
      _selectedBook = null;
      show404 = true;
      return;
    }

    if (path.isDetailsPage) {
      if (path.id < 0 || path.id > books.length - 1) {
        show404 = true;
        return;
      }

      _selectedBook = books[path.id];
    } else {
      _selectedBook = null;
    }

    show404 = false;
  }

  void _proceedLastPage() {
    lastScreen = true;
    notifyListeners();
  }

  void _handleReasonTapped(String reason) {
    _selectedReason = reason;
    notifyListeners();
  }

  void updateAnxiety(double value) {
    anxiety = value;
    notifyListeners();
  }
}

class AnxietyValueScreen extends StatefulWidget {
  final String reason;
  final ValueChanged<double> updateAnxiety;
  final Function onTap;
  const AnxietyValueScreen(
      {Key key, this.reason, this.updateAnxiety, this.onTap})
      : super(key: key);
  @override
  _AnxietyValueScreenState createState() =>
      _AnxietyValueScreenState(reason, updateAnxiety, onTap);
}

class _AnxietyValueScreenState extends State<AnxietyValueScreen> {
  final String reason;
  double anxiety = 0;
  final ValueChanged<double> updateAnxiety;
  final Function onTap;
  _AnxietyValueScreenState(this.reason, this.updateAnxiety, this.onTap);
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Container(
          child: Column(children: [
            Padding(
              padding: EdgeInsets.only(bottom: 24),
            ),
            Text("How anxious did you feel?", style: TextStyle(fontSize: 20)),
            Padding(
              padding: EdgeInsets.only(bottom: 24),
            ),
            GradientSlider(anxiety, 0, 10, null, anxiety.round().toString(),
                    (value) => updateAnxiety(value)),
            Padding(
              padding: EdgeInsets.only(bottom: 24),
            ),
            FlatButton(
              child: Text("Press"),
              onPressed: onTap,
            ),
          ])),
    );
  }
}

class AnxietyValuePage extends Page {
  final String endReason;
  final ValueChanged<double> onTapped;
  final Function onTap;
  AnxietyValuePage(this.endReason, this.onTapped, this.onTap);

  @override
  Route createRoute(BuildContext context) {
    return MaterialPageRoute(
        settings: this,
        builder: (BuildContext context) {
          return AnxietyValueScreen(
              reason: endReason, updateAnxiety: onTapped, onTap: onTap);
        });
  }
}

class EndDistressDeciderPage extends Page {
  final double anxiety;
  final String endReason;

  EndDistressDeciderPage(this.endReason, this.anxiety);

  @override
  Route createRoute(BuildContext context) {
    return MaterialPageRoute(
        settings: this,
        builder: (BuildContext context) {
          if (endReason == "End Reason 1" && anxiety <= 4)
            return EndedAnxietyWell();
          else if (endReason == "End Reason 2" && anxiety <= 7)
            return EndedAnxietyAverage();
          else if (endReason == "End Reason 3")
            return EndedAnxietyAverage();
          else
            return SkipReasonWell();
        });
  }
}


class BookRoutePath {
  final int id;
  final bool isUnknown;

  BookRoutePath.home()
      : id = null,
        isUnknown = false;

  BookRoutePath.details(this.id) : isUnknown = false;

  BookRoutePath.unknown()
      : id = null,
        isUnknown = true;

  bool get isHomePage => id == null;

  bool get isDetailsPage => id != null;
}

class BooksListScreen extends StatelessWidget {
  final List<Book> books;
  final ValueChanged<String> onTapped;
  List<String> reasons = [
    "End Reason 1",
    "End Reason 2",
    "End Reason 3",
    "Skip"
  ];

  BooksListScreen({
    @required this.books,
    @required this.onTapped,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: ListView(
        children: [
          ListView.builder(
              primary: false,
              shrinkWrap: true,
              itemCount: reasons.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(reasons[index]),
                  onTap: () => onTapped(reasons[index]),
                );
              }),
        ],
      ),
    );
  }
}

class EndedAnxietyWell extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text("Ended anxiety well")),
    );
  }
}

class EndedAnxietyPoorly extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text("Ended anxiety poorly")),
    );
  }
}

class EndedAnxietyAverage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text("Ended anxiety well")),
    );
  }
}

class SkipReasonWell extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text("Ended anxiety, skipped reason well")),
    );
  }
}

class UnknownScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Center(
        child: Text('404!'),
      ),
    );
  }
}

