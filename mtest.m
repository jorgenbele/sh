#!/bin/sh
# The mtest module.

function test1() {
    echo "This is test1 from module1: $@"
}

test2() {
    echo "This is test2 from module1: $@"
}
