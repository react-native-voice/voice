#!/usr/bin/env bash
adb reverse tcp:8081 tcp:8081

adb -d reverse tcp:8081 tcp:8081

adb -e reverse tcp:8081 tcp:8081
