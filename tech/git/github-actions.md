---
type: reference
---
## Github Actions
Two quick examples of Github Actions workflow jobs. They both generate releases of the current repo, which is a Go binary. One does it automatically, the other manually:

### Workflow Automatic Run

```yaml
name: release-automatically

# on:
#   push:
#     tags:
#       - 'v*'
#   workflow_dispatch:    

permissions:
  contents: write # Allow workflow to create releases

jobs:
  release-automatically:
    runs-on: ubuntu-latest
    steps:
      - name: checkout_github_action_code
        uses: actions/checkout@v4
        with:
          ref: ${{ github.ref }}

      - name: setup_go_environment
        uses: actions/setup-go@v5
        with:
          go-version: '1.22.0'

      - name: build_artifact
        run: |
          if [[ "$(uname -m)" != "x86_64" ]]; then
            echo "Error. This runner Linux image is not x86_64/amd64!"
            exit 1
          fi
          export ProgramName=$(head -1 go.mod | awk -F'/' '{print $NF}' | awk '{print $NF}')
          GOOS=linux
          GOARCH=amd64
          BinaryName=${ProgramName}-${GOOS}-${GOARCH}
          echo "BinaryName=${BinaryName}" >> $GITHUB_ENV
          go build -ldflags "-s -w" -o $BinaryName
          tar czvf ${BinaryName}.tgz $BinaryName

      - name: create_release
        id: create_release
        uses: actions/create-release@v1
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
        with:
          tag_name: ${{ github.ref_name }}
          release_name: Release ${{ github.ref_name }}
          draft: false
          prerelease: false
          body: 'Release ${{ github.ref_name }}'

      - name: upload_release_assets
        uses: actions/upload-release-asset@v1
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
          # Above is provided by Actions, you do not need to create your own token
        with:
          upload_url: ${{ steps.create_release.outputs.upload_url }}
          # Above is the upload URL for the release
          asset_path: ${{ env.BinaryName }}.tgz
          asset_name: ${{ env.BinaryName }}.tgz
          asset_content_type: application/gzip
```          

### Workflow Manual Run

```yaml
name: release-manually

on:
  workflow_dispatch:
    inputs:
      tag_name:
        description: 'Input tag version to release'     
        required: true              
        type: string

permissions:
  contents: write # Allow workflow to create releases

jobs:
  release-manually:
    runs-on: ubuntu-latest
    steps:
      - name: checkout_github_action_code
        uses: actions/checkout@v4
        with:
          ref: ${{ github.event.inputs.tag_name }}

      - name: setup_go_environment
        uses: actions/setup-go@v5
        with:
          go-version: '1.22.0'

      - name: build_artifact
        run: |
          printf "==> Now running within a CONTAINER!"
          printf "==> lsb_release -a\n"
          lsb_release -a
          printf "==> cat /etc/os-release\n"
          cat /etc/os-release

          if [[ "$(uname -m)" != "x86_64" ]]; then
            echo "Error. This runner Linux image is not x86_64/amd64!"
            exit 1
          fi
          export ProgramName=$(head -1 go.mod | awk -F'/' '{print $NF}' | awk '{print $NF}')
          GOOS=linux
          GOARCH=amd64
          BinaryName=${ProgramName}-${GOOS}-${GOARCH}
          echo "BinaryName=${BinaryName}" >> $GITHUB_ENV
          go build -ldflags "-s -w" -o $BinaryName
          tar czvf ${BinaryName}.tgz $BinaryName

      - name: create_release
        id: create_release
        uses: actions/create-release@v1
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
          # Above is provided by Actions, you do not need to create your own token
        with:
          tag_name: ${{ github.event.inputs.tag_name }}
          release_name: Release ${{ github.event.inputs.tag_name }}
          draft: false
          prerelease: false
          body: 'Release ${{ github.event.inputs.tag_name }}'

      - name: upload_release_assets
        uses: actions/upload-release-asset@v1
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
        with:
          upload_url: ${{ steps.create_release.outputs.upload_url }}
          # Above is the upload URL for the release
          asset_path: ${{ env.BinaryName }}.tgz
          asset_name: ${{ env.BinaryName }}.tgz
          asset_content_type: application/gzip
```

### See also
- [Validate YAML in GitHub Actions](validate-yaml.md): a job that checks the YAML files a push changed against a schema.
