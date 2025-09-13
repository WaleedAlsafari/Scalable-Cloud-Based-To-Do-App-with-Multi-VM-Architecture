sudo apt update && sudo apt upgrade -y

sudo apt install postgresql postgresql-contrib -y

sudo -i -u postgres psql -c "CREATE DATABASE todoapp;"
sudo -i -u postgres psql -c "CREATE USER admin WITH ENCRYPTED PASSWORD 'Admin123@';"
sudo -i -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE todoapp TO myuser;"

echo "host    all             all             10.0.1.0/24           md5" | sudo tee -a /etc/postgresql/*/main/pg_hba.conf

sudo sed -i "s/^#listen_addresses = 'localhost'/listen_addresses = '*'/g" /etc/postgresql/*/main/postgresql.conf

sudo systemctl restart postgresql
