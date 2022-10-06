#!/bin/bash

apt remove --purge $old_pkgs -y && apt install $new_version -y