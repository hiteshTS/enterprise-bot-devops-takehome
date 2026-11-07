# Findings — Part 4 Debug Lab

## Defect 1 — Missing numeric user and group IDs

**Symptom:**

```text
Error: container has runAsNonRoot and image has non-numeric user (nonroot), cannot verify user is non-root
```

**Cause:**

The containers had `runAsNonRoot: true` but did not specify numeric user and group IDs. Kubernetes could not verify the image's named user.

**Fix:**

Added the following to the security context of all six workloads:

```yaml
runAsNonRoot: true
runAsUser: 65532
runAsGroup: 65532
```

UID/GID 65532 matches the non-root user in the supplied image.

**How I found it:**

Inspected pod status and container events using `kubectl describe pod`. Identified the security-context validation error and checked the image's user information.

---

## Defect 2 — Invalid migration Job restart policy

**Symptom:**

```text
Job.batch "migrate" is invalid:
spec.template.spec.restartPolicy:
Required value: valid values: "OnFailure", "Never"
```

**Cause:**

The migration Job used `restartPolicy: Always`, which is not supported for Kubernetes Jobs.

**Fix:**

Changed the migration Job restart policy to:

```yaml
restartPolicy: Never
```

This allows the Job to complete or fail without automatically restarting its container indefinitely.

**How I found it:**

Inspected the Helm installation error and checked the migration Job template.

---

## Defect 3 — Incorrect backend namespace in gateway URL

**Symptom:**

The gateway `/status` endpoint did not report `backend=ok`.

**Cause:**

The gateway was configured to contact:

```text
http://backend.default.svc:8080
```

The backend Service was deployed in the `debug-lab` namespace, not `default`.

**Fix:**

Updated `BACKEND_URL` to:

```text
http://backend.debug-lab.svc:8080
```

**How I found it:**

Checked gateway logs and its environment configuration. Tested backend connectivity from inside the cluster and verified the corrected gateway URL returned `backend=ok`.

---

## Defect 4 — Incorrect reporter RoleBinding subject

**Symptom:**

Initially, the verification reported:

```text
FAIL ServiceAccount debug-lab/reporter cannot list pods
```

**Cause:**

The RoleBinding referenced the `default` ServiceAccount, while the reporter Deployment used the `reporter` ServiceAccount.

**Fix:**

Changed the RoleBinding subject to:

```yaml
subjects:
  - kind: ServiceAccount
    name: reporter
    namespace: debug-lab
```

**How I found it:**

Inspected the RoleBinding and reporter Deployment ServiceAccount configuration. Verified the permission using:

```bash
kubectl auth can-i list pods -n debug-lab \
  --as=system:serviceaccount:debug-lab:reporter
```

The result after the fix was:

```text
yes
```

---

## Defect 5 — Metrics resource requests exceeded LimitRange

**Symptom:**

The metrics workload could not be admitted with its original CPU resource configuration.

**Cause:**

The metrics container requested 2 CPU cores and had a 4-core limit, exceeding the namespace LimitRange maximum of 1 CPU core.

**Fix:**

Reduced the metrics CPU resources to:

```yaml
resources:
  requests:
    cpu: "200m"
    memory: "64Mi"
  limits:
    cpu: "500m"
    memory: "128Mi"
```

**How I found it:**

Inspected the namespace LimitRange and metrics Deployment resource configuration. Compared the configured requests and limits against the allowed maximum.

---

## Defect 6 — Worker cache directory was not writable

**Symptom:**

Actual recorded worker log:

```text
FATAL: worker could not initialise its cache:
mkdir /var/cache/app: read-only file system —
the process needs a writable directory at /var/cache/app
```

**Cause:**

The worker ran with a read-only root filesystem but needed a writable directory for its cache.

**Fix:**

Added an `emptyDir` volume mounted at `/var/cache/app`:

```yaml
volumeMounts:
  - name: worker-cache
    mountPath: /var/cache/app

volumes:
  - name: worker-cache
    emptyDir: {}
```

This provides temporary writable storage without making the entire container filesystem writable.

**How I found it:**

Inspected worker logs using `kubectl logs deployment/worker -n debug-lab`. The fatal error explicitly identified the cache directory and the need for writable storage. Verified that the worker subsequently became ready.

---

## Remaining issue and investigation status

The reporter Deployment remains unresolved.

The current verification result is:

- 9 checks passing.
- 2 checks failing:
  - Reporter Deployment readiness.
  - Reporter `/report` endpoint pod count.

The reporter repeatedly logs:

```text
pod list failed: parse pod list: unexpected end of JSON input
```

The reporter ServiceAccount permission was corrected and verified. A separate diagnostic pod using the same ServiceAccount and projected Kubernetes CA successfully retrieved the Kubernetes PodList with HTTP 200.

Additional reporter configuration changes were tested, including a Kubernetes CA certificate setting and a writable cache volume, but these did not resolve the issue.

Further investigation would focus on the reporter application's HTTP response handling and PodList parsing. The issue is disclosed rather than claiming a successful fix.

## Final status

Five infrastructure and configuration fixes were verified, along with the worker cache fix recorded during the investigation. The reporter-related checks remain unresolved at submission time.