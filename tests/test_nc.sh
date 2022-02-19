#!/usr/bin/env sh

cat >"nc_listen.sh" <<EOF
#!/usr/bin/env sh
if [ \$# -ne 1 ]; then >&2 echo "usage: \$0 1234"; exit 1; fi
echo "Starting netcat on :\$1 ..."
lsof -i :\$1 | awk '/nc /{print \$2}' | xargs kill -9
nc -l \$1
EOF

cat >"nc_hello.sh" <<EOF
#!/usr/bin/env sh
sleep 1
if [ \$# -ne 1 ]; then >&2 echo "usage: \$0 1234"; exit 1; fi
for i in \`seq 1 10\`; do echo hello world \$i; done | nc 127.0.0.1 \$1
EOF

chmod u+x nc_listen.sh
chmod u+x nc_hello.sh

PORT1=1234
PORT2=4321
../par "./nc_listen.sh $PORT1" "./nc_listen.sh $PORT2" "echo bravo" "./nc_hello.sh $PORT1" "./nc_hello.sh $PORT2"
EC=$?

# Cleanup
rm nc_listen.sh nc_hello.sh
exit $EC
