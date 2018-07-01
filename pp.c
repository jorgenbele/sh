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
    char *name;        /* The function identifier.       */
    char *contents;    /* ALL of the functions contents. */
    bool with_keyword; /* Is the function defined using
                        * the 'function keyword'? */
};

struct module {
    char *name;              /* The module name/identifier. */
    struct function **funcv; /* The vector of functions which the module
                              * consists of. */
    size_t funcc;            /* The number of functions in the vector. */
    size_t funcvsize;
};

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

// ALLOCS
void extend(void **p, size_t *nelems, size_t elemsize) {
    size_t nsize = *nelems*2 + 2;
    char *n = xcalloc(nsize, elemsize);
    if (*p != NULL) {
        memcpy(n, *p, *nelems);
        free(*p);
    }
    *p = n;
    *nelems = nsize;
}

/* ALLOCS */
/* double the buffer given by b. If *b == NULL then
 * create a new empty zeroed-buffer, else memcpy the old buffer
 * over to the new zeroed-buffer. */
void extend_buf(char **b, size_t *bsize) {
    extend((void **) b, bsize, 1);
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
void pushstrn(char **b, size_t *bsize, size_t *bufi, const char *s, size_t max) {
    while (max-- > 0 && *s) {
        pushc(b, bsize, bufi, *s);
        s++;
    }
}

void skip_blanks(FILE *f) {
    int c;
    while (isblank(c = fgetc(f)));
    ungetc(c, f);
}

bool istoken(int c) {
    return isalnum(c) || c == '_';
}

/* Get the next token. */
ssize_t getnext(char **b, size_t *bsize, FILE *f) {
    size_t bufi = 0;

    bool ok;
    while ((ok = !feof(f) && !ferror(f))) {
        int c = fgetc(f);
        if (c == EOF) {
            goto end;
        }
        if (!istoken(c)) {
            if (bufi == 0) {
                pushc(b, bsize, &bufi, c);
            } else {
                ungetc(c, f);
            }
            goto end;
        }
        pushc(b, bsize, &bufi, c);
    }
end:
    pushc(b, bsize, &bufi, '\0');
    return bufi;
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


char **buffs = NULL;
size_t nbuffs = 0;
size_t sbuffs = 0;

// These functions held a stack of states .
char *peekbuffs() {
    if (nbuffs == 0 || sbuffs == 0) {
        return NULL;
    }
    return buffs[nbuffs-1];
}

char *popbuffs() {
    if (nbuffs == 0 || sbuffs == 0) {
        return NULL;
    }
    return buffs[--nbuffs];
}

// ALLOCS
void pushbuff(char *buff) {
    if (nbuffs + 1 >= sbuffs) {
        size_t nsbuffs = 2*sbuffs + 1;
        char **new_buffs = xcalloc(nsbuffs, sizeof (buffs));
        if (buffs) {
            memcpy(new_buffs, buffs, nbuffs);
            free(buffs);
        }
        buffs = new_buffs;
        sbuffs = nsbuffs;
    }
    buffs[nbuffs++] = buff;
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
            free(states);
        }
        states = new_states;
        sstates = nsstates;
    }

    states[nstates++] = s;
}

void free_func(struct function *func) {
    free(func->name);
    free(func->contents);
}

void func_tostr(const struct function *func, char **outstr, size_t *outstrsize) {
    size_t bi = 0;

    if (func->with_keyword) {
        const char *keywordstr = "function ";
        pushstrn(outstr, outstrsize, &bi, keywordstr, strlen(keywordstr));
    }

    pushstrn(outstr, outstrsize, &bi, func->name, strlen(func->name));
    const char *funcopen = "() {";
    pushstrn(outstr, outstrsize, &bi, funcopen, strlen(funcopen));
    pushstrn(outstr, outstrsize, &bi, func->contents, strlen(func->contents));
    const char *funcclose = "}";
    pushstrn(outstr, outstrsize, &bi, funcclose, strlen(funcclose));
    (*outstr)[bi] = '\0';
}

void free_module(struct module *module) {
    free(module->name);
    if (module->funcv) {
        for (size_t i = 0; i < module->funcc; i++) {
            free_func(module->funcv[i]);
            free(module->funcv[i]);
        }
        free(module->funcv);
    }
}

void list_funcs(const struct module *module) {
    if (module->funcv == NULL) {
        verbosef("Attempted to list empty module!\n");
        return;
    }

    printf("# Module: %s, funcc: %lu\n", module->name, module->funcc);
    for (size_t i = 0; i < module->funcc; i++) {
        if (module->funcv[i] == NULL) {
            verbosef("Attempted to list empty function!\n");
            continue;
        }
        printf("# Exports: %s\n", module->funcv[i]->name);
    }

    printf("\n");

    char *outstr = NULL;
    size_t outsize = 0;

    for (size_t i = 0; i < module->funcc; i++) {
        func_tostr(module->funcv[i], &outstr, &outsize);
        printf("# Generated function: %s\n", module->funcv[i]->name);
        printf("%s\n", outstr);
    }
    free(outstr);
}

struct module *find_module(struct module *modulev, size_t modulec, const char *name) {
    for (size_t i = 0; i < modulec; i++) {
        if (!strcmp(name, modulev[i].name)) {
            return &modulev[i];
        }
    }
    return NULL;
}

struct function *find_function(const struct module *module, const char *name) {
    for (size_t i = 0; i < module->funcc; i++) {
        if (!strcmp(name, module->funcv[i]->name)) {
            return module->funcv[i];
        }
    }
    return NULL;
}


/* Reads the next function block considering strings, blocks, comments and more. */
bool read_function_block(FILE *f, struct function *func) {
    enum fbstate {NORMAL, IN_SSTRING, IN_DSTRING,
                  IN_COMMENT, IN_INNER_BLOCK, IN_SUBSHELL};
    const char *fbstate_str[] = {"NORMAL", "IN_SSTRING", "IN_DSTRING",
                                 "IN_COMMENT", "IN_INNER_BLOCK", "IN_SUBSHELL"};
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
                pushc(&func->contents, &cs, &ci, c);
            }
            ignore_next_char = false;
        }

        size_t read = getnext(&b, &bs, f);
        ok = read > 0;
        if (!ok) {
            break;
        }

        verbosef("state: %s getnext: '%s'\n", fbstate_str[s], b);

        // Ignoring next char should be possible in all states except for IN_COMMENT.
        if (!strcmp(b, "\\") && s != IN_COMMENT) {
            ignore_next_char = true;
            continue; // CONTINUE
        }

        switch (s) {
            case NORMAL:
                if      (!strcmp(b, "\"")) { pushstate(s); s = IN_DSTRING;     }
                else if (!strcmp(b, "\'")) { pushstate(s); s = IN_SSTRING;     }
                //else if (!strcmp(b, "{"))  { pushstate(s); s = IN_INNER_BLOCK; }
                //else if (!strcmp(b, "("))  { pushstate(s); s = IN_SUBSHELL;    }
                else if (!strcmp(b, "#"))  { pushstate(s); s = IN_COMMENT;     }

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
                // TODO
                break;

            case IN_SUBSHELL:
                // TODO
                if (!strcmp(b, ")")) {
                    
                }
                break;
        }

        if (!done) {
            // Append input to contents.
            pushstrn(&func->contents, &cs, &ci, b, read);
        }
    }

    free(b);
    
    return ok;
}

bool parse_next_func(FILE *f, struct function *func) {
    char *b = NULL;
    size_t bs = 0;

    extend_buf(&b, &bs);

    enum fpstate {FP_FUNCTION, FP_IDENT, FP_COMMENT};
    const char *fpstate_str[] = {"FP_FUNCTION", "FP_IDENT", "FP_COMMENT"};


    enum fpstate s = FP_IDENT;
    int ident_stage = 0;
    char *identstr = NULL;

    bool ok = true;
    bool done = false;

    while (!done && ok && (ok = !feof(f) && !ferror(f))) {
        ok = getnext(&b, &bs, f) > 0;
        if (!ok) {
            break;
        }

        verbosef("ident_stage: %d, state: %s getnext: '%s'\n", ident_stage, fpstate_str[s], b);

        switch (s) {

            case FP_FUNCTION: {
                // Save the function identifier.
                // Which we expect to be the next identifier.
                char *trimmed = trim(b);
                if (!isident(trimmed)) {
                    errorf("%s is not a valid function identifier.\n", trimmed);
                    ok = false;
                    break;
                }
                func->name = strdup(trimmed);

                verbosef("Reading function block: %s\n", func->name);
                ok = read_function_block(f, func);
                verbosef("OK: %d, Read function %s contents:\n%s\n", ok, func->name, func->contents);
                done = true;
                break;
            }

            case FP_COMMENT:
                if (!strcmp(b, "\n")) {
                    s = popstate();
                }
                break;

            case FP_IDENT: {
                switch (ident_stage) {
                    case 0:
                        if (!strcmp(b, "#")) {
                            pushstate(s);
                            s = FP_COMMENT;
                        } else if (!trimcmp(b, "function")) {
                            // Is definitively the beginning of
                            // a function definition.
                            //verbosef("Found function declaration based upon 'function' keyword\n");
                            func->with_keyword = true;
                            s = FP_IDENT;
                            ident_stage = 0;
                        } else if (isident(b)) {
                            // May or may not be the identifier
                            // for a function declaration.
                            ident_stage = 1;
                            // Save identstr for later.
                            char *trimmed = trim(b);
                            identstr = strdup(trimmed);
                        }
                        break;

                        
                    case 1:
                        if (!strcmp(b, "(")) {
                            ident_stage = 2;
                        } else {
                            goto no_function;
                        }
                        break;

                    case 2:
                        if (!strcmp(b, ")")) {
                            ident_stage = 3;
                        } else {
                            goto no_function;
                        }
                        break;

                    case 3:
                        if (!trimcmp(b, "{")) {
                            // Found beginning of a function.
                            // Save name.
                            func->name = identstr;
                            identstr = NULL;

                            verbosef("Found valid function start using %s (){: %s\n",
                                     func->name, func->name);

                            ok = read_function_block(f, func);
                            verbosef("OK: %d, Read function %s\n =================contents=================:\n%s\n==================================\n", ok, func->name, func->contents);
                            done = true;
                            break;
                        }
                }
                break;

            no_function:
                s = FP_IDENT;
                free(identstr);
                identstr = NULL;
                ident_stage = 0;
                break;
            }
        }
    }

    free(identstr);
    free(b);
    return ok;
}

// ALLOCS
void pushfunc(struct module *m, struct function *f) {
    verbosef("Pushing function: %s\n", f->name);

    if (!m->funcv || m->funcc + 1 >= m->funcvsize) {
        size_t nsize = m->funcvsize*2 + 1;
        struct function **nfuncv = xcalloc(nsize, sizeof (struct function*));
        if (m->funcc) {
            memcpy(nfuncv, m->funcv, m->funcc*sizeof (struct function*));
            free(m->funcv);
        }
        m->funcvsize = nsize;
        m->funcv = nfuncv;
    }
    m->funcv[m->funcc++] = f;
}

bool process_scripts(const char *spath, const char *ext, struct module *modulev, size_t modulec) {
    verbosef("Processing script: %s\n", spath);

    FILE *f = fopen(spath, "r");
    if (!f) {
        perror("fopen");
        return false;
    }

    char *b = NULL;
    size_t bs = 0;

    FILE *out;
    if (ext == NULL) {
        out = stdout;
    } else {
        char *outpath = NULL;
        size_t outsize = 0;
        size_t outi = 0;
        pushstrn(&outpath, &outsize, &outi, spath, strlen(spath));
        pushstrn(&outpath, &outsize, &outi, ext, strlen(ext));
        outpath[outi] = '\0';
        out = fopen(outpath, "w");
        free(outpath);
    }


    bool done = false;
    bool ok = true;

    size_t stage = 0;
    #define MODULE_INDEX 3
    #define FUNCTION_INDEX 5
    const char *stages_str[] = {"#", "!", "import", NULL, ".", NULL};
    const size_t nstages = sizeof(stages_str)/sizeof(*stages_str);

    char *b_saved[sizeof(stages_str)/sizeof(*stages_str)];
    for (size_t i = 0; i < nstages; i++) {
        if (stages_str[i]) {
            b_saved[i] = strdup(stages_str[i]);
        } else {
            b_saved[i] = NULL;
        }
    }

    while (!done && ok && (ok = !feof(f) && !ferror(f) && !ferror(out))) {
        size_t read = getnext(&b, &bs, f);
        ok = read > 0;
        if (!ok) {
            break;
        }

        if (stage >= nstages) {
            verbosef("Completed all stages: module: '%s' function: '%s'\n", b_saved[MODULE_INDEX], b_saved[FUNCTION_INDEX]);
            // We completed all stages, which means that
            // the import statement is complete.
            struct module *m = find_module(modulev, modulec, b_saved[MODULE_INDEX]);
            if (!m) {
                errorf("Unable to find module: '%s'\n", b_saved[MODULE_INDEX]);
                ok = false;
                continue;
            }

            struct function *f = find_function(m, b_saved[FUNCTION_INDEX]);
            if (!f) {
                errorf("Unable to find function: '%s' in module: '%s'\n", b_saved[FUNCTION_INDEX], b_saved[MODULE_INDEX]);
                ok = false;
                continue;
            }

            // Reuse b to store function
            func_tostr(f, &b, &bs);
            // Write
            fprintf(out, "%s\n", b); // NOTE: newline
            // Reset and release resources.
            stage = 0;
            for (size_t i = 0; i < nstages; i++) {
                free(b_saved[i]);
                if (stages_str[i]) {
                    b_saved[i] = strdup(stages_str[i]);
                } else {
                    b_saved[i] = NULL;
                }
            }
        } else if (stages_str[stage] == NULL) {
            if (!isident(b)) {
                errorf("'%s' is not a valid identifier!\n", b);
            }
            verbosef("Doing custom stage: %d!\n", stage);
            // A stage marked with NULL requires custom input.
            // We save this inputin the b_saved vector.
            b_saved[stage] = strdup(b);
            stage++;

        } else if (!trimcmp(b, stages_str[stage])) {
            verbosef("Doing stage: %d!\n", stage);
            // The next stage is valid. Increment.
            stage++;

        } else {
            verbosef("Resetting: %d!\n", stage);
            // Not a valid stage. Reprint all valid tokens
            // so that we match the input.
            for (size_t i = 0; i < stage; i++) {
                if (stages_str[i]) {
                    fprintf(out, "%s", stages_str[i]);
                } else {
                    fprintf(out, "%s", b_saved[i]);
                }
            }
            // Reset resources.
            for (size_t i = 0; i < nstages; i++) {
                free(b_saved[i]);
                if (stages_str[i]) {
                    b_saved[i] = strdup(stages_str[i]);
                } else {
                    b_saved[i] = NULL;
                }
            }
            stage = 0;

            // Print out the token we just read.
            fprintf(out, "%s", b);
        }

        // Skip blanks for the stages marked with NULL.
        if (stage < nstages && !stages_str[stage]) {
            skip_blanks(f);
        }
    }

    for (size_t i = 0; i < nstages; i++) {
        free(b_saved[i]);
    }

    free(b);

    fclose(out);
    fclose(f);

    return true;
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
    verbosef("==Parsed modulename of %s as %s.\n", mpath, mout->name);


    bool ok = true;
    while (ok) {
        /* Parse functions.  */
        struct function *func = xcalloc(1, sizeof (struct function));
        if ((ok = parse_next_func(f, func))) {
            pushfunc(mout, func);
        } else {
            free(func);
        }
    }

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
    const char **module_paths = xcalloc(argc-optind, sizeof (char**));
    int mi = 0;
    const char **scripts = xcalloc(argc-optind, sizeof (char**));
    int si = 0;

    for (int i = optind; i < argc; i++) {
        /* Ends with .m == module. */
        int len = strlen(argv[i]);
        if (len >= 2 && !strcmp(&argv[i][len-2], ".m")) {
            module_paths[mi++] = argv[i];
        } else {
            scripts[si++] = argv[i];
        }
    }

    struct module *modules = xcalloc(mi+1, sizeof (struct module));

    /* Parse modules. */
    for (int i = 0; i < mi; i++) {
        parse_module(module_paths[i], &modules[i]);
        //list_funcs(&modules[i]);
    }

    /* Process input scripts. */
    for (int i = 0; i < si; i++) {
        process_scripts(scripts[i], NULL, modules, mi);
    }

    /* Cleanup. */
    for (int i = 0; i < mi; i++) {
        free_module(&modules[i]);
    }
    free(modules);

    free(module_paths);
    free(scripts);

    // GLOBALS
    free(states);
    for (size_t i = 0; i < nbuffs; i++) {
        free(buffs[i]);
    }
    free(buffs);

    return 0; 
}
