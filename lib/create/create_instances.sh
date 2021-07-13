create_server $MASTER_INSTANCE_TYPE master &

COUNTER=0
while [  $COUNTER -lt $WORKER_COUNT ]; do
  let COUNTER=COUNTER+1
  create_server $WORKER_INSTANCE_TYPE worker$COUNTER &
done

wait


MASTER_IP=$(public_ip $MASTER_INSTANCE_TYPE master)

echo "Waiting for $(instance_name $MASTER_INSTANCE_TYPE master) to be up..."

until ssh $SSH_USER@$MASTER_IP true >/dev/null 2>&1; do
  sleep 1
  echo "Waiting for $(instance_name $MASTER_INSTANCE_TYPE master) to be up..."
done

COUNTER=0
while [  $COUNTER -lt $WORKER_COUNT ]; do
  let COUNTER=COUNTER+1

  WORKER_IP=$(public_ip $WORKER_INSTANCE_TYPE worker$COUNTER)

  echo "Waiting for $(instance_name $WORKER_INSTANCE_TYPE worker$COUNTER) to be up..."

  until ssh $SSH_USER@$WORKER_IP true >/dev/null 2>&1; do
    sleep 1
    echo "Waiting for $(instance_name $WORKER_INSTANCE_TYPE worker$COUNTER) to be up..."
  done
done
