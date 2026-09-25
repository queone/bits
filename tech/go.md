---
type: reference
---
## Go
Useful GoLang bits.

### References
- Useful examples = <https://gobyexample.com/>
- Static analysis = <https://github.com/analysis-tools-dev/static-analysis#go>


### Install Go

Run the install script from the gkit scripts folder. On a Mac with Homebrew it installs or upgrades Go through `brew`. Asking for a specific version, or passing `-a`, uses the official archive instead, which is what happens on Linux and Windows/GitBASH anyway.

```bash
curl -kLo /tmp/install-go.sh https://github.com/queone/gkit/raw/main/scripts/install_go.sh
bash /tmp/install-go.sh            # Install or upgrade to the latest Go ... or
bash /tmp/install-go.sh go1.23.3   # Install this specific version from the archive
bash /tmp/install-go.sh -n         # Dry run: print the plan only

# Root/sudo privilege needed in order to install the archive under `/usr/local/`

# Then update essential system variables (Homebrew manages GOROOT on a Mac)
export GOROOT=/usr/local/go       # Archive installs only
export GOPATH=~/.go               # Create this dir if necessary
export PATH=$PATH:$GOROOT/bin:$GOPATH/bin
```


### Point to Local

While refactoring and troubleshooting code it is sometimes necessary to point to the local version of a package.

You can do this by modifying the `go.mod` file as follows: 

```bash
require (
    github.com/queone/utl v1.0.0
)

replace github.com/queone/utl => /Users/myuser/mycode/utl
```


### Build Issues

1. If you get: 

```bash
$ go build
go: go.mod file not found in current directory or any parent directory; see 'go help modules'
```

Try this 

```bash
go mod init <package_name>   # For example, this would be 'zls' for github.com/queone/<repo>
go mod tidy
```

2. If you get incompatible modules, try `go clean -modcache`
3. You may also want to install `staticcheck` and run: 

```bash
go vet ./...
staticcheck ./...
```

This will check for common code issues.


### Generate Functions Hierarchy Graph
Use `go-callvis` for that: 

```bash
go install github.com/ofabry/go-callvis@latest
go-callvis -focus main ./...
```


### Using `struct{}` for Efficient Maps

To save memory when you need a "set" data structure in Go, use a map whose keys are the set's elements. Make the value type `struct{}`. Why?

- **Zero Memory Overhead**: `struct{}` is an empty struct type in Go, and it occupies **0 bytes of memory**.
- **Efficiency**: By using `struct{}` as the map value, you avoid unnecessary memory consumption compared to using `bool` or other types.
- **Simplicity**: This approach naturally creates a set-like behavior, where only the keys are significant.

For example: 

```go
// Create a set using a map with struct{} as the value type
uniqueIds := make(map[string]struct{})

// You can add some items to the set
uniqueIds["uuid-1"] = struct{}{}
uniqueIds["uuid-2"] = struct{}{}
uniqueIds["uuid-3"] = struct{}{}

for _, i := range someList {
    item := i.(map[string]interface{})  // Assert as JSON object
    resourceId := utl.Str(item["id"])   // Get UUID string value
    
    // Skip processing if this resourceId is already in the set
    if _, seen := uniqueIds[resourceId]; seen {
        fmt.Printf("Id %s has already been seen.\n", resourceId)
        continue
    }

    // Add it to the set (mark it as seen)
    uniqueIds[resourceId] = struct{}{}
}
```


### Reduce Binary Executable Size

To reduce binary executable sizes:
1. Always compile with `-ldflags "-s -w"`
2. And use UPX: 

```bash
brew install upx
upx -9 <binary>
```


### Useful Code Snippets

- Check if field exists in given struct 

```go
func FieldInStruct(Field string, Struct interface{}) bool {
    val := reflect.ValueOf(Struct)
    for i := 1; i < val.Type().NumField(); i++ {
        if val.Type().Field(i).Name == Field {
            return true
        }
    }
    return false
}
```

- Return list of JSON objects in local data file 

```go
func GetListFromLocalFile(storeFile string) interface{} {
    localFile := filepath.Join(progConfDir, storeFile)  // Note progConfDir is global
    JSONData, err := ioutil.ReadFile(localFile)
    if err != nil {
        panic(err)
    }

    switch storeFile {
    case InstanceDataFile:                     // Return list of instance records
        var list []InstanceType
        err = json.Unmarshal(JSONData, &list)
        if err != nil { panic(err) }
        return list
    case DNSDataFile:                          // Return list of DNS records
        var list []ResourceRecordSetType
        err = json.Unmarshal(JSONData, &list)
        if err != nil { panic(err) }
        return list
    case ELBDatafile:                          // Return list of ELB records
        var list []LoadBalancerDescriptionType
        err = json.Unmarshal(JSONData, &list)
        if err != nil { panic(err) }
        return list
    case ZoneDataFile:                         // Return list of zone records
        var list []HostedZoneType
        err = json.Unmarshal(JSONData, &list)
        if err != nil { panic(err) }
        return list
    case StackDataFile:                        // Return list of stack records
        var list []StackType
        err = json.Unmarshal(JSONData, &list)
        if err != nil { panic(err) }
        return list
    default:                                   // Return list of generic JSON records
        var list interface{}
        err = json.Unmarshal(JSONData, &list)
        if err != nil { panic(err) }
        return list
    }
}
```


### Common Makefile

Makefiles are usually not needed with Go, but if you must, this one for macOS and Linux will build target binaries for multiple OSes. 

```makefile
# Makefile
# Assumes GOPATH is already set up properly, e.g., $HOME/.go

default:
GOOS=darwin GOARCH=amd64 go build -ldflags "-s -w" -o build/macos/awsinfo
all:
rm -rf build
mkdir -p build/{macos,centos,windows}
go get -u github.com/aws/aws-sdk-go/...
go get -u github.com/vaughan0/go-ini
GOOS=darwin GOARCH=amd64 go build -ldflags "-s -w" -o build/macos/awsinfo
GOOS=linux GOARCH=amd64 go build -ldflags "-s -w" -o build/centos/awsinfo
GOOS=windows GOARCH=amd64 go build -ldflags "-s -w" -o build/windows/awsinfo.exe

# Modify below target to where you keep your binaries
install:
cp build/macos/awsinfo $(HOME)/bin
clean:
rm -rf build
```
