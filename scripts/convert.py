import os

# Download data
os.system('cd /home/col/raw; wget -c -N https://www.itis.gov/downloads/itisMySQLBulk.zip')

# Unzip data
os.system('cd /home/col/raw; unzip itisMySQLBulk.zip')

# Import data into MySQL
os.system('cd /home/col/raw/itisMySQL022620; mysql -hdatabase -uroot -pbiodiversity < CreateDB.sql')

# Convert the data to CoLDP
os.system('cd /home/col/scripts; cat convert.sql | mysql -hdatabase -uroot -pbiodiversity')

