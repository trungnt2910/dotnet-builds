#!/bin/bash -e

GITHUB_SERVER_URL="https://github.com"
GITHUB_API_URL="https://api.github.com"
GITHUB_REPOSITORY="trungnt2910/dotnet-builds"

for i in "$@"
do
case $i in
    --architecture=*)
    ARCHITECTURE="${i#*=}"
    shift # past argument=value
    ;;
    --install-dir=*)
    INSTALL_DIR="${i#*=}"
    shift # past argument=value
    ;;
    -h|--help)
    echo "Usage: dotnet-install.sh [options]"
    echo ""
    echo "Options:"
    echo "  --architecture=<architecture>  Architecture of .NET to install"
    echo "  --install-dir=<path>           Path where .NET will be installed"
    echo "  -h|--help                      Display this help message"
    exit 0
    ;;
    *)
            # unknown option
    echo "Unknown option: $i"
    exit 1
    ;;
esac
done

if [ -z "$ARCHITECTURE" ]; then
    ARCHITECTURE=$(getarch)
    if [ "$ARCHITECTURE" == "x86_64" ]; then
        ARCHITECTURE="x64"
    fi
fi

if [ -z "$INSTALL_DIR" ]; then
    INSTALL_DIR=".dotnet"
fi

latestRev=""
releaseUrl="$GITHUB_SERVER_URL/$GITHUB_REPOSITORY/releases/tag/net"
pageNum=1

while [ -z "$latestRev" ];
do
    json=$(curl -s $GITHUB_API_URL/repos/$GITHUB_REPOSITORY/releases?page=$pageNum)
    pageNum=$((pageNum + 1))
    if [ $(echo $json | jq length) -eq 0 ]; then
        # This means that we've passed the end and reached an empty array
        break
    fi
    if [ $(echo $json | jq 'objects // {} | has("message")') == "true" ]; then
        # API has return an error object
        echo "Unable to fetch releases from GitHub API"
        exit 2
    fi
    # Store array of revisions
    revisions=($(echo $json | jq -e -r ".[] | .html_url | select(contains(\"Release\") and contains(\"$ARCHITECTURE\"))[${#releaseUrl}:]")) \
        || continue
    latestRev=${revisions[0]}
done

if [ -z "$latestRev" ]; then
    echo "Unable to find a .NET release for $ARCHITECTURE"
    exit 3
fi

installUrl="$GITHUB_SERVER_URL/$GITHUB_REPOSITORY/releases/download/net$latestRev/net$latestRev.tar.gz"

echo "Installing .NET from $installUrl..."

rm -rf $INSTALL_DIR
mkdir -p $INSTALL_DIR

curl -sL $installUrl | tar -xz -C $INSTALL_DIR

# See https://discuss.haiku-os.org/t/gsoc-2023-net-port/13237/39 for more details
addattr SYS:ENV "DOTNET_SYSTEM_NET_DISABLEIPV6=1\\0COMPlus_EnableWriteXorExecute=0" $INSTALL_DIR/dotnet
