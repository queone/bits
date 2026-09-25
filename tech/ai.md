---
type: note
---
## AI

Notes I keep on working with AI models. How I see the software worth building before AGI is on its own page ([Software Before AGI](before-agi.md)). Everything here has a sell-by date, because what models can do has been changing faster than these notes.

### Prompts that keep answers honest

Two prompts I reuse whenever being right matters more than being fast:

- `Do a thorough review of X, then adversarially double-check your conclusion for accuracy.`
- `Assess the claim and provide a concise take.`

### Run DeepSeek Locally

Use [ollama](https://github.com/ollama/ollama) for this.

Pick the DeepSeek R1 model you want to try: 7b (4.7GB) - 14b (9G) - 32b (20GB) - 70b (43GB) - 671b (404GB)

```bash
brew install ollama                   # Install ollama
ollama serve                          # Start ollama - in a diff shell window
ollama pull deepseek-r1:7b            # Pull deepseek-r1:7b
ollama run deepseek-r1:7b             # Run it
alias r1='ollama run deepseek-r1:7b'  # Setup a shell alias to prompt question
```

### Embeddings

[Embeddings](https://en.wikipedia.org/wiki/Word_embedding) are lists of numbers that stand for data and capture its meaning or its relations. For example, `"cat" → [0.12, -0.83, 0.45, ...]`, a list of a few hundred to a few thousand numbers. They are widely used for finding similar items, ranking, and grouping.

#### Common Patterns

The most common use is semantic search. Embed a set of documents and a query, then find the nearest neighbors (FAISS, Annoy, ScaNN, Pinecone). No text-generating model is needed.

Recommendation engines use the same idea. They place users and items in one shared space and rank by distance (Spotify, YouTube, Amazon). Fraud and anomaly detection embed transactions or log lines and flag the outliers. Clustering and deduplication group similar items for topic discovery, customer segments, or duplicate detection.

Code search maps plain-language queries and code into the same space (Sourcegraph's older approach, GitHub code search before Copilot). Finally, classification embeds inputs and compares them against class centers or a simple linear layer. That is faster and cheaper than calling a full LLM (for example Sentence-BERT for duplicate-question detection or support-ticket routing).

#### When Embeddings Are Enough

For tasks about matching, ranking, or grouping, embeddings alone are often enough. They are faster, cheaper, more predictable, and easier to debug than reaching for an LLM.

Current as of September 2026.
