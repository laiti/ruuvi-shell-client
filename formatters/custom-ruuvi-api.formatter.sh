#!/usr/bin/env bash

parse_json() {
		jq -c '
				.[] | 
				{
						id,
						tag_name, 
						temperature, 
						humidity, 
						datetime, 
						battery_low
				}
		'
}