import 'package:flutter/material.dart';

/// An [IndexedStack] that builds each child only once it has been visited but
/// keeps previously visited children alive (preserving their state).
class LazyIndexedStack extends StatelessWidget {
  const LazyIndexedStack({
    super.key,
    required this.index,
    required this.visited,
    required this.children,
  });

  final int index;
  final Set<int> visited;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        for (var i = 0; i < children.length; i++)
          if (visited.contains(i))
            Offstage(offstage: i != index, child: children[i]),
      ],
    );
  }
}
