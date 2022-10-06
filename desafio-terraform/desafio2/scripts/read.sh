#!/bin/bash

dpkg -s $list_pkgs

if [ $? -eq 0 ]
then
    echo "Pacote se encontra no SO"
else
    apt install -y $list_pkgs
fi