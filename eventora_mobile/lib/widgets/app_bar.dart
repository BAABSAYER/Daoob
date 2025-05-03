import 'package:flutter/material.dart';
import 'package:eventora_app/config/theme.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool showBackButton;
  final List<Widget>? actions;
  final Widget? leading;
  final bool centerTitle;
  final Color? backgroundColor;
  final PreferredSizeWidget? bottom;
  
  const CustomAppBar({
    Key? key,
    required this.title,
    this.showBackButton = true,
    this.actions,
    this.leading,
    this.centerTitle = true,
    this.backgroundColor,
    this.bottom,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(title),
      centerTitle: centerTitle,
      backgroundColor: backgroundColor ?? AppTheme.surfaceColor,
      elevation: 0,
      actions: actions,
      leading: leading ?? (showBackButton ? const BackButton() : null),
      bottom: bottom,
    );
  }
  
  @override
  Size get preferredSize => bottom == null 
      ? const Size.fromHeight(kToolbarHeight) 
      : Size.fromHeight(kToolbarHeight + bottom!.preferredSize.height);
}

class SearchAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final TextEditingController searchController;
  final Function(String) onSearch;
  final VoidCallback? onClear;
  final bool showBackButton;
  final String hintText;
  
  const SearchAppBar({
    Key? key,
    required this.title,
    required this.searchController,
    required this.onSearch,
    this.onClear,
    this.showBackButton = true,
    this.hintText = 'Search...',
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(title),
      centerTitle: true,
      backgroundColor: AppTheme.surfaceColor,
      elevation: 0,
      leading: showBackButton ? const BackButton() : null,
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: Container(
            height: 48,
            decoration: BoxDecoration(
              color: AppTheme.backgroundColor,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.textTertiaryColor.withOpacity(0.5)),
            ),
            child: Center(
              child: TextField(
                controller: searchController,
                onChanged: onSearch,
                decoration: InputDecoration(
                  hintText: hintText,
                  prefixIcon: const Icon(Icons.search, color: AppTheme.textSecondaryColor),
                  suffixIcon: searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, color: AppTheme.textSecondaryColor),
                          onPressed: () {
                            searchController.clear();
                            if (onClear != null) {
                              onClear!();
                            }
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
  
  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 60);
}