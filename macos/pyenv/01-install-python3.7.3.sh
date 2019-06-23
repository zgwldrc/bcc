#!/bin/bash
CFLAGS="-I$(xcrun --show-sdk-path)/usr/include" pyenv install -k -v 3.7.3
