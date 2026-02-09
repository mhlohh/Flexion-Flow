class CalibrationSession {
  List<double> _peaks = [];
  double _currentMax = 0;
  bool _isRising = true;

  // Call this on every frame from the stream
  void processFrame(double currentAngle) {
    // simple peak detection logic
    if (currentAngle > _currentMax) {
      _currentMax = currentAngle;
      _isRising = true;
    } else if (currentAngle < (_currentMax - 10) && _isRising) {
      // Angle dropped by 10 degrees, meaning peak is passed
      _peaks.add(_currentMax);
      _currentMax = 0; // Reset for next rep
      _isRising = false;
      // print("Rep Captured: Peak at ${_peaks.last}");
    }
  }

  bool get isCalibrationComplete => _peaks.length >= 3;

  int get repCount => _peaks.length;

  double getFinalBaseline() {
    if (_peaks.isEmpty) return 0.0;
    // Calculate average of captured peaks
    double sum = _peaks.reduce((a, b) => a + b);
    return sum / _peaks.length;
  }
}
