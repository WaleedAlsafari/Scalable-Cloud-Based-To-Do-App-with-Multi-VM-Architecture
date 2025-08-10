sudo apt update && sudo apt upgrade -y

curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt install -y nodejs git

git clone https://github.com/vickytilotia/PERN-ToDo-App.git
cd PERN-ToDo-App/client


npm install
npm start
