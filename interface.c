#include <r_core.h>
#include <r_lang.h>
#include "HsFFI.h"
#include "lang_haskell_stub.h"

int init(RLang *user)
{
	hs_init(0, 0);
	return R_TRUE;
}

bool setup(RLang *user)
{
	return R_TRUE;
}


int fini(RLang *user)
{
	return R_TRUE;
}

int prompt(RLang *user)
{
	return R_TRUE;
}

int run(RLang *user, const char *code, int len)
{
	eprintf("%s", code);
	return R_TRUE;
}

RLangPlugin plugin_haskell = {
	.name = "haskell",
	.alias = "hask",
	.desc = "Haskell language extension",
	.license = NULL,
	.help = NULL,
	.ext = "hs",
	.init = &init,
	.setup = &setup,
	.fini = &fini,
	.prompt = &prompt,
	.run = &run,
	.run_file = NULL,
	.set_argv = NULL
};

#ifndef CORELIB
struct r_lib_struct_t radare_plugin = {
	.type = R_LIB_TYPE_LANG,
	.data = &plugin_haskell,
};
#endif
