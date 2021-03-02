# Fetch GH Release Asset

This action downloads multiple assets from a GitHub release. Private repos are supported.

## Inputs

### `repo` - optional

The `org/repo`. Defaults to the current repo.

### `version` - optional
The release version to fetch from. Default `"latest"`. If not `"latest"`, this has to be in the form `tags/<tag_name>` or `<release_id>`.

### `file` - required
Pattern of the files in the release to download (regex)

### `token` - optional
Personal Access Token to access repository. You need to either specify this or use the ``secrets.GITHUB_TOKEN`` environment variable. Note that if you are working with a private repository, you cannot use the default ``secrets.GITHUB_TOKEN`` - you have to set up a [personal access token with at least the scope org:hook](https://github.com/dsaltares/fetch-gh-release-asset/issues/10#issuecomment-668665447).

### `path` - optional
Output path for the downloaded files.

## Outputs

### `version`
The version number of the release tag. Can be used to deploy for example to itch.io

## Example usage

```yaml
uses: Itsblue/download-release-assets-action@v1
with:
  repo: "linuxmuster/linuxmuster-linbo-gui"
  version: "latest"
  file: "*.zip"
  token: ${{ secrets.YOUR_TOKEN }}
  path: "./assets"
```
