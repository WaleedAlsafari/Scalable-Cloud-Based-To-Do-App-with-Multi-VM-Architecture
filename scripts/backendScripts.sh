sudo apt update && sudo apt upgrade -y

sudo apt install -y nodejs git curl

git clone https://github.com/WaleedAlsafari/Scalable-Cloud-Based-To-Do-App-with-Multi-VM-Architecture.git

cd Scalable-Cloud-Based-To-Do-App-with-Multi-VM-Architecture/app/server

cat <<EOF > .env
DB_HOST=10.0.2.4
DB_PORT=5432
DB_USER=admin
DB_PASSWORD=Admin123@
DB_NAME=todoapp
EOF

npm install
npm run server
