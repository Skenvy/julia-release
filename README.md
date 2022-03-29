# [julia-release](https://github.com/Skenvy/julia-release)
#### An action to proctor the CD (release and registering) of a julia project.
#
A github action to automate the release of any push to master that updates the project version, and tag its commit with the registrator command (so, requires having installed [Registrator](https://github.com/JuliaRegistries/Registrator.jl)). This is the ideological reverse order of the standard [julia TagBot](https://github.com/JuliaRegistries/TagBot), which creates github releases of commits after _manually_ registering them.
#
## Inputs
### `who-to-greet`
* **Required**
* The name of the person to greet. 
* Default `"World"`.
#
## Outputs
### `time`
* The time we greeted you.
#
## Example usage
```
uses: actions/hello-world-docker-action@v1
with:
  who-to-greet: 'Mona the Octocat'
```
