#!/usr/bin/env bash
# https://docs.github.com/en/actions/using-workflows/workflow-commands-for-github-actions
# https://docs.github.com/en/actions/creating-actions/setting-exit-codes-for-actions
set -euxo pipefail

# Sanity in
MAIN_BRANCH="$INPUT_DEPLOYMENT_BRANCH"
SUBDIR="$INPUT_SUBDIRECTORY"
PROJECT_FILE="$SUBDIR/Project.toml"
HEAD=$(git rev-parse HEAD)
echo "::notice::Targetting $PROJECT_FILE in branch $MAIN_BRANCH, on SHA $HEAD"

# We need to update the local ref/heads of $MAIN
# (while this SHOULD be run only against a HEAD _on_ $MAIN, it's not guarenteed)
# After the below, the ref should now include a local $MAIN ~ # git show-ref
set +e
git fetch origin $MAIN_BRANCH:$MAIN_BRANCH
set -e
# If only running on a push to $MAIN, this fetch above will trigger an error of --
# fatal: Refusing to fetch into current branch refs/heads/main of non-bare repository
# which is not an issue to running this ~ although needed to supply a ref for the below
# rev-parse to identify the top commit on it, which is then handled by the intentional exit below
MAIN=$(git rev-parse $MAIN_BRANCH)
# A push against the deployment branch would make the HEAD commit the same commit as the head of MAIN.
# HEAD here is the same as GITHUB_SHA, so this is also confirming that there's no race condition on too many quick commits to MAIN
# HEAD would be the same as GITHUB_SHA, if the HEAD is not frobbed prior to starting the action. HEAD is used here _rather than_ GITHUB_SHA to allow testing via frobbing.
[ "$HEAD" != "$MAIN" ] && echo "::error::HEAD, $HEAD, is NOT the HEAD of $MAIN_BRANCH, $MAIN. Can only deploy from deployment_branch, which is configured to $MAIN_BRANCH" && exit 1

# Otherwise, get the project diff
PREVIOUS_MAIN=$(git rev-parse $MAIN^1)
SHA_DIFF="$PREVIOUS_MAIN..$HEAD"
echo "::notice::The 'previous main'..'current_head' diff is $SHA_DIFF"
echo "::set-output name=diff_from::$PREVIOUS_MAIN"
echo "::set-output name=diff_to::$HEAD"
set +u
PROJECT_DIFF=$(git diff $SHA_DIFF $PROJECT_FILE)
[ "$PROJECT_DIFF" == "" ] && echo "::warning::The diff $SHA_DIFF has no lines in $PROJECT_FILE, so ending the action." && exit 0

# And use it to capture the version diff, if it exists.
# Re-allow pipefail ~ intentionally setting a warning if the result is empty.
set +o pipefail
OLD_VERSION="$(echo "$PROJECT_DIFF" | grep -e "^-version = " | cut -d \" -f 2)"
if [ "$OLD_VERSION" != "" ]; then
    echo "::notice::OLD VERSION IS $OLD_VERSION"
    echo "::set-output name=old_version::$OLD_VERSION"
else
    echo "::warning::The diff $SHA_DIFF has no line that matches \"^-version = \" (old version) in $PROJECT_FILE; allowing the action to continue to find a new version."
    echo "::set-output name=old_version::0.0.0"
fi
NEW_VERSION="$(echo "$PROJECT_DIFF" | grep -e "^+version = " | cut -d \" -f 2)"
if [ "$NEW_VERSION" == "" ]; then
    echo "::warning::The diff $SHA_DIFF has no line that matches \"^+version = \" (new version) in $PROJECT_FILE, so ending the action."
    exit 0
else
    echo "::notice::NEW VERSION IS $NEW_VERSION"
    echo "::set-output name=new_version::$NEW_VERSION"
fi
set -uo pipefail

# Both the release and registration comment require the GITHUB_TOKEN to be provided,
# but the above git operations do not, so both the release and registration are wrapped in optional
# but default true arguments, that can be disabled, in case for some reason, someone would want to
# use this without providing their GITHUB_TOKEN to a potentially "untrusted" action -- but the
# action will still yield the "new_release" and "old_release" outputs to be used with the github
# published actions that release / comment.

# Release
if [ "$INPUT_AUTO_RELEASE" == "true" ]; then
    # Get the relevant inputs for creating a release at $HEAD
    CHANGELOG="$INPUT_CHANGELOG"
    RELEASE_TAG_TEMPLATE="$INPUT_RELEASE_TAG_TEMPLATE"
    RELEASE_NAME_TEMPLATE="$INPUT_RELEASE_NAME_TEMPLATE"
    # Sanitise the inputs
    [ "$CHANGELOG" == "" ] && CHANGELOG="--generate-notes" || CHANGELOG="-F $CHANGELOG"
    RELEASE_TAG_TEMPLATE=$(echo "$RELEASE_TAG_TEMPLATE" | sed "s/<NEW_VERSION>/$NEW_VERSION/g; s|/|_|g;")
    RELEASE_NAME_TEMPLATE=$(echo "$RELEASE_NAME_TEMPLATE" | sed "s/<NEW_VERSION>/$NEW_VERSION/g;")
    echo "::notice::gh release create $RELEASE_TAG_TEMPLATE $CHANGELOG $RELEASE_NAME_TEMPLATE"
    gh release create "$RELEASE_TAG_TEMPLATE" "$CHANGELOG" -t "$RELEASE_NAME_TEMPLATE"
else
    echo "::warning::Option \"auto_release\" is not the default true, so the release was not published."
fi

# Now we've released, tag the commit to summon registrator.
REGDIR=""
[ "$SUBDIR" != "." ] && REGDIR="subdir=$SUBDIR"
REGISTRATOR_COMMENT="@JuliaRegistrator register branch=$MAIN_BRANCH $REGDIR"
API="repos/$GITHUB_REPOSITORY/commits/$HEAD/comments"
echo "::notice::Registrating with \"$REGISTRATOR_COMMENT\" to $API"
if [ "$INPUT_AUTO_REGISTER" == "true" ]; then
    gh api "$API" -f body="$REGISTRATOR_COMMENT"
else
    echo "::warning::Option \"auto_register\" is not the default true, so the register comment was not written."
fi
