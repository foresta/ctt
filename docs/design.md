# ctt Design Document

**Status**: Draft
**Author**: foresta
**Last updated**: 2026-05-15
**Project**: [foresta/ctt](https://github.com/foresta/ctt)

---

## 1. Summary

ctt を「単一の Claude Code セッションを最短で起動するツール」から、「並列エージェント工場 + 大局レビュー支援ツール」へ進化させる。中核となるのは Strategic Review Document Agent ── 完了したタスクをアーキテクチャ・抽象度・依存関係の観点で評価し、人間レビュアー(あなた)の認知負荷を最小化する資料を自動生成する仕組み。

設計は段階的昇格 (個人 phase → チーム展開) を前提とし、初期はリポジトリへの汚染ゼロで個人運用、`ctt promote` コマンドで選択的にチームに昇格できる。

---

## 2. Problem Statement

現状の ctt は worktree + tmux + neovim + Claude Code の起動を自動化するが、以下の構造的な課題が残る。

**並列開発の bottleneck**: モノレポでタスク同士が依存しているため、人間 (開発者本人) が依存解決と context 伝搬を担い、結果として並列度が上がらない。Agent は「いま何が ready か」を自律的に判断できる外部メモリを持たない。

**同期型の認知負荷**: neovim 上で生成されるコードを読みながら開発しているため、agent のスループットを活かしきれない。Claude のコード品質が「個別最適化」に偏り、全体アーキテクチャから逆算する判断が agent 単独では困難。

**ハーネス層の不足**: CLAUDE.md による prompt-level の制約は 70-90% しか遵守されない (HumanLayer 2026)。決定論的に強制する Conformance 層 (Hooks, fitness functions) が未整備のため、agent の出力品質に揺らぎが残る。

**レビューの重力がコードレベルに偏在**: 既存の AI レビューツールは全て「コードレベルの review」を扱い、開発者が本当に脳のサイクルを使いたい「アーキテクチャ、構造、抽象度、依存関係」の大局レビューを準備する agent は存在しない。

---

## 3. Goals / Non-Goals

### Goals

- 個人開発者 1 名が、3-5 個の Claude Code エージェントを並列に走らせ、人間は介入と大局レビューに専念できる workflow を実現する。
- Linear のチケットを起点として、agent が読みやすい spec.md を半自動で起草するパイプラインを構築する。
- タスク完了時に Strategic Review Document を自動生成し、PR レビューの認知負荷を 1/5 程度に圧縮する。
- 個人 phase ではリポジトリへの汚染をゼロに保ち、`ctt promote` でチーム展開時に選択的に昇格できる。
- 既存の ctt の使い勝手 (`ctt new`, `ctt ls`, `ctt done`) を破壊せず、加算的に機能を追加する。

### Non-Goals

- Linear との完全双方向同期は目指さない。ctt は Linear を主に read-only で扱う。
- 20+ agent を同時に走らせる Gas Town 級のスケールは目指さない (3-5 agent 規模が target)。
- async coding agent (Codex Cloud, Claude Code for web) との統合は Phase 5 以降のオプション。最初は同期型 worktree 中心。
- Strategic Review Agent が「自動修正」まで踏み込むことはしない。人間の判断を必須とする。
- マルチプラットフォーム対応 (Windows) は当面非対象。macOS/Linux のみ。

---

## 4. Design Principles

実装中の判断に迷ったときに参照する原則。

**P1. 個人 phase ファースト**: 全ての機能は、まず個人運用で完結すること。チーム機能は後付け。

**P2. リポジトリ汚染ゼロ**: 個人 phase で git status を変えるファイルを 1 つも作らない。`ctt promote` で初めて commit 対象が生まれる。

**P3. フィードバックは早い層で**: PostToolUse Hook (ms) > pre-commit (s) > CI (min) > human review (h) の順で押し下げる。

**P4. Prompt よりも Hook**: 「これを必ず守って」と CLAUDE.md に書くのは 70-90% の遵守率。決定論的に強制したいことは Hook で書く。

**P5. メモリは外に出す**: タスクの依存関係、進捗、決定ログを agent の context ではなく Beads / spec.md / LEARNINGS.md に外出しする。Session は使い捨て。

**P6. 引用可能性の強制**: AI が出すレビュー資料は全て「コードの該当行への引用付き」を必須とする。幻覚への防御。

**P7. 1 ページ制約**: Strategic Review Document は 80 行以内、各セクション 5 行以内。読まれない資料は無価値。

**P8. オプショナリティの保持**: ctt を使わないチームメンバーが影響を受けないこと。個人 hack はチーム展開後も user-scope に隔離可能。

---

## 5. Architecture Overview

ctt は次の 3 つのレイヤーで構成される。

```
┌─────────────────────────────────────────────────────────────┐
│  Interface Layer                                            │
│  - CLI commands (ctt new, watch, promote, spec, ...)        │
│  - Neovim plugin (ctt.nvim: :CttSpec, :CttNew, :CttAsk)    │
│  - TUI dashboard (ctt watch)                                │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│  Orchestration Layer                                        │
│  - Configuration resolver (3-layer cascade)                 │
│  - Beads (task dependency store)                            │
│  - Worktree lifecycle manager                               │
│  - Intervention queue (4 detectors)                         │
│  - Review pipeline coordinator (Stage A/B/C)                │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│  Execution Layer (per worktree)                             │
│  - Claude Code session (with injected .claude/settings)     │
│  - PostToolUse / Stop hooks (language-specific)             │
│  - Sub-agents (spec-drafter, code-reviewer × 5, strategic)  │
└─────────────────────────────────────────────────────────────┘
```

### Configuration Layout

```
~/.config/ctt/                          # User-scope (個人 phase の中心)
├── ctt.toml                            # グローバル設定
├── hooks/<language>/                   # 言語別 hook テンプレート
├── skills/                             # 共通 skill
├── agents/                             # spec-drafter.md, strategic-reviewer.md など
└── projects/<repo-id>/                 # リポジトリ別の個人設定
    ├── project.toml
    ├── constitution.md
    ├── adr/
    ├── specs/features/<task-id>/
    └── beads/

<repo>/                                 # Repository (チーム展開時のみ)
├── .ctt/project.toml                   # 個人 phase ではここに置かない
├── docs/architecture.md                # 昇格時の constitution
└── docs/adr/                           # 昇格時の ADR

<worktree>/                             # ctt new で動的生成、gitignore
└── .claude/settings.json               # 言語別 hook を動的合成
```

**Lookup cascade** (`project.toml` を例に):

1. `<cwd>/.ctt/project.toml`
2. `~/.config/ctt/projects/<repo-id>/project.toml`
3. なければ `ctt init --personal` を促す

`<repo-id>` は `git remote get-url origin` の URL を slug 化 (例: `github.com_foresta_ctt`)。remote がない場合は `.git/config` に UUID を埋める。

---

## 6. Component Design

### 6.1. Configuration System

**Responsibility**: 設定のロード、cascade 解決、worktree への動的注入。

**Key data structures**:

```toml
# project.toml
[project]
name = "my-monorepo"
constitution = "./docs/architecture.md"   # or "@personal/constitution.md"
adr_dir = "./docs/adr"

[languages]
typescript = { paths = ["packages/web", "packages/api"] }
python = { paths = ["services/ml"] }

[commands]
test = "pnpm test"                        # 必須
typecheck = "pnpm typecheck"
format = "pnpm format"
test_python = "uv run pytest"             # 言語別オーバーライド

[harness]
preset = "balanced"                       # strict / balanced / loose
auto_review = true
max_retries = 3
token_budget_per_task = 50000

[linear]
team = "ENG"
workspace_id = "..."
```

**Implementation notes**:

- Config resolver は MoonBit で型付き構造体として実装。`Result<Config, ConfigError>` を返す。
- `@personal/` prefix は user-scope への明示的参照。promote 後も個人設定を維持する手段。
- `test_<language>` のオーバーライドは monorepo 対応の核。

### 6.2. Spec Drafting Agent

**Responsibility**: Linear ticket と個人指示を入力に、agent 向けの spec.md を起草する。

**Trigger**: `:CttSpec --from-linear LIN-123` (neovim) または `ctt spec new --from-linear LIN-123` (CLI)。

**Workflow**:

1. Linear MCP で ticket を fetch (title, description, comments, labels, parent project)
2. Codebase を探索 (ticket 内の固有名詞で grep、関連ファイル特定)
3. constitution.md と関連 ADR を読み込む
4. Neovim に追加指示用のプロンプトバッファを開く → ユーザーが implementation hint を書く
5. 全入力を元に spec.md を起草:
   - What: 達成すべきこと
   - Why: ビジネス的・技術的理由
   - What NOT to build: 明示的な非目標 (Zencoder 原則)
   - Affected layers: 触るレイヤーの宣言
   - Acceptance criteria: 検証可能な完了条件
   - References: 関連ファイル・既存パターン
6. Linear ticket に spec.md への link を 1 コメント書き戻す

**Output location**: `~/.config/ctt/projects/<repo-id>/specs/features/<branch-name>/spec.md`

**Promotion target** (チーム展開時): `<repo>/.specify/features/<branch-name>/spec.md`

### 6.3. Beads (Task Dependency Store)

**Responsibility**: タスクの依存グラフを保持し、「ready なタスク」を agent と人間に提供する。

**Choice**: Beads (Steve Yegge) または beads_rust (Dicklesworthstone) を依存として取り込む。MoonBit でゼロから書く選択肢もあるが、既に成熟した実装を借りる方が ROI 高い。

**Storage location**: `~/.config/ctt/projects/<repo-id>/beads/` (個人 phase) → 必要なら `<repo>/.beads/` に昇格。

**Key operations**:

- `bd create "task title" --depends-on <other-id> --epic <epic-id>`
- `bd ready` → 着手可能なタスクの列挙
- `bd close <id>` → タスク完了
- `bd graph` → 依存グラフの可視化

**ctt integration**:

- `ctt new --task <bead-id>` で worktree 起動時に該当 bead を `in_progress` に
- `ctt done` で `closed` に
- `ctt watch` で `ready` リストを表示

### 6.4. Harness Layer

**Responsibility**: Constraints / Conformance / Knowledge の 3 層 (Martin Fowler 2026) を実装する。

#### 6.4.1. Hook Templates (Conformance)

Language-scoped hooks under `~/.config/ctt/hooks/<language>/`:

**TypeScript** (`~/.config/ctt/hooks/typescript/post-tool-use.json`):

```json
{
  "PostToolUse": [{
    "matcher": "Write|Edit|MultiEdit",
    "filePattern": "*.ts|*.tsx|*.js|*.jsx",
    "hooks": [
      { "type": "command", "command": "biome check --apply $CLAUDE_FILE_PATH" },
      { "type": "command", "command": "tsc --noEmit -p . 2>&1 | head -20" }
    ]
  }]
}
```

**Python** (`~/.config/ctt/hooks/python/post-tool-use.json`):

```json
{
  "PostToolUse": [{
    "matcher": "Write|Edit|MultiEdit",
    "filePattern": "*.py",
    "hooks": [
      { "type": "command", "command": "uvx ruff check --fix $CLAUDE_FILE_PATH" },
      { "type": "command", "command": "uvx mypy $CLAUDE_FILE_PATH" }
    ]
  }]
}
```

**Performance constraint**: PostToolUse hook の合計実行時間は **500ms 以内**。重い処理は Stop hook へ。

#### 6.4.2. Dynamic Settings Injection

`ctt new` 時に project.toml の `[languages]` を読み、該当する hook テンプレートを worktree の `.claude/settings.json` にマージして書き出す。worktree 削除時に消滅。

#### 6.4.3. Fitness Functions

`<repo>/.ctt/fitness/` または `~/.config/ctt/projects/<id>/fitness/` に配置:

- `no_cross_layer_imports.test.ts` (presentation → infra の直接参照を禁止)
- `no_circular_dependency.test.ts`
- `file_size_limit.test.ts` (500 行超で警告)
- `naming_convention.test.ts`

実行は pre-commit hook で。ArchUnitTS, archlint など既存ツールを採用。

#### 6.4.4. Constitution (Knowledge)

`~/.config/ctt/projects/<id>/constitution.md` (個人 phase) → `<repo>/docs/architecture.md` (昇格後)。

最大 1 ページ。内容:

- Mission: このプロジェクトが解決する問題
- Tech stack: 使用言語・主要ライブラリ
- Non-negotiables: 絶対に守るべき 5 原則
- Tabboos: 絶対にやってはいけないこと 3 つ
- Module boundaries: 主要モジュールの責務と依存方向

### 6.5. Monitoring Dashboard (`ctt watch`)

**Responsibility**: 並走中の worktree の状態を一目で把握できる TUI。

**Display elements**:

| Column | Description |
|--------|-------------|
| Status | working / waiting-input / waiting-review / blocked / done (色分け) |
| Task | bead ID + 短いタイトル |
| Worktree | branch name |
| Context % | Claude session の token 使用率 (50% 黄、80% 赤) |
| Last activity | 最後の tool 呼び出し + 1 行出力 |
| Cost | 累積 token 使用量と推定コスト |

**Side panel**:

- Intervention queue (後述、4 categories)
- Beads dependency graph (current epic)
- Token budget vs spent (this month)

**Implementation choice**: ratatui-rs (Rust) または bubbletea (Go) を subprocess として shell out するのが現実的。MoonBit で raw TUI を書くのは時期尚早。

### 6.6. Intervention Queue

**Responsibility**: 「人間の介入が必要な状態」を 4 種類のカテゴリで検出し、優先度付きキューで提示する。

| Category | Detection Method | Response |
|----------|------------------|----------|
| A. Permission prompt | PermissionRequest hook + tmux pane grep | 即座に通知、自動承認候補なら提案 |
| B. Clarification request | Custom tool `request-human-input` 呼び出し | キューに積む |
| C. Silent stall | pane output が 60 秒以上停止 | 「見にいきますか?」と prompt |
| D. Loop detected | 同一ファイル 4 回連続編集、同一テスト 3 回失敗 | session kill + queue 行き |

**Notification**: macOS は `terminal-notifier`、Linux は `notify-send`、optional でスマホへ ntfy.sh。

### 6.7. Review Pipeline (3 Stages)

タスク完了 (Stop hook 発火) 時に走る 3 段階パイプライン。

#### Stage A: Mechanical Review (秒オーダー)

- format / lint / type-check / test の結果を集計
- 失敗時は agent に再投入して自動修正 (max 3 retries)
- 上限超過で human queue 行き
- Cost guard: token_budget_per_task を超えたら即停止

#### Stage B: Code-level AI Review (分オーダー)

5 並列サブエージェント (GENDA zenn 記事の構成を流用):

- `code-quality-reviewer`
- `performance-reviewer`
- `test-coverage-reviewer`
- `documentation-accuracy-reviewer`
- `security-code-reviewer`

各 reviewer は独立 context window、結果をインラインコメントとして diff に注釈。

**自動修正の条件**:

- 修正範囲が spec で宣言された affected_layers 内
- diff のサイズが現在 PR の 20% 以内
- max 2 iterations

超過は human queue 行き。

#### Stage C: Strategic Review Document Generation (10 分オーダー)

詳細は次セクション。

### 6.8. Strategic Review Agent (CORE FEATURE)

**Responsibility**: タスク完了後の diff を「アーキテクチャ、構造、抽象度、依存関係」の観点で評価し、人間レビュアーが PR の大局判断を 5 分で下せる資料を生成する。

**Input**:

- Task の完成 diff (`git diff main...feature-branch`)
- 元の spec.md
- constitution.md
- 関連する ADR (`*.md` from `adr_dir`)
- LEARNINGS.md (実装中に agent が書き残した気づき)
- 依存グラフ (静的解析: `pnpm why`, `cargo tree`, または madge 等)

**Output**: `~/.config/ctt/projects/<id>/reviews/<task-id>/strategic.md` (または昇格後 `<repo>/.ctt/reviews/...`)

**Template** (1 ページ厳守):

```markdown
# Strategic Review: <Task Name>

## 0. Inferred Spec (spec.md が無い場合のみ)
- agent が diff から推測した「何を作ろうとしていたか」

## 1. Spec Compliance
- [✓] 要件 X を満たす (file:line)
- [✓] 要件 Y を満たす (file:line)
- [△] 要件 Z は部分達成 (file:line) — 理由
- [!] Spec で除外宣言した A に踏み込んでいる (file:line)

## 2. Architectural Impact
- 触ったレイヤー: presentation / domain / infra
- レイヤー間の依存:
  - 新規: domain → infra (constitution の依存方向と一致 ✓ / 違反 ✗)
- 境界の曖昧化: <file:line に短いコメント>

## 3. Abstraction Level Audit
- 新規抽象: `BillingPortalService` (file:line)
  - 責務: ...
  - なぜ必要か: <agent の推測>
  - 既存の類似抽象との重複懸念: `PaymentService` と類似度 60%
- 「1 回限りの抽象」と思われる箇所: <file:line>

## 4. Dependency Changes
- 新規外部依存: `stripe@14.2.0` (Stripe SDK)
  - 代替: 既に `@stripe/api-client@13.0` があるが採用しなかった理由 (推測)
- 内部依存の方向変化: (Mermaid before/after)
- 循環依存検出: なし / あり (file)

## 5. Pattern Consistency
- 命名: 既存 ServiceXxx 流 / 違反 (file:line)
- エラーハンドリング: Result 型 / try-catch 混在 (file:line)
- ロギング: 既存 logger 利用 / console.log 混入 (file:line)

## 6. Decision Log
- 実装中の重要判断 (LEARNINGS.md より抽出):
  - 1. Stripe Customer Portal を採用 (alt: 自作 UI を却下、理由: ...)
  - 2. ...

## 7. Reviewer Hot Spots (Top 5)
1. `apps/web/services/billing.ts:42` — 新規抽象の妥当性
2. `apps/web/api/webhook.ts:118` — 既存パターンからの逸脱
3. `packages/shared/types.ts:7` — 型定義の漏洩懸念
4. `migrations/2026-05-15.sql` — schema 変更の互換性
5. `apps/web/components/Subscribe.tsx:200` — UI 状態管理の複雑性
```

**Critical constraints**:

- 全ての主張に **file:line の引用が必須** (幻覚抑制)
- Document 全体で **80 行以内** (各セクション 5 行以内)
- 引用先は git blame で実在を検証する (内部チェック)

**Writer/Reviewer pattern**: 生成後、別 Claude session に「この document に見落としは?」と投げる second pass を実行。信頼性向上 (Anthropic internal practice)。

**PR description への埋め込み**: Section 1, 2, 7 のみを PR description 冒頭に展開、残りは `.ctt/reviews/<task>/strategic.md` へのリンクで参照。

### 6.9. Neovim Integration (`ctt.nvim`)

**Commands**:

| Command | Description |
|---------|-------------|
| `:CttSpec [--from-linear <id>]` | Spec drafting agent を起動、バッファに spec を開く |
| `:CttPlan` | 開いている spec から実装計画を生成、Beads に投入 |
| `:CttNew [<bead-id>]` | タスクを worktree で起動 |
| `:CttDispatch` | Beads から `ready` を選んで投入 (telescope 連携) |
| `:CttWatch` | TUI dashboard を tmux pane で開く |
| `:CttAsk <question>` | 現在の worktree context で Claude に質問 |
| `:CttReview <task-id>` | Strategic Review Document をバッファに開く |
| `:CttPromote` | チーム展開モードへの昇格対話を開始 |

**PR review**: octo.nvim 連携で、PR description から Strategic Review Document に jump できる仕組み。

### 6.10. Promotion Workflow (`ctt promote`)

**Trigger**: ユーザーが個人 phase で十分な確信を得たタイミングで手動実行。

**Interactive flow**:

```
$ ctt promote

Detected personal phase in ~/.config/ctt/projects/github.com_foresta_repo/

Select items to promote to the repository:

[x] project.toml         → .ctt/project.toml
[x] constitution.md      → docs/architecture.md  (推奨: docs 配下)
[ ] adr/                 → docs/adr/             (推奨: docs 配下)
[x] hooks/typescript/    → .ctt/hooks/typescript/ (個人カスタムのみ)
[ ] specs/               → 個人ノートとして user-scope に保持
[ ] beads/               → 個人運用継続

Continue? [y/N]
```

**Post-promotion**:

- 選択されたファイルをリポジトリにコピー
- `.gitignore` に `.claude/` を追加 (worktree の動的設定が漏れないように)
- `git add` 候補としてユーザーに提示 (実際の commit はしない)
- 昇格しなかった項目は user-scope に残し、`project.toml` から `@personal/` で参照

---

## 7. User Workflows

### 7.1. 新タスクの開始

```
1. Linear で ticket LIN-123 を作成 (普段の運用)
2. neovim で :CttSpec --from-linear LIN-123
3. spec drafting agent が起動、bufferに spec ドラフトと QUESTION コメント
4. ユーザーが「認証は既存 AuthService に乗せる」等の指示を追記
5. :w で spec.md 確定
6. :CttPlan で実装計画とタスク分解、Beads に投入
7. :CttDispatch で ready なタスクを選択、worktree 起動
8. 別タスクの spec 起草に移る (並列化)
9. ctt watch で進捗監視、介入待ちは notification で通知
```

### 7.2. レビュー待ちの対応

```
1. Stage A/B が完了したタスクが review queue に入る
2. notification を受け取る
3. neovim で :CttReview <task-id>
4. Strategic Review Document が開く (80 行)
5. Section 1, 7 で大局確認 (1-2 分)
6. 気になる箇所は :CttAsk "なぜこの抽象を導入した?" で対話
7. 承認なら :CttDone <task-id> で PR 作成
8. 修正必要なら spec を更新して再投入
```

### 7.3. 個人 phase → チーム展開

```
1. 3 ヶ月運用、constitution と spec template が定常状態に
2. ctt promote 実行
3. 選択的に repo にコピー、git status を確認
4. PR で「ctt 設定を導入」とチームに提案
5. チームの議論で constitution.md を共同編集
6. ctt 非使用メンバーは .ctt/project.toml を無視して通常開発を継続
```

---

## 8. Implementation Phases

各 phase は週単位の目安。MoonBit での実装速度や Claude Code に委譲する範囲で前後する。

### Phase 1: Harness Foundation (Week 1-2)

**Goal**: 個別最適化を抑える土台を確立。

- [ ] `ctt init --personal` コマンド (user-scope ディレクトリ作成 + 自動言語検出)
- [ ] Configuration resolver (3-layer cascade)
- [ ] Language-specific hook templates (TypeScript, Python, MoonBit を最初に)
- [ ] `ctt new` の拡張: 動的な `.claude/settings.json` 注入
- [ ] constitution.md テンプレートと起草フロー

**Exit criteria**: PostToolUse Hook で format/lint が確実に走る、constitution.md がある状態で agent が起動。

### Phase 2: Task Dependency & Spec Drafting (Week 3-4)

**Goal**: 並列化の前提となる依存解決と spec ベース運用。

- [ ] Beads (または br) を依存として取り込み、user-scope に統合
- [ ] `ctt new --depends-on` フラグ
- [ ] Spec Drafting Agent (Linear MCP 連携)
- [ ] `:CttSpec` neovim plugin (最小実装)
- [ ] `ctt ready` コマンド (着手可能タスクの列挙)

**Exit criteria**: Linear ticket から spec.md → tasks → 並列 worktree への線が通る。

### Phase 3: Monitoring & Intervention (Week 5-6)

**Goal**: 並列タスクを「見える化」して人間 bottleneck を減らす。

- [ ] `ctt watch` TUI (ratatui-rs を subprocess で起動)
- [ ] Intervention queue の 4 detectors
- [ ] Notification 連携 (terminal-notifier / notify-send)
- [ ] Stage A: 自動 retry ループ (max_retries, token_budget_per_task)

**Exit criteria**: 3 タスク並走中、停止/介入待ちが notification で届く。

### Phase 4: Code Review Pipeline (Week 7-8)

**Goal**: Stage A/B でコードレベルの瑕疵を agent が潰す。

- [ ] Stage B: 5 並列 reviewer サブエージェント (Claude Code Action 構成を流用)
- [ ] インラインコメント生成 (GitHub MCP 連携)
- [ ] Spec 逸脱判定ロジック (affected_layers 比較)

**Exit criteria**: 完了タスクで Stage B が走り、人間が見るべきコメントだけ残る。

### Phase 5: Strategic Review Agent (Week 9-12) — CORE

**Goal**: 大局レビュー資料の自動生成。ctt の独自性の核。

- [ ] Strategic Review Agent の prompt 設計
- [ ] Input gathering (diff, spec, constitution, ADR, LEARNINGS, dependency graph)
- [ ] Template-driven output generation
- [ ] 引用検証ロジック (git blame で実在チェック)
- [ ] Writer/Reviewer second pass
- [ ] PR description への自動埋め込み
- [ ] `:CttReview` neovim 統合

**Exit criteria**: 完了タスクで Strategic Review Document が生成され、PR を 5 分で大局判断できる。

### Phase 6: Polish & Promotion (Week 13+)

- [ ] `ctt promote` 対話的フロー
- [ ] `@personal/` prefix の resolver 対応
- [ ] octo.nvim 連携 (PR review 環境)
- [ ] Async path: Claude Code for web への投入 (`ctt new --async`)
- [ ] Mobile dashboard (tailscale + minimal web UI)

---

## 9. Risks & Mitigations

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| Credit 暴走 (自動修正ループ) | High | High | max_retries / token_budget_per_task を Stage A/B で強制。月次 budget の hard cap。 |
| Strategic Review Agent の幻覚 | High | High | 引用必須 (file:line) + git blame 検証 + writer/reviewer second pass |
| Review document が読まれない | Medium | High | 80 行制約、Section 1+7 を PR description に強制埋め込み |
| Hook の合計実行時間が長い | Medium | Medium | PostToolUse は 500ms 上限、超えるものは Stop hook に逃がす |
| Linear MCP の不安定 | Medium | Medium | spec 起草は Linear なしでも完結可能なフォールバック |
| Beads と Linear の二重管理 | Medium | Low | Beads は agent 用、Linear は人間用に役割を厳格化 |
| マシン間同期忘れ | Low | Medium | `ctt doctor` で user-scope の health check、dotfiles 連携の推奨 |
| MoonBit エコシステムの不足 | Medium | Low | TUI / heavy 処理は subprocess (ratatui-rs, Beads) を呼ぶ |

---

## 10. Open Questions

実装中に判断が必要、現時点では未確定の項目。

**Q1**: Beads と Linear の同期は最終的にどこまでやるか?

現状の方針は「最小限」(spec link 1 回 + epic 完了サマリ 1 回) だが、運用してみると Linear に進捗が見えなくて困る可能性がある。Phase 5 完了時に再評価。

**Q2**: Strategic Review Agent のモデル選択は固定か可変か?

Opus を使うとコスト高、Sonnet では精度不足の懸念。Phase 5 で両方試して decision rule を決める。

**Q3**: monorepo 横断の Strategic Review はどう扱う?

複数 package に影響する変更で、依存方向が package 境界を跨ぐ場合。初期は package ごとに個別 review を生成し、上位 summary を出すアプローチで様子見。

**Q4**: ctt 自体の dogfooding をどう設計するか?

ctt の開発に ctt を使う際、ctt の constitution と spec を ctt 自身で管理することになる。再帰構造の運用方法は実装してみないと分からない。

**Q5**: チーム展開時の constitution 共同編集はどう促すか?

`ctt promote` 後、個人が書いた constitution はチームと議論し直しになる。draft.md として置くオプションは入れたが、議論の触媒となる仕組みがあると良い。

---

## 11. Appendix

### A. Slash Command Reference (CLI)

```
ctt init --personal              # 個人 phase で初期化
ctt new [task-id]                # タスクを worktree で起動
ctt new --depends-on <id>        # 依存を明示して起動
ctt new --async                  # Claude Code for web に投入 (Phase 6+)
ctt ls                           # 進行中タスク一覧
ctt status [--all]               # 状態詳細
ctt ready                        # 着手可能タスクの列挙 (Beads)
ctt watch                        # TUI dashboard
ctt spec new --from-linear <id>  # Spec 起草
ctt spec plan <spec-path>        # 実装計画とタスク分解
ctt review <task-id>             # Strategic Review Document を表示
ctt done <task-id>               # タスク完了、PR 作成
ctt promote                      # チーム展開への昇格
ctt doctor                       # 設定 health check
ctt version
```

### B. Neovim Plugin Commands (`ctt.nvim`)

```vim
:CttInit                         " 個人 phase 初期化
:CttSpec [--from-linear <id>]
:CttPlan
:CttNew [<bead-id>]
:CttDispatch                     " telescope で ready から選択
:CttWatch                        " TUI を tmux pane で
:CttAsk <question>
:CttReview <task-id>
:CttDone <task-id>
:CttPromote
```

### C. Project.toml Full Schema

```toml
[project]
name = "string"
description = "string"
constitution = "path"             # 相対 path or @personal/
adr_dir = "path"

[languages.<lang>]
paths = ["path", ...]             # monorepo の対象ディレクトリ

[commands]
test = "string"                   # 必須
typecheck = "string"
format = "string"
test_<lang> = "string"            # 言語別オーバーライド

[harness]
preset = "strict | balanced | loose"
auto_review = true | false
max_retries = 3                   # Stage A
token_budget_per_task = 50000
monthly_budget = 1000000          # hard cap

[review]
strategic_review_model = "opus | sonnet"
require_quote_verification = true

[linear]
team = "string"
workspace_id = "string"

[promotion]
constitution_target = "docs/architecture.md"
adr_target = "docs/adr"
hooks_target = ".ctt/hooks"
```

### D. References & Prior Art

- **Geoffrey Huntley** — Ralph Loop, six-month recap, harness engineering writings
- **Steve Yegge** — Beads, Gas Town, Developer Agent Evolution Model
- **Damian Galarza** — "Building a Linear-Driven Agent Loop with Claude Code" (2026-02)
- **Martin Fowler** — "Harness engineering for coding agent users" (2026-04)
- **HumanLayer** — "Writing a good CLAUDE.md", "Skill Issue: Harness Engineering"
- **Sakasegawa** — "Harness Engineering Best Practices for Claude Code/Codex Users 2026"
- **Anthropic** — "Effective harnesses for long-running agents", "Claude Code Best Practices"
- **GitHub Spec Kit** — Spec-driven development toolkit
- **raine/workmux** — git worktrees + tmux 並列開発 OSS (ctt の同類)
- **ComposioHQ/agent-orchestrator** — CI 失敗自動修正、レビュー対応 orchestrator
- **GENDA (zenn)** — 5 並列 PR レビューの実装例

### E. Glossary

- **Harness**: AI agent を生成的モデルから「ship できるシステム」に変換する scaffold 全体 (制約、フィードバック、制御の仕組み)
- **Constitution**: プロジェクトの不変原則を記述した 1 ページのドキュメント
- **Spec**: agent 向けに書かれた、機能ごとの「何を/なぜ/何をしないか」
- **Bead**: Beads システムにおける単一タスクの単位
- **Epic**: 複数の Bead を束ねた上位タスク
- **Worktree**: git worktree。並列開発の物理的隔離
- **Promotion**: 個人 phase の設定をチームリポジトリに昇格すること
- **Stage A/B/C**: レビューパイプラインの 3 段階 (Mechanical / Code-level / Strategic)
- **SDD**: Spec-Driven Development
