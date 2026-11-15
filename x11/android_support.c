// android_support.c - helpers for modern Android (scoped storage etc.)
// このファイルだけ UTF-8 です (SDL のメッセージボックスが UTF-8 を要求するため)

#ifdef ANDROID

#include <stdio.h>
#include <string.h>
#include <unistd.h>
#include <sys/stat.h>
#include <SDL.h>
#include "common.h"
#include "android_support.h"

static int is_usable_dir(const char *path)
{
	struct stat sb;

	if (stat(path, &sb) != 0 || !S_ISDIR(sb.st_mode))
		return 0;
	return access(path, R_OK | W_OK | X_OK) == 0;
}

// データディレクトリを決める。優先順位:
//  1. (内部ストレージ)/px68k           ...「すべてのファイルへのアクセス」が必要
//  2. (アプリ専用領域)/dir.txt の1行目  ... 従来互換
//  3. 1. を新規作成 (権限がある場合のみ成功する)
//  4. (内部ストレージ)/Android/data/<package>/files ... 権限不要
int Android_GetDataDir(char *out, size_t len)
{
	const char *extpath;
	char shared[MAX_PATH], buf[MAX_PATH];
	char *p;
	FILE *fp;

	shared[0] = '\0';
	extpath = SDL_AndroidGetExternalStoragePath();
	p6logd("extpath:%s", extpath ? extpath : "(null)");

	if (extpath != NULL && strlen(extpath) < MAX_PATH - 16) {
		strcpy(shared, extpath);
		p = strstr(shared, "/Android/data/");
		if (p != NULL) {
			*p = '\0';
			strcat(shared, "/px68k");
		} else {
			shared[0] = '\0';
		}
	}

	// 1.
	if (shared[0] != '\0' && is_usable_dir(shared)) {
		snprintf(out, len, "%s", shared);
		return 0;
	}

	// 2.
	if (extpath != NULL) {
		snprintf(buf, sizeof(buf), "%s/dir.txt", extpath);
		if ((fp = fopen(buf, "r")) != NULL) {
			buf[0] = '\0';
			if (fgets(buf, sizeof(buf) - 1, fp) != NULL) {
				buf[strcspn(buf, "\r\n")] = '\0';
			}
			fclose(fp);
			if (buf[0] != '\0' && is_usable_dir(buf)) {
				snprintf(out, len, "%s", buf);
				return 0;
			}
		}
	}

	// 3.
	if (shared[0] != '\0') {
		mkdir(shared, 0775);
		if (is_usable_dir(shared)) {
			snprintf(out, len, "%s", shared);
			return 0;
		}
	}

	// 4.
	if (extpath != NULL) {
		snprintf(out, len, "%s", extpath);
		return 0;
	}

	// 最後の手段 (アプリ内部領域)
	extpath = SDL_AndroidGetInternalStoragePath();
	snprintf(out, len, "%s", extpath ? extpath : "/sdcard/px68k");
	return 0;
}

void Android_ShowRomMissing(const char *dir)
{
	char msg[MAX_PATH + 512];

	snprintf(msg, sizeof(msg),
		 "BIOS ROM またはフォント ROM が見つかりません。\n\n"
		 "次のフォルダに iplrom.dat (または iplrom30.dat / iplromco.dat / "
		 "iplromxv.dat) と cgrom.dat (または cgrom.tmp) を置いてから、"
		 "もう一度起動してください。\n\n%s", dir);
	SDL_ShowSimpleMessageBox(SDL_MESSAGEBOX_ERROR, "PX68K", msg, NULL);
}

#endif // ANDROID
