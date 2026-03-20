#include <lean/lean.h>
#include <clang-c/Index.h>
#include <string.h>
#include <stdlib.h>

/*
External object classes (so Lean's GC can call our finalizers)
*/

static void cxindex_finalizer(void *ptr) {
    clang_disposeIndex((CXIndex)ptr);
}

static void cxtu_finalizer(void *ptr) {
    clang_disposeTranslationUnit((CXTranslationUnit)ptr);
}

// Cursor wrapper: holds the CXCursor value plus a Lean reference to the TU
// so that the TU stays alive as long as any cursor exists.
typedef struct {
    CXCursor cursor;
    lean_object *tu_ref;  // borrowed Lean TU object, ref-counted
} CursorData;

static void cxcursor_finalizer(void *ptr) {
    CursorData *cd = (CursorData *)ptr;
    lean_dec(cd->tu_ref);
    free(cd);
}

static lean_external_class *g_cxindex_class = NULL;
static lean_external_class *g_cxtu_class = NULL;
static lean_external_class *g_cxcursor_class = NULL;

static lean_external_class *get_cxindex_class(void) {
    if (g_cxindex_class == NULL) {
        g_cxindex_class = lean_register_external_class(cxindex_finalizer, NULL);
    }
    return g_cxindex_class;
}

static lean_external_class *get_cxtu_class(void) {
    if (g_cxtu_class == NULL) {
        g_cxtu_class = lean_register_external_class(cxtu_finalizer, NULL);
    }
    return g_cxtu_class;
}

static lean_external_class *get_cxcursor_class(void) {
    if (g_cxcursor_class == NULL) {
        g_cxcursor_class = lean_register_external_class(cxcursor_finalizer, NULL);
    }
    return g_cxcursor_class;
}

// ---------------------------------------------------------------------------
// Helpers: box/unbox CXCursor
// ---------------------------------------------------------------------------

// Create a Lean Cursor object that holds both the CXCursor value and
// a reference to the TU Lean object (to keep it alive).
static lean_obj_res cursor_to_lean(CXCursor cursor, lean_object *tu_ref) {
    CursorData *cd = malloc(sizeof(CursorData));
    cd->cursor = cursor;
    cd->tu_ref = tu_ref;
    lean_inc(tu_ref);  // cursor now holds a reference
    return lean_alloc_external(get_cxcursor_class(), cd);
}

static CXCursor lean_to_cursor(lean_obj_arg obj) {
    CursorData *cd = (CursorData *)lean_get_external_data(obj);
    return cd->cursor;
}

static lean_object *lean_cursor_tu_ref(lean_obj_arg obj) {
    CursorData *cd = (CursorData *)lean_get_external_data(obj);
    return cd->tu_ref;
}

// ---------------------------------------------------------------------------
// Helper: CXString -> Lean String (disposes the CXString)
// ---------------------------------------------------------------------------

static lean_obj_res cxstring_to_lean(CXString s) {
    const char *cstr = clang_getCString(s);
    lean_obj_res result = lean_mk_string(cstr ? cstr : "");
    clang_disposeString(s);
    return result;
}

// ---------------------------------------------------------------------------
// Index lifecycle
// ---------------------------------------------------------------------------

lean_obj_res lean_clang_createIndex(uint8_t excludeDeclsFromPCH,
                                    uint8_t displayDiagnostics,
                                    lean_obj_arg world) {
    CXIndex idx = clang_createIndex(excludeDeclsFromPCH, displayDiagnostics);
    if (!idx) {
        return lean_io_result_mk_error(
            lean_mk_io_user_error(lean_mk_string("clang_createIndex failed")));
    }
    lean_obj_res obj = lean_alloc_external(get_cxindex_class(), idx);
    return lean_io_result_mk_ok(obj);
}

lean_obj_res lean_clang_disposeIndex(lean_obj_arg idx, lean_obj_arg world) {
    lean_dec_ref(idx);
    return lean_io_result_mk_ok(lean_box(0));
}

// ---------------------------------------------------------------------------
// Translation unit
// ---------------------------------------------------------------------------

lean_obj_res lean_clang_parseTranslationUnit(lean_obj_arg idx,
                                              lean_obj_arg filename,
                                              lean_obj_arg args,
                                              lean_obj_arg world) {
    CXIndex cxIdx = (CXIndex)lean_get_external_data(idx);
    const char *fname = lean_string_cstr(filename);

    // Convert Lean Array String to const char**
    size_t nargs = lean_array_size(args);
    const char **cargs = NULL;
    if (nargs > 0) {
        cargs = malloc(nargs * sizeof(const char *));
        for (size_t i = 0; i < nargs; i++) {
            cargs[i] = lean_string_cstr(lean_array_get_core(args, i));
        }
    }

    CXTranslationUnit tu = clang_parseTranslationUnit(
        cxIdx, fname, cargs, (int)nargs, NULL, 0,
        CXTranslationUnit_None);

    if (cargs) free(cargs);

    if (!tu) {
        return lean_io_result_mk_error(
            lean_mk_io_user_error(
                lean_mk_string("clang_parseTranslationUnit failed")));
    }

    lean_obj_res obj = lean_alloc_external(get_cxtu_class(), tu);
    return lean_io_result_mk_ok(obj);
}

lean_obj_res lean_clang_disposeTranslationUnit(lean_obj_arg tu,
                                                lean_obj_arg world) {
    lean_dec_ref(tu);
    return lean_io_result_mk_ok(lean_box(0));
}

// ---------------------------------------------------------------------------
// Cursor: get TU cursor
// ---------------------------------------------------------------------------

lean_obj_res lean_clang_getTranslationUnitCursor(lean_obj_arg tu,
                                                  lean_obj_arg world) {
    CXTranslationUnit cxTU =
        (CXTranslationUnit)lean_get_external_data(tu);
    CXCursor cursor = clang_getTranslationUnitCursor(cxTU);
    // tu is borrowed (@&), so cursor_to_lean will lean_inc it
    return lean_io_result_mk_ok(cursor_to_lean(cursor, tu));
}

// ---------------------------------------------------------------------------
// Cursor queries
// ---------------------------------------------------------------------------

lean_obj_res lean_clang_getCursorKind(lean_obj_arg cursor, lean_obj_arg world) {
    CXCursor c = lean_to_cursor(cursor);
    enum CXCursorKind kind = clang_getCursorKind(c);
    return lean_io_result_mk_ok(lean_box((unsigned)kind));
}

lean_obj_res lean_clang_getCursorSpelling(lean_obj_arg cursor,
                                           lean_obj_arg world) {
    CXCursor c = lean_to_cursor(cursor);
    CXString spelling = clang_getCursorSpelling(c);
    return lean_io_result_mk_ok(cxstring_to_lean(spelling));
}

lean_obj_res lean_clang_getCursorTypeSpelling(lean_obj_arg cursor,
                                               lean_obj_arg world) {
    CXCursor c = lean_to_cursor(cursor);
    CXType ty = clang_getCursorType(c);
    CXString spelling = clang_getTypeSpelling(ty);
    return lean_io_result_mk_ok(cxstring_to_lean(spelling));
}

lean_obj_res lean_clang_getCursorTypeKind(lean_obj_arg cursor,
                                           lean_obj_arg world) {
    CXCursor c = lean_to_cursor(cursor);
    CXType ty = clang_getCursorType(c);
    return lean_io_result_mk_ok(lean_box((unsigned)ty.kind));
}

// ---------------------------------------------------------------------------
// Source location
// ---------------------------------------------------------------------------

lean_obj_res lean_clang_isFromMainFile(lean_obj_arg cursor,
                                        lean_obj_arg world) {
    CXCursor c = lean_to_cursor(cursor);
    CXSourceLocation loc = clang_getCursorLocation(c);
    return lean_io_result_mk_ok(lean_box(clang_Location_isFromMainFile(loc) != 0));
}

lean_obj_res lean_clang_isInSystemHeader(lean_obj_arg cursor,
                                          lean_obj_arg world) {
    CXCursor c = lean_to_cursor(cursor);
    CXSourceLocation loc = clang_getCursorLocation(c);
    return lean_io_result_mk_ok(lean_box(clang_Location_isInSystemHeader(loc) != 0));
}

lean_obj_res lean_clang_getCursorLocation(lean_obj_arg cursor,
                                            lean_obj_arg world) {
    CXCursor c = lean_to_cursor(cursor);
    CXSourceLocation loc = clang_getCursorLocation(c);

    CXFile file;
    unsigned line, column, offset;
    clang_getSpellingLocation(loc, &file, &line, &column, &offset);

    CXString fileName = clang_getFileName(file);
    lean_obj_res leanFile = cxstring_to_lean(fileName);

    // SourceLocation: 1 object field (String), 8 bytes scalar (2x UInt32)
    // lean_ctor_set_uint32 offset is from start of data area, not scalar area,
    // so with 1 pointer (8 bytes), scalars start at offset 8.
    lean_obj_res obj = lean_alloc_ctor(0, 1, 8);
    lean_ctor_set(obj, 0, leanFile);
    lean_ctor_set_uint32(obj, sizeof(void *), (uint32_t)line);
    lean_ctor_set_uint32(obj, sizeof(void *) + 4, (uint32_t)column);
    return lean_io_result_mk_ok(obj);
}

// ---------------------------------------------------------------------------
// Child visitor: collects immediate children into a Lean Array
// ---------------------------------------------------------------------------

typedef struct {
    CXCursor *buf;
    size_t len;
    size_t cap;
} CursorBuf;

static enum CXChildVisitResult collect_children_visitor(CXCursor cursor,
                                                        CXCursor parent,
                                                        CXClientData data) {
    CursorBuf *buf = (CursorBuf *)data;
    if (buf->len == buf->cap) {
        buf->cap = buf->cap ? buf->cap * 2 : 16;
        buf->buf = realloc(buf->buf, buf->cap * sizeof(CXCursor));
    }
    buf->buf[buf->len++] = cursor;
    return CXChildVisit_Continue;
}

lean_obj_res lean_clang_getChildren(lean_obj_arg cursor, lean_obj_arg world) {
    CXCursor c = lean_to_cursor(cursor);
    lean_object *tu_ref = lean_cursor_tu_ref(cursor);

    CursorBuf buf = {NULL, 0, 0};
    clang_visitChildren(c, collect_children_visitor, &buf);

    lean_obj_res arr = lean_alloc_array(buf.len, buf.len);
    lean_object **data = lean_array_cptr(arr);
    for (size_t i = 0; i < buf.len; i++) {
        data[i] = cursor_to_lean(buf.buf[i], tu_ref);
    }

    free(buf.buf);
    return lean_io_result_mk_ok(arr);
}

// ---------------------------------------------------------------------------
// Cursor equality and hashing (libclang provides these)
// ---------------------------------------------------------------------------

uint8_t lean_clang_equalCursors(lean_obj_arg a, lean_obj_arg b) {
    CXCursor ca = lean_to_cursor(a);
    CXCursor cb = lean_to_cursor(b);
    return clang_equalCursors(ca, cb) != 0;
}

uint32_t lean_clang_hashCursor(lean_obj_arg cursor) {
    CXCursor c = lean_to_cursor(cursor);
    return clang_hashCursor(c);
}

// ---------------------------------------------------------------------------
// Null cursor check
// ---------------------------------------------------------------------------

lean_obj_res lean_clang_cursorIsNull(lean_obj_arg cursor, lean_obj_arg world) {
    CXCursor c = lean_to_cursor(cursor);
    return lean_io_result_mk_ok(lean_box(clang_Cursor_isNull(c) != 0));
}
