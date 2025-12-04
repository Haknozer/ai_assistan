/// Görev filtreleme seçenekleri
enum TaskFilter {
  all('Tümü'),
  pending('Yapılacak'),
  inProgress('Devam Ediyor'),
  completed('Yapıldı');

  const TaskFilter(this.displayName);
  final String displayName;
}

