# TODO

- Make `openebs-hostpath` the default storageclass automatically

  ```bash
    kubectl patch storageclass openebs-hostpath -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'
  ```

- Add Certificate for `vault`
  - May require some self-bootstrapping + cert-manager
