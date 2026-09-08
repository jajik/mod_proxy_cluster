#!/usr/bin/sh
# Collects code coverage of the modules built with -DENABLE_COVERAGE=ON.
#
#   coverage.sh capture <name> <output-dir>   gather the counters dumped so far
#   coverage.sh report <output-dir>           merge the gathered tracefiles into reports
#
# "capture" produces the coverage-<name>.json and coverage-<name>.info tracefiles,
# "report" merges every tracefile within the output directory into test-coverage.txt,
# test-coverage.html and lcov/index.html.
#
# The httpd instance under test has to be stopped before capturing, otherwise gcov
# has not dumped its counters yet and there is nothing to collect.
#
# The location of the sources is derived from the location of this script, override
# it with the NATIVE variable if needed.
#
# exits with 0 if the data were collected
# exits with 1 if there is nothing to collect
# exits with 2 when used incorrectly

NATIVE=${NATIVE:-$(cd -- "$(dirname -- "$0")/.." && pwd)}

# gcovr is always given --root so that the paths within the tracefiles stay relative
# to native/. That keeps tracefiles captured from different runs (and, since the
# tracefiles are plain data, even from different machines and gcc versions) mergeable.
GCOVR="gcovr --gcov-ignore-parse-errors=negative_hits.warn_once_per_file --root $NATIVE"

capture() {
    name=$1
    out=$2

    if [ -z "$(find $NATIVE -name '*.gcda' 2> /dev/null)" ]; then
        echo "No coverage data found in $NATIVE, is httpd stopped?"
        return 1
    fi

    mkdir -p $out
    $GCOVR --json $out/coverage-$name.json > $out/coverage-$name.log 2>&1
    # "unused" is ignored as well, the exclude pattern matches nothing when httpd
    # headers do not live in /usr/local (which is the case outside of our container)
    lcov --capture --directory $NATIVE/build --ignore-errors gcov,negative,unused \
         --exclude '/usr/local/*' --output-file $out/coverage-$name.info \
         > $out/coverage-lcov-$name.log 2>&1
}

report() {
    out=$1

    if [ -z "$(ls $out/coverage-*.json 2> /dev/null)" ]; then
        echo "No tracefiles to report on within $out."
        return 1
    fi

    mkdir -p $out/lcov
    # the glob is quoted on purpose, it is gcovr who expands it
    $GCOVR --add-tracefile "$out/coverage-*.json" \
           --txt $out/test-coverage.txt --html-details $out/test-coverage.html \
           > $out/test-coverage.log 2>&1
    genhtml --ignore-errors negative,empty $out/coverage-*.info \
            --output-directory $out/lcov > $out/lcov/test-coverage-lcov.log 2>&1
}

usage() {
    echo "usage: $0 capture <name> <output-dir>"
    echo "       $0 report <output-dir>"
    exit 2
}

case "$1" in
capture)
    if [ -z "$2" ] || [ -z "$3" ]; then usage; fi
    capture "$2" "$3";;
report)
    if [ -z "$2" ]; then usage; fi
    report "$2";;
*)
    usage;;
esac
