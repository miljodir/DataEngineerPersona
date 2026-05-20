# Contributing

Thank you for your interest in this project! Pull requests, issues, and feedback are welcome.

This project follows the standard Microsoft / Azure-Samples contribution model.

## Contributor License Agreement

This project welcomes contributions and suggestions. Most contributions require you to agree to a Contributor License Agreement (CLA) declaring that you have the right to, and actually do, grant us the rights to use your contribution. For details, visit [https://cla.opensource.microsoft.com](https://cla.opensource.microsoft.com).

When you submit a pull request, a CLA bot will automatically determine whether you need to provide a CLA and decorate the PR appropriately (status check, comment). Simply follow the instructions provided by the bot. You will only need to do this once across all repos using our CLA.

## Code of Conduct

This project has adopted the [Microsoft Open Source Code of Conduct](https://opensource.microsoft.com/codeofconduct/). For more information see the [Code of Conduct FAQ](https://opensource.microsoft.com/codeofconduct/faq/) or contact [opencode@microsoft.com](mailto:opencode@microsoft.com) with any additional questions or comments.

## How to contribute

1. **Fork** the repository and create a topic branch from `main`.
2. **Open the project in Codespaces or the dev container** — this is the supported development environment.
3. **Make your change.** Keep PRs small and focused.
4. **Run the smoke test locally** before pushing:
   ```bash
   wsl zsh -c "scripts/setup-local-env.sh"
   wsl zsh -c "scripts/migrate-data.sh"
   ```
5. **Open a pull request** using the PR template. Link any related issues.

### What kinds of contributions are most useful?

- Bug fixes in the bash scripts (cross-platform issues, edge cases).
- New T-SQL → PL/pgSQL translation patterns in [reference/tsql-to-plpgsql-cheatsheet.md](reference/tsql-to-plpgsql-cheatsheet.md).
- Additional pgtap tests in [tests/pgtap/t/](tests/pgtap/t/).
- Additional security or performance tests in [tests/security/t/](tests/security/t/) and [tests/performance/t/](tests/performance/t/).
- Improvements to the dev container or one-click experience.

### What is out of scope?

- Application-layer changes (this is a database-layer migration accelerator).
- Changes that would require commercial support contracts to use the sample.
- Anything that breaks the one-click Codespaces experience.

## Style

- **Bash:** `set -euo pipefail`, LF line endings (enforced via [.gitattributes](.gitattributes)), POSIX-portable where reasonable.
- **SQL:** lowercase keywords for PostgreSQL, snake_case identifiers in target.
- **Markdown:** GitHub-flavored, reference links over inline.
- **Commit messages:** present tense, imperative mood (`add`, `fix`, `refactor`).
