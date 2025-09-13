<!--
SPDX-FileCopyrightText: 2025 NONE

SPDX-License-Identifier: Unlicense
-->

# TODO

- Make `openebs-hostpath` the default storageclass automatically

  ```bash
    kubectl patch storageclass openebs-hostpath -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'
  ```

- Add Certificate for `vault`
  - May require some self-bootstrapping + cert-manager
- Add Admin Group
- Add User with Admin access

## References

- https://www.feistyduck.com/library/openssl-cookbook/online/
