import 'package:flutter/material.dart';
import 'package:roomify_app/utils/colors.dart'; // Ensure you have these files in your project
import 'package:roomify_app/utils/text_styles.dart'; // Ensure you have these files in your project
import 'package:roomify_app/widgets/pinterest_grid.dart'; // Ensure you have this widget in your project

class FavoritesScreen extends StatefulWidget {
  @override
  _FavoritesScreenState createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _selectedIndex = 0;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        bottom: false,
        child: NestedScrollView(
          headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
            return <Widget>[
              SliverAppBar(
                backgroundColor: Colors.white,
                elevation: 0,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.black),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                ),
                actions: [
                  Container(
                    padding: EdgeInsets.symmetric(vertical: 5, horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      "Clear all",
                      style: TextStyle(
                        color: Colors.orange,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 16,
                  )
                ],
                title: const Text('Marketplace',
                    style: TextStyle(
                        color: Colors.black, fontWeight: FontWeight.bold)),
              ),
            ];
          },
          body: Column(
            children: [
              SizedBox(
                height: 10,
              ),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  height: 40,
                  width: MediaQuery.of(context).size.width * 0.8,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TabBar(
                    dividerHeight: 0,
                    controller: _tabController,
                    indicatorWeight: 0,
                    indicatorPadding: EdgeInsets.all(0),
                    indicator: BoxDecoration(
                      color: orangeColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    indicatorSize: TabBarIndicatorSize.tab,
                    indicatorColor: Colors.transparent, // Removes the thin line
                    labelColor: orangeColor,

                    unselectedLabelColor: Colors.black,
                    labelStyle: TextStyle(fontWeight: FontWeight.w400),
                    tabs: [
                      Tab(text: 'Properties'),
                      Tab(
                        text: 'Marketplace',
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(
                height: 10,
              ),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    PinterestGrid(items: itemsProperties),
                    PinterestGrid(items: itemsMarketplace),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

final List<FeaturedItemCard> itemsProperties = [
  FeaturedItemCard(
    title: "Luxury Villa",
    location: "Malibu, CA",
    price: "\$4,000",
    imagePath:
        'https://encrypted-tbn1.gstatic.com/shopping?q=tbn:ANd9GcT3uDBOCiNU82O0P1tQSwT0BMRUQTJPmHfkGV7XYREHlNlDTZyLpHK7lHP4nz9p59bZU4pjXsYO9TPiTgssBqVeBUwxPplbx949IaprHZM', // Replace with your asset path
  ),
  // Add more properties as needed
];

final List<FeaturedItemCard> itemsMarketplace = [
  FeaturedItemCard(
    title: "Modern Desk",
    location: "Boston, MA",
    price: "\$100",
    imagePath:
        'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcQcjskeT_9yg8wAhnnV_9zpi4U7Jn20bQa40g&s', // Replace with your asset path
  ),
  FeaturedItemCard(
    title: "Luxury Villa",
    location: "Malibu, CA",
    price: "\$4,000",
    imagePath:
        'https://encrypted-tbn1.gstatic.com/shopping?q=tbn:ANd9GcT3uDBOCiNU82O0P1tQSwT0BMRUQTJPmHfkGV7XYREHlNlDTZyLpHK7lHP4nz9p59bZU4pjXsYO9TPiTgssBqVeBUwxPplbx949IaprHZM', // Replace with your asset path
  ),
  FeaturedItemCard(
    title: "Luxury Villa",
    location: "Malibu, CA",
    price: "\$4,000",
    imagePath:
        'https://encrypted-tbn1.gstatic.com/shopping?q=tbn:ANd9GcT3uDBOCiNU82O0P1tQSwT0BMRUQTJPmHfkGV7XYREHlNlDTZyLpHK7lHP4nz9p59bZU4pjXsYO9TPiTgssBqVeBUwxPplbx949IaprHZM', // Replace with your asset path
  ),
  FeaturedItemCard(
    title: "Luxury Villa",
    location: "Malibu, CA",
    price: "\$4,000",
    imagePath:
        'https://encrypted-tbn1.gstatic.com/shopping?q=tbn:ANd9GcT3uDBOCiNU82O0P1tQSwT0BMRUQTJPmHfkGV7XYREHlNlDTZyLpHK7lHP4nz9p59bZU4pjXsYO9TPiTgssBqVeBUwxPplbx949IaprHZM', // Replace with your asset path
  ),
  FeaturedItemCard(
    title: "Luxury Villa",
    location: "Malibu, CA",
    price: "\$4,000",
    imagePath:
        'https://encrypted-tbn1.gstatic.com/shopping?q=tbn:ANd9GcT3uDBOCiNU82O0P1tQSwT0BMRUQTJPmHfkGV7XYREHlNlDTZyLpHK7lHP4nz9p59bZU4pjXsYO9TPiTgssBqVeBUwxPplbx949IaprHZM', // Replace with your asset path
  ),
  FeaturedItemCard(
    title: "Luxury Villa",
    location: "Malibu, CA",
    price: "\$4,000",
    imagePath:
        'https://encrypted-tbn1.gstatic.com/shopping?q=tbn:ANd9GcT3uDBOCiNU82O0P1tQSwT0BMRUQTJPmHfkGV7XYREHlNlDTZyLpHK7lHP4nz9p59bZU4pjXsYO9TPiTgssBqVeBUwxPplbx949IaprHZM', // Replace with your asset path
  ),
  // Add more marketplace items as needed
];
