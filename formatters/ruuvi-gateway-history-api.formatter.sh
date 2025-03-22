#!/usr/bin/env bash

parse_json() {
    jq -c '
        .data.tags | to_entries[] | .value as $tag |
        {
            id: $tag.id,
            tag_name: $tag.id,
            temperature: $tag.temperature, 
            humidity: $tag.humidity, 
            datetime: ($tag.timestamp | todate),
            voltage: $tag.voltage
        }
    '
}