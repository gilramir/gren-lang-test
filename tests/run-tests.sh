#!/usr/bin/env bash

set -e

gren make TestsMain
node app

gren make SeedTestsMain
node app