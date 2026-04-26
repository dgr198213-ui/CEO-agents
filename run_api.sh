#!/bin/bash
export PATH=$HOME/.nimble/bin:$PATH
nim c --threads:off -r api_wrapper.nim
