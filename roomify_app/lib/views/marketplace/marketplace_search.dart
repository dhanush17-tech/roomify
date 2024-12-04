import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:roomify_app/providers/marketplace_provider.dart';
import 'package:roomify_app/utils/colors.dart';
import 'package:roomify_app/views/marketplace/item_details.dart';

class MarketplaceSearchScreen extends StatefulWidget {
  final String searchQuery;

  const MarketplaceSearchScreen({Key? key, this.searchQuery = ''})
      : super(key: key);

  @override
  _MarketplaceSearchScreenState createState() =>
      _MarketplaceSearchScreenState();
}

class _MarketplaceSearchScreenState extends State<MarketplaceSearchScreen> {
  late TextEditingController _searchController;
  final FocusNode _searchFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.searchQuery);
    super.initState();
    _searchFocusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Container(
              height: 60,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: Hero(
                        tag: 'search_field',
                        child: Material(
                          color: Colors.transparent,
                          child: Container(
                            height: 48,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            margin: const EdgeInsets.only(right: 16),
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.search, color: Colors.grey),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: TextField(
                                    controller: _searchController,
                                    focusNode: _searchFocusNode,
                                    decoration: const InputDecoration(
                                      hintText: 'Search marketplace...',
                                      border: InputBorder.none,
                                      hintStyle: TextStyle(color: Colors.grey),
                                    ),
                                    onChanged: (query) {
                                      context
                                          .read<MarketplaceProvider>()
                                          .getSearchSuggestions(query);
                                    },
                                    onSubmitted: (query) {
                                      context
                                          .read<MarketplaceProvider>()
                                          .search(query);
                                      Navigator.pop(context, {
                                        'results': context
                                            .read<MarketplaceProvider>()
                                            .items,
                                        'query': query,
                                      });
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    Container(
                      width: 40,
                      padding: const EdgeInsets.all(0),
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.close_rounded,
                            size: 20, color: Colors.black),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: Consumer<MarketplaceProvider>(
                builder: (context, provider, _) {
                  if (provider.searchSuggestions.isNotEmpty) {
                    return ListView.builder(
                      itemCount: provider.searchSuggestions.length,
                      itemBuilder: (context, index) {
                        final listing = provider.searchSuggestions[index];
                        return ListTile(
                          leading: Icon(Icons.search, color: Colors.grey),
                          title: Text(listing.title),
                          onTap: () async {
                            _searchController.text = listing.title;
                            await provider.search(listing.title);
                            if (provider.items.isNotEmpty) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ItemDetailsScreen(
                                    item: provider.items.first,
                                  ),
                                ),
                              );
                            }
                          },
                        );
                      },
                    );
                  }

                  if (provider.isLoading) {
                    return Center(child: CircularProgressIndicator());
                  }

                  if (provider.error != null) {
                    return Center(child: Text(provider.error!));
                  }

                  if (provider.items.isEmpty && _searchController.text.isNotEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.search_off, size: 64, color: Colors.grey),
                          SizedBox(height: 16),
                          Text(
                            'No results found',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade700,
                            ),
                          ),
                          Text(
                            'Try searching with different keywords',
                            style: TextStyle(
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    itemCount: provider.items.length,
                    itemBuilder: (context, index) {
                      final item = provider.items[index];
                      return ListTile(
                        title: Text(item.title),
                        subtitle: Text('\$${item.price}'),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  ItemDetailsScreen(item: item),
                            ),
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _handleSearch() {
    final query = _searchController.text;
    if (query.isNotEmpty) {
      final filteredItems = context.read<MarketplaceProvider>().search(query);
      Navigator.pop(context, {
        'results': filteredItems,
        'query': query,
      });
    }
  }
}
