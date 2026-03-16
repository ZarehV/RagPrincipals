#!/usr/bin/env bash
# create_rag_project.sh
#
# Creates labels, milestones, and 25 GitHub issues for the VolleyBall RAG
# implementation, then optionally creates a GitHub Project v2 board.
#
# Prerequisites:
#   - gh CLI installed and authenticated  (gh auth login)
#   - For project creation: a PAT with the 'project' OAuth scope stored in
#     the PROJECT_TOKEN environment variable
#
# Usage:
#   bash scripts/create_rag_project.sh [--repo OWNER/REPO] [--skip-project]
#
# Examples:
#   bash scripts/create_rag_project.sh
#   bash scripts/create_rag_project.sh --repo ZarehV/RagPrincipals
#   PROJECT_TOKEN=ghp_xxx bash scripts/create_rag_project.sh

set -euo pipefail

# ── Parse arguments ───────────────────────────────────────────────────────────
REPO=""
SKIP_PROJECT=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --repo) REPO="$2"; shift 2 ;;
    --skip-project) SKIP_PROJECT=true; shift ;;
    *) echo "Unknown argument: $1"; exit 1 ;;
  esac
done

# Detect repo from git remote if not provided
if [ -z "$REPO" ]; then
  REPO=$(gh repo view --json nameWithOwner --jq '.nameWithOwner' 2>/dev/null || true)
fi
if [ -z "$REPO" ]; then
  echo "❌  Could not detect repo. Pass --repo OWNER/REPO explicitly."
  exit 1
fi
echo "Repository: $REPO"

# ── Token setup ───────────────────────────────────────────────────────────────
# Issues/labels/milestones use whatever gh is authenticated with.
# Project creation requires PROJECT_TOKEN with 'project' scope.
PROJECT_TOKEN="${PROJECT_TOKEN:-}"

# ── Helper functions ──────────────────────────────────────────────────────────

upsert_label() {
  local name="$1" color="$2" desc="$3"
  gh label create "$name" --color "$color" --description "$desc" --repo "$REPO" 2>/dev/null \
    || gh label edit "$name" --color "$color" --description "$desc" --repo "$REPO" 2>/dev/null \
    || true
}

create_milestone() {
  local title="$1" desc="$2"
  local num
  num=$(gh api "repos/$REPO/milestones" --paginate \
    --jq ".[] | select(.title == \"$title\") | .number" 2>/dev/null | head -1)
  if [ -z "$num" ]; then
    num=$(gh api "repos/$REPO/milestones" \
      -f title="$title" -f description="$desc" -f state="open" \
      --jq ".number")
  fi
  echo "$num"
}

create_issue() {
  local title="$1" body="$2" labels="$3" milestone="$4"
  local existing
  existing=$(gh issue list --repo "$REPO" --state open --search "\"$title\" in:title" \
    --json number,title --jq ".[] | select(.title == \"$title\") | .number" 2>/dev/null | head -1)
  if [ -n "$existing" ]; then
    echo "$existing"
  else
    gh issue create --repo "$REPO" \
      --title "$title" \
      --body "$body" \
      --label "$labels" \
      --milestone "$milestone" \
      --json number --jq ".number"
  fi
}

# ── 1. Labels ─────────────────────────────────────────────────────────────────
echo ""
echo "Creating labels…"
upsert_label "notebook-1"      "0075ca" "Notebook 1: Simple RAG"
upsert_label "notebook-2"      "e4e669" "Notebook 2: Agentic RAG (smolagents)"
upsert_label "notebook-3"      "d93f0b" "Notebook 3: Advanced Agentic RAG (LangChain)"
upsert_label "data-loading"    "bfd4f2" "Data loading and preprocessing"
upsert_label "retrieval"       "fef2c0" "Retrieval strategy"
upsert_label "agent"           "e99695" "Agent design and tooling"
upsert_label "evaluation"      "c2e0c6" "Evaluation and metrics"
upsert_label "csv-analysis"    "c5def5" "CSV / tabular data handling"
upsert_label "infrastructure"  "ededed" "Setup, vector store, base configuration"
echo "✅ Labels done"

# ── 2. Milestones ─────────────────────────────────────────────────────────────
echo ""
echo "Creating milestones…"
M1=$(create_milestone \
  "Notebook 1: Simple RAG with VolleyBall Dataset" \
  "CSV/HTML/TXT loading, metadata extraction, domain evaluation, filtered retrieval")
M2=$(create_milestone \
  "Notebook 2: Agentic RAG with smolagents" \
  "CSV analyzer tool, rules comparison tool, multi-tool agent, agent evaluation")
M3=$(create_milestone \
  "Notebook 3: Advanced Agentic RAG with LangChain" \
  "Hybrid search, re-ranking, LLM compression, KPI evaluation, cross-document reasoning")
echo "✅ Milestones: N1=#$M1  N2=#$M2  N3=#$M3"

# ── 3. Issues ─────────────────────────────────────────────────────────────────
echo ""
echo "Creating issues…"
ISSUE_NUMBERS=()

add() {
  local n
  n=$(create_issue "$1" "$2" "$3" "$4")
  ISSUE_NUMBERS+=("$n")
  echo "  #$n  $1"
}

# ── Notebook 1 ────────────────────────────────────────────────────────────────
add "[N1] CSV Loader with Rich Metadata Extraction" \
"## Overview
Implement \`extract_csv_metadata()\` and \`csv_to_text_chunks()\` for the VolleyBall match statistics CSV.

## Deliverables
- [ ] \`extract_csv_metadata(file_path)\` — file info, row/column counts, data types, date ranges, unique team names, numeric statistics summary
- [ ] \`csv_to_text_chunks(file_path, chunk_by='row'|'group', group_size=5)\` — converts tabular rows to natural-language text chunks
- [ ] \`load_and_chunk_csv_files(file_paths, chunk_strategy)\` — returns \`List[Document]\` with rich metadata

## Acceptance criteria
- Each Document has: \`source_type\`, \`file_name\`, \`row_count\`, \`column_names\`, \`teams\`, \`statistics_summary\`, \`chunk_index\`
- Both chunking strategies produce valid Documents
- At least 1 unit test covers the metadata extractor

## Reference
\`Notebooks/Instructions_for_Implementing_RAG_with_VolleyBall_Dataset.md\` — Challenge 1 (Section 4)" \
  "notebook-1,data-loading,csv-analysis" "$M1"

add "[N1] HTML Volleyball Rules Metadata Extraction" \
"## Overview
Implement \`extract_html_metadata_volleyball()\` and \`load_and_chunk_html_volleyball()\` for official volleyball rules HTML files.

## Deliverables
- [ ] Extract \`volleyball_type\`, \`competition_level\`, \`organization\`, \`rule_sections\` from filename and content
- [ ] Load with \`UnstructuredHTMLLoader\`, attach metadata, apply \`RecursiveCharacterTextSplitter\`
- [ ] Verify by querying the ChromaDB collection

## Reference
\`Notebooks/Instructions_for_Implementing_RAG_with_VolleyBall_Dataset.md\` — Challenge 2 (Section 5)" \
  "notebook-1,data-loading" "$M1"

add "[N1] Text File Loader with Content Categorization" \
"## Overview
Load TXT files with \`extract_text_metadata_volleyball()\`, identifying content type (lesson_plan / rules) and domain attributes from filename patterns.

## Deliverables
- [ ] Implement metadata extractor identifying \`content_type\`, \`document_category\`, \`volleyball_type\`, \`competition_level\`
- [ ] Load with \`TextLoader\`, attach metadata, chunk with shared splitter

## Reference
\`Notebooks/Instructions_for_Implementing_RAG_with_VolleyBall_Dataset.md\` — Section 6" \
  "notebook-1,data-loading" "$M1"

add "[N1] Build ChromaDB Vector Store from All Sources" \
"## Overview
Merge CSV, HTML, and TXT documents and create a persistent ChromaDB vector store.

## Deliverables
- [ ] Combine all document lists
- [ ] Create \`Chroma.from_documents()\` — collection \`VolleyBall_Documentation_RAG\`, persisted to \`./chroma_db_volleyball\`
- [ ] Print per-source and total document counts

## Reference
\`Notebooks/Instructions_for_Implementing_RAG_with_VolleyBall_Dataset.md\` — Section 7" \
  "notebook-1,infrastructure" "$M1"

add "[N1] Domain-Specific Volleyball System Prompt" \
"## Overview
Create a volleyball-tailored system prompt covering all formats (beach/sand/grass/indoor), statistics, lesson plans, and regulations.

## Deliverables
- [ ] Define \`volleyball_system_message\` and integrate into the RAG function
- [ ] Prompt instructs model to specify volleyball format and cite statistics with context

## Reference
\`Notebooks/Instructions_for_Implementing_RAG_with_VolleyBall_Dataset.md\` — Challenge 3 (Section 8)" \
  "notebook-1,retrieval" "$M1"

add "[N1] Diverse Volleyball Query Testing" \
"## Overview
Test the RAG pipeline with ≥10 queries spanning rules, statistics, educational content, comparative, and specific-fact categories.

## Deliverables
- [ ] Run queries for all 5 categories and print Q&A pairs
- [ ] At least 5 queries produce non-empty, domain-appropriate answers

## Reference
\`Notebooks/Instructions_for_Implementing_RAG_with_VolleyBall_Dataset.md\` — Challenge 4 (Section 9)" \
  "notebook-1,evaluation" "$M1"

add "[N1] Domain Evaluation: Terminology Accuracy & Rule Specificity" \
"## Overview
Implement two volleyball-specific evaluators (1–5 score) plus a combined evaluation function.

## Deliverables
- [ ] \`evaluate_volleyball_terminology(question, answer)\`
- [ ] \`evaluate_rule_specificity(question, answer, context)\`
- [ ] \`evaluate_volleyball_rag_response()\` combining 5 metrics total
- [ ] Run on at least 1 sample query

## Reference
\`Notebooks/Instructions_for_Implementing_RAG_with_VolleyBall_Dataset.md\` — Challenge 5 (Section 10)" \
  "notebook-1,evaluation" "$M1"

add "[N1] Metadata-Based Filtered Retrieval" \
"## Overview
Implement \`filtered_rag_query(question, filters)\` with ChromaDB metadata filters and demonstrate with 3 targeted queries.

## Deliverables
- [ ] \`filtered_rag_query()\` applying \`search_kwargs={'filter': filters}\`
- [ ] Demo: beach rules only, CSV data only, educational content only

## Reference
\`Notebooks/Instructions_for_Implementing_RAG_with_VolleyBall_Dataset.md\` — Challenge 6 (Section 11)" \
  "notebook-1,retrieval" "$M1"

# ── Notebook 2 ────────────────────────────────────────────────────────────────
add "[N2] Base Setup: Replicate Document Loading Pipeline" \
"## Overview
Replicate Notebook 1 Sections 1–7 inside the agentic notebook.

## Deliverables
- [ ] Copy installation, imports, model loading, all loaders
- [ ] Rebuild ChromaDB vector store; verify counts match N1

## Reference
\`Notebooks/Instructions_for_Implementing_RAG_with_VolleyBall_Dataset.md\` — Notebook 2, Sections 1–7" \
  "notebook-2,infrastructure" "$M2"

add "[N2] CSV Analyzer Tool — Statistical Analysis (smolagents)" \
"## Overview
Build \`VolleyBallCSVAnalyzer(Tool)\` answering natural-language statistical questions about match data using pandas.

## Deliverables
- [ ] smolagents \`Tool\` subclass with name, description, inputs, output_type
- [ ] \`forward(query)\` routing for team stats, dates, scores, comparisons, general overview
- [ ] Error handling returns a helpful message

## Reference
\`Notebooks/Instructions_for_Implementing_RAG_with_VolleyBall_Dataset.md\` — Challenge 7 (Section 8)" \
  "notebook-2,agent,csv-analysis" "$M2"

add "[N2] Rules Comparison Tool — Multi-Document Reasoning (smolagents)" \
"## Overview
Build \`VolleyBallRulesComparison(Tool)\` that retrieves format-specific rules and produces side-by-side comparisons.

## Deliverables
- [ ] smolagents \`Tool\` subclass
- [ ] \`forward(query)\` identifies formats, retrieves via \`volleyball_type\` filter, formats comparison
- [ ] Falls back to all formats when none mentioned

## Reference
\`Notebooks/Instructions_for_Implementing_RAG_with_VolleyBall_Dataset.md\` — Challenge 8 (Section 9)" \
  "notebook-2,agent,retrieval" "$M2"

add "[N2] Multi-Tool Volleyball Agent" \
"## Overview
Assemble a \`CodeAgent\` (smolagents) with knowledge search, CSV analyzer, and rules comparison tools.

## Deliverables
- [ ] \`VolleyBallKnowledgeSearch(Tool)\` wrapping ChromaDB similarity search
- [ ] \`CodeAgent(tools=[...], max_steps=10, verbosity_level=2)\`

## Reference
\`Notebooks/Instructions_for_Implementing_RAG_with_VolleyBall_Dataset.md\` — Challenge 9 (Section 10)" \
  "notebook-2,agent" "$M2"

add "[N2] Complex Multi-Step Query Testing" \
"## Overview
Test the multi-tool agent with 4 query types (statistical, comparative, educational, multi-step) and verify tool selection.

## Deliverables
- [ ] Run all 4 test cases; document actual tool selected
- [ ] At least 3/4 use the expected tool

## Reference
\`Notebooks/Instructions_for_Implementing_RAG_with_VolleyBall_Dataset.md\` — Challenge 10 (Section 11)" \
  "notebook-2,evaluation" "$M2"

add "[N2] Agent Evaluation: Tool Usage & Reasoning Quality" \
"## Overview
Build \`ToolUsageEvaluator\` and \`MultiStepReasoningEvaluator\`, assemble them into an evaluation agent, and run comprehensive evaluation.

## Deliverables
- [ ] Both evaluators: 1–5 score + text explanation
- [ ] \`comprehensive_volleyball_agent_evaluation()\` running 6 total metrics
- [ ] Run evaluation on a complex multi-source query

## Reference
\`Notebooks/Instructions_for_Implementing_RAG_with_VolleyBall_Dataset.md\` — Challenge 11 (Sections 12–13)" \
  "notebook-2,evaluation,agent" "$M2"

# ── Notebook 3 ────────────────────────────────────────────────────────────────
add "[N3] Base Setup: Replicate Document Loading Pipeline" \
"## Overview
Replicate Notebook 1 Sections 1–7 inside the advanced LangChain notebook.

## Deliverables
- [ ] Copy installation, imports, LangChain LLM wrapper, all loaders
- [ ] Rebuild ChromaDB vector store; verify counts

## Reference
\`Notebooks/Instructions_for_Implementing_RAG_with_VolleyBall_Dataset.md\` — Notebook 3, Sections 1–7" \
  "notebook-3,infrastructure" "$M3"

add "[N3] Advanced CSV Analysis Tool (LangChain + pandas)" \
"## Overview
Build \`create_advanced_csv_analyzer(csv_path)\` returning a LangChain \`Tool\` with pandas-powered time-series, comparison, aggregation, and filtering analysis.

## Deliverables
- [ ] \`analyze_csv(query)\` routing to ≥4 branch types
- [ ] LangChain \`Tool\` wrapper returned from factory function

## Reference
\`Notebooks/Instructions_for_Implementing_RAG_with_VolleyBall_Dataset.md\` — Challenge 12 (Section 8)" \
  "notebook-3,agent,csv-analysis" "$M3"

add "[N3] Agent V1: Basic Vector Retriever" \
"## Overview
Build baseline \`agent_v1_executor\` (LangChain ReAct) using top-5 vector similarity search.

## Deliverables
- [ ] \`basic_volleyball_retriever(query)\` → formatted doc excerpts
- [ ] \`Tool\` wrapper; \`AgentExecutor\` with \`max_iterations=5\`

## Reference
\`Notebooks/Instructions_for_Implementing_RAG_with_VolleyBall_Dataset.md\` — Section 9 (Agent V1)" \
  "notebook-3,retrieval" "$M3"

add "[N3] Agent V2: Hypothetical Question Expansion" \
"## Overview
Implement \`generate_volleyball_hypothetical_questions()\` and wrap into \`agent_v2_executor\` for broader retrieval coverage.

## Deliverables
- [ ] LLM generates 2 related questions per input
- [ ] Retrieves for original + generated, de-duplicates
- [ ] \`agent_v2_executor\` using expanded retrieval tool

## Reference
\`Notebooks/Instructions_for_Implementing_RAG_with_VolleyBall_Dataset.md\` — Challenge 13 (Section 10)" \
  "notebook-3,retrieval" "$M3"

add "[N3] Agent V3: BM25 + Vector Hybrid Search" \
"## Overview
Implement \`EnsembleRetriever\` (BM25 0.4 + vector 0.6) and wrap into \`agent_v3_executor\`.

## Deliverables
- [ ] \`BM25Retriever\` with \`k=5\` + vector retriever
- [ ] \`EnsembleRetriever\` with weights [0.4, 0.6]
- [ ] \`agent_v3_executor\`

## Reference
\`Notebooks/Instructions_for_Implementing_RAG_with_VolleyBall_Dataset.md\` — Challenge 14 (Section 11)" \
  "notebook-3,retrieval" "$M3"

add "[N3] Agent V4: Cross-Encoder Re-Ranking" \
"## Overview
Add cross-encoder re-ranking on top of hybrid retrieval; wrap into \`agent_v4_executor\`.

## Deliverables
- [ ] Load \`CrossEncoder('cross-encoder/ms-marco-MiniLM-L-6-v2')\`
- [ ] Retrieve 10 candidates, score all, return top-5 re-ranked
- [ ] \`agent_v4_executor\`

## Reference
\`Notebooks/Instructions_for_Implementing_RAG_with_VolleyBall_Dataset.md\` — Challenge 15 (Section 12)" \
  "notebook-3,retrieval" "$M3"

add "[N3] Agent V5: LLM Contextual Compression" \
"## Overview
Wrap hybrid retriever with \`ContextualCompressionRetriever\`; build \`agent_v5_executor\` with compression + CSV tools.

## Deliverables
- [ ] \`LLMChainExtractor\` compressor
- [ ] \`ContextualCompressionRetriever\`
- [ ] \`agent_v5_executor\` with tools: \`[compression_tool_v5, advanced_csv_tool]\`, \`max_iterations=10\`

## Reference
\`Notebooks/Instructions_for_Implementing_RAG_with_VolleyBall_Dataset.md\` — Challenge 16 (Section 13)" \
  "notebook-3,retrieval" "$M3"

add "[N3] Comparative Agent Testing (V1 → V5)" \
"## Overview
Run V1–V5 on 3 test queries (simple / medium / complex) and compare outputs side-by-side.

## Deliverables
- [ ] \`compare_agent_performance(query_dict)\` running all 5 versions
- [ ] Test all 3 query complexity levels; print truncated answers

## Reference
\`Notebooks/Instructions_for_Implementing_RAG_with_VolleyBall_Dataset.md\` — Challenge 17 (Section 14)" \
  "notebook-3,evaluation" "$M3"

add "[N3] KPI Evaluation: Quality Metrics + Performance Trade-offs" \
"## Overview
Implement quality evaluators (groundedness, context relevance, answer relevance) and execution-time KPI; compare V1, V3, V5 on 5 queries.

## Deliverables
- [ ] Three \`evaluate_*()\` functions each returning \`{score, explanation, metric}\`
- [ ] \`evaluate_agent_with_kpis()\` timing + evaluating each agent
- [ ] \`compare_agents_comprehensive()\` → \`pd.DataFrame\` saved to CSV
- [ ] Print: average scores, quality-per-second, best performers by complexity

## Reference
\`Notebooks/Instructions_for_Implementing_RAG_with_VolleyBall_Dataset.md\` — Challenge 17B (Section 14B)" \
  "notebook-3,evaluation" "$M3"

add "[N3] Cross-Document Reasoning Queries" \
"## Overview
Test Agent V5 with 3 complex queries requiring synthesis across CSV stats, rules, and lesson plans.

## Deliverables
- [ ] All 3 queries complete; each answer integrates ≥2 document types
- [ ] Verbose output shows tool selection rationale

## Reference
\`Notebooks/Instructions_for_Implementing_RAG_with_VolleyBall_Dataset.md\` — Challenge 18 (Section 15)" \
  "notebook-3,retrieval,evaluation" "$M3"

add "[N3] Intelligent Metadata Filtering" \
"## Overview
Implement \`intelligent_filtered_retrieval(query)\` that auto-selects metadata filters from query keywords; wrap as LangChain Tool.

## Deliverables
- [ ] Auto-filters for volleyball format, source type, competition level
- [ ] Demo with 3 queries; log applied filters
- [ ] Falls back to unfiltered retrieval when no keywords detected

## Reference
\`Notebooks/Instructions_for_Implementing_RAG_with_VolleyBall_Dataset.md\` — Challenge 19 (Section 16)" \
  "notebook-3,retrieval" "$M3"

echo ""
echo "✅ Created/found ${#ISSUE_NUMBERS[@]} issues: ${ISSUE_NUMBERS[*]}"

# ── 4. GitHub Project v2 ──────────────────────────────────────────────────────
if [ "$SKIP_PROJECT" = true ]; then
  echo ""
  echo "Skipping GitHub Project v2 creation (--skip-project)"
  exit 0
fi

if [ -z "$PROJECT_TOKEN" ]; then
  echo ""
  echo "⚠️  PROJECT_TOKEN not set — skipping GitHub Project v2 creation."
  echo ""
  echo "To also create the project board:"
  echo "  1. Create a GitHub Personal Access Token with the 'project' OAuth scope"
  echo "  2. Re-run:  PROJECT_TOKEN=ghp_xxx bash scripts/create_rag_project.sh"
  exit 0
fi

echo ""
echo "Creating GitHub Project v2…"
OWNER="${REPO%%/*}"

OWNER_ID=$(GH_TOKEN="$PROJECT_TOKEN" gh api graphql \
  -f query='query($login:String!){user(login:$login){id}}' \
  -f login="$OWNER" \
  --jq '.data.user.id')

PROJECT_DATA=$(GH_TOKEN="$PROJECT_TOKEN" gh api graphql -f query='
  mutation($owner: String!, $title: String!) {
    createProjectV2(input: {ownerId: $owner, title: $title}) {
      projectV2 { id number url }
    }
  }' \
  -f owner="$OWNER_ID" \
  -f title="VolleyBall RAG Implementation" \
  --jq '.data.createProjectV2.projectV2')

PROJECT_ID=$(echo "$PROJECT_DATA" | jq -r '.id')
PROJECT_URL=$(echo "$PROJECT_DATA" | jq -r '.url')
echo "  Project URL: $PROJECT_URL"

# Add Notebook single-select field
GH_TOKEN="$PROJECT_TOKEN" gh api graphql -f query='
  mutation($projectId: ID!, $name: String!, $dataType: ProjectV2CustomFieldType!) {
    createProjectV2Field(input: {projectId: $projectId, name: $name, dataType: $dataType}) {
      projectV2Field { ... on ProjectV2SingleSelectField { id } }
    }
  }' \
  -f projectId="$PROJECT_ID" -f name="Notebook" -f dataType="SINGLE_SELECT" >/dev/null 2>&1 || true

# Add all issues to the project
echo "Adding ${#ISSUE_NUMBERS[@]} issues to project…"
ADDED=0
for NUM in "${ISSUE_NUMBERS[@]}"; do
  ISSUE_NODE_ID=$(gh api "repos/$REPO/issues/$NUM" --jq '.node_id' 2>/dev/null || true)
  if [ -n "$ISSUE_NODE_ID" ]; then
    GH_TOKEN="$PROJECT_TOKEN" gh api graphql -f query='
      mutation($projectId: ID!, $contentId: ID!) {
        addProjectV2ItemById(input: {projectId: $projectId, contentId: $contentId}) {
          item { id }
        }
      }' \
      -f projectId="$PROJECT_ID" -f contentId="$ISSUE_NODE_ID" >/dev/null 2>&1 && ADDED=$((ADDED+1)) || true
  fi
done

echo ""
echo "════════════════════════════════════════════════"
echo " VolleyBall RAG — Setup Complete"
echo "════════════════════════════════════════════════"
echo " Issues:  ${#ISSUE_NUMBERS[@]}"
echo " Project: $PROJECT_URL"
echo " Added to project: $ADDED / ${#ISSUE_NUMBERS[@]}"
echo "════════════════════════════════════════════════"
