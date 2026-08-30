# entra_external_id_example

Demonstrates the current bootstrap state of `entra_external_id`.

The app calls the typed Pigeon bridge and displays whether the official MSAL
SDK is linked on the running platform. During bootstrap it intentionally reports
that MSAL is not linked; authentication UI will be added after the contract and
native sign-in stages pass their validation gates.

Run it on Android or iOS:

```shell
flutter run
```
