DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
java -cp $DIR/lib/obvie.jar obvie.Base "$@"
