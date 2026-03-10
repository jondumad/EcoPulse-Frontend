/// Utility class for formatting dates, durations, and other values throughout the app.
class EcoFormatters {
  /// Formats a duration as a timer string (e.g., "01:23:45").
  static String formatTimerDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    
    if (duration.inHours > 0) {
      return "${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds";
    } else {
      return "$twoDigitMinutes:$twoDigitSeconds";
    }
  }

  /// Formats a duration as a human-readable summary (e.g., "1h 23m" or "45m").
  static String formatSummaryDuration(Duration d) {
    if (d.inMinutes < 60) {
      return "${d.inMinutes}m";
    }
    final hours = d.inHours;
    final minutes = d.inMinutes.remainder(60);
    return "${hours}h ${minutes}m";
  }
}
