---
type: howto
---
## Validate YAML in GitHub Actions

A repository full of YAML config files needs a gate that rejects a broken or off-schema file on any branch, before a human reviews it. [GitHub Actions](https://docs.github.com/en/actions) can run that gate on every push and pull request, and the Python [schema](https://pypi.org/project/schema/) package can hold the rules in a few lines. The workflow lists the YAML files the push changed and hands the list to a script.

### 1. Write the schema and the checker

```python
# .github/validate_yaml.py
import sys
import yaml
from schema import Optional, Regex, Schema, SchemaError

SERVICE = Schema({
    "name": Regex(r"^[a-z][a-z0-9-]*$"),
    "owner": str,
    Optional("environments"): [lambda e: e in ("dev", "qa", "prod")],
    Optional("public"): bool,
})

failed = 0
for path in open(sys.argv[1]).read().split():
    try:
        SERVICE.validate(yaml.safe_load(open(path)))
        print(f"ok    {path}")
    except (yaml.YAMLError, SchemaError) as e:
        failed += 1
        print(f"FAIL  {path}\n{e}")
sys.exit(1 if failed else 0)
```

`yaml.safe_load` fails on bad YAML. `Schema.validate` fails on a missing key, a wrong type, or a value outside the allowed set. The script checks every file before it exits, so one run reports all failures.

### 2. Run it on every push and pull request

```yaml
# .github/workflows/validate-yaml.yml
name: validate-yaml
on: [push, pull_request]
jobs:
  validate:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0
      - run: pip install pyyaml schema
      - name: Validate changed YAML files
        run: |
          if [[ "${{ github.event_name }}" == "pull_request" ]]; then
            BASE="origin/${{ github.base_ref }}"
          else
            BASE="${{ github.event.before }}"
          fi
          [[ "$BASE" =~ ^0+$ ]] && BASE="origin/main"
          LIST=$(mktemp)
          git diff --name-only --diff-filter=d "$BASE" HEAD | grep -E '\.ya?ml$' | grep -v '^\.github/' > "$LIST" || true
          if [[ -s "$LIST" ]]; then python3 .github/validate_yaml.py "$LIST"; else echo "No YAML files changed"; fi
```

- `on: [push, pull_request]` with no branch filter runs the job on every branch.
- `fetch-depth: 0` fetches the full history, so the diff against the base commit works.
- A pull request diffs against the tip of its base branch. A push diffs against the commit before the push.
- A push that creates a branch has an all-zero "before" commit, so it falls back to `main`.
- `--diff-filter=d` skips deleted files. The `.github/` exclusion keeps the workflow files out, since they follow a different schema.

To check every file in the repository instead, replace the `git diff` command with `git ls-files`.

### 3. Which commit the job sees

`github.sha` [depends on the event](https://docs.github.com/en/actions/reference/workflows-and-actions/events-that-trigger-workflows):

- push: the tip commit pushed to the branch.
- pull_request: the merge commit GitHub builds from the pull request onto its base branch.
- workflow_dispatch: the last commit on the branch or tag that received the dispatch.

`actions/checkout` checks out that commit by default. On a pull request the script therefore sees the merged result, not the branch tip alone.
