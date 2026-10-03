#!/usr/bin/env bash
# Fills the __COMMITS__ / __PRS__ / __CONTRIBS__ placeholders in readme.source.md
# with live numbers from GitHub's GraphQL API. Runs in CI before readme-aura.
# Local use: GH_TOKEN=$(gh auth token) bash .github/scripts/inject-stats.sh ziad-aboughaleb /tmp/preview.md
set -uo pipefail
LOGIN="${1:-ziad-aboughaleb}"
FILE="${2:-readme.source.md}"

QUERY='query($login:String!){user(login:$login){
  contributionsCollection{totalCommitContributions totalPullRequestContributions}
  repositoriesContributedTo(first:1,contributionTypes:[COMMIT,ISSUE,PULL_REQUEST,REPOSITORY]){totalCount}
}}'

JQ='[.data.user.contributionsCollection.totalCommitContributions,
     .data.user.contributionsCollection.totalPullRequestContributions,
     .data.user.repositoriesContributedTo.totalCount] | map(tostring) | join(" ")'

OUT="$(gh api graphql -f login="$LOGIN" -f query="$QUERY" --jq "$JQ" 2>/dev/null || true)"
read -r COMMITS PRS CONTRIBS <<<"$OUT"

# Anything that is not a plain number (API error, null) becomes a dash, so a
# placeholder token can never end up on the public profile.
for v in COMMITS PRS CONTRIBS; do
  [[ "${!v:-}" =~ ^[0-9]+$ ]] || printf -v "$v" '%s' '-'
done

sed -i "s/__COMMITS__/$COMMITS/g; s/__PRS__/$PRS/g; s/__CONTRIBS__/$CONTRIBS/g" "$FILE"
echo "Injected: commits=$COMMITS prs=$PRS contributed_to=$CONTRIBS"
