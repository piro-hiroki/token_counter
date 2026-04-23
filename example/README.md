# token_counter_example

A Flutter demo app for the [`token_counter`](../) package.

## Features

- Live character / token count as you type
- Model selector covering GPT-4o, GPT-4, o3, Claude 4, Gemini 2, Llama 3.1
- Input-cost estimate in USD, using the bundled pricing table
- Side-by-side token-count comparison across 5 tokenizer families

## Run

```bash
cd example
flutter pub get
flutter run
```

Works on iOS, Android, macOS, Windows, Linux, and Web — the underlying
`token_counter` package is pure Dart with no FFI or platform channels.
