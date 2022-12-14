/* http.h generated by valac 0.48.24, the Vala compiler, do not modify */

#ifndef __SRC_HTTP_H__
#define __SRC_HTTP_H__

#include <glib.h>
#include <glib-object.h>
#include <stdlib.h>
#include <string.h>
#include <gee.h>
#include <gio/gio.h>

G_BEGIN_DECLS

typedef enum  {
	HTTP_METHOD_HEAD,
	HTTP_METHOD_GET,
	HTTP_METHOD_POST
} HttpMethod;

#define HTTP_TYPE_METHOD (http_method_get_type ())

#define HTTP_TYPE_BYTE_ARRAY (http_byte_array_get_type ())
#define HTTP_BYTE_ARRAY(obj) (G_TYPE_CHECK_INSTANCE_CAST ((obj), HTTP_TYPE_BYTE_ARRAY, HttpByteArray))
#define HTTP_BYTE_ARRAY_CLASS(klass) (G_TYPE_CHECK_CLASS_CAST ((klass), HTTP_TYPE_BYTE_ARRAY, HttpByteArrayClass))
#define HTTP_IS_BYTE_ARRAY(obj) (G_TYPE_CHECK_INSTANCE_TYPE ((obj), HTTP_TYPE_BYTE_ARRAY))
#define HTTP_IS_BYTE_ARRAY_CLASS(klass) (G_TYPE_CHECK_CLASS_TYPE ((klass), HTTP_TYPE_BYTE_ARRAY))
#define HTTP_BYTE_ARRAY_GET_CLASS(obj) (G_TYPE_INSTANCE_GET_CLASS ((obj), HTTP_TYPE_BYTE_ARRAY, HttpByteArrayClass))

typedef struct _HttpByteArray HttpByteArray;
typedef struct _HttpByteArrayClass HttpByteArrayClass;
typedef struct _HttpByteArrayPrivate HttpByteArrayPrivate;

#define HTTP_TYPE_URL (http_url_get_type ())
#define HTTP_URL(obj) (G_TYPE_CHECK_INSTANCE_CAST ((obj), HTTP_TYPE_URL, HttpURL))
#define HTTP_URL_CLASS(klass) (G_TYPE_CHECK_CLASS_CAST ((klass), HTTP_TYPE_URL, HttpURLClass))
#define HTTP_IS_URL(obj) (G_TYPE_CHECK_INSTANCE_TYPE ((obj), HTTP_TYPE_URL))
#define HTTP_IS_URL_CLASS(klass) (G_TYPE_CHECK_CLASS_TYPE ((klass), HTTP_TYPE_URL))
#define HTTP_URL_GET_CLASS(obj) (G_TYPE_INSTANCE_GET_CLASS ((obj), HTTP_TYPE_URL, HttpURLClass))

typedef struct _HttpURL HttpURL;
typedef struct _HttpURLClass HttpURLClass;
typedef struct _HttpURLPrivate HttpURLPrivate;

#define HTTP_TYPE_STATUS (http_status_get_type ())
#define HTTP_STATUS(obj) (G_TYPE_CHECK_INSTANCE_CAST ((obj), HTTP_TYPE_STATUS, HttpStatus))
#define HTTP_STATUS_CLASS(klass) (G_TYPE_CHECK_CLASS_CAST ((klass), HTTP_TYPE_STATUS, HttpStatusClass))
#define HTTP_IS_STATUS(obj) (G_TYPE_CHECK_INSTANCE_TYPE ((obj), HTTP_TYPE_STATUS))
#define HTTP_IS_STATUS_CLASS(klass) (G_TYPE_CHECK_CLASS_TYPE ((klass), HTTP_TYPE_STATUS))
#define HTTP_STATUS_GET_CLASS(obj) (G_TYPE_INSTANCE_GET_CLASS ((obj), HTTP_TYPE_STATUS, HttpStatusClass))

typedef struct _HttpStatus HttpStatus;
typedef struct _HttpStatusClass HttpStatusClass;
typedef struct _HttpStatusPrivate HttpStatusPrivate;

#define HTTP_TYPE_RESPONSE (http_response_get_type ())
#define HTTP_RESPONSE(obj) (G_TYPE_CHECK_INSTANCE_CAST ((obj), HTTP_TYPE_RESPONSE, HttpResponse))
#define HTTP_RESPONSE_CLASS(klass) (G_TYPE_CHECK_CLASS_CAST ((klass), HTTP_TYPE_RESPONSE, HttpResponseClass))
#define HTTP_IS_RESPONSE(obj) (G_TYPE_CHECK_INSTANCE_TYPE ((obj), HTTP_TYPE_RESPONSE))
#define HTTP_IS_RESPONSE_CLASS(klass) (G_TYPE_CHECK_CLASS_TYPE ((klass), HTTP_TYPE_RESPONSE))
#define HTTP_RESPONSE_GET_CLASS(obj) (G_TYPE_INSTANCE_GET_CLASS ((obj), HTTP_TYPE_RESPONSE, HttpResponseClass))

typedef struct _HttpResponse HttpResponse;
typedef struct _HttpResponseClass HttpResponseClass;
typedef struct _HttpResponsePrivate HttpResponsePrivate;

#define HTTP_TYPE_CLIENT (http_client_get_type ())
#define HTTP_CLIENT(obj) (G_TYPE_CHECK_INSTANCE_CAST ((obj), HTTP_TYPE_CLIENT, HttpClient))
#define HTTP_CLIENT_CLASS(klass) (G_TYPE_CHECK_CLASS_CAST ((klass), HTTP_TYPE_CLIENT, HttpClientClass))
#define HTTP_IS_CLIENT(obj) (G_TYPE_CHECK_INSTANCE_TYPE ((obj), HTTP_TYPE_CLIENT))
#define HTTP_IS_CLIENT_CLASS(klass) (G_TYPE_CHECK_CLASS_TYPE ((klass), HTTP_TYPE_CLIENT))
#define HTTP_CLIENT_GET_CLASS(obj) (G_TYPE_INSTANCE_GET_CLASS ((obj), HTTP_TYPE_CLIENT, HttpClientClass))

typedef struct _HttpClient HttpClient;
typedef struct _HttpClientClass HttpClientClass;
typedef struct _HttpClientPrivate HttpClientPrivate;

typedef enum  {
	HTTP_HTTP_ERROR_MALFORMED_URL,
	HTTP_HTTP_ERROR_BAD_RESPONSE,
	HTTP_HTTP_ERROR_UNSUPPORTED_PROTOCOL,
	HTTP_HTTP_ERROR_UNKNOWN_TRANSFER_LENGTH,
	HTTP_HTTP_ERROR_BAD_CHUNK_SIZE,
	HTTP_HTTP_ERROR_UNKNOWN_PAYLOAD_LENGTH,
	HTTP_HTTP_ERROR_CONNECTION_ERROR
} HttpHttpError;
#define HTTP_HTTP_ERROR http_http_error_quark ()
struct _HttpByteArray {
	GTypeInstance parent_instance;
	volatile int ref_count;
	HttpByteArrayPrivate * priv;
	gssize download_size;
};

struct _HttpByteArrayClass {
	GTypeClass parent_class;
	void (*finalize) (HttpByteArray *self);
};

struct _HttpURL {
	GTypeInstance parent_instance;
	volatile int ref_count;
	HttpURLPrivate * priv;
};

struct _HttpURLClass {
	GTypeClass parent_class;
	void (*finalize) (HttpURL *self);
};

struct _HttpStatus {
	GTypeInstance parent_instance;
	volatile int ref_count;
	HttpStatusPrivate * priv;
};

struct _HttpStatusClass {
	GTypeClass parent_class;
	void (*finalize) (HttpStatus *self);
};

struct _HttpResponse {
	GTypeInstance parent_instance;
	volatile int ref_count;
	HttpResponsePrivate * priv;
};

struct _HttpResponseClass {
	GTypeClass parent_class;
	void (*finalize) (HttpResponse *self);
};

struct _HttpClient {
	GObject parent_instance;
	HttpClientPrivate * priv;
	GeeHashMap* headers;
};

struct _HttpClientClass {
	GObjectClass parent_class;
};

GQuark http_http_error_quark (void);
GType http_method_get_type (void) G_GNUC_CONST;
gchar* http_method_to_string (HttpMethod self);
gpointer http_byte_array_ref (gpointer instance);
void http_byte_array_unref (gpointer instance);
GParamSpec* http_param_spec_byte_array (const gchar* name,
                                        const gchar* nick,
                                        const gchar* blurb,
                                        GType object_type,
                                        GParamFlags flags);
void http_value_set_byte_array (GValue* value,
                                gpointer v_object);
void http_value_take_byte_array (GValue* value,
                                 gpointer v_object);
gpointer http_value_get_byte_array (const GValue* value);
GType http_byte_array_get_type (void) G_GNUC_CONST;
G_DEFINE_AUTOPTR_CLEANUP_FUNC (HttpByteArray, http_byte_array_unref)
HttpByteArray* http_byte_array_new (guint8* data,
                                    gint data_length1,
                                    gssize length,
                                    gssize down_size);
HttpByteArray* http_byte_array_construct (GType object_type,
                                          guint8* data,
                                          gint data_length1,
                                          gssize length,
                                          gssize down_size);
gssize http_byte_array_get_length (HttpByteArray* self);
guint8* http_byte_array_get_data (HttpByteArray* self,
                                  gint* result_length1);
gpointer http_url_ref (gpointer instance);
void http_url_unref (gpointer instance);
GParamSpec* http_param_spec_url (const gchar* name,
                                 const gchar* nick,
                                 const gchar* blurb,
                                 GType object_type,
                                 GParamFlags flags);
void http_value_set_url (GValue* value,
                         gpointer v_object);
void http_value_take_url (GValue* value,
                          gpointer v_object);
gpointer http_value_get_url (const GValue* value);
GType http_url_get_type (void) G_GNUC_CONST;
G_DEFINE_AUTOPTR_CLEANUP_FUNC (HttpURL, http_url_unref)
HttpURL* http_url_new_from_string (const gchar* url_str,
                                   GError** error);
HttpURL* http_url_construct_from_string (GType object_type,
                                         const gchar* url_str,
                                         GError** error);
gchar* http_url_to_string (HttpURL* self);
HttpURL* http_url_new (void);
HttpURL* http_url_construct (GType object_type);
const gchar* http_url_get_scheme (HttpURL* self);
const gchar* http_url_get_host (HttpURL* self);
guint16 http_url_get_port (HttpURL* self);
const gchar* http_url_get_path (HttpURL* self);
const gchar* http_url_get_query (HttpURL* self);
const gchar* http_url_get_fragment (HttpURL* self);
const gchar* http_url_get_raw (HttpURL* self);
gpointer http_status_ref (gpointer instance);
void http_status_unref (gpointer instance);
GParamSpec* http_param_spec_status (const gchar* name,
                                    const gchar* nick,
                                    const gchar* blurb,
                                    GType object_type,
                                    GParamFlags flags);
void http_value_set_status (GValue* value,
                            gpointer v_object);
void http_value_take_status (GValue* value,
                             gpointer v_object);
gpointer http_value_get_status (const GValue* value);
GType http_status_get_type (void) G_GNUC_CONST;
G_DEFINE_AUTOPTR_CLEANUP_FUNC (HttpStatus, http_status_unref)
gchar* http_status_to_string (HttpStatus* self);
const gchar* http_status_get_protocol_version (HttpStatus* self);
guint http_status_get_code (HttpStatus* self);
const gchar* http_status_get_text (HttpStatus* self);
gpointer http_response_ref (gpointer instance);
void http_response_unref (gpointer instance);
GParamSpec* http_param_spec_response (const gchar* name,
                                      const gchar* nick,
                                      const gchar* blurb,
                                      GType object_type,
                                      GParamFlags flags);
void http_value_set_response (GValue* value,
                              gpointer v_object);
void http_value_take_response (GValue* value,
                               gpointer v_object);
gpointer http_value_get_response (const GValue* value);
GType http_response_get_type (void) G_GNUC_CONST;
G_DEFINE_AUTOPTR_CLEANUP_FUNC (HttpResponse, http_response_unref)
gchar* http_response_to_string (HttpResponse* self);
GeeHashMap* http_response_get_headers (HttpResponse* self);
HttpStatus* http_response_get_status (HttpResponse* self);
HttpByteArray* http_response_get_payload (HttpResponse* self);
gchar* http_encode (GeeHashMap* data);
GType http_client_get_type (void) G_GNUC_CONST;
G_DEFINE_AUTOPTR_CLEANUP_FUNC (HttpClient, g_object_unref)
HttpClient* http_client_new (void);
HttpClient* http_client_construct (GType object_type);
HttpResponse* http_client_get (HttpClient* self,
                               const gchar* raw_url,
                               GError** error);
HttpResponse* http_client_post (HttpClient* self,
                                const gchar* raw_url,
                                const gchar* data,
                                GeeHashMap* post_headers,
                                GError** error);
HttpResponse* http_client_post_form (HttpClient* self,
                                     const gchar* raw_url,
                                     GeeHashMap* data,
                                     GError** error);
HttpResponse* http_client_head (HttpClient* self,
                                const gchar* raw_url,
                                GError** error);
gboolean http_client_get_allow_cookies (HttpClient* self);
void http_client_set_allow_cookies (HttpClient* self,
                                    gboolean value);
gboolean http_client_get_use_compression (HttpClient* self);
void http_client_set_use_compression (HttpClient* self,
                                      gboolean value);
guint http_client_get_timeout (HttpClient* self);
void http_client_set_timeout (HttpClient* self,
                              guint value);

G_END_DECLS

#endif
