# token_counter

LLM のトークン数を Flutter / Dart から計測するためのパッケージです。
OpenAI・Anthropic・Google など、主要なモデルのトークナイザに対応し、日本語・英語・多言語のテキストで精度の高い計測を行うことを目指します。

## モチベーション

LLM を組み込んだアプリでは、以下の用途でトークン数の事前計測が必要になります。

- コンテキストウィンドウに収まるかの判定（例: Claude 200K、GPT-4o 128K）
- API コストの見積り（入力／出力トークン単価の合算）
- ストリーミング UI での残量表示、プロンプト編集時のリアルタイムカウント
- RAG のチャンク分割・要約のしきい値判定

既存の Dart 実装は OpenAI の tiktoken 互換に留まるものが多く、Anthropic / Google / ローカルモデルまで含めて **Flutter アプリ内で完結して計測できる** ものが少ないため、このパッケージを作成します。

## サポート予定のモデル / トークナイザ

| プロバイダ | モデル | トークナイザ | ステータス |
| --- | --- | --- | --- |
| OpenAI | GPT-4o, GPT-4.1, o-series | `o200k_base` (tiktoken BPE) | 計画中 |
| OpenAI | GPT-4, GPT-3.5 | `cl100k_base` (tiktoken BPE) | 計画中 |
| Anthropic | Claude 3.x / 4.x | SentencePiece 互換 BPE | 計画中 |
| Google | Gemini 1.5 / 2.x | SentencePiece 互換 | 計画中 |
| Meta | Llama 3.x | tiktoken 互換 BPE | 計画中 |
| ヒューリスティック | 任意 | 文字種別の近似推定 | 計画中 |

## 設計方針

### 1. 精度とバンドルサイズのトレードオフ

トークナイザの語彙ファイル（BPE マージや SentencePiece モデル）は数 MB 〜 十数 MB に及びます。Flutter アプリに同梱すると APK / IPA サイズを圧迫するため、以下の二層構成を取ります。

- **正確モード (accurate)**: 実際の語彙ファイルを Flutter アセットとして読み込み、モデルと同じトークナイズを行う。
- **推定モード (heuristic)**: 語彙ファイル不要。言語（日本語・中国語・韓国語・英語・記号など）ごとの平均バイト／文字あたりトークン比率で近似する。

デフォルトは heuristic、`TokenCounter.loadVocab(...)` を呼び出すと accurate に切り替わります。

### 2. 多言語対応

日本語や中国語は 1 文字で複数トークン消費されることが多く、英語との比率が大きく異なります。Unicode スクリプト（Hiragana / Katakana / CJK Ideographs / Hangul など）ごとに係数を持たせ、Latin 系テキストとの混在でも精度が落ちないようにします。

### 3. プラットフォーム

Pure Dart 実装を基本とし、FFI やネイティブコードに依存しません。Flutter のサポートする全プラットフォーム（iOS / Android / macOS / Windows / Linux / Web）で動作します。

## API（予定）

```dart
import 'package:token_counter/token_counter.dart';

// 1. もっとも簡単な使い方（heuristic, デフォルトモデル）
final count = TokenCounter.estimate('こんにちは、world!');

// 2. モデルを指定
final counter = TokenCounter.forModel(LlmModel.gpt4o);
final n = counter.count('prompt text');

// 3. 正確モード（アセットから vocab を読み込み）
final accurate = await TokenCounter.forModel(LlmModel.claude4Sonnet)
    .loadVocab();
final exact = accurate.count('prompt text');

// 4. チャット形式のメッセージ配列をまとめて計測
final total = counter.countMessages([
  ChatMessage.system('You are a helpful assistant.'),
  ChatMessage.user('東京の天気は？'),
]);

// 5. コスト見積り
final cost = counter.estimateCost(
  inputTokens: n,
  outputTokens: 500,
  pricing: ModelPricing.gpt4o,
);
```

## ロードマップ

- [ ] v0.1: heuristic モードの実装、OpenAI / Claude / Gemini の推定係数
- [ ] v0.2: tiktoken 互換 (`cl100k_base`, `o200k_base`) の純 Dart 実装
- [ ] v0.3: SentencePiece 互換 (Claude / Gemini) の純 Dart 実装
- [ ] v0.4: チャットメッセージ・画像・ツール呼び出しのオーバーヘッド計算
- [ ] v0.5: コスト見積り API、モデル単価テーブルの同梱
- [ ] v1.0: ベンチマーク（各モデル公式カウンタとの誤差測定）と安定版リリース

## 非目標

- クラウド API を呼び出しての計測（ネットワーク依存のため）
- モデル推論そのもの（あくまでトークナイズのみ）
- 学習／再トークナイズ用途（本パッケージは計測用途に最適化）

## ライセンス

MIT（予定）
