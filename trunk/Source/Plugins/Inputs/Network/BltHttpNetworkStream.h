/*****************************************************************
|
|   BlueTune - HTTP Network Stream
|
|   (c) 2002-2006 Gilles Boccon-Gibod
|   Author: Gilles Boccon-Gibod (bok@bok.net)
|
****************************************************************/

#ifndef _BLT_HTTP_NETWORK_STREAM_H_
#define _BLT_HTTP_NETWORK_STREAM_H_

/*----------------------------------------------------------------------
|   includes
+---------------------------------------------------------------------*/
#include "BltTypes.h"
#include "BltModule.h"

/*----------------------------------------------------------------------
|   functions
+---------------------------------------------------------------------*/
#if defined(__cplusplus)
extern "C" {
#endif

BLT_Result 
BLT_HttpNetworkStream_Create(const char* url, ATX_InputStream** stream);

#if defined(__cplusplus)
}
#endif

#endif /* _BLT_HTTP_NETWORK_STREAM_H_ */
