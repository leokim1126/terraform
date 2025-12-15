#!/bin/bash

dnf install -y httpd
echo "My ALD Web Page" > /var/www/html/index.html2
systemctl restart httpd && systemctl enable httpd