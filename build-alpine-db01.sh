#!/bin/sh

#rm -rf output-alpine-* 

packer build \
    --var-file="alpine-3.17.0-db01.json" \
    --var-file="alpine-builder.json" \
    alpine-db01.json
