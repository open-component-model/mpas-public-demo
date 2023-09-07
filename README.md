[![REUSE status](https://api.reuse.software/badge/github.com/open-component-model/demo-secure-delivery)](https://api.reuse.software/info/github.com/open-component-model/demo-secure-delivery)

# MPAS with Flux and Open Component Model

## Fully guided walkthrough

![workflow](./docs/images/diagram.png)

This walkthrough deploys a full end-to-end pipeline demonstrating how OCM and Flux can be employed to deploy applications in air-gapped environments.

The demo environment consists of Gitea, Tekton, Flux and the MPAS controllers.
Two Gitea organizations are created:
- [software-provider](https://gitea.ocm.dev/software-provider)
- [software-consumer](https://gitea.ocm.dev/software-consumer)

The provider organization contains a repository that models the `podinfo` application. When a new release is created a Tekton pipeline will be triggered that builds the component and pushes it to the [software provider's OCI registry](https://gitea.ocm.dev/software-provider/-/packages).

## Software Consumer

The software consumer organization models an air-gapped scenario where applications are deployed from a secure OCI registry rather than directly from an arbitrary upstream source.

The software consumer organization contains a repository named [ocm-applications](https://gitea.ocm.dev/software-consumer/ocm-applications). During the setup of the demo a PR is created which contains the Kubernetes manifests required to deploy the component published by the software provider.

Once this pull request is merged the Flux machinery will deploy the dependency `weave-gitops` and subsequently the `podinfo` component. The [weave-gitops dashboard](https://weave-gitops.ocm.dev) can be used to understand the state of the cluster.

## Business entities

Components:
![mpas-component](./docs/images/mpas-components.png)

MPAS-flow:
![mpas-flow](./docs/images/mpas-flow.png)

## Deployed products

We are going to deploy two products: [podinfo](https://github.com/stefanprodan/podinfo) and [Weave-Gitops front-end](https://github.com/weaveworks/weave-gitops).

### Demo walkthrough

Step-by-step instructions are provided to guide you through the process of deploying the demo environment. The scenario simulates actions on both sides, software provider and software consumer:  

1. provider: cut a new release v1.0.0 for product "podinfo" which triggers a CICD pipeline in Tekton
2. provider: verify the release automation process in the Tekton UI
3. consumer: install two products, "podinfo" from steps 1. and 2. and the "Weave GitOps dashboard"
4. consumer: use the Weave GitOps dashboard to check the product deployment
5. consumer: access the deployed "podinfo" product
6. consumer: apply modification to product configuration
7. consumer: monitor the config update of the product
8. provider: cut a release update v1.1.0 with new features
9. consumer: apply updated product version and keep modified configuration
10. consumer: monitor the product update

#### 1. Setup demo environment

To deploy the demo environment execute the following:

`make run`

Once the environment has been created, log in to Gitea using the following credentials:

```
username: ocm-admin
password: password
```

#### 2. Cut a release for `podinfo`

Navigate to: https://gitea.ocm.dev/software-provider/podinfo-component/releases and click "New Release".

Enter "v1.0.0" for both the tag name and release name, and then click "Publish Release".

![release](./docs/images/publish.png)

#### 3. Verify the release

Once the release is published, navigate to https://ci.ocm.dev/#/namespaces/tekton-pipelines/pipelineruns and follow the progress of the release automation.

![ci](./docs/images/release_automation.png)

#### 4. Install the Component

When the release pipeline has been completed we can install the component. Navigate to https://gitea.ocm.dev/software-consumer/ocm-applications/pulls/1 and merge the pull request.

![install](./docs/images/install.png)

_Note_: If you see an error that the PR needs rebasing, you can ignore that.

#### 5. Merge the two created PRs

The two generators above will create two sets of PRs containing manifests that will further produce application-specific configuration objects. Like Configuration, Localization and FluxDeployer.
These objects will be generated via the mpas-product-controller.

![two-prs](./docs/images/two_pull_requests.png)

After the two PRs are merged, give it a minute and the applications should be reconciled.

Once things are done, the Weave-Gitops application should be accessible under https://weave-gitops.ocm.dev. You can log in with username: `admin` and password `password`.

_Note_: It can take a little while because flux needs to reconcile the new repository content. Until then, it might error because it's looking for a values.yaml file in the GitRepository object.

Once the two applications are merged, you should see two "products" under [products](https://gitea.ocm.dev/software-consumer/mpas-ocm-applications/src/branch/main/products).

![products](./docs/images/products.png)

#### 6. View the application

We can view the `podinfo` Helm release that's been deployed in the default namespace: https://weave-gitops.ocm.dev/helm_release/graph?clusterName=Default&name=podinfo&namespace=default

We can also view the running application at https://podinfo.ocm.dev

![podinfo](./docs/images/application.png)

#### 7. Change configuration values

The application can be configured using the parameters exposed in `values.yaml`. Now that podinfo is deployed we can tweak a few parameters, navigate to
https://gitea.ocm.dev/software-consumer/mpas-ocm-applications/_edit/main/products/podinfo/values.yaml

![configure](./docs/images/configure.png)

and adopt the current values to

```yaml
podinfo:
  message: This is my updated message
  replicas: 2
  serviceAccountName: default
```

Commit the changes to the main branch and wait for it all to be reconciled back into the deployed application.

#### 7. View the configured application

Once the controllers and objects finish updating, you should have two running pods and an updated message:

```
kubectl get pods
NAME                           READY   STATUS    RESTARTS   AGE
podinfo-7fb6788b66-b5gml       1/1     Running   0          23s
podinfo-7fb6788b66-xh7bq       1/1     Running   0          23s
weave-gitops-db47485b8-6k4zb   1/1     Running   0          10m
```

Navigate to https://podinfo.ocm.dev to view the new message.

![update](./docs/images/update.png)

#### 8. Cut a new release

Let's jump back to the provider repository and cut another release. This release will contain a new feature that changes the image displayed by the podinfo application. Follow the same process as before to create a release, bumping the version to `v1.1.0`. Make sure to select the branch _`new-release`_ to apply the updated configuration data.

#### 9. Verify the release

Once the release is published, navigate to https://ci.ocm.dev/#/namespaces/tekton-pipelines/pipelineruns and follow the progress of the release automation.

#### 10. Merge the new PR

This update will trigger a new PR for the application reconciling a new version:

![update pr](./docs/images/updated_pr.png)

It contains a diff to the values file back to the version that the vendor ships as default, since we adopted that config for our environment. Most likely 
you want to keep your changes, so revert that changes by modifying the file on the PR branch. If not, just merge the PR as is. Either way, it
should result in a reconciliation of the application.

#### 11. Monitor the application update

Jump back to https://weave-gitops.ocm.dev to view the rollout of the new release.

![update-wego](./docs/images/update-wego.png)

#### 12. View the updated application

Finally, navigate to https://podinfo.ocm.dev which now displays the OCM logo in place of the cuttlefish and the updated application version of 6.3.6.

![update-ocm](./docs/images/update-ocm.png)

### Conclusion

By leveraging the capabilities of Gitea, Tekton, Flux, and the MPAS system controllers, this demo showcases the seamless deployment of components and dependencies in a secure manner. The use of secure OCI registries and automated release pipelines ensures the integrity and reliability of the deployment process.

Users can easily set up the demo environment, cut releases, monitor release automation, view the Weave GitOps dashboard and observe the deployment and update of applications. We have presented a practical illustration of how OCM and Flux can be employed to facilitate the deployment and management of applications in air-gapped environments, offering a robust and efficient solution for secure software delivery.

## Contributing

Code contributions, feature requests, bug reports, and help requests are very welcome. Please refer to the [Contributing Guide in the Community repository](https://github.com/open-component-model/community/blob/main/CONTRIBUTING.md) for more information on how to contribute to OCM.

OCM follows the [CNCF Code of Conduct](https://github.com/cncf/foundation/blob/main/code-of-conduct.md).

## Licensing

Copyright 2022-2023 SAP SE or an SAP affiliate company and Open Component Model contributors.
Please see our [LICENSE](LICENSE) for copyright and license information.
Detailed information including third-party components and their licensing/copyright information is available [via the REUSE tool](https://api.reuse.software/info/github.com/open-component-model/demo-secure-delivery).
