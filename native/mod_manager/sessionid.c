/*
 *  mod_cluster
 *
 *  Copyright(c) 2009 Red Hat Middleware, LLC,
 *  and individual contributors as indicated by the @authors tag.
 *  See the copyright.txt in the distribution for a
 *  full listing of individual contributors.
 *
 *  This library is free software; you can redistribute it and/or
 *  modify it under the terms of the GNU Lesser General Public
 *  License as published by the Free Software Foundation; either
 *  version 2 of the License, or (at your option) any later version.
 *
 *  This library is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 *  Lesser General Public License for more details.
 *
 *  You should have received a copy of the GNU Lesser General Public
 *  License along with this library in the file COPYING.LIB;
 *  if not, write to the Free Software Foundation, Inc.,
 *  59 Temple Place - Suite 330, Boston, MA 02111-1307, USA
 *
 * @author Jean-Frederic Clere
 * @version $Revision$
 */

/**
 * @file  sessionid.c
 * @brief sessionid description Storage Module for Apache
 *
 * @defgroup MEM sessionids
 * @ingroup  APACHE_MODS
 * @{
 */

#include "apr.h"
#include "apr_strings.h"
#include "apr_pools.h"
#include "apr_time.h"

#include "ap_slotmem.h"
#include "sessionid.h"

#include "mod_manager.h"

static mem_t *create_attach_mem_sessionid(char *string, unsigned int *num, int type, int create, apr_pool_t *p,
                                          slotmem_storage_method *storage)
{
    mem_t *ptr;
    const char *storename;
    apr_status_t rv;

    ptr = apr_pcalloc(p, sizeof(mem_t));
    if (!ptr) {
        return NULL;
    }
    ptr->storage = storage;
    storename = apr_pstrcat(p, string, SESSIONIDEXE, NULL);
    if (create)
        rv = ptr->storage->create(&ptr->slotmem, storename, sizeof(sessionidinfo_t), *num, type, p);
    else {
        apr_size_t size = sizeof(sessionidinfo_t);
        rv = ptr->storage->attach(&ptr->slotmem, storename, &size, num, p);
    }
    if (rv != APR_SUCCESS) {
        return NULL;
    }
    ptr->num = *num;
    ptr->p = p;
    return ptr;
}

/**
 * Update a sessionid record in the shared table
 * @param pointer to the shared table.
 * @param sessionid sessionid to store in the shared table.
 * @return APR_SUCCESS if all went well
 *
 */
static apr_status_t update(void *mem, void *data, apr_pool_t *pool)
{
    sessionidinfo_t *in = (sessionidinfo_t *)data;
    sessionidinfo_t *ou = (sessionidinfo_t *)mem;
    (void)pool;

    if (strcmp(in->sessionid, ou->sessionid) == 0) {
        memcpy(ou, in, sizeof(sessionidinfo_t));
        ou->id = in->id;
        ou->updatetime = apr_time_sec(apr_time_now());
        return APR_EEXIST; /* it exists so we are done */
    }
    return APR_SUCCESS;
}

apr_status_t insert_update_sessionid(mem_t *s, sessionidinfo_t *sessionid)
{
    apr_status_t rv;
    sessionidinfo_t *ou;
    unsigned int id = 0;

    sessionid->id = 0;
    rv = s->storage->doall(s->slotmem, update, &sessionid, s->p);
    if (rv == APR_EEXIST) {
        return APR_SUCCESS; /* updated */
    }

    /* we have to insert it */
    rv = s->storage->grab(s->slotmem, &id);
    if (rv != APR_SUCCESS) {
        return rv;
    }
    rv = s->storage->dptr(s->slotmem, id, (void **)&ou);
    if (rv != APR_SUCCESS) {
        return rv;
    }
    memcpy(ou, sessionid, sizeof(sessionidinfo_t));
    ou->id = id;
    ou->updatetime = apr_time_sec(apr_time_now());

    return APR_SUCCESS;
}

/**
 * read a sessionid record from the shared table
 * @param pointer to the shared table.
 * @param sessionid sessionid to read from the shared table.
 * @return address of the read sessionid or NULL if error.
 */
static apr_status_t loc_read_sessionid(void *mem, void *data, apr_pool_t *pool)
{
    sessionidinfo_t *in = (sessionidinfo_t *)data;
    sessionidinfo_t *ou = (sessionidinfo_t *)mem;
    (void)pool;

    if (strcmp(in->sessionid, ou->sessionid) == 0) {
        in->id = ou->id;
        return APR_EEXIST;
    }
    return APR_SUCCESS;
}

sessionidinfo_t *read_sessionid(mem_t *s, sessionidinfo_t *sessionid)
{
    apr_status_t rv;
    sessionidinfo_t *ou;

    if (!sessionid->id) {
        rv = s->storage->doall(s->slotmem, loc_read_sessionid, sessionid, s->p);
        if (rv != APR_EEXIST)
            return NULL;
    }
    rv = s->storage->dptr(s->slotmem, sessionid->id, (void **)&ou);
    if (rv == APR_SUCCESS)
        return ou;
    return NULL;
}

/**
 * get a sessionid record from the shared table
 * @param pointer to the shared table.
 * @param sessionid address where the sessionid is locate in the shared table.
 * @param id  in the sessionid table.
 * @return APR_SUCCESS if all went well
 */
apr_status_t get_sessionid(mem_t *s, sessionidinfo_t **sessionid, int id)
{
    return s->storage->dptr(s->slotmem, id, (void **)sessionid);
}

/**
 * remove(free) a sessionid record from the shared table
 * @param pointer to the shared table.
 * @param sessionid sessionid to remove from the shared table.
 * @return APR_SUCCESS if all went well
 */
apr_status_t remove_sessionid(mem_t *s, sessionidinfo_t *sessionid)
{
    apr_status_t rv;
    sessionidinfo_t *ou = sessionid;
    if (sessionid->id) {
        rv = s->storage->release(s->slotmem, sessionid->id);
    }
    else {
        /* XXX: for the moment January 2007 ap_slotmem_free only uses ident to remove */
        rv = s->storage->doall(s->slotmem, loc_read_sessionid, &ou, s->p);
        if (rv == APR_EEXIST)
            rv = s->storage->release(s->slotmem, ou->id);
    }
    return rv;
}

/*
 * get the ids for the used (not free) sessionids in the table
 * @param pointer to the shared table.
 * @param ids array of int to store the used id (must be big enough).
 * @return number of sessionid existing or -1 if error.
 */
static apr_status_t loc_get_id(void *mem, void *data, apr_pool_t *pool)
{
    struct counter *count = (struct counter *)data;
    sessionidinfo_t *ou = (sessionidinfo_t *)mem;
    *count->values = ou->id;
    count->values++;
    count->count++;
    return APR_SUCCESS;
}
int get_ids_used_sessionid(mem_t *s, int *ids)
{
    struct counter count;
    count.count = 0;
    count.values = ids;
    if (s->storage->doall(s->slotmem, loc_get_id, &count, s->p) != APR_SUCCESS)
        return 0;
    return count.count;
}

/*
 * read the size of the table.
 * @param pointer to the shared table.
 * @return number of sessionid existing or -1 if error.
 */
int get_max_size_sessionid(mem_t *s)
{
    return s->storage->num_slots(s->slotmem);
}

/**
 * attach to the shared sessionid table
 * @param name of an existing shared table.
 * @param address to store the size of the shared table.
 * @param p pool to use for allocations.
 * @return address of struct used to access the table.
 */
mem_t *get_mem_sessionid(char *string, unsigned int *num, apr_pool_t *p, slotmem_storage_method *storage)
{
    return create_attach_mem_sessionid(string, num, 0, 0, p, storage);
}

/**
 * create a shared sessionid table
 * @param name to use to create the table.
 * @param size of the shared table.
 * @param persist tell if the slotmem element are persistent.
 * @param p pool to use for allocations.
 * @return address of struct used to access the table.
 */
mem_t *create_mem_sessionid(char *string, unsigned int *num, int persist, apr_pool_t *p, slotmem_storage_method *storage)
{
    return create_attach_mem_sessionid(string, num, persist, 1, p, storage);
}
