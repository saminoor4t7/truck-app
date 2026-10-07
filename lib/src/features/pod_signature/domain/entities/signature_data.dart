class SignatureData {
  const SignatureData({
    required this.points,
    required this.base64Png,
  });

  final List<List<double>> points;
  final String base64Png;
}
