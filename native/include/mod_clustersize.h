/*
 * Copyright The mod_cluster Project Authors
 * SPDX-License-Identifier: Apache-2.0
 */

/*
 * @author Jean-Frederic Clere
 */

#ifndef MOD_CLUSTERSIZE_H
#define MOD_CLUSTERSIZE_H

/* For host.h */
#define HOSTALIAS_SIZE 255

/* For context.h */
#define CONTEXT_SIZE   80

/* For node.h */
#define BALANCER_SIZE  40
#define JVMROUTE_SIZE  64
#define DOMAIN_SIZE    20
#define HOSTNODE_SIZE  64
#define PORTNODE_SIZE  7
#define SCHEME_SIZE    16
#define AJPSECRET_SIZE 64

/* For balancer.h */
#define COOKNAME_SIZE  30
#define PATHNAME_SIZE  30

/* For sessionid.h */
#define SESSIONID_SIZE 128

#endif /* MOD_CLUSTERSIZE_H */
