# Worktree Command

**Description**: Use git worktrees to work on multiple branches simultaneously in separate directories.

## What are Git Worktrees?

Git worktrees allow you to have multiple working directories for the same repository, each checked out to different branches. This enables:

- Working on multiple features in parallel
- Quickly switching context without stashing
- Running tests on different branches simultaneously
- Comparing branches side-by-side
- Reviewing PRs without disturbing your work

## When to Use

Use worktrees when:
- Working on multiple features simultaneously
- Reviewing PRs while keeping your work intact
- Running long-running processes (tests, builds) on different branches
- Comparing implementations across branches
- Hotfixing production while developing features

## Basic Worktree Commands

### Create a New Worktree

```bash
# Create worktree for existing branch
git worktree add ../repo-feature-name feature-name

# Create worktree with new branch
git worktree add -b new-feature ../repo-new-feature

# Create worktree from remote branch
git worktree add ../repo-pr-123 origin/pr-123

# Create temporary worktree (won't create permanent branch)
git worktree add --detach ../repo-temp abc123
```

**Naming convention**:
```bash
# If main repo is at: ~/projects/myapp
# Worktrees at:
#   ~/projects/myapp-feature-auth    (feature branch)
#   ~/projects/myapp-pr-456          (PR review)
#   ~/projects/myapp-hotfix-123      (hotfix)
#   ~/projects/myapp-experiment      (experiments)
```

### List Worktrees

```bash
# List all worktrees
git worktree list

# Output:
# /Users/me/projects/myapp         abc123 [main]
# /Users/me/projects/myapp-auth    def456 [feature/auth]
# /Users/me/projects/myapp-pr-123  ghi789 [pr-123]
```

### Switch to Worktree

```bash
# Just cd into it
cd ../myapp-feature-auth

# Or use a helper function (add to ~/.zshrc)
function gwt() {
  local worktree=$(git worktree list | fzf | awk '{print $1}')
  if [ -n "$worktree" ]; then
    cd "$worktree"
  fi
}
```

### Remove Worktree

```bash
# Remove worktree directory
git worktree remove ../repo-feature-name

# Or delete directory and prune
rm -rf ../repo-feature-name
git worktree prune

# Force remove (with uncommitted changes)
git worktree remove --force ../repo-feature-name
```

### Prune Worktrees

```bash
# Clean up deleted worktree references
git worktree prune

# Show what would be pruned
git worktree prune --dry-run
```

## Common Workflows

### Workflow 1: Feature Development

```bash
# Start new feature
git worktree add -b feature/user-auth ../myapp-auth

cd ../myapp-auth

# Develop feature
npm install
npm test
# ... make changes ...

git add .
git commit -m "feat: add user authentication"

# When done
git push -u origin feature/user-auth

# Create PR
gh pr create

# Return to main repo
cd ../myapp

# Remove worktree when feature merged
git worktree remove ../myapp-auth
```

### Workflow 2: PR Review

```bash
# Fetch PR
gh pr checkout 456

# Or create worktree for PR
git worktree add ../myapp-pr-456 origin/pr-456-branch

cd ../myapp-pr-456

# Install and test
npm install
npm test
npm run dev

# Test the changes, make comments
gh pr review --comment

# Return to main work
cd ../myapp

# Clean up when done reviewing
git worktree remove ../myapp-pr-456
```

### Workflow 3: Hotfix While Developing

```bash
# Currently working on feature in main repo
# Urgent hotfix needed

# Create hotfix worktree from production
git worktree add -b hotfix/critical-bug ../myapp-hotfix origin/main

cd ../myapp-hotfix

# Fix the bug
# ... make changes ...

npm test
git commit -am "fix: critical production bug"
git push -u origin hotfix/critical-bug

# Create PR and get it merged
gh pr create
gh pr merge --auto --squash

# Return to feature work
cd ../myapp

# Continue feature work uninterrupted
# Clean up hotfix worktree later
git worktree remove ../myapp-hotfix
```

### Workflow 4: Parallel Testing

```bash
# Run tests on multiple branches simultaneously

# Main repo - running feature tests
cd ~/projects/myapp
npm test -- --watch &

# Worktree 1 - running integration tests
git worktree add ../myapp-integration origin/main
cd ../myapp-integration
npm run test:integration &

# Worktree 2 - running E2E tests
git worktree add ../myapp-e2e origin/staging
cd ../myapp-e2e
npm run test:e2e &

# All tests running in parallel, different branches
```

### Workflow 5: Comparing Branches

```bash
# Compare implementations side-by-side

# Main repo - new implementation
cd ~/projects/myapp
code src/feature.ts

# Worktree - old implementation
git worktree add ../myapp-compare main^
cd ../myapp-compare
code src/feature.ts

# Use VS Code to compare files side-by-side
code --diff ~/projects/myapp/src/feature.ts ~/projects/myapp-compare/src/feature.ts

# Clean up
git worktree remove ../myapp-compare
```

## Worktree Best Practices

### DO:
✅ Use descriptive worktree directory names
✅ Keep worktrees in a consistent location
✅ Remove worktrees when done
✅ Run `git worktree prune` regularly
✅ Use worktrees for long-running tasks
✅ Create worktrees from remote branches for PRs

### DON'T:
❌ Create too many worktrees (hard to manage)
❌ Forget to remove worktrees (wastes disk space)
❌ Share worktree directories (they're local)
❌ Commit from wrong worktree
❌ Have the same branch checked out in multiple worktrees (not allowed)

## Worktree Management

### Create Organization System

```bash
# Main repo location
~/projects/myapp/

# Worktree locations
~/projects/worktrees/myapp-feature-*
~/projects/worktrees/myapp-pr-*
~/projects/worktrees/myapp-hotfix-*

# Helper function to create organized worktrees
function gwt-new() {
  local branch=$1
  local type=$2  # feature, pr, hotfix
  local repo_name=$(basename $(git rev-parse --show-toplevel))

  local worktree_dir="$HOME/projects/worktrees/${repo_name}-${type}-${branch}"

  git worktree add -b "$type/$branch" "$worktree_dir"
  cd "$worktree_dir"
}

# Usage:
# gwt-new user-auth feature
# Creates: ~/projects/worktrees/myapp-feature-user-auth
# Branch: feature/user-auth
```

### Cleanup Script

```bash
#!/bin/bash
# cleanup-worktrees.sh

# Remove all worktrees that have been merged
git worktree list | tail -n +2 | while read worktree hash branch; do
  branch_name=$(echo $branch | tr -d '[]')

  # Check if branch is merged
  if git branch --merged main | grep -q "$branch_name"; then
    echo "Removing merged worktree: $worktree ($branch_name)"
    git worktree remove "$worktree"
  fi
done

# Prune deleted worktrees
git worktree prune

echo "Worktree cleanup complete!"
```

### List Active Worktrees with Status

```bash
# Add to ~/.zshrc
function gwt-status() {
  echo "Git Worktrees:"
  echo ""

  git worktree list | while read path hash branch; do
    echo "📁 $path"
    echo "   Branch: $branch"

    # Check for uncommitted changes
    cd "$path"
    if [[ -n $(git status --porcelain) ]]; then
      echo "   Status: ⚠️  Uncommitted changes"
    else
      echo "   Status: ✅ Clean"
    fi

    echo ""
  done
}
```

## Worktree + Other Tools

### With tmux/zellij

```bash
# Create tmux session for each worktree
git worktree list | while read path hash branch; do
  session_name=$(basename "$path")
  tmux new-session -d -s "$session_name" -c "$path"
done

# Switch between worktrees with tmux
tmux list-sessions | fzf | cut -d: -f1 | xargs tmux switch-client -t
```

### With VS Code

```bash
# Open worktree in new VS Code window
git worktree list | fzf | awk '{print $1}' | xargs code

# Or create alias
alias gwt-code='git worktree list | fzf | awk "{print \$1}" | xargs code'
```

### With npm/yarn

```bash
# Each worktree has its own node_modules
cd ~/projects/myapp
npm install  # Main repo dependencies

cd ~/projects/myapp-feature
npm install  # Feature dependencies (might differ)

# This is good for:
# - Testing with different dependency versions
# - Avoiding node_modules conflicts
# - Parallel installs
```

## Common Issues and Solutions

### Issue: "fatal: 'branch-name' is already checked out"

**Problem**: Can't checkout same branch in multiple worktrees

**Solution**:
```bash
# Use different branch
git worktree add -b new-branch-name ../repo-new origin/existing-branch

# Or detach
git worktree add --detach ../repo-temp origin/existing-branch
```

### Issue: Disk space usage

**Problem**: Multiple node_modules directories use lots of space

**Solution**:
```bash
# Share node_modules (symlink)
# In worktree:
rm -rf node_modules
ln -s ../main-repo/node_modules node_modules

# Or use pnpm which shares dependencies
pnpm install
```

### Issue: Lost track of worktrees

**Problem**: Created worktrees but forgot where they are

**Solution**:
```bash
# List all worktrees
git worktree list

# Find and clean up
git worktree prune --dry-run
git worktree prune
```

### Issue: Worktree location moved

**Problem**: Moved worktree directory manually

**Solution**:
```bash
# Don't move manually, use git worktree move
git worktree move old-path new-path

# If already moved, prune and re-add
git worktree prune
git worktree add new-path existing-branch
```

## Advanced Worktree Tips

### Bare Repository Setup

For ultimate worktree workflow, use bare repository:

```bash
# Clone as bare repository
git clone --bare git@github.com:user/repo.git ~/projects/repos/myapp.git

# Create main worktree
git worktree add ~/projects/myapp main

# All branches as worktrees
cd ~/projects/repos/myapp.git
git worktree add ~/projects/myapp-develop develop
git worktree add ~/projects/myapp-staging staging

# Benefits:
# - No "main" working directory
# - All branches equal
# - Cleaner organization
```

### Integration with CI/CD

```bash
# Use worktrees for CI parallel jobs
# .github/workflows/test.yml

jobs:
  test:
    strategy:
      matrix:
        node: [16, 18, 20]
    steps:
      - uses: actions/checkout@v3

      - name: Setup Node
        uses: actions/setup-node@v3
        with:
          node-version: ${{ matrix.node }}

      - name: Create worktree for parallel test
        run: |
          git worktree add ../test-${{ matrix.node }}
          cd ../test-${{ matrix.node }}
          npm install
          npm test
```

## Worktree Aliases

Add to `~/.gitconfig`:

```ini
[alias]
  # Create new worktree
  wt = worktree add

  # List worktrees
  wtl = worktree list

  # Remove worktree
  wtr = worktree remove

  # Prune worktrees
  wtp = worktree prune

  # Create worktree from PR
  wt-pr = "!f() { gh pr checkout $1 && git worktree add ../$(basename $(pwd))-pr-$1 pr-$1; }; f"
```

Usage:
```bash
git wt ../repo-feature feature-branch
git wtl
git wtr ../repo-feature
git wtp
```

## Worktree Checklist

Before using worktrees:

- [ ] Understand basic git worktree commands
- [ ] Plan worktree naming convention
- [ ] Set up worktree directory structure
- [ ] Add worktree aliases to git config
- [ ] Create cleanup scripts
- [ ] Integrate with shell (fzf, tmux, etc.)

When creating worktree:

- [ ] Use descriptive directory name
- [ ] Follow naming convention
- [ ] Note the purpose (feature, PR, hotfix)
- [ ] Set up environment (npm install, etc.)

When removing worktree:

- [ ] Commit or stash changes
- [ ] Push branch if needed
- [ ] Remove worktree directory
- [ ] Prune worktree references
- [ ] Delete remote branch if merged

## Integration with Other Commands

- `/plan` - Create worktree for planned work
- `/execute` - Use worktrees for parallel execution
- `/review` - Use worktrees for PR reviews
- `/verify` - Test in isolated worktree
