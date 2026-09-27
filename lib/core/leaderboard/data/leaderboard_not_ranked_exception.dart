/// Thrown when `GET /leaderboard` returns 400 — the caller has no CEFR
/// level set yet, or the nightly recompute hasn't run for them yet. This is
/// an expected, common state (not an error to log), distinct from a network
/// failure or a 403 for non-students.
class LeaderboardNotRankedException implements Exception {
  const LeaderboardNotRankedException(this.message);

  final String message;

  @override
  String toString() => message;
}
