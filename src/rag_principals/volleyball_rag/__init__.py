"""Volleyball RAG — progressive retrieval-augmented generation over the VolleyBall dataset.

Three implementation levels:

- Notebook 1 (simple_rag): CSV/HTML/TXT loading, metadata extraction, basic retrieval,
  domain-specific evaluation.
- Notebook 2 (agentic_rag): smolagents multi-tool agent with CSV analyzer, rules
  comparison, and reasoning-quality evaluation.
- Notebook 3 (advanced_rag): LangChain agents V1–V5 with hypothetical-question expansion,
  BM25+vector hybrid search, cross-encoder re-ranking, LLM contextual compression,
  KPI-based agent comparison, and production-ready error handling.
"""

__all__: list[str] = []
