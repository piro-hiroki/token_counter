import 'dart:math';

/// Image detail level for OpenAI vision models.
enum ImageDetail { low, high, auto }

/// Estimates the token cost of an image attachment.
///
/// Each provider uses a different formula:
///
/// - **OpenAI** (`gpt-4o`, `gpt-4-turbo` etc.): tile-based calculation.
///   Low detail = 85 tokens. High detail = tiles × 170 + 85 base tokens,
///   where each tile covers a 512 × 512 region after scaling.
/// - **Anthropic Claude**: approximately width × height / 750, clamped to
///   a reasonable range, plus a small per-image base cost.
/// - **Google Gemini**: 258 tokens per image regardless of size (as of
///   Gemini 1.5 / 2.x vision models).
///
/// These figures are derived from official documentation and may change as
/// providers update their pricing.
class ImageTokenEstimator {
  const ImageTokenEstimator._();

  // ---------------------------------------------------------------------------
  // OpenAI
  // ---------------------------------------------------------------------------

  /// Calculates the token cost for an image sent to an OpenAI vision model.
  ///
  /// [width] and [height] are the actual image dimensions in pixels.
  /// [detail] controls the resolution tier used for encoding:
  /// - [ImageDetail.low] always costs 85 tokens.
  /// - [ImageDetail.high] (default) tiles the image and costs more.
  /// - [ImageDetail.auto] uses [ImageDetail.high] when either dimension > 512.
  static int openai({
    required int width,
    required int height,
    ImageDetail detail = ImageDetail.auto,
  }) {
    final resolved = detail == ImageDetail.auto
        ? (width > 512 || height > 512 ? ImageDetail.high : ImageDetail.low)
        : detail;

    if (resolved == ImageDetail.low) return 85;

    // Scale to fit within 2048 × 2048 maintaining aspect ratio.
    var w = width;
    var h = height;
    if (w > 2048 || h > 2048) {
      final scale = 2048 / max(w, h);
      w = (w * scale).round();
      h = (h * scale).round();
    }

    // Scale so the shortest side is 768 px.
    final short = min(w, h);
    if (short > 768) {
      final scale = 768 / short;
      w = (w * scale).round();
      h = (h * scale).round();
    }

    final tilesW = (w / 512).ceil();
    final tilesH = (h / 512).ceil();
    return tilesW * tilesH * 170 + 85;
  }

  // ---------------------------------------------------------------------------
  // Anthropic Claude
  // ---------------------------------------------------------------------------

  /// Calculates the approximate token cost for an image sent to Claude.
  ///
  /// Uses the formula documented by Anthropic:
  /// `tokens = (width × height) / 750`, with a minimum of 1 token.
  static int claude({required int width, required int height}) {
    final tokens = (width * height / 750).ceil();
    return max(1, tokens);
  }

  // ---------------------------------------------------------------------------
  // Google Gemini
  // ---------------------------------------------------------------------------

  /// Returns the flat per-image token cost for Gemini vision models.
  ///
  /// Gemini 1.5 and 2.x charge a fixed 258 tokens per image (subject to
  /// change; verify against the latest Google pricing documentation).
  static int gemini() => 258;
}
