#!/bin/bash

sed -e "s;%ONE%;$(shuf -i 1-10 -n 1);g" \
    -e "s;%TWO%;$(shuf -i 1-100 -n 1);g" \
    -e "s;%THREE%;$(shuf -i 1-1000 -n 1);g" \
    /usr/share/nginx/html/template.txt