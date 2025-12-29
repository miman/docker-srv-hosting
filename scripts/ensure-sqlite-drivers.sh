# installs the sqlite drivers if they are not already installed

if ! command -v sqlite3 &> /dev/null
then
    echo "sqlite3 not found, installing..."
    sudo apt install sqlite3 -y
fi
