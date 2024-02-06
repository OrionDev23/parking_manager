class ChartData {
  ChartData(this.x, this.y, this.label);
  final String label;
  final int x;
  final int y;
}

class ChartDataCategory {
  ChartDataCategory(this.category,this.values);

  final String category;
  final List<ChartData> values;
}