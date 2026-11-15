#ifndef _px68k_android_support_h
#define _px68k_android_support_h

#ifdef ANDROID
#include <stddef.h>

#ifdef __cplusplus
extern "C" {
#endif

int Android_GetDataDir(char *out, size_t len);
void Android_ShowRomMissing(const char *dir);

#ifdef __cplusplus
}
#endif

#endif // ANDROID
#endif
