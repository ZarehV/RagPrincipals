# Volleyball RAG — Project Tasks

Deliverables extracted from
`Notebooks/Instructions_for_Implementing_RAG_with_VolleyBall_Dataset.md`.

Project package: `src/rag_principals/volleyball_rag/`

---

## Notebook 1 — Simple RAG with VolleyBall Dataset

**File:** `Notebooks/01-SimpleRAG/RAG_with_Local_LLM_and_Embeddings_VolleyBall.ipynb`

### Task 1 — CSV Loading with Rich Metadata

- [ ] Implement `extract_csv_metadata(file_path)` to capture schema (columns, types,
      row count), date ranges, unique team names, and numeric statistics.
- [ ] Implement `csv_to_text_chunks(file_path, chunk_by, group_size)` supporting
      `"row"` and `"group"` chunking strategies.
- [ ] Implement `load_and_chunk_csv_files(file_paths, chunk_strategy)` to produce
      LangChain `Document` objects with full metadata attached.
- [ ] Verify output against `UnstructuredDataVolleyBall/CSVFiles/vb_matches.csv`.

**Complexity:** Basic | **Focus:** Data handling

---

### Task 2 — Rules-Specific HTML Metadata Extraction

- [ ] Implement `extract_html_metadata_volleyball(file_path)` to derive `volleyball_type`
      (`beach | sand | grass | indoor | general`), `competition_level`
      (`adult | junior | general`), `organization`, and `rule_sections` from filename
      and page content via BeautifulSoup.
- [ ] Implement `load_and_chunk_html_volleyball(file_paths, chunk_size, chunk_overlap)`
      using `UnstructuredHTMLLoader` and `RecursiveCharacterTextSplitter`.
- [ ] Demonstrate correct parsing by querying the Chroma database post-ingestion.

**Complexity:** Basic | **Focus:** Domain metadata extraction

---

### Task 3 — Domain-Specific System Prompt

- [ ] Write `volleyball_system_message` covering all knowledge-base types (rules,
      match data, lesson plans) and format-aware answer instructions.
- [ ] Wire the prompt into the RAG function so it prefixes every generation call.

**Complexity:** Basic | **Focus:** Prompt engineering

---

### Task 4 — Diverse Volleyball Query Testing

- [ ] Define a query set covering: rules, match statistics, educational/coaching,
      comparative (format differences), and specific rule lookups (10+ queries).
- [ ] Run the first 5 queries through the RAG pipeline and print answers.

**Complexity:** Basic | **Focus:** System testing

---

### Task 5 — Volleyball Domain Evaluation Metrics

- [ ] Implement `evaluate_volleyball_terminology(question, answer)` with a 1–5 scoring
      rubric for term correctness (serve, spike, libero, rally scoring, etc.).
- [ ] Implement `evaluate_rule_specificity(question, answer, context)` to check whether
      format-specific rules are clearly attributed to the correct format.
- [ ] Implement `evaluate_volleyball_rag_response(question, answer, context)` combining
      groundedness, context relevance, answer relevance, terminology accuracy, and
      (conditionally) rule specificity.

**Complexity:** Medium | **Focus:** Evaluation

---

### Task 6 — Metadata-Based Filtered Retrieval

- [ ] Implement `filtered_rag_query(question, filters)` that creates a filtered Chroma
      retriever when `filters` is supplied.
- [ ] Demonstrate three filter scenarios: `volleyball_type=beach`, `source_type=csv`,
      and `document_category=educational`.

**Complexity:** Medium | **Focus:** Retrieval

---

## Notebook 2 — Agentic RAG with VolleyBall Dataset (smolagents)

**File:** `Notebooks/02-AgenticRAG/RAG_with_Agentic_RAG_and_Embeddings_VolleyBall.ipynb`

### Task 7 — CSV Analyzer Tool (smolagents)

- [ ] Implement `VolleyBallCSVAnalyzer(Tool)` with `name`, `description`, and `inputs`
      populated correctly.
- [ ] Implement `forward(query)` handling team, date, score/result, comparative, and
      general-statistics branches via pandas.
- [ ] Return natural-language formatted results including a data sample.

**Complexity:** Medium | **Focus:** Tool creation

---

### Task 8 — Rules Comparison Tool (smolagents)

- [ ] Implement `VolleyBallRulesComparison(Tool)` that detects format names in the
      query and performs per-format filtered Chroma similarity searches.
- [ ] Format output as a side-by-side comparison of retrieved rule excerpts.

**Complexity:** Medium | **Focus:** Multi-document reasoning

---

### Task 9 — Multi-Tool Volleyball Agent

- [ ] Implement `VolleyBallKnowledgeSearch(Tool)` for general vector retrieval with
      source-type metadata in the response.
- [ ] Compose `volleyball_agent = CodeAgent(tools=[knowledge_tool, csv_analyzer_tool,
      rules_comparison_tool], ...)` with `verbosity_level=2`.

**Complexity:** Medium | **Focus:** Agent orchestration

---

### Task 10 — Complex Query Handling

- [ ] Define `complex_volleyball_queries` covering statistical, comparative, educational,
      and multi-step queries.
- [ ] Run all four test cases through `volleyball_agent` and capture verbose reasoning
      traces showing tool selection, intermediate results, and answer synthesis.

**Complexity:** Medium | **Focus:** Testing

---

### Task 11 — Agent Performance Evaluation (Tool Usage & Reasoning Quality)

- [ ] Implement `ToolUsageEvaluator(Tool)` with a 1–5 rubric for tool selection
      appropriateness, multi-tool necessity, and improvement suggestions.
- [ ] Implement `MultiStepReasoningEvaluator(Tool)` with a 1–5 rubric for logical flow,
      step clarity, information gathering, and synthesis coherence.
- [ ] Implement `comprehensive_volleyball_agent_evaluation(...)` combining all six
      metrics (groundedness, context relevance, answer relevance, terminology,
      tool usage, reasoning quality).
- [ ] Run the evaluation on at least one complex multi-step query.

**Complexity:** High | **Focus:** Agent evaluation

---

## Notebook 3 — Advanced Agentic RAG with VolleyBall Dataset (LangChain)

**File:** `Notebooks/03-AdvenceAgenticRAG/Advance_Agentic_RAG_with_Langchain_VolleyBall.ipynb`

### Task 12 — Advanced Statistical Analysis Tool (LangChain + pandas)

- [ ] Implement `create_advanced_csv_analyzer(csv_path)` returning a LangChain `Tool`.
- [ ] Support query branches: time-series / trend, team comparison, aggregation
      (average, mean, total), and filtered lookups.
- [ ] Return comprehensive statistics for unrecognized queries including sample data.

**Complexity:** High | **Focus:** Data analysis

---

### Task 13 — Volleyball-Specific Hypothetical Question Generation

- [ ] Implement `generate_volleyball_hypothetical_questions(query, num)` using the LLM
      to produce `num` related questions covering rules, formats, statistics, and
      coaching perspectives.
- [ ] Implement `retriever_with_volleyball_hypotheticals(query)` that de-duplicates
      documents retrieved for original + generated questions.
- [ ] Create `hypothetical_tool_v2` (LangChain `Tool`) and `agent_v2_executor`.

**Complexity:** High | **Focus:** Query expansion

---

### Task 14 — BM25 + Vector Hybrid Search

- [ ] Create `bm25_retriever` from all ingested documents with `k=5`.
- [ ] Create `hybrid_retriever_v3 = EnsembleRetriever(weights=[0.4, 0.6])`.
- [ ] Implement `volleyball_hybrid_search(query)` with source-type/format metadata in
      the response and create `hybrid_tool_v3` + `agent_v3_executor`.

**Complexity:** High | **Focus:** Retrieval

---

### Task 15 — Cross-Encoder Re-Ranking

- [ ] Load `cross-encoder/ms-marco-MiniLM-L-6-v2` via `sentence_transformers`.
- [ ] Implement `volleyball_retrieval_with_reranking(query, top_k)`: retrieve 10
      candidates with hybrid retriever, score with cross-encoder, re-rank, return top k
      with scores shown.
- [ ] Create `reranking_tool_v4` + `agent_v4_executor`.

**Complexity:** High | **Focus:** Ranking

---

### Task 16 — LLM Contextual Compression

- [ ] Create `compression_retriever_v5 = ContextualCompressionRetriever(
      base_compressor=LLMChainExtractor.from_llm(llm),
      base_retriever=hybrid_retriever_v3)`.
- [ ] Implement `volleyball_compressed_retrieval(query)` and create `compression_tool_v5`.
- [ ] Create `agent_v5_executor` with both `compression_tool_v5` and `advanced_csv_tool`.

**Complexity:** High | **Focus:** Compression

---

### Task 17 — Progressive Agent Performance Comparison (V1–V5)

- [ ] Define `volleyball_test_queries` covering simple, medium, and complex queries of
      types: rule-specific, comparative, and multi-source.
- [ ] Implement `compare_agent_performance(query_dict)` running all five agent versions
      against the same query and printing side-by-side answer summaries.
- [ ] Execute comparisons for all test queries.

**Complexity:** High | **Focus:** Analysis

---

### Task 17B — KPI-Based Agent Evaluation (V1, V3, V5)

- [ ] Implement `evaluate_groundedness(question, context, answer, llm)` returning a
      dict with numeric `score` and parsed explanation.
- [ ] Implement `evaluate_context_relevance(question, context, llm)` with the same
      return structure.
- [ ] Implement `evaluate_answer_relevance(question, answer, llm)` with the same
      return structure.
- [ ] Implement `evaluate_agent_with_kpis(agent_executor, agent_name, query, retriever,
      llm)` that times execution, extracts context from the retriever, runs all three
      quality evaluations, and returns a flat result dict with `execution_time` and
      `average_quality_score`.
- [ ] Implement `compare_agents_comprehensive(test_queries, agent_configs, llm)`
      returning a `pd.DataFrame` of all results.
- [ ] Run the framework over `evaluation_test_queries` × `[V1, V3, V5]`.
- [ ] Print summary tables: average scores by agent, quality-per-second trade-off,
      performance by complexity, and a detailed results table.
- [ ] Save full results to `agent_comparison_results.csv`.
- [ ] Produce (or describe) four visualisations: quality-metrics bar chart,
      quality-vs-speed scatter plot, complexity heatmap, and line chart showing
      metric progression V1→V3→V5.

**Complexity:** Very High | **Focus:** Metrics & performance

---

### Task 18 — Cross-Document Reasoning

- [ ] Define `cross_document_queries` (3 queries) requiring simultaneous use of match
      statistics, rules documents, and lesson plans.
- [ ] Run each through `agent_v5_executor` in verbose mode and document tool-selection
      patterns and synthesis quality.

**Complexity:** Very High | **Focus:** Synthesis

---

### Task 19 — Intelligent Metadata Filtering

- [ ] Implement `intelligent_filtered_retrieval(query)` that analyses the query string
      to auto-select `volleyball_type`, `source_type`, `document_category`, and
      `competition_level` filters before retrieval.
- [ ] Create `intelligent_filter_tool` and `agent_intelligent_filter`.
- [ ] Test with three queries that should trigger distinct filter combinations.

**Complexity:** Very High | **Focus:** Dynamic retrieval

---

### Task 20 — Production-Ready Error Handling & Monitoring

- [ ] Implement `ProductionVolleyballRAG` class with `query(question, timeout)`,
      graceful agent fallback to direct vector retrieval on failure, and internal
      `query_log` tracking latency, status, and method per call.
- [ ] Implement `get_statistics()` returning total queries, error count, error rate,
      average latency, and success rate.
- [ ] Test with three queries (two valid + one intentionally vague) and print per-query
      status and aggregate statistics.

**Complexity:** Very High | **Focus:** Engineering

---

## Summary

| #   | Task                               | Notebook | Complexity  |
|-----|------------------------------------|----------|-------------|
| 1   | CSV Loading with Rich Metadata     | 1        | Basic       |
| 2   | Rules-Specific HTML Metadata       | 1        | Basic       |
| 3   | Domain-Specific System Prompt      | 1        | Basic       |
| 4   | Diverse Volleyball Query Testing   | 1        | Basic       |
| 5   | Volleyball Domain Evaluation       | 1        | Medium      |
| 6   | Metadata-Based Filtered Retrieval  | 1        | Medium      |
| 7   | CSV Analyzer Tool (smolagents)     | 2        | Medium      |
| 8   | Rules Comparison Tool              | 2        | Medium      |
| 9   | Multi-Tool Volleyball Agent        | 2        | Medium      |
| 10  | Complex Query Handling             | 2        | Medium      |
| 11  | Agent Performance Evaluation       | 2        | High        |
| 12  | Advanced Statistical Tool          | 3        | High        |
| 13  | Hypothetical Question Generation   | 3        | High        |
| 14  | BM25 + Vector Hybrid Search        | 3        | High        |
| 15  | Cross-Encoder Re-Ranking           | 3        | High        |
| 16  | LLM Contextual Compression         | 3        | High        |
| 17  | Progressive Agent Comparison V1–V5 | 3        | High        |
| 17B | KPI-Based Agent Evaluation         | 3        | Very High   |
| 18  | Cross-Document Reasoning           | 3        | Very High   |
| 19  | Intelligent Metadata Filtering     | 3        | Very High   |
| 20  | Production-Ready Implementation    | 3        | Very High   |
