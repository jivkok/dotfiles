Build or update test environments (local + Docker) based on current setup file hashes.
`run-tests.sh` calls this automatically, but you can run it standalone to pre-build images without running tests.

```bash
bash tests/create-test-envs.sh
```
