#!/bin/bash

dnf install -y httpd
cat <<EOF > /var/www/html/index.html
<h1>DB IP: ${dbaddress}</h1>
<h1>DB Port: ${dbport}</h1>
<h1>DB name: ${dbname}</h1>
EOF
systemctl enable --now httpd