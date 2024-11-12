import 'package:flutter/material.dart';
import 'package:roomify_app/widgets/pinterest_grid.dart';

class MarketplaceScreen extends StatelessWidget {
  const MarketplaceScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.menu, color: Colors.black),
          onPressed: () {},
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none, color: Colors.black),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.favorite_outline, color: Colors.black),
            onPressed: () {},
          ),
        ],
        title: const Text('Marketplace',
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        child: Padding(
            padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                decoration: InputDecoration(
                  hintText: "Search for furniture, books...",
                  prefixIcon: const Icon(Icons.search, color: Colors.grey),
                  filled: true,
                  fillColor: Colors.grey.shade200,
                  contentPadding: const EdgeInsets.symmetric(vertical: 20),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text("Categories",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              const Text("browse specific types of items",
                  style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 25),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: const [
                    SizedBox(
                      width: 10,
                    ),
                    CategoryIcon(
                      title: "Electronics",
                      icon: Icons.weekend,
                      imagePath: "assets/icons/electronics.png",
                    ),
                    SizedBox(
                      width: 20,
                    ),
                    CategoryIcon(
                      title: "Furniture",
                      icon: Icons.checkroom,
                      imagePath: "assets/icons/furniture.png",
                    ),
                    SizedBox(
                      width: 20,
                    ),
                    CategoryIcon(
                      title: "Clothing",
                      icon: Icons.kitchen,
                      imagePath: "assets/icons/clothing.png",
                    ),
                    SizedBox(
                      width: 20,
                    ),
                    CategoryIcon(
                      title: "Books",
                      icon: Icons.computer,
                      imagePath: "assets/icons/books.png",
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 25),
              const Text("Featured Items",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              const SizedBox(height: 15),
              PinterestGrid(items: items)
            ],
          ),
        ),
      ),
    );
  }
}

final List<FeaturedItemCard> items = [
  FeaturedItemCard(
    title: "Modern Desk",
    location: "Boston, MA",
    price: "\$100",
    imagePath: 'https://dhanush.wtf/media/bzeveb2gu0h.png?file=',
  ),
  FeaturedItemCard(
    title: "Modern Desk",
    location: "Boston, MA",
    price: "\$100",
    imagePath: 'https://dhanush.wtf/media/qy6ad3134ui.png?file=',
  ),
  FeaturedItemCard(
    title: "Modern Desk",
    location: "Boston, MA",
    price: "\$100",
    imagePath: 'https://dhanush.wtf/media/856iexr7fck.jpeg?file=',
  ),
  FeaturedItemCard(
    title: "Modern Desk",
    location: "Boston, MA",
    price: "\$100",
    imagePath: 'https://dhanush.wtf/media/qy6ad3134ui.png?file=',
  ),
  // Add more items as needed
];

class CategoryIcon extends StatelessWidget {
  final String title;
  final IconData icon;
  final String imagePath;

  const CategoryIcon({
    Key? key,
    required this.title,
    required this.icon,
    required this.imagePath,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // IconButton(
        //   icon: Icon(
        //     icon,
        //     size: 24,
        //     color: Colors.black,
        //   ),
        //   onPressed: () {},
        // ),
        Image.asset(
          imagePath,
          width: 30,
        ),
        SizedBox(
          height: 12,
        ),
        Text(title, style: const TextStyle(color: Colors.black)),
      ],
    );
  }
}
