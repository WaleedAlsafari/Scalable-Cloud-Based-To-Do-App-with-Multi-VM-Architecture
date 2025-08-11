#!/bin/bash


sudo apt update && sudo apt upgrade -y


sudo apt install -y curl git


sudo apt install -y nodejs npm


if ! command -v node &> /dev/null; then
    sudo ln -s /usr/bin/nodejs /usr/bin/node
fi


node -v
npm -v

git clone https://github.com/WaleedAlsafari/PERN-ToDo-App.git
cd PERN-ToDo-App/server

npm install
npm run server
