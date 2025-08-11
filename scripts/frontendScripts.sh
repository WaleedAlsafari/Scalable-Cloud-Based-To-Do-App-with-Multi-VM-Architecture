sudo apt update && sudo apt upgrade -y

curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt install -y nodejs git

git clone https://github.com/WaleedAlsafari/Scalable-Cloud-Based-To-Do-App-with-Multi-VM-Architecture.git
cd Scalable-Cloud-Based-To-Do-App-with-Multi-VM-Architecture/app/client


npm install
npm start
