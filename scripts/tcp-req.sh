#!/bin/bash

echo -n "$1" | ncat -w1 $2 $3