/*
 * File: pp.c
 * Author: Jørgen Bele Reinfjell
 * Date: 01.07.2018 [dd.mm.yyyy]
 * Description:
 *  A simple shell script pre-processor used to
 *  include shell script functions in "modules".
 *
 *  Example usage:
 *  #!/bin/sh
 *  # Imports funcname from module 'modulename'
 *  # Does NOT take care of transitive dependencies.
 *  #!import modulename.funcname 
 *
 *  #!/bin/sh
 *  # Imports all functions from module 'modulename'
 *  #!import modulename
 *
 *file: modulename.m
 *  #!/bin/sh
 *  # Modules are defined as scripts named with the
 *  # same name as the module and with the '.m' extension.
 */

/*
 * !! The modules to be imported HAS to be passed as a input file parameter. 
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <stdarg.h>
#include <ctype.h>

#include <stdbool.h>

struct function {
    char *name;     /* The function identifier.       */
    char *contents; /* ALL of the functions contents. */
};

struct module {
    char *name;             /* The module name/identifier. */
    struct function *funcv; /* The vector of functions which the module
                             * consists of. */
    size_t funcc;           /* The number of functions in the vector. */
};

enum state {OUTER, STRING, COMMENT, FUNCTION}; /* Parse state. */

/* Globals. */
bool verbose_output = false;
const char *outfile = "outfile";

void verbosef(const char *fmt, ...) {
    if (!verbose_output) {
        return;
    }

    va_list ap;
    va_start(ap, fmt);
    vfprintf(stderr, fmt, ap);
    va_end(ap); // XXX - remove?
}

void errorf(const char *fmt, ...) {
    va_list ap;
    va_start(ap, fmt);
    vfprintf(stderr, fmt, ap);
    va_end(ap); // XXX - remove?
}

void *xcalloc(size_t nmembs, size_t membsize) {
    void *m = calloc(nmembs, membsize);
    if (!m) {
        perror("calloc");
        exit(1);
    }
    return m;
}

// ALLOCS
char *modulename(const char *path) {
    int pathlen = strlen(path);
    int lastslash = -1;
    int lastext = pathlen-1;

    for (int i = 0; i < pathlen; i++) {
        if (path[i] == '/') {
            lastslash = i;
        } else if (path[i] == '.') {
            lastext = i;
        }
    }

    char *mname = xcalloc(pathlen+1, 1);
    char *p = mname;

    for (int i = lastslash+1; i < lastext; i++) {
        *p++ = path[i];
    }
    *p = '\0';

    return mname;
}

/* ALLOCS */
/* double the buffer given by b. If *b == NULL then
 * create a new empty zeroed-buffer, else memcpy the old buffer
 * over to the new zeroed-buffer. */
void extend_buf(char **b, size_t *bsize) {
    size_t nsize = *bsize*2 + 2;
    char *n = xcalloc(nsize, 1);
    if (*b != NULL) {
        memcpy(n, *b, *bsize);
        free(*b);
    }
    *b = n;
    *bsize = nsize;
}

/* Add a character to the end of the buffer. */
void pushc(char **b, size_t *bsize, size_t *bufi, int c) {
    if (*bufi + 1 + 1 >= *bsize) {
        extend_buf(b, bsize);
    }
    (*b)[*bufi] = c;
    (*bufi)++;
}

/* Add a string to the end of the buffer. */
void pushstrn(char **b, size_t *bsize, size_t *bufi, char *s, size_t max) {
    while (max-- > 0 && *s) {
        pushc(b, bsize, bufi, *s);
        s++;
    }
}

/* Get the next token. */
ssize_t getnext(char **b, size_t *bsize, FILE *f) {
    size_t bufi = 0;

    bool ok;
    while ((ok = !feof(f) && !ferror(f))) {
        int c = fgetc(f);
        if (c == EOF) {
            break;
        }
        pushc(b, bsize, &bufi, c);
        if (!isalnum(c)) {
            break;
        }
    }
    pushc(b, bsize, &bufi, '\0');
    return bufi-1;
}

/* Trims a returns a pointer to the new trimmed start. */
char *trim(char *s) {
    while (*s && isblank(*s)) s++;
    char *p = s;
    while (*p && !isblank(*p)) p++;
    *p = '\0';
    return s;
}

int trimcmp(const char *p, const char *q) {
    while (*p && isblank(*p)) p++;
    while (*q && isblank(*q)) q++;

    size_t plen = 0;
    while (p[plen] && !isblank(p[plen])) plen++;
    size_t qlen = 0;
    while (q[qlen] && !isblank(q[qlen])) qlen++;

    if (plen < qlen) {
        return -1;
    } else if (plen > qlen) {
        return 1;
    }

    return strncmp(p, q, plen);
}

enum fpstate {FP_NONE, FP_FUNCTION, FP_IDENT};

bool isident(const char *s) {
    if (!isalpha(*s) && *s != '_') {
        return false; /* Illegal start of identifier. */
    }
    while (*s) {
        if (!isalnum(*s) && *s != '_') {
            return false;
        }
        s++;
    }
    return true;
}

typedef int state;

state *states = NULL;
size_t nstates = 0;
size_t sstates = 0;

// These functions held a stack of states .
state peekstate() {
    if (nstates == 0 || sstates == 0) {
        return -1;
    }
    return states[nstates-1];
}

state popstate() {
    if (nstates == 0 || sstates == 0) {
        return -1;
    }
    return states[--nstates];
}

// ALLOCS
void pushstate(state s) {
    if (nstates + 1 >= sstates) {
        size_t nsstates = 2*sstates + 1;
        state *new_states = xcalloc(nsstates, sizeof (state));
        if (states) {
            memcpy(new_states, states, nstates);
        }
        states = new_states;
        sstates = nsstates;
    }

    states[nstates++] = s;
}


/* Reads the next function block considering strings, blocks, comments and more. */
bool read_function_block(FILE *f, char **content) {
    enum fbstate {NORMAL, IN_SSTRING, IN_DSTRING,
                  IN_COMMENT, IN_INNER_BLOCK, IN_SUBSHELL};
    size_t cs = 0;
    size_t ci = 0;

    char *b = NULL;
    size_t bs = 0;

    extend_buf(&b, &bs);
    enum fbstate s = NORMAL;

    bool done = false;
    bool ignore_next_char = false;
    bool ok = true;
    while (!done && ok && (ok = !feof(f) && !ferror(f))) {
        if (ignore_next_char) {
            // The last token was a '\', so we ignore ONE char.
            int c = fgetc(f);
            if (c != EOF) {
                pushc(content, &cs, &ci, c);
            }
            ignore_next_char = false;
        }

        ok = getnext(&b, &bs, f) > 0;
        if (!ok) {
            break;
        }
        // Append input to contents.
        pushstrn(content, &cs, &ci, b, bs);

        // Ignoring next char should be possible in all states except for IN_COMMENT.
        if (!strcmp(b, "\\") && s != IN_COMMENT) {
            ignore_next_char = true;
            continue; // CONTINUE
        }

        switch (s) {
            case NORMAL:
                if      (!strcmp(b, "\"")) { pushstate(s); s = IN_DSTRING;     }
                else if (!strcmp(b, "\'")) { pushstate(s); s = IN_SSTRING;     }
                else if (!strcmp(b, "{"))  { pushstate(s); s = IN_INNER_BLOCK; }
                else if (!strcmp(b, "("))  { pushstate(s); s = IN_SUBSHELL;    }

                // If } is encountered while in the NORMAL state.
                // Then we know that the function declaration is over.
                else if (!strcmp(b, "}"))  { s = popstate(); done = true;      }
                break;

            case IN_SSTRING:
                // Reached end of sstring.
                if (!strcmp(b, "\'")) {
                    s = popstate();
                }
                break;

            case IN_DSTRING:
                // Reached end of dstring.
                if (!strcmp(b, "\"")) {
                    s = popstate();
                }
                break;

            case IN_COMMENT:
                if (!strcmp(b, "\n")) {
                    // Go to the previous/outer state.
                    s = popstate();
                    break;
                }

            case IN_INNER_BLOCK:
                pushstate(s);
                break;

            case IN_SUBSHELL:
                pushstate(s);
                break;
        }
    }
    
    return ok;
}

bool parse_next_func(FILE *f, char **name, char **content) {
    char *b = NULL;
    size_t bs = 0;

    extend_buf(&b, &bs);

    enum fpstate s = FP_IDENT;

    bool ok = true;
    while (ok && (ok = !feof(f) && !ferror(f))) {
        ok = getnext(&b, &bs, f) > 0;
        if (!ok) {
            break;
        }

        printf("getnext: '%s'\n", b);

        switch (s) {
            case FP_NONE:
                if (!trimcmp(b, "function")) {
                    // Is definitively the beginning of
                    // a function definition.
                    printf("Found function declaration based upon 'function' keyword\n");
                    s = FP_FUNCTION;
                } else if (isident(b)) {
                    // May or may not be the identifier
                    // for a function declaration.
                    s = FP_IDENT;
                }
                break;

            case FP_FUNCTION: {
                // Save the function identifier.
                // Which we expect to be the next identifier.
                char *trimmed = trim(b);
                if (!isident(trimmed)) {
                    errorf("%s is not a valid function identifier.\n", trimmed);
                    ok = false;
                    break;
                }
                *name = strdup(trimmed);

                ok = read_function_block(f, content);

                break;
            }

            case FP_IDENT:
                break;
        }


    }
    return ok;
}

/* ALLOCS */
bool parse_module(const char *mpath, struct module *mout) {
    verbosef("Parsing module: %s\n", mpath);

    FILE *f = fopen(mpath, "r");
    if (!f) {
        perror("fopen");
        return false;
    }

    mout->name = modulename(mpath);
    verbosef("Parsed modulename of %s as %s.\n", mpath, mout->name);

    /* Parse functions.  */
    char *name = NULL;
    char *content = NULL;

    while (parse_next_func(f, &name, &content)) {
        printf("Parsed function '%s':\n%s\n\n", name, content);
    }
    /* TODO  */

    fclose(f);
    return true; 
}

void usage(const char *name) {
    printf("Usage: %s [-hv] [-o OUTFILE] [INFILE...]\n", name);
    printf("  -h   Show this message and exit.\n");
    printf("  -v   Enable verbose output.\n");
    printf("  -o   Use custom output name instead of default 'outfile'.\n");
}

int main(int argc, char *argv[]) {
    int errflg = 0;
    int c;
    const char *opts = "hvo:";
    while ((c = getopt(argc, argv, opts)) != -1) {
        switch (c) {
            case 'h':
                usage(*argv);
                exit(0);
                break;

            case 'v': 
                verbose_output = true;
                break;

            case 'o':
                outfile = optarg;
                break;

            case ':':
                fprintf(stderr, "Option -%c requires an operand\n", optopt);
                errflg++;
                break;

            case '?':
                fprintf(stderr, "Unrecognized option '-%c'\n", optopt);
                errflg++;
                break;
        } 
    }

    /* Fail early on parsing errors. */
    if (errflg) {
        usage(*argv);
        exit(2);
    }

    /* Differentiate regular scripts and modules. */
    const char **modules = xcalloc(argc-optind, sizeof (char**));
    int mi = 0;
    const char **scripts = xcalloc(argc-optind, sizeof (char**));
    int si = 0;

    for (int i = optind; i < argc; i++) {
        /* Ends with .m == module. */
        int len = strlen(argv[i]);
        if (len >= 2 && !strcmp(&argv[i][len-2], ".m")) {
            modules[mi++] = argv[i];
        } else {
            scripts[si++] = argv[i];
        }
    }

    /* Parse modules. */
    for (int i = 0; i < mi; i++) {
        struct module m;
        memset(&m, 0, sizeof(m));
        parse_module(modules[i], &m);
        free(m.name);
    }

    free(modules);
    free(scripts);

    // GLOBALS
    free(states);

    return 0; 
}
