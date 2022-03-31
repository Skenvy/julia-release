# [julia-release](https://github.com/Skenvy/julia-release)
An action to proctor the CD (release and registering) of a julia project. [![Test](https://github.com/Skenvy/julia-release/actions/workflows/main.yaml/badge.svg?branch=main&event=push)](https://github.com/Skenvy/julia-release/actions/workflows/main.yaml)
#
A github action to automate the release and registration of a Julia package (via the [Registrator](https://github.com/JuliaRegistries/Registrator.jl) bot, so will require it to be installed). It will detect any commit to a designated deployment branch that updates the project version in the required `Project.toml`, and create a release and registration for it.

This is the ideological reverse order of the standard [julia TagBot](https://github.com/JuliaRegistries/TagBot), which creates github releases of commits after _manually_ registering them. Instead, this action, when set up in the recommended way, will, if it detects a change to the `version`, create a release, and comment the `"@JuliaRegistrator register"` command on the commit that it has released, for a _truly continuous_ **deployment strategy**; **_CD_**.
#
## Inputs
### `deployment_branch`
* **Required**
* Name of branch from which against to deploy; e.g. master|main|trunk|other.
### `subdirectory`
* _Optional_
* The path to the folder/subdirectory containing the Pkg's Project.toml.
* Default `"."`.
### `changelog`
* _Optional_
* An optional changelog with which to generate notes in the release.
* Default `""`.
### `release_tag_template`
* _Optional_
* A template to generate the release tag. Exposes "<NEW_VERSION>". ("/" will be replaced with "_"). 
* Default `"v<NEW_VERSION>"`.
### `release_name_template`
* _Optional_
* A template to generate the release name. Exposes "<NEW_VERSION>".
* Default `"Version: <NEW_VERSION>"`.
### `auto_release`
* _Optional_
* Whether to automatically release your new version.
* Default `true`.
### `auto_register`
* _Optional_
* Whether to automatically register your new release.
* Default `true`.
#
## Outputs
### `new_version`
* The new version listed in project.
### `old_version`
* The old version listed in project.
### `diff_from`
* The sha of the "previous head of the deployment branch" that is used to check for a change in the version.
### `diff_to`
* The sha of the commit that is taken as the current ~ which without frobbing the head will be the github_sha.
#
## Example usage
### _Optional:_ The `on:` to use for the workflow
* For a `deployment_branch` of `main`, and a `subdirectory` of `path/to/your`
* Even if you use the default `subdirectory` that is `"."` ~ _the project root_, it's still advised to speficically target `'./Project.toml'` for the workflow, if calling this is it's primary intent, to not over trigger it.
```
on:
  push:
    branches:
    - 'main'
    paths:
    - 'path/to/your/Project.toml'
```
### **Required:** In jobs.<job_id>.runs-on:
* This is a docker job, so you'll need;
```
runs-on: 'ubuntu-latest' # docker jobs not supported on windows or mac
```
### **Required:** In jobs.<job_id>.steps[*]
* Prior to the `uses: Skenvy/julia-release@v1` step, you'll need to checkout with depth 0, as this action checks the diff against older commits. If you _only_ allow squashes, a checkout depth greater than 1 might be ok, although 0 is recommended.
```
- name: 🏁 Checkout
  uses: actions/checkout@v3
  with:
    fetch-depth: 0
```
### In jobs.<job_id>.steps[*].uses:
* For a package project located at the root `./Project.toml`, with the deployment branch being `main`, in the least decorated way;
```
- uses: Skenvy/julia-release@v1
  env:
    GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
  with:
    deployment_branch: 'main'
```
* For a package project located at `./path/to/your/Project.toml`, with optionally more verbose release tag and name, and a pretty step name.
```
- name: Julia 🔴🟢🟣 Release 🚰 and Register 📦
  uses: Skenvy/julia-release@v1
  id: release_step
  env:
    GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
  with:
    deployment_branch: 'main'
    subdirectory: "path/to/your"
    release_tag_template: "julia-v<NEW_VERSION>"
    release_name_template: "Julia: Version <NEW_VERSION>"
```
* Although "registering" via the [Registrator](https://github.com/JuliaRegistries/Registrator.jl) bot is a primary intent of this, if you simply want to automate releases, but _not_ automate the registration, you can prevent the registrator comment with;
```
- uses: Skenvy/julia-release@v1
  ...
  with:
    ...
    auto_register: false
```
* If you are restrictive about which actions you're happy to supply your `$GITHUB_TOKEN` to, the release and registration can _both_ be disallowed, while still setting outputs to be used elsewhere of `${{ steps.julia_release.outputs.<OUTPUT_NAME> }}` for the outputs mentioned above of `new_version`, `old_version`, `diff_from`, and `diff_to`;
```
- uses: Skenvy/julia-release@v1
  id: julia_release
  with:
    deployment_branch: 'main'
    auto_release: false
    auto_register: false
```
#
## A full example
### The CD workflow ~ `./.github/workflows/julia-build.yaml`
* For a deployment branch `main`, with a project in a subdir `subdir`.
* Assumes the existence of a `./.github/workflows/julia-test.yaml`
```
name: Julia 🔴🟢🟣 Test 🦂 Release 🚰 and Register 📦
on:
  push:
    branches:
    - 'main'
    paths:
    # The project toml contains _more_ than _just_ the version, but updating it would reflect
    # a logical update to the project which semantically _should_ include a version update.
    - 'subdir/Project.toml'
  workflow_dispatch:
defaults:
  run:
    working-directory: subdir
jobs:
  test:
    name: Julia 🔴🟢🟣 Test 🦂
    uses: ./.github/workflows/julia-test.yaml
  release-and-register:
    name: Julia 🔴🟢🟣 Release 🚰 and Register 📦
    needs: [test]
    runs-on: ubuntu-latest
    steps:
    - name: 🏁 Checkout
      uses: actions/checkout@v3
      with:
        fetch-depth: 0
    - name: Julia 🔴🟢🟣 Release 🚰 and Register 📦
      uses: Skenvy/julia-release@v1
      id: release_step
      env:
        GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
      with:
        deployment_branch: 'main'
        subdirectory: "subdir"
        release_tag_template: "julia-v<NEW_VERSION>"
        release_name_template: "Julia: Version <NEW_VERSION>"
```
### The CI workflow ~ `./.github/workflows/julia-test.yaml`
* For a deployment branch `main`, with a project `MyProject` in a subdir `subdir`.
```
name: Julia 🔴🟢🟣 Tests 🦂
on:
  push:
    branches-ignore:
    - 'main'
    # Ignoring the only branch that triggers the build which calls this with it's own push
    # context via workflow call below will stop double runs of the full step. But we do still
    # need conditions on main's HEAD ref for each job as the callee workflow sends a push event.
    paths:
    - 'subdir/**'
    - '.github/workflows/julia-*'
  pull_request:
    branches:
    - 'main'
    paths:
    - 'subdir/**'
    - '.github/workflows/julia-*'
  workflow_call: # To be called by build, on a push to main that ups the version
  # Although this is an event itself - and the event payload is the same as the callee,
  # the "event_name" is _also_ the same. The event's in the callee are push and workflow_dispatch.
defaults:
  run:
    shell: bash
    working-directory: subdir
jobs:
  quick-test:
    name: Julia 🔴🟢🟣 Quick Test 🦂
    if: ${{ github.event_name == 'push' && !(github.event.ref == 'refs/heads/main') }}
    runs-on: ubuntu-latest
    steps:
    - name: 🏁 Checkout
      uses: actions/checkout@v3
    - name: 🔴🟢🟣 Set up Julia
      uses: julia-actions/setup-julia@v1.6
      with:
        version: '1.2.0' # The [compat].julia version in subdir/Project.toml
        arch: 'x64'
    - name: 🧱 Install build dependencies
      run: |
        rm -rf docs/build/
        rm -rf docs/site/
        rm -f deps/build.log
        rm -f Manifest.toml
        rm -f */Manifest.toml
        julia --project=. -e "import Pkg; Pkg.resolve(); Pkg.instantiate();"
        julia --project=test -e "import Pkg; Pkg.resolve(); Pkg.instantiate();"
        julia --project=docs -e "import Pkg; Pkg.develop(Pkg.PackageSpec(path=pwd())); Pkg.resolve(); Pkg.instantiate();"
    - name: 🦂 Test
      run: julia --project=. -e "import Pkg; Pkg.test();"
  full-test:
    name: Julia 🔴🟢🟣 Full Test 🦂
    if: >- 
      ${{ github.event_name == 'pull_request' ||
      github.event_name == 'workflow_dispatch' ||
      (github.event_name == 'push' && github.event.ref == 'refs/heads/main') }}
    runs-on: '${{ matrix.os }}'
    strategy:
      fail-fast: false
      matrix:
        # From versions in https://julialang-s3.julialang.org/bin/versions.json
        version: ['1', 'nightly', '1.2.0'] # '1.2.0' is The [compat].julia version in subdir/Project.toml
        os: [ubuntu-latest, macOS-latest, windows-latest]
        arch: [x64]
    steps:
    - name: 🏁 Checkout
      uses: actions/checkout@v3
    - name: 🔴🟢🟣 Set up Julia ${{ matrix.version }}
      uses: julia-actions/setup-julia@v1.6
      with:
        version: ${{ matrix.version }}
        arch: ${{ matrix.arch }}
    - name: 🧰 Cache
      uses: actions/cache@v1
      env:
        cache-name: cache-artifacts
      with:
        path: ~/.julia/artifacts
        key: ${{ runner.os }}-test-${{ env.cache-name }}-${{ hashFiles('**/Project.toml') }}
        restore-keys: |
          ${{ runner.os }}-test-${{ env.cache-name }}-
          ${{ runner.os }}-test-
          ${{ runner.os }}-
    - name: 🧱 Build
      uses: julia-actions/julia-buildpkg@v1.2
      with:
        project: subdir
    - name: 🦂 Test
      uses: julia-actions/julia-runtest@v1.7
      with:
        project: subdir
  docs:
    name: Julia 🔴🟢🟣 Docs 📄
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v3
    - uses: julia-actions/setup-julia@v1.6
      with:
        version: '1'
    - run: julia --project=docs -e "using Documenter: doctest; using MyProject; doctest(MyProject)"
```
