#!/bin/bash

set -x

rm -rf ${DOMAIN_PATH}

java weblogic.WLST << EOF

weblogic_version         = "${WEBLOGIC_VERSION}"
domain_uid               = "${DOMAIN_UID}"
domain_name              = "${DOMAIN_NAME}"
domain_path              = "${DOMAIN_PATH}"
admin_username           = "${ADMIN_USERNAME}"
admin_password           = "${ADMIN_PASSWORD}"
production_mode_enabled  = true

admin_server_name        = "${ADMIN_SERVER_NAME}"
admin_server_port        = ${ADMIN_SERVER_PORT}
t3_channel_port          = ${T3_CHANNEL_PORT}
t3_public_address        = "${T3_PUBLIC_ADDRESS}"

cluster_name             = "${CLUSTER_NAME}"
number_of_ms             = ${MANAGED_SERVER_COUNT}
managed_server_port      = ${MANAGED_SERVER_PORT}
managed_server_base_name = "${MANAGED_SERVER_BASE_NAME}"

selectTemplate('Basic WebLogic Server Domain', weblogic_version)
loadTemplates()

# configure the domain
cd('/')
cmo.setName(domain_name)
setOption('DomainName', domain_name)

cd('/Security/' + domain_name + '/User/weblogic')
cmo.setName(admin_username)
cmo.setPassword(admin_password)

# configure the admin server
cd('/Servers/AdminServer')
cmo.setName(admin_server_name)
cmo.setListenPort(admin_server_port)
cmo.setListenAddress(domain_uid + "-" + admin_server_name)

# TBD - who should configure this? i.e. should it move to sit config?
nap=create('T3Channel', 'NetworkAccessPoint')
nap.setPublicPort(t3_channel_port)
nap.setPublicAddress(t3_public_address)
nap.setListenPort(t3_channel_port)

# create the cluster
cd('/')
cl=create(cluster_name, 'Cluster')

for index in range(1, number_of_ms+1):
  name = managed_server_base_name + str(index)
  ms=create(name, 'Server')
  ms.setCluster(cl)
  ms.setListenPort(managed_server_port)
  ms.setListenAddress(domain_uid + '-' + name)
  ms.setNumOfRetriesBeforeMSIMode(0)
  ms.setRetryIntervalBeforeMSIMode(1)

# write out the domain
setOption('OverwriteDomain', 'true')
writeDomain(domain_path)
closeTemplate()

# convert it to production mode
readDomain(domain_path)
cd('/')
cmo.setProductionModeEnabled(true)
updateDomain()
closeDomain()

exit()

EOF
