/* dwm config cloned from oxwm (Mod4, st, colors, gaps, rules, keys). */

/* appearance */
static const unsigned int borderpx  = 2;
static const unsigned int snap      = 32;
static const unsigned int gappih    = 5;
static const unsigned int gappiv    = 5;
static const unsigned int gappoh    = 5;
static const unsigned int gappov    = 5;
static int smartgaps          = 1;
static const int showbar            = 1;
static const int topbar             = 1;
static const char *fonts[]          = { "JetBrainsMono Nerd Font:style=Bold:size=10" };
static const char dmenufont[]       = "JetBrainsMono Nerd Font:style=Bold:size=10";
static const char col_fg[]          = "#bbbbbb";
static const char col_bg[]          = "#1a1b26";
static const char col_gray2[]       = "#444444";
static const char col_cyan[]        = "#0db9d7";
static const char col_blue[]        = "#6dade3";
static const char *colors[][3]      = {
	/*               fg         bg         border   */
	[SchemeNorm] = { col_fg,    col_bg,    col_gray2 },
	[SchemeSel]  = { col_cyan,  col_bg,    col_blue  },
};

/* tagging — same nerd-font icons as oxwm */
static const char *tags[] = { "", "󰊯", "", "", "󰙯", "󱇤", "", "󱘶", "󰧮" };

static const Rule rules[] = {
	/* class               instance    title          tags mask  isfloating  monitor */
	{ "Gimp",              NULL,       NULL,          0,         1,          -1 },
	{ "gimp",              NULL,       NULL,          0,         1,          -1 },
	{ "mpv",               NULL,       NULL,          0,         1,          -1 },
	{ "st",                NULL,       "hx",          0,         1,          -1 },
	{ "st",                NULL,       "hx-anywhere", 0,         1,          -1 },
	{ "st",                NULL,       "nnn",         0,         1,          -1 },
	{ "St",                NULL,       "hx",          0,         1,          -1 },
	{ "St",                NULL,       "nnn",         0,         1,          -1 },
	{ "Pavucontrol",       NULL,       NULL,          0,         1,          -1 },
	{ "pavucontrol",       NULL,       NULL,          0,         1,          -1 },
	{ "dde-control-center",NULL,       NULL,          0,         1,          -1 },
	{ "fcitx5-configtool", NULL,       NULL,          0,         1,          -1 },
	{ "fcitx-configtool",  NULL,       NULL,          0,         1,          -1 },
	{ "aTrustTray2",       NULL,       NULL,          0,         1,          -1 },
	{ "aTrustAgent",       NULL,       NULL,          0,         1,          -1 },
};

/* layout(s) */
static const float mfact     = 0.50;
static const int nmaster     = 1;
static const int resizehints = 0;
static const int lockfullscreen = 1;

#define FORCE_VSPLIT 1
#include "vanitygaps.c"

static const Layout layouts[] = {
	/* symbol     arrange function */
	{ "[T]",      tile },
	{ "[F]",      NULL },
	{ "[M]",      monocle },
};

static void
cyclelayout(const Arg *arg)
{
	int i = 0;

	for (i = 0; i < LENGTH(layouts) && selmon->lt[selmon->sellt] != &layouts[i]; i++)
		;
	i += arg->i;
	if (i < 0)
		i = LENGTH(layouts) - 1;
	else if (i >= LENGTH(layouts))
		i = 0;
	setlayout(&((Arg) { .v = &layouts[i] }));
}

/* key definitions */
#define MODKEY Mod4Mask
#define TAGKEYS(KEY,TAG) \
	{ MODKEY,                       KEY,      view,           {.ui = 1 << TAG} }, \
	{ MODKEY|ControlMask,           KEY,      toggleview,     {.ui = 1 << TAG} }, \
	{ MODKEY|ShiftMask,             KEY,      tag,            {.ui = 1 << TAG} }, \
	{ MODKEY|ControlMask|ShiftMask, KEY,      toggletag,      {.ui = 1 << TAG} },

#define SHCMD(cmd) { .v = (const char*[]){ "/bin/sh", "-c", cmd, NULL } }

/* commands */
static char dmenumon[2] = "0";
static const char *dmenucmd[] = { "dmenu_run", "-l", "10", "-m", dmenumon, "-fn", dmenufont, "-nb", col_bg, "-nf", col_fg, "-sb", col_blue, "-sf", col_bg, NULL };
static const char *termcmd[]  = { "st", NULL };
static const char *bravecmd[] = { "brave", NULL };
static const char *hxcmd[]    = { "st", "-t", "hx", "-e", "hx", NULL };
static const char *nnncmd[]   = { "st", "-t", "nnn", "-e", "nnn", NULL };
static const char *scrotcmd[] = { "screenshot-to-clipboard", NULL };
static const char *hxanycmd[] = { "hx-anywhere", NULL };
static const char *restartcmd[] = { "pkill", "-x", "dwm", NULL };
static const char *imebtncmd[]  = { "fcitx5-configtool", NULL };
static const char *volbtncmd[]  = { "pavucontrol", NULL };

static const Key keys[] = {
	/* modifier                     key        function        argument */
	{ MODKEY,                       XK_Return, spawn,          {.v = termcmd } },
	{ MODKEY,                       XK_d,      spawn,          {.v = dmenucmd } },
	{ MODKEY,                       XK_g,      spawn,          {.v = bravecmd } },
	{ MODKEY,                       XK_e,      spawn,          {.v = hxcmd } },
	{ MODKEY|ShiftMask,             XK_n,      spawn,          {.v = nnncmd } },
	{ ControlMask|Mod1Mask,         XK_v,      spawn,          {.v = hxanycmd } },
	{ MODKEY,                       XK_s,      spawn,          {.v = scrotcmd } },
	{ MODKEY,                       XK_q,      killclient,     {0} },
	{ MODKEY|ShiftMask,             XK_slash,  spawn,          SHCMD("st -t keybinds -e less \"$HOME/.config/dwm/keybinds.txt\"") },
	{ MODKEY,                       XK_f,      togglefloating, {0} },
	{ MODKEY|ShiftMask,             XK_f,      setlayout,      {.v = &layouts[2]} },
	{ MODKEY|ShiftMask,             XK_space,  cyclelayout,    {.i = +1 } },
	{ MODKEY,                       XK_h,      setmfact,       {.f = -0.05} },
	{ MODKEY,                       XK_l,      setmfact,       {.f = +0.05} },
	{ MODKEY,                       XK_i,      incnmaster,     {.i = +1 } },
	{ MODKEY,                       XK_p,      incnmaster,     {.i = -1 } },
	{ MODKEY,                       XK_a,      togglegaps,     {0} },
	{ MODKEY,                       XK_b,      togglebar,      {0} },
	{ MODKEY,                       XK_j,      focusstack,     {.i = +1 } },
	{ MODKEY,                       XK_k,      focusstack,     {.i = -1 } },
	{ MODKEY|ShiftMask,             XK_j,      zoom,           {0} },
	{ MODKEY|ShiftMask,             XK_k,      zoom,           {0} },
	{ MODKEY,                       XK_comma,  focusmon,       {.i = -1 } },
	{ MODKEY,                       XK_period, focusmon,       {.i = +1 } },
	{ MODKEY|ShiftMask,             XK_comma,  tagmon,         {.i = -1 } },
	{ MODKEY|ShiftMask,             XK_period, tagmon,         {.i = +1 } },
	{ MODKEY,                       XK_Tab,    view,           {0} },
	{ MODKEY,                       XK_0,      view,           {.ui = ~0 } },
	{ MODKEY|ShiftMask,             XK_0,      tag,            {.ui = ~0 } },
	{ MODKEY|ShiftMask,             XK_r,      spawn,          {.v = restartcmd } },
	TAGKEYS(                        XK_1,                      0)
	TAGKEYS(                        XK_2,                      1)
	TAGKEYS(                        XK_3,                      2)
	TAGKEYS(                        XK_4,                      3)
	TAGKEYS(                        XK_5,                      4)
	TAGKEYS(                        XK_6,                      5)
	TAGKEYS(                        XK_7,                      6)
	TAGKEYS(                        XK_8,                      7)
	TAGKEYS(                        XK_9,                      8)
	{ MODKEY|ShiftMask,             XK_q,      quit,           {0} },
};

static const Button buttons[] = {
	/* click                event mask      button          function        argument */
	{ ClkLtSymbol,          0,              Button1,        cyclelayout,    {.i = +1 } },
	{ ClkLtSymbol,          0,              Button3,        setlayout,      {.v = &layouts[2]} },
	{ ClkWinTitle,          0,              Button2,        zoom,           {0} },
	{ ClkStatusText,        0,              Button1,        spawn,          {.v = imebtncmd } },
	{ ClkStatusText,        0,              Button3,        spawn,          {.v = volbtncmd } },
	{ ClkClientWin,         MODKEY,         Button1,        movemouse,      {0} },
	{ ClkClientWin,         MODKEY,         Button2,        togglefloating, {0} },
	{ ClkClientWin,         MODKEY,         Button3,        resizemouse,    {0} },
	{ ClkTagBar,            0,              Button1,        view,           {0} },
	{ ClkTagBar,            0,              Button3,        toggleview,     {0} },
	{ ClkTagBar,            MODKEY,         Button1,        tag,            {0} },
	{ ClkTagBar,            MODKEY,         Button3,        toggletag,      {0} },
};
