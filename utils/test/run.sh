#!/bin/bash -e
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir" || :' EXIT

[ -f game.conf ] || { echo "Must be run in game root folder." >&2; exit 1; }
[ -n "$DOCKER_IMAGE" ] || { echo "Specify a docker image." >&2; exit 1; }

mkdir -p "$tmpdir/world"
chmod -R 777 "$tmpdir" # container uses unprivileged user inside

vol=(
	-v "$PWD/utils/test/minetest.conf":/etc/minetest/minetest.conf
	-v "$tmpdir":/var/lib/minetest/.minetest
	-v "$PWD":/var/lib/minetest/.minetest/games/minetest_game
)
docker run --rm -i "${vol[@]}" "$DOCKER_IMAGE" --config /etc/minetest/minetest.conf --gameid minetest

test -f "$tmpdir/world/map.sqlite" || exit 1
exit 0
