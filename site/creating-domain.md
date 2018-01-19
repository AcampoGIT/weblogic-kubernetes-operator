# Creating a WebLogic domain

The WebLogic *domain* must be installed into the folder that will be mounted as `shared/domain`. The recommended approach is to use the provided `create-domain-job.sh` script, however instructions are also provided for manually installing and configuring a WebLogic domain (see [Manually creating a domain](manually-creating-domain.md)).

## Important considerations and restrictions for WebLogic domains in Kubernetes

When running a WebLogic *domain* in Kubernetes, there are some additional considerations that must be taken into account to ensure correct functioning:

*	Multicast is not well supported in Kubernetes at the time of writing.  Some networking providers have some support for multicast, but it is generally considered of “beta” quality.  Oracle recommends configuring WebLogic *clusters* to use unicast.
*	The `ListenAddress` for all servers must be set to the correct DNS name, it should not be set to `0.0.0.0` or left blank.  This is required for cluster discovery of servers to work correctly.
*	If there is a desire to expose a T3 channel outside of the Kubernetes *cluster*, for example to allow WLST or RMI connections from clients outside Kubernetes, then the recommended approach is to define a dedicated channel (per server) and to expose that channel using a `NodePort` *service*.  It is required that the channel’s internal and external ports be set to the same value as the chosen `NodePort`, for example they could all be `32000`.  If all three are not the same, WebLogic will reject T3 connection requests.

## Creating a domain namespace

Oracle recommends creating *namespaces* to host WebLogic *domains*. It is not required to maintain a one to one relationship between WebLogic *domains* and Kubernetes *namespaces*, but this may be done if desired. More than one WebLogic *domain* may be run in a single *namespace* if desired.

Any *namespaces* that were listed in the `targetNamespaces` parameter in the *operator* parameters file when deploying the operator would have been created by the script.  

To create an additional namespace, issue the following command:

```
kubectl create namespace NAMESPACE
```

In this command, replace `NAMESPACE` with the desired *namespace*.

Note: Kubernetes does not allow upper case characters in the `NAMESPACE`.  Only lower-case characters, numbers and the hyphen character are allowed.

## Setting up secrets for the admin server credentials

The admin server username and password credentials must be stored in a Kubernetes *secret* in the same *namespace* that the *domain* will run in.  The script does not create the *secret* in order to avoid storing the credentials in a file.  Oracle recommends that this command be executed in a secure shell and appropriate measures be taken to protect the security of the credentials.

Issue the following command to create the secret:

```
kubectl -n NAMESPACE create secret generic SECRET_NAME
  --from-literal=username=ADMIN-USERNAME
  --from-literal=password=ADMIN-PASSWORD
```

In this command, replace the uppercase items with the correct values for the domain.

The `SECRET_NAME` value specified here must be in the format `DOMAINUID-weblogic-credentials` where `DOMAINUID` is replaced with the `domainUID` for the *domain*.

## Important considerations for persistent volumes

WebLogic *domains* that are managed by the operator are required to store their configuration and state on a *persistent volume*.  This volume is mounted read/write on all containers that are running a server in the *domain*.  There are many different *persistent volume* providers, but they do not all support multiple read/write mounts.  It is required that the chosen provider supports multiple read/write mounts. Details of available providers are available at [https://kubernetes.io/docs/concepts/storage/persistent-volumes](https://kubernetes.io/docs/concepts/storage/persistent-volumes).  Careful attention should be provided to the table in the section titles “Access Modes”.

In a single-node Kubernetes *cluster*, such as may be used for testing or proof of concept activities, `HostPath` provides the simplest configuration.  In a multi-node Kubernetes *cluster* a `HostPath` which happens to be located on shared storage mounted by all nodes in the Kubernetes *cluster* is the simplest configuration.  If nodes do not have shared storage, then NFS is probably the most widely available option.  There are other options listed in the referenced table.

## Creating a persistent volume for the domain

The *persistent volume* for the *domain* must be created using the appropriate tools before running the script to create the *domain*.  In the simplest case, the `HostPath` provider, this means creating a directory on the Kubernetes master and ensuring it has the correct permissions:

```
mkdir –m 777 –p /path/to/domain1PersistentVolume
```

For other providers, consult the documentation for the provider for instructions on how to create a persistent volume.

## Customizing the domain parameters file

The *domain* is created with the provided installation script (`create-domain-job.sh`).  The input to this script is the file `create-domain-job-inputs.yaml`, which needs to updated to reflect the target environment.  

The following parameters must be provided in the input file:

### CONFIGURATION PARAMETERS FOR THE CREATE DOMAIN JOB

| Parameter	| Definition	| Default |
| --- | --- | --- |
| adminPort	| Port number for the administration server.	| 7001 |
| adminServerName	| The name of the administration server.	| admin-server |
| createDomainScript	| Script used to create the domain.  This parameter should not be modified. |	/u01/weblogic/create-domain-script.sh |
| domainName	| Name of the WebLogic domain to create.	| base_domain |
| domainUid	| Unique ID that will be used to identify this particular domain. This ID must be unique across all domains in a Kubernetes cluster.	| domain1 |
| managedServerCount	| Number of managed server to generate for the domain.	| 2 |
| managedServerNameBase	| Base string used to generate managed server names.	| managed-server |
| managedServerPort	| Port number for each managed server.	| 8001 |
| persistencePath	| Physical path of the persistent volume storage. |	/scratch/k8s_dir/persistentVolume001 |
| persistenceSize	| Total storage allocated by the persistent volume.	| 10Gi |
| persistenceStorageClass	| Name of the storage class to set for the persistent volume and persistent volume claim.	| weblogic |
| persistenceVolumeClaimName	| Name of the Kubernetes persistent volume claim for this domain.	| pv001-claim |
| persistenceVolumeName	| Name of the Kubernetes persistent volume for this domain.	| pv001 |
| productionModeEnabled	| Boolean indicating if production mode is enabled for the domain.	true
secretsMountPath	Path for mounting secrets.  This parameter should not be modified. |	/var/run/secrets-domain1 |
| secretName	| Name of the Kubernetes secret for the Admin Server's username and password. |	domain1-weblogic-credentials |
| T3ChannelPort	| Port for the T3Channel of the NetworkAccessPoint.	| 7002 |
| namespace	| The Kubernetes namespace to create the domain in.	| default |
| loadBalancerAdminPort	| The node port for the load balancer to accept admin requests.	| 30315 |
| loadBalancerWebPort	| The node port for the load balancer to accept user traffic. 	| 30305 |
| enableLoadBalancerAdminPort	| Determines whether the load balancer admin port should be exposed outside the Kubernetes cluster.	| false |
| enablePrometheusIntegration	| Determines whether the Prometheus integration will be enabled.  If set to ‘true’, then the WLS Exporter will be installed on all servers in the domain and configured to export metrics to Prometheus. |	false |

## Limitations of the create domain script

This Technology Preview release has some limitation in the create domain script that users should be aware of.

*	The script assumes the use of the `HostPath` *persistent volume* provider.
*	The script creates the specified number of managed servers and places them all in one *cluster*.
*	The script always creates one *cluster*.

Oracle intends to remove these limitations in a future release.

## Using the script to create a domain

To execute the script and create a domain, issue the following command:

```
./create-domain-job.sh –i create-domain-job-inputs.yaml
```

## What the script does

The script will perform the following steps:

*	Create Kubernetes YAML files based on the provided inputs.
*	Create a *persistent volume* for the shared state.
*	Create a *persistent volume claim* for that volume.
*	Create a Kubernetes *job* that will start up a utility WebLogic Server container and run WLST to create the *domain* on the shared storage.
*	Wait for the *job* to finish and then create a *domain custom resource* for the new *domain*.

The default *domain* created the script has the following characteristics:

*	An admin server named `admin-server` listening on port `7001`.
*	A single *cluster* named `cluster-1` containing the specified number of managed servers.
*	A managed server named `managed-server1` listening on port `8001` (and so on up to the requested number of managed servers).
*	Log files are located in `/shared/logs`.
*	No applications deployed.
*	No data sources.
*	No JMS resources.
*	A T3 channel.

## Common Problems

This section provides details of common problems that occur during domain creation and how to resolve them.

### Persistent volume provider not configured correctly

Possibly the most common problem experienced during testing was incorrect configuration of the *persistent volume* provider.  The *persistent volume* must be accessible to all Kubernetes nodes, and must be able to be mounted as Read/Write/Many.  If this is not the case, the *domain* creation will fail.

The simplest case is where the `HostPath` provider is used.  This can be either with one Kubernetes node, or with the `HostPath` residing in shared storage available at the same location on every node (for example on an NFS mount).  In this case, the path used for the *persistent volume* must have its permission bits set to 777.

## YAML files created by the script

Write me

```
# Copyright 2017, 2018, Oracle Corporation and/or its affiliates.  All rights reserved.
# Licensed under the Universal Permissive License v 1.0 as shown at http://oss.oracle.com/licenses/upl.
apiVersion: batch/v1
kind: Job
metadata:
  name: domain-domain1-job
  namespace: domain1
spec:
  template:
    metadata:
      labels:
        app: domain-domain1-job
        weblogic.domainUID: domain1
    spec:
      restartPolicy: Never
      containers:
        - name: domain-job
          image: store/oracle/weblogic:12.2.1.3
          imagePullPolicy: IfNotPresent
          ports:
            - containerPort: 7001
          volumeMounts:
          - mountPath: /u01/weblogic
            name: config-map-scripts
          - mountPath: /shared
            name: pv-storage
          - mountPath: /var/run/secrets-domain1
            name: secrets
          command: ["/bin/sh"]
          args: ["/u01/weblogic/create-domain-job.sh"]
          env:
            - name: SHARED_PATH
              value: "/shared"
      volumes:
        - name: config-map-scripts
          configMap:
            name: domain-domain1-scripts
        - name: pv-storage
          persistentVolumeClaim:
            claimName: domain1-pv001-claim
        - name: secrets
          secret:
            secretName: domain1-weblogic-credentials

(many more lines omitted)
```

## Verifying the domain creation

Write me

## Configuring the domain readiness

Kubernetes has a concept of “readiness” which is used to determine when external requests should be routed to a particular *pod*.  The *domain* creation *job* provided with the *operator* configures the readiness probe to use the WebLogic ReadyApp, which provides a mechanism to check when the server is actually ready to process work, as opposed to just in the RUNNING state.  Often applications have some work to do after the server is RUNNING but before they are ready to process new requests.

ReadyApp provides an API that allows an application to register itself, so that its state will be taken into consideration when determining if the server is “ready”, and an API that allows the application to inform ReadyApp when it considers itself to be ready.

Add details of how to use ReadyApp API
