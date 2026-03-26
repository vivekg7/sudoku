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
  boxLineReduction('Box/Line Reduction'),
  xWing('X-Wing'),
  swordfish('Swordfish'),
  jellyfish('Jellyfish'),
  xyWing('XY-Wing'),
  xyzWing('XYZ-Wing'),
  uniqueRectangleType1('Unique Rectangle Type 1'),
  uniqueRectangleType2('Unique Rectangle Type 2'),
  uniqueRectangleType3('Unique Rectangle Type 3'),
  uniqueRectangleType4('Unique Rectangle Type 4'),
  simpleColoring('Simple Coloring'),
  xChain('X-Chain'),
  xyChain('XY-Chain'),
  alternatingInferenceChain('Alternating Inference Chain'),
  forcingChain('Forcing Chain'),
  almostLockedSet('Almost Locked Set'),
  sueDeCoq('Sue de Coq'),
  backtracking('Backtracking'),
  wrongValue('Wrong Value');

  final String label;
  const StrategyType(this.label);
}
