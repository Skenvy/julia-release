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
### The `on:` to use for the workflow
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
### In jobs.<job_id>.runs-on:
* This is a docker job, so you'll need;
```
runs-on: 'ubuntu-latest' # docker jobs not supported on windows or mac
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
