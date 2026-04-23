# token_counter example

Run the example from the package root:

```bash
dart run example/token_counter_example.dart
```

The sample demonstrates:

1. Quick one-off estimation via `TokenCounter.estimate`.
2. Picking a specific model via `TokenCounter.forModel(LlmModel.claude4Sonnet)`.
3. Comparing tokenizer families (GPT-4o vs GPT-4 vs Claude vs Gemini vs Llama).
4. Measuring a chat-style message array with per-message overhead.
5. Estimating USD cost from token counts.
