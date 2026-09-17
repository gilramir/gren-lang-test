#!/usr/bin/env bash

set -e

geng make TestsMain
node app

geng make SeedTestsMain
node app