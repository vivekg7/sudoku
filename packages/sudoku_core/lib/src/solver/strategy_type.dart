/// All solving strategy types, ordered roughly by difficulty.
enum StrategyType {
  nakedSingle('Naked Single'),
  hiddenSingle('Hidden Single'),
  nakedPair('Naked Pair'),
  hiddenPair('Hidden Pair'),
  nakedTriple('Naked Triple'),
  hiddenTriple('Hidden Triple'),
  nakedQuad('Naked Quad'),
  hiddenQuad('Hidden Quad'),
  pointingPair('Pointing Pair'),
  pointingTriple('Pointing Triple'),
  boxLineReduction('Box/Line Reduction');

  final String label;
  const StrategyType(this.label);
}
