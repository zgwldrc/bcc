#!/bin/bash
. used-in-gitlab-ci-lib.sh

function _test_check_env_for_normal_env() {
    local hello=123 check_env hello
    if [ $? -eq 0 ];then
        echo suc
    else
        echo fail
    fi
}

function _test_check_env_for_missing_env() {
    check_env undefinedvariable
    if [ ! $? -eq 0 ];then
        echo suc
    else
        echo fail
    fi
}

_test_check_env_for_normal_env
_test_check_env_for_missing_env


