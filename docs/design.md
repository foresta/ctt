# 非対話モードの設計

`ctt new` / `open` / `done` / `status` を引数だけで実行できるようにする。引数が足りない段だけ
従来どおり fzf とプロンプトに落ちるので、人の使い方は変わらない。エージェントからの利用を
想定し、終了コードと出力も整える。

## インターフェース

```
ctt new  --repo <名前|パス> --branch <既存ブランチ> [--no-focus]
ctt new  --repo <名前|パス> --branch <新ブランチ> --base <元ブランチ> [--no-focus]
ctt open <repo>__<branch> [--no-focus]
ctt done <repo>__<branch> --yes [--delete-branch]
ctt status [--all | <repo>__<branch>]
```

| 引数 | 意味 |
|---|---|
| `--repo` | workspace（`$HOME/work`）配下のリポジトリ。ディレクトリ名か絶対パス。名前が複数に一致したらエラーにしてパスを要求する |
| `--branch` | `--base` 無し: 既存ブランチを checkout（無ければエラー）。`--base` あり: そのブランチから新規作成 |
| `--no-focus` | workspace を作るだけで focus しない |
| `--yes` | `done` の削除確認を省略する |
| `--delete-branch` | `done` でローカルブランチも削除する。`git branch -d` のみで、未マージなら警告して残す |

### 振る舞いの決め事

- `--branch` 指定時に worktree が既にあれば、そのブランチの worktree であることを確かめたうえで確認せず再利用する。`new` は冪等で、「開く」と同じ意味になる
- `--yes` は削除確認だけに効く。ブランチ削除は `--delete-branch` を付けたときだけ行う
- 終了コードは成功 0、エラーまたはキャンセル（fzf を抜けた、`N` と答えた）は 1
- `new` / `open` は最後に `Worktree: <path>` を 1 行出す
- 未知のサブコマンドと `--xxx` はエラーにする（終了コード 1）
- tmux モードで tmux の外から `--no-focus` を指定したときは、nvim を前面で起動せずエラーにする

## 部品と受け渡すデータ

```
argv ─▶ cli.parse ─▶ CommandInput { command : Command } ─▶ commands.dispatch ─▶ &Runnable
                                                                                  │ run()
                                            interpreter.run ◀── CommandResult ◀───┘
                                                  │ Bool（成功か）
                                            main ─▶ exit(0 | 1)
```

### `Command`（`src/commands/command.mbt`）

引数の解釈は `cli` パッケージに閉じ、`commands` は型付きのオプションだけを受け取る。

```moonbit
pub(all) struct NewOptions    { repo : String?; branch : String?; base : String?; focus : Bool }
pub(all) struct OpenOptions   { name : String?; focus : Bool }
pub(all) struct DoneOptions   { name : String?; yes : Bool; delete_branch : Bool }
pub(all) struct StatusOptions { all : Bool; name : String? }

pub(all) enum Command {
  Ls
  Open(OpenOptions)
  Status(StatusOptions)
  Done(DoneOptions)
  New(NewOptions)
  Help
  Version
  Usage(String)   // 引数エラー。メッセージを表示して exit 1
}
```

### 引数解析（`src/cli/args.mbt`）

- 共通の字句解析が `--key value` / `--key=value` / flag / positional を分ける。値を取るオプションと
  flag の許可リストはサブコマンドごとに持ち、リストに無いものは `unknown option` にする
- サブコマンドごとの組み立て関数が `Scanned` から各 `Options` を作る。失敗は `Command::Usage(msg)`

### `WorkspaceManager::open` の `focus`（`src/ports/workspace.mbt`）

`open(repo_name~, branch~, workdir~, continue_session~, focus~)` に `focus : Bool` を足す。

- herdr: `focus=false` なら `workspace focus` を呼ばない。既存ラベルを見つけた場合も同様
- tmux: `focus=false` なら `new-window -d`。既存 window があれば `select-window` を省略

### `NewCommand` の段取り（`src/commands/sub_commands/new.mbt`）

回答済みの段は `Select` などを作らず、直接次の段を呼ぶ。

```
run
 ├ repo 未指定 → Select(repos) → with_repo
 └ repo 指定   → resolve_repo(repos, query) → with_repo / Error
with_repo(repo_dir)
 ├ branch 未指定            → Select(branches) → Menu（checkout / 新規作成）→ 従来どおり
 ├ branch 指定・base 無し   → branches に無ければ Error。あれば checkout_and_open
 └ branch 指定・base あり   → create_branch_and_open(base_branch=base)
checkout_and_open / create_branch_and_open
 └ worktree 既存: branch が引数指定なら確認なしで link_and_open(continue_session=true)
```

`resolve_repo(repos, query) -> Result[String, String]` は `src/domain/discovery.mbt` の純粋関数。
絶対パスなら候補に含まれるか、名前なら basename の完全一致で引く。0 件・複数件はエラー文に
候補を列挙する。

### `open` / `done` / `status`

`open` / `done` / `status` は共通の `pick_worktree(worktrees, name?, prompt, k)` で worktree を決める。
`name` があれば一覧から引いて無ければ `Error("worktree not found: x")`、無ければ `Select` に落ちる。

- `done`: `yes` で削除確認を飛ばす。ブランチ削除は `delete_branch` があれば `git branch -d`、
  失敗なら理由を添えて警告し残す。`yes` のみなら残す。どちらも無ければ従来どおり対話
- `status`: `name` があれば 1 件の Table

ブランチ操作（存在確認・削除）は worktree を消す前に `VCS::resolve_git_dir` で得た git dir に対して行う。
worktree 削除後に workdir から解決しようとして失敗していた既存の不具合の修正を兼ねる。

### 終了コード

`interpreter.run` が `Bool` を返す。`Error` と `Cancelled.` に至る分岐が `false`、`Sequence` /
`Then` は AND。`Then` は前段が失敗したら後段を実行しない。`main` は `false` なら `@sys.exit(1)`。設定ファイルや
worktree ディレクトリの検証に失敗したときも 1 で終わる。
