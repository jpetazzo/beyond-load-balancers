**Initialize helmfile plugins:**

```
helmfile init --force
```

**If needed, enable missing components:**

If your Kubernetes cluster *does not* have a storage class,
you can request the installation of the rancher local path provisioner
by setting this environment variable:

```
export INSTALL_LOCAL_PATH_PROVISIONER=yes
```

Likewise, if your cluster *does not* have metrics server
(`kubectl top nodes` says that the metrics API is not available),
you can request its installation by settings this variable:

```
export INSTALL_METRICS_SERVER=yes
```

**Install operators:**

```
helmfile sync
```

**Create namespace:**

```
NAMESPACE=app
kubectl create namespace $NAMESPACE
kns $NAMESPACE
```

**Deploy database, message queue, and ollama:**

```
kubectl apply -f postgres
kubectl apply -f rabbitmq
kubectl apply -f ollama
# Ignore the warning about the names that cannot be generated with apply :)
```

**Run Bento processors:**

```
helmfile sync -f bento/helmfile.yaml -n $NAMESPACE
```

**Install dashboard:**

```
helmfile sync -e dashboard
kubectl apply -f grafana
```

You can then open grafana (default login password: `admin` / `prom-operator`)
and the custom dashboard should be visible.

**Check queue:**

```
kubectl exec mq-server-0 -- rabbitmqctl list_queues
```

**Check database:**

```
kubectl cnpg psql db -- messages -c "select * from messages;"
```

**Scale up ollama and consumer:**

```
kubectl scale deployment consumer,ollama --replicas 100
```

This should trigger node autoscaling. It will take a few
minutes for the new nodes to come up. Wait a bit. Eventually,
the queue should start to come down. Yay!

But if we look with `kubectl top pods`, many of these pods
are idle. We have overprovisioned ollama. Let's try to
do better with autoscaling.

**Enable autoscaling on ollama:**

```
kubectl autoscale deployment ollama --max=100
```

Now we wait a bit. After a few minutes, ollama should be
scaled down until we reach a kind of "cruise speed" where we
have "just the right amount" of ollama pods to handle the
load.

But... If we look with `kubectl top pods` again, we'll see
that some pods are still idle. This is because of unfair load
balancing. We're going to change that by having exactly
one ollama pod per bento consumer, and have each bento
consumer talk to its "own" ollama. We'll achieve that by
running ollama as a sidecar right next to the bento
consumer.

**Switch to sidecar architecture and KEDA autoscaler:**

```
helmfile sync -f bento/helmfile.yaml -n $NAMESPACE -e sidecar
```

This will scale according to the queue depth, and it should
also stabilize after a while.

Check the results:

```
kubectl get so,hpa,deploy
```

After a while the number of nodes should also go down on its own.

**Scale to zero:**

```
kubectl scale deployment bento-generator --replicas=0
```

If we shutdown the generator, eventually, the queue will
drain and then, the autoscaler should scale down the consumer
to zero as well.

