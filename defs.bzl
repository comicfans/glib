load("@rules_cc_autoconf//autoconf:cc_autoconf_info.bzl", "CcAutoconfInfo")
load("@rules_cc_autoconf//autoconf:package_info.bzl", "package_info")
load("@rules_cc_autoconf//autoconf:autoconf.bzl", "autoconf")
load("@rules_cc_autoconf//autoconf:autoconf_hdr.bzl", "autoconf_hdr")
load("@rules_cc_autoconf//autoconf:meson_hdr.bzl", "meson_hdr")
load("@rules_cc_autoconf//autoconf:checks.bzl", "checks")
load("@rules_cc_autoconf//autoconf:checks.bzl", "macros")
load("@rules_cc//cc:cc_library.bzl", "cc_library")
load("@version_info//:version.bzl", "major_version","minor_version","micro_version")

int64_m = 'll'

def gen_type_checks():

    
    check_size = ["short","int", "long","long long", "size_t", "void*"]
    check_align = ["int", "long", "long long"]

    ret = [checks.AC_CHECK_SIZEOF(t) for t in check_size] +[checks.AC_CHECK_ALIGNOF(t) for t in check_align] 

    ret += [
    checks.AC_CHECK_SIZEOF("ssize_t", includes = ["#include <unistd.h>"])
    ]

    ret += macros.AC_DEFINE_EXPR(define = ["glib_void_p","glib_long","glib_size_t", "glib_ssize_t"], expr = '''
glib_void_p = ac_cv_sizeof_voidp
glib_long = ac_cv_sizeof_long
glib_size_t = ac_cv_sizeof_size_t
glib_ssize_t = ac_cv_sizeof_ssize_t
    ''', requires = ["ac_cv_sizeof_voidp", "ac_cv_sizeof_long", "ac_cv_sizeof_size_t", "ac_cv_sizeof_ssize_t"])

    ret += macros.AC_DEFINE_EXPR(define = ["long_long_size_equal_to_long_size"],
                          expr = '''
long_long_size_equal_to_long_size = int(ac_cv_sizeof_long == ac_cv_sizeof_long_long)
                          ''',
    requires = ["ac_cv_sizeof_long", "ac_cv_sizeof_long_long"])


    ret += [checks.AC_TRY_COMPILE(code = '''
#if defined(_AIX) && !defined(__GNUC__)
#pragma options langlvl=stdc99
#endif
#pragma GCC diagnostic error "-Wincompatible-pointer-types"
#include <stdint.h>
#include <stdio.h>
int main () {
  int64_t i1 = 1;
  long *i2 = &i1;
  (void) i2;
  return 1;
}''', name = "int64_t_is_long", requires = ["long_long_size_equal_to_long_size"],
    ),
checks.AC_TRY_COMPILE(code = '''
#if defined(_AIX) && !defined(__GNUC__)
                      #pragma options langlvl=stdc99
                      #endif
                      #pragma GCC diagnostic error "-Wincompatible-pointer-types"
                      #include <stdint.h>
                      #include <stdio.h>
                      int main () {
                        int64_t i1 = 1;
                        long long *i2 = &i1;
                        (void) i2;
                        return 1;
                      }
''', name = "int64_t_is_long_long", requires = ["long_long_size_equal_to_long_size"],
    )
    ]

    ret += macros.AC_DEFINE_EXPR(["gint16",
                              "gint16_modifier",
                              "gint16_format",
                              "guint16_format"], expr = '''
if ac_cv_sizeof_short==2:
    gint16 = 'short'
    gint16_modifier='"h"'
    gint16_format='"hi"'
    guint16_format='"hu"'
elif ac_cv_sizeof_int == 2:
    gint16 = 'int'
    gint16_modifier='""'
    gint16_format='"i"'
    guint16_format='"u"'
else:
    assert False, "Compiler provides no native 16-bit integer type"
                             ''', requires = ["ac_cv_sizeof_int","ac_cv_sizeof_short"]) 

    ret +=  macros.AC_DEFINE_EXPR(["gint32","gint32_modifier","gint32_format","guint32_format", "guint32_align"],expr = '''
if ac_cv_sizeof_short == 4:
    gint32 = 'short'
    gint32_modifier='"h"'
    gint32_format='"hi"'
    guint32_format='"hu"'
    guint32_align = short_align
elif ac_cv_sizeof_int == 4:
    gint32 = 'int'
    gint32_modifier='""'
    gint32_format='"i"'
    guint32_format='"u"'
    guint32_align = ALIGNOF_INT 
elif ac_cv_sizeof_long == 4:
    gint32 = 'long'
    gint32_modifier='"l"'
    gint32_format='"li"'
    guint32_format='"lu"'
    guint32_align = ALIGNOF_LONG
else:
    assert False, 'Compiler provides no native 32-bit integer type'
''',
                                                                                                                 requires = ["ac_cv_sizeof_short",
"ac_cv_sizeof_int", "ac_cv_sizeof_long", "ALIGNOF_INT"])


    ret += macros.AC_DEFINE_EXPR(
    define = ["gint64","gint64_modifier","gint64_format","guint64_format","glib_extension", "gint64_constant", "guint64_constant","guint64_align"],
    expr = '''
if ac_cv_sizeof_int == 8:
    gint64 = 'int'
    gint64_modifier='""'
    gint64_format='"i"'
    guint64_format='"u"'
    glib_extension=''
    gint64_constant='(val)'
    guint64_constant='(val)'
    guint64_align = ALIGNOF_INT
elif ac_cv_sizeof_long == 8 and (ac_cv_sizeof_long_long != ac_cv_sizeof_long or int64_t_is_long):
    gint64 = 'long'
    glib_extension=''
    gint64_modifier='"l"'
    gint64_format='"li"'
    guint64_format='"lu"'
    gint64_constant='(val##L)'
    guint64_constant='(val##UL)'
    guint64_align = ALIGNOF_LONG
elif long_long_size == 8 and (ac_cv_sizeof_long_long != ac_cv_long_size or int64_t_is_long_long):
    gint64 = 'long long'
    glib_extension='G_GNUC_EXTENSION '
    gint64_modifier=int64_m
    gint64_format=int64_m + 'i'
    guint64_format=int64_m + 'u'
    gint64_constant='(G_GNUC_EXTENSION (val##LL))'
    guint64_constant='(G_GNUC_EXTENSION (val##ULL))'
    guint64_align = ALIGNOF_LONG_LONG
else:
    assert False, 'Compiler provides no native 64-bit integer type'
    ''',
    requires = ["ac_cv_sizeof_int", "ac_cv_sizeof_long", "ac_cv_sizeof_long_long", "long_long_size_equal_to_long_size","int64_t_is_long","int64_t_is_long_long","ALIGNOF_LONG","ALIGNOF_LONG_LONG"])

    g_sizet_try_type = ["short", "int", "long", "long long"]

    for t in g_sizet_try_type:
        ret += [checks.AC_TRY_COMPILE(code = '''
#include <stddef.h>
        static size_t f (size_t *i) { return *i + 1; }
        int main (void) {
          unsigned  ''' + t + '''  i = 0;
          f (&i);
          return 0;
        }
        ''', 
                                   # TODO pass -Werror argument
        define = ('g_sizet_compatibility_{}'.format(t)).replace(' ','_'))]
    

    ret += macros.AC_DEFINE_EXPR(define = ["glib_size_type_define","gsize_modifier", "gssize_modifier","gsize_format","gssize_format","glib_msize_type"], requires = [("g_sizet_compatibility_{}".format(t)).replace(' ','_') for t in g_sizet_try_type] + [("ac_cv_sizeof_{}".format(t)).replace(' ','_') for t in g_sizet_try_type + ["size_t"]], expr = '''
if g_sizet_compatibility_short and ac_cv_sizeof_short == ac_cv_sizeof_size_t:
    glib_size_type_define = "short"
    gsize_modifier='"h"'
    gssize_modifier='"h"'
    gsize_format ='"hu"'
    gssize_format ='"hi"'
    glib_msize_type='SHRT'
elif g_sizet_compatibility_int and ac_cv_sizeof_int == ac_cv_sizeof_size_t:
    glib_size_type_define = "int"
    gsize_modifier='""'
    gssize_modifier='""'
    gsize_format ='"u"'
    gssize_format ='"i"'
    glib_msize_type='INT'
elif g_sizet_compatibility_long and ac_cv_sizeof_long == ac_cv_sizeof_size_t:
    glib_size_type_define = "long"
    gsize_modifier='"l"'
    gssize_modifier='"l"'
    gsize_format ='"lu"'
    gssize_format ='"li"'
    glib_msize_type='LONG'
elif g_sizet_compatibility_long_long and ac_cv_sizeof_long_long == ac_cv_sizeof_size_t:
    glib_size_type_define = "long long"
    gsize_modifier='"{0}"'
    gssize_modifier='"{0}"'
    gsize_format ='"{0}u"'
    gssize_format ='"{0}i"'
    glib_msize_type='INT64'
else:
    assert False,'Could not determine size of size_t.'
                                 '''.format(int64_m))


    ret += macros.AC_DEFINE_EXPR(
        define = ["glib_intptr_type_define","gintptr_modifier",
        "gintptr_format","guintptr_format","glib_gpi_cast","glib_gpui_cast"],
        requires = ["ac_cv_sizeof_voidp","ac_cv_sizeof_int","ac_cv_sizeof_long",
        "ac_cv_sizeof_long_long"],expr = '''
if ac_cv_sizeof_voidp == ac_cv_sizeof_int:
    glib_intptr_type_define = "int"
    gintptr_modifier = '""'
    gintptr_format = '"i"'
    guintptr_format = '"u"'
    glib_gpi_cast = '(gint)'
    glib_gpui_cast = '(guint)'
elif ac_cv_sizeof_voidp == ac_cv_sizeof_long:
    glib_intptr_type_define = "long"
    gintptr_modifier = '"l"'
    gintptr_format = '"li"'
    guintptr_format = '"lu"'
    glib_gpi_cast = '(glong)'
    glib_gpui_cast = '(gulong)'
elif ac_cv_sizeof_voidp == ac_cv_sizeof_long_long:
    glib_intptr_type_define = "long long"
    gintptr_modifier = '"{0}"'
    gintptr_format = '"{0}i"'
    guintptr_format = '"{0}u"'
    glib_gpi_cast = '(gint64)'
    glib_gpui_cast = '(guint64)'
else:
    assert False,'Could not determine size of void *'
        '''.format(int64_m)
    )

    ret += macros.AC_DEFINE_EXPR(define = ["ac_cv_has_64bit_type"],requires = ["ac_cv_sizeof_{}".format(t) for t in ["long","long_long","int"]], expr = '''
if ac_cv_sizeof_long != 8 and ac_cv_sizeof_long_long != 8 and ac_cv_sizeof_int != 8:
    assert False, 'GLib requires a 64-bit type. You might want to consider using the GNU C compiler.'
else:
    ac_cv_has_64bit_type = 1
    ''')

    ret += macros.AC_DEFINE_EXPR(define = ["gintbits","glongbits","gsizebits","gssizebits"], requires = ["ac_cv_sizeof_{}".format(t) for t in ["int","long","size_t","ssize_t"]], expr = '''
gintbits = ac_cv_sizeof_int * 8
glongbits = ac_cv_sizeof_long * 8
gsizebits = ac_cv_sizeof_size_t * 8
gssizebits = ac_cv_sizeof_ssize_t * 8
    ''')

    ret += select(
        {
            # TODO cygwin
            "@platforms//os:windows": [checks.AC_DEFINE("g_module_suffix",value="dll")],
            "//conditions:default":[checks.AC_DEFINE("g_module_suffix",value='so')]
        }
    )

    return ret
 



def define_name(header):
    return "HAVE_" + header.upper().replace(".","_").replace("/","_")


def gen_glib_conf():

    interface_age = 0 if minor_version %2 == 1 else micro_version
    binary_age = 100 * minor_version + micro_version

    package_info(
        name = "package_info",
        module_bazel = "//:MODULE.bazel",
        package_bugreport = 'https://gitlab.gnome.org/GNOME/glib/issues/new',
        package_tarname = '"glib"',
        package_url = '""',
    )


    exeext = select(
        {"@platforms//os:windows":[
            checks.AC_DEFINE("EXEEXT",".exe")
        ],
        "//conditions:default":[checks.AC_DEFINE("EXEEXT","")]})



    headers = [
        'alloca.h',
        'afunix.h',
        'crt_externs.h',
        'dirent.h', # MSC does not come with this by default
        'float.h',
        'fstab.h',
        'ftw.h',
        'grp.h',
        'intsafe.h',
        'inttypes.h',
        'libproc.h',
        'limits.h',
        'linux/netlink.h',
        'locale.h',
        'mach/mach_time.h',
        'memory.h',
        'mntent.h',
        'netlink/netlink.h',
        'netlink/netlink_route.h',
        'poll.h',
        'pwd.h',
        'sched.h',
        'spawn.h',
        'stdatomic.h',
        'stdckdint.h',
        'stdint.h',
        'stdlib.h',
        'string.h',
        'strings.h',
        'sys/auxv.h',
        'sys/event.h',
        'sys/uio.h',
        'sys/filio.h',
        'sys/inotify.h',
        'sys/mkdev.h',
        'sys/mntctl.h',
        'sys/mnttab.h',
        'sys/mount.h',
        'sys/param.h',
        'sys/prctl.h',
        'sys/resource.h',
        'sys/select.h',
        'sys/statfs.h',
        'sys/stat.h',
        'sys/statvfs.h',
        'sys/sysctl.h',
        'sys/time.h', # MSC does not come with this by default
        'sys/times.h',
        'sys/types.h',
        'sys/ucred.h',
        'sys/vfs.h',
        'sys/vfstab.h',
        'sys/vmount.h',
        'sys/wait.h',
        'syslog.h',
        'termios.h',
        'unistd.h',
        'values.h',
        'vcruntime.h',
        'wchar.h',
        'xlocale.h',
    ]



    soversion = 0

    langinfo = checks.AC_TRY_LINK(code = '''#include <langinfo.h>
                                  int main (int argc, char ** argv) {
                                  char *codeset = nl_langinfo (CODESET);
                                  (void) codeset;
                                  return 0;
    }''', define = "HAVE_LANGINFO_CODESET")

    langinfo_time = checks.AC_TRY_LINK(code = '''#include <langinfo.h>
                                       int main (int argc, char ** argv) {
                                       char *str;
                                       str = nl_langinfo (PM_STR);
                                       str = nl_langinfo (D_T_FMT);
                                       str = nl_langinfo (D_FMT);
                                       str = nl_langinfo (T_FMT);
                                       str = nl_langinfo (T_FMT_AMPM);
                                       str = nl_langinfo (MON_1);
                                       str = nl_langinfo (ABMON_12);
                                       str = nl_langinfo (DAY_1);
                                       str = nl_langinfo (ABDAY_7);
                                       (void) str;
                                       return 0;
    }''', define = "HAVE_LANGINFO_TIME")

    langinfo_era = checks.AC_TRY_LINK(code = '''#include <langinfo.h>
                                      int main (int argc, char **argv) {
                                      char *str;
                                      str = nl_langinfo (ERA);
                                      str = nl_langinfo (ERA_D_T_FMT);
                                      str = nl_langinfo (ERA_D_FMT);
                                      str = nl_langinfo (ERA_T_FMT);
                                      str = nl_langinfo (_NL_TIME_ERA_NUM_ENTRIES);
                                      (void) str;
                                      return 0;
    }''', define = "HAVE_LANGINFO_ERA")

    langinfo_outdigit = checks.AC_TRY_LINK(
        code = '''#include <langinfo.h>
               int main (int argc, char ** argv) {
                 char *str;
                 str = nl_langinfo (_NL_CTYPE_OUTDIGIT0_MB);
                 str = nl_langinfo (_NL_CTYPE_OUTDIGIT1_MB);
                 str = nl_langinfo (_NL_CTYPE_OUTDIGIT2_MB);
                 str = nl_langinfo (_NL_CTYPE_OUTDIGIT3_MB);
                 str = nl_langinfo (_NL_CTYPE_OUTDIGIT4_MB);
                 str = nl_langinfo (_NL_CTYPE_OUTDIGIT5_MB);
                 str = nl_langinfo (_NL_CTYPE_OUTDIGIT6_MB);
                 str = nl_langinfo (_NL_CTYPE_OUTDIGIT7_MB);
                 str = nl_langinfo (_NL_CTYPE_OUTDIGIT8_MB);
                 str = nl_langinfo (_NL_CTYPE_OUTDIGIT9_MB);
                 (void) str;
                 return 0;
               }''',
               define = "HAVE_LANGINFO_OUTDIGIT"
    )

    langinfo_altmon = checks.AC_TRY_LINK(code='''#ifndef _GNU_SOURCE
                                         # define _GNU_SOURCE
                                         #endif
                                         #include <langinfo.h>
                                         int main (int argc, char ** argv) {
                                         char *str;
                                         str = nl_langinfo (ALTMON_1);
                                         str = nl_langinfo (ALTMON_2);
                                         str = nl_langinfo (ALTMON_3);
                                         str = nl_langinfo (ALTMON_4);
                                         str = nl_langinfo (ALTMON_5);
                                         str = nl_langinfo (ALTMON_6);
                                         str = nl_langinfo (ALTMON_7);
                                         str = nl_langinfo (ALTMON_8);
                                         str = nl_langinfo (ALTMON_9);
                                         str = nl_langinfo (ALTMON_10);
                                         str = nl_langinfo (ALTMON_11);
                                         str = nl_langinfo (ALTMON_12);
                                         (void) str;
                                         return 0;
                                         }''',
                                         define = "HAVE_LANGINFO_ALTMON"
    )

    langinfo_abaltmon = checks.AC_TRY_LINK(code ='''#ifndef _GNU_SOURCE
                                           # define _GNU_SOURCE
                                           #endif
                                           #include <langinfo.h>
                                           int main (int argc, char ** argv) {
                                           char *str;
                                           str = nl_langinfo (_NL_ABALTMON_1);
                                           str = nl_langinfo (_NL_ABALTMON_2);
                                           str = nl_langinfo (_NL_ABALTMON_3);
                                           str = nl_langinfo (_NL_ABALTMON_4);
                                           str = nl_langinfo (_NL_ABALTMON_5);
                                           str = nl_langinfo (_NL_ABALTMON_6);
                                           str = nl_langinfo (_NL_ABALTMON_7);
                                           str = nl_langinfo (_NL_ABALTMON_8);
                                           str = nl_langinfo (_NL_ABALTMON_9);
                                           str = nl_langinfo (_NL_ABALTMON_10);
                                           str = nl_langinfo (_NL_ABALTMON_11);
                                           str = nl_langinfo (_NL_ABALTMON_12);
                                           (void) str;
                                           return 0;
    }''', define = "HAVE_LANGINFO_ABALTMON")

    langinfo_time_codeset = checks.AC_TRY_LINK(code ='''#include <langinfo.h>
                                               int main (int argc, char ** argv) {
                                               char *codeset = nl_langinfo (_NL_TIME_CODESET);
                                               (void) codeset;
                                               return 0;
                                               }''',
                                               define="HAVE_LANGINFO_TIME_CODESET"

    )

    functions = [
        'accept4',
        'close_range',
        'copy_file_range',
        'endmntent',
        'endservent',
        'epoll_create1',
        'faccessat',
        'fallocate',
        'fchmod',
        'fchown',
        'fdwalk',
        'free_aligned_sized',
        'free_sized',
        'fsync',
        'ftruncate64',
        'getauxval',
        'getc_unlocked',
        'getfsent',
        'getfsstat',
        'getgrgid_r',
        'getifaddrs',
        'getmntent_r',
        'getpwnam_r',
        'getpwuid_r',
        'getresuid',
        'getvfsstat',
        'gmtime_r',
        'hasmntopt',
        'inotify_init1',
        'issetugid',
        'kevent',
        'kqueue',
        'lchmod',
        'lchown',
        'link',
        'localtime_r',
        'lstat',
        'mbrtowc',
        'memalign',
        'memmem',
        'mmap',
        'newlocale',
        'pipe2',
        'poll',
        'prlimit',
        'readlink',
        'recvmmsg',
        'sendmmsg',
        'setenv',
        'setmntent',
        'strerror_r',
        'strnlen',
        'strsignal',
        'strtod_l',
        'strtoll_l',
        'strtoull_l',
        'symlink',
        'timegm',
        'unsetenv',
        'uselocale',
        'utimes',
        'utimensat',
        'valloc',
        'vasprintf',
        'vsnprintf',
        'wcrtomb',
        'wcslen',
        'wcsnlen',
        'sysctlbyname',
    ]

    functions_checks = [checks.AC_CHECK_FUNC(func,define = define_name(func)) for func in functions] + select({
                "@platforms//os:windows":[],
                "//conditions:default":[checks.AC_CHECK_FUNC("if_indextoname", define = define_name("if_indextoname")),
                checks.AC_CHECK_FUNC("if_nametoindex", define = define_name("if_nametoindex"))]
            })

    #print(functions_checks)
    
    header_checks = [checks.AC_CHECK_HEADER(h,define = define_name(h)) for h in headers]

    header_cond_checks = [checks.AC_CHECK_FUNC("statvfs", requires = ["HAVE_SYS_STATVFS_H"]),
                           # TODO HAVE_SYS_STATFS_H or HAVE_SYS_MOUNT_H ?
                          checks.AC_CHECK_FUNC("statfs", requires = ["HAVE_SYS_STATFS_H"]),
                          checks.AC_CHECK_FUNC("prctl", requires = ["HAVE_SYS_PRCTL_H"])
    ] 

    sizeof_checks = [
        checks.AC_CHECK_SIZEOF(check_type, define = "SIZEOF_{}".format(check_type.upper().replace(" ","_")))
        for check_type in ["char","int","short","long","long long","size_t"]
    ]+ [checks.AC_CHECK_SIZEOF("void*", define = "SIZEOF_VOID_P"),
        checks.AC_CHECK_SIZEOF("ssize_t", define = "SIZEOF_SSIZE_T", includes = ["#include <unistd.h>"]),
        checks.AC_CHECK_SIZEOF("wchar_t", define = "SIZEOF_WCHAR_T", includes = ["#include <stddef.h>"]),
    ]




    #always required

    always_required = [checks.AC_DEFINE(key, value = 1) for key in ["HAVE_DCGETTEXT", "HAVE_GETTEXT"]]



    # TODO linux libmount
    # TODO linux selinux
    # TODO support libxattr


    xattr_nofollow = '''
                 #include <stdio.h>
                 #ifdef HAVE_SYS_TYPES_H
                 #include <sys/types.h>
                 #endif
                 #ifdef HAVE_SYS_XATTR_H
                 #include <sys/xattr.h>
                 #elif HAVE_ATTR_XATTR_H
                 #include <attr/xattr.h>
                 #endif

                 int main (void) {
                   ssize_t len = getxattr("", "", NULL, 0, 0, XATTR_NOFOLLOW);
                   return len;
                 }
    '''



    xattr_checks = [
        checks.AC_CHECK_FUNC(function = "getxattr",code = '''
                             "include <sys/xattr.h>"
                             int main(){
                             getxattr();
                             }
        ''',define = "HAVE_SYS_XATTR_H"),
        checks.AC_TRY_COMPILE(code = xattr_nofollow, compile_defines = ["HAVE_SYS_XATTR_H"], requires = ["HAVE_SYS_XATTR_H"],define = "HAVE_XATTR_NOFOLLOW"),
    ]

    # TODO assert HAVE_SYS_XATTR_H is 1


    sys_checks = [checks.AC_TRY_COMPILE(code='''
#include <linux/futex.h>
               #include <sys/syscall.h>
               #include <unistd.h>
               int main (int argc, char ** argv) {
                 syscall (__NR_futex, NULL, FUTEX_WAKE, FUTEX_WAIT);
                 return 0;
               }
                               ''', define = "HAVE_FUTEX"),


                  checks.AC_TRY_COMPILE(code = '''
#include <linux/futex.h>
               #include <sys/syscall.h>
               #include <unistd.h>
               int main (int argc, char ** argv) {
                 syscall (__NR_futex_time64, NULL, FUTEX_WAKE, FUTEX_WAIT);
                 return 0;
               }
                  ''',define = "HAVE_FUTEX_TIME64"),

                  checks.AC_TRY_LINK(code = '''
#include <sys/eventfd.h>
               #include <unistd.h>
               int main (int argc, char ** argv) {
                 eventfd (0, EFD_CLOEXEC);
                 return 0;
               }
                                     ''',define = "HAVE_EVENTFD"
                                     ),
                  checks.AC_TRY_LINK(code = '''
#define _GNU_SOURCE
               #include <poll.h>
               #include <stddef.h>
               int main (int argc, char ** argv) {
                 struct pollfd fds[1] = {{0}};
                 struct timespec ts = {0};
                 ppoll (fds, 1, NULL, NULL);
                 return 0;
               }
                                     ''',define = "HAVE_PPOLL"),
                  checks.AC_TRY_LINK(code = '''
#include <sys/syscall.h>
               #include <sys/wait.h>
               #include <linux/wait.h>
               #include <unistd.h>
               int main (int argc, char ** argv) {
                 siginfo_t child_info = { 0, };
                 syscall (SYS_pidfd_open, 0, 0);
                 waitid (P_PIDFD, 0, &child_info, WEXITED | WNOHANG);
                 return 0;
               }
                  ''', define = "HAVE_PIDFD"),
                  checks.AC_TRY_COMPILE(code='''
int main() {
static __uint128_t v1 = 100;
static __uint128_t v2 = 10;
static __uint128_t u;
u = v1 / v2;
(void) u;
}
                  ''',define = "HAVE_UINT128_T"),
                  checks.AC_TRY_LINK(code='''
  #include <time.h>
  struct timespec t;
  int main (int argc, char ** argv) {
    return clock_gettime(CLOCK_REALTIME, &t);
  }
                  ''',
                  #TODO meson also try to link with -lrt
                  define = "HAVE_CLOCK_GETTIME"),
                  checks.AC_TRY_COMPILE(code='''
#include <unistd.h>
                        #ifdef HAVE_SYS_PARAM_H
                        #include <sys/param.h>
                        #endif
                        #ifdef HAVE_SYS_VFS_H
                        #include <sys/vfs.h>
                        #endif
                        #ifdef HAVE_SYS_MOUNT_H
                        #include <sys/mount.h>
                        #endif
                        #ifdef HAVE_SYS_STATFS_H
                        #include <sys/statfs.h>
                        #endif
                        void some_func (void) {
                          struct statfs st;
                          statfs("/", &st);
                        }
                  ''',name = "ac_cv_statfs_args_2",
                  compile_defines = ["HAVE_SYS_PARAM_H","HAVE_SYS_VFS_H","HAVE_SYS_MOUNT_H","HAVE_SYS_STATFS_H"]),

                  checks.AC_TRY_COMPILE(code='''
#include <unistd.h>
                          #ifdef HAVE_SYS_PARAM_H
                          #include <sys/param.h>
                          #endif
                          #ifdef HAVE_SYS_VFS_H
                          #include <sys/vfs.h>
                          #endif
                          #ifdef HAVE_SYS_MOUNT_H
                          #include <sys/mount.h>
                          #endif
                          #ifdef HAVE_SYS_STATFS_H
                          #include <sys/statfs.h>
                          #endif
                          void some_func (void) {
                            struct statfs st;
                            statfs("/", &st, sizeof (st), 0);
                          }
                  ''', name = "ac_cv_statfs_args_4",compile_defines = ["HAVE_SYS_PARAM_H","HAVE_SYS_VFS_H","HAVE_SYS_MOUNT_H","HAVE_SYS_STATFS_H"])
    ] + macros.AC_DEFINE_EXPR(define = ["STATFS_ARGS"],
    requires = ["ac_cv_statfs_args_2","ac_cv_statfs_args_4"], expr = '''
if ac_cv_statfs_args_2:
    STATFS_ARGS=2
elif ac_cv_statfs_args_4:
    STATFS_ARGS=4
else:
    assert False, 'Unable to determine number of arguments to statfs()'
    ''') + [
        checks.AC_TRY_COMPILE(code='''
#include <fcntl.h>
                  #include <sys/types.h>
                  #include <sys/stat.h>
                  void some_func (void) {
                    open(".", O_DIRECTORY, 0);
                  }
        ''', define = "HAVE_OPEN_O_DIRECTORY"),
        checks.AC_TRY_COMPILE(code='''
#include <fcntl.h>
                  #include <sys/types.h>
                  #include <sys/stat.h>
                  void some_func (void) {
                    fcntl(0, F_FULLFSYNC, 0);
                  }
                              ''',define = "HAVE_FCNTL_F_FULLFSYNC"
        ),
    ] + select({
        "@platforms//os:windows":[
            checks.AC_DEFINE("HAVE_C99_SNPRINTF", 0),
            checks.AC_DEFINE("HAVE_C99_VSNPRINTF", 0),
            checks.AC_DEFINE("HAVE_UNIX98_PRINTF", 0),],
        "@platforms//os:macos":[
            checks.AC_DEFINE("HAVE_C99_SNPRINTF", 1),
            checks.AC_DEFINE("HAVE_C99_VSNPRINTF", 1),
            checks.AC_DEFINE("HAVE_UNIX98_PRINTF", 1),],
        "//conditions:default":[
            # TODO, this requires run on target machine, here we assume it's always true
            checks.AC_DEFINE("HAVE_C99_SNPRINTF", 1),
            checks.AC_DEFINE("HAVE_C99_VSNPRINTF", 1),
            checks.AC_DEFINE("HAVE_UNIX98_PRINTF", 1),],
    }) + [
        checks.AC_TRY_COMPILE(code="signed char x;", name = "ac_cv_char"),
        checks.AC_CHECK_TYPE("ptrdiff_t", includes = ["#include <stddef.h>"], define = "HAVE_PTRDIFF_T")
    ]  + macros.AC_DEFINE_EXPR(define =["signed"], requires = ["ac_cv_char"], expr='''
if ac_cv_char:
    signed = None
else:
    signed = "/* NOOP */"
    ''') + [
        checks.AC_TRY_LINK(code='''
#include <signal.h>
               #include <sys/types.h>
               sig_atomic_t val = 42;
               int main (int argc, char ** argv) {
                 return val == 42 ? 0 : 1;
               }
        ''', define = "HAVE_SIG_ATOMIC_T"),
        checks.AC_TRY_COMPILE(code='''
long long ll = 1LL;
                  int i = 63;
                  int some_func (void) {
                    long long llmax = (long long) -1;
                    return ll << i | ll >> i | llmax / ll | llmax % ll;
                  }
''',define = "HAVE_LONG_LONG"),
        checks.AC_TRY_COMPILE(code = '''
/* The Stardent Vistra knows sizeof(long double), but does not support it.  */
                  long double foo = 0.0;
                  /* On Ultrix 4.3 cc, long double is 4 and double is 8.  */
                  int array [2*(sizeof(long double) >= sizeof(double)) - 1];
                             ''' , define = "HAVE_LONG_DOUBLE"),
        checks.AC_CHECK_TYPE("wchar_t", define = "HAVE_WCHAR_T", includes = ["#include <stddef.h>"]),
        checks.AC_CHECK_TYPE("wint_t", define = "HAVE_WINT_T", includes = ["#include <wchar.h>"]),
    ]


    autoconf(
        name = "glib_conf",
        checks = [
            checks.AC_DEFINE("GETTEXT_PACKAGE",value ='"glib20"'),
            checks.AC_DEFINE("ENABLE_NLS"),
            checks.AC_DEFINE("GLIB_MAJOR_VERSION", major_version),
            checks.AC_DEFINE("GLIB_MINOR_VERSION", minor_version),
            checks.AC_DEFINE("GLIB_MICRO_VERSION", micro_version),
            checks.AC_DEFINE("GLIB_INTERFACE_AGE", interface_age),
            checks.AC_DEFINE("GLIB_BINARY_AGE", binary_age),
            langinfo,
            checks.AC_DEFINE("HAVE_CODESET", condition = "HAVE_LANGINFO_CODESET"),
            langinfo_time,
            langinfo_era,
            langinfo_outdigit,
            langinfo_altmon,
            langinfo_abaltmon,
            langinfo_time_codeset,

            #TODO glib use runtime strlcpy check which is not friendly to cross compile (https://bugzilla.gnome.org/show_bug.cgi?id=53933 Solaris 8), here we simply treat it as BSD compliant
            checks.AC_DEFINE("HAVE_STRLCPY"),

            #TODO, glib use runtime check to determine if 
            #"/proc/self/cmdline", O_RDONLY|O_BINARY can be read
            checks.AC_DEFINE("HAVE_PROC_SELF_CMDLINE"),

        ]+functions_checks + header_checks + header_cond_checks + exeext + sizeof_checks + always_required + xattr_checks + 
            # TODO sunos XOPEN_SOURCE __EXTENSIONS__

        [checks.AC_CHECK_TYPE("PTRACE_O_EXITKILL", includes = ["#include <sys/ptrace.h>"], define = "HAVE_PTRACE_O_EXITKILL"),

         checks.AC_DEFINE("USE_SYSTEM_PRINTF", requires = ["HAVE_UNIX98_PRINTF","HAVE_C99_SNPRINTF","HAVE_C99_VSNPRINTF"])
         
        ] + sys_checks
        ,

        #  TODO dtrace

        # TODO meson only check has_header for headers (preprocess only)
    )

    

    meson_hdr(
        name = "gen_glib_conf",
        out = "config.h",
        deps = [
            "glib_conf",
            "package_info"
        ],
    )

    cc_library(
        name="config",
        hdrs = ["config.h"],
        srcs = [],
        visibility = ["//visibility:public"],
    )

    
    # endian check
    endian_checks = [checks.AC_TRY_COMPILE(code = '''
    #if defined(__BYTE_ORDER__)
        typedef char array[__BYTE_ORDER__ == __ORDER_LITTLE_ENDIAN__ ? 1: - 1];
    
    #elif defined(__APPLE__)
        #include <TargetConditionals.h>
        #if defined(__LITTLE_ENDIAN__)
        #else
            #error fail compile for big endian
        #endif
    #else
        // win32 or other os, assume little endian
    #endif
        ''',name = "ac_cv_is_little_endian"),
                     checks.AC_DEFINE("g_byte_order",condition = "ac_cv_is_little_endian", if_true = "G_LITTLE_ENDIAN", if_false = "G_BIG_ENDIAN"),
                     checks.AC_DEFINE("g_bs_native",condition = "ac_cv_is_little_endian",if_true = "LE", if_false = "BE"),
                     checks.AC_DEFINE("g_bs_alien",condition = "ac_cv_is_little_endian",if_true = "BE", if_false = "LE"),
    ]


    func_checks = [
        checks.AC_CHECK_HEADER("alloca.h"),
        checks.AC_DEFINE("GLIB_HAVE_ALLOCA_H",condition = 'ac_cv_header_alloca_h', if_true = True, if_false = False),
    ]


    type_checks = gen_type_checks()

    win_defines = [
            checks.AC_DEFINE(define = "g_pid_type", value = 'void*'),
            checks.AC_DEFINE(define = "g_pid_format", value = '"p"'),
            checks.AC_DEFINE(define = "g_dir_separator", value = '\\\\'),
            checks.AC_DEFINE(define = "g_searchpath_separator", value = ';'),
        ]

    



    os_define = select({
        "windows_x86_64_or_arm64":win_defines + [checks.AC_DEFINE("g_pollfd_format", value = '%#'+int64_m+'x')],
        "@platforms//os:windows":win_defines + [
            checks.AC_DEFINE("g_pollfd_format", value = '"%#x"'),
        ],
        "//conditions:default":[
            checks.AC_DEFINE(define = "g_pid_type", value = "int"),
            checks.AC_DEFINE(define = "g_pid_format", value = '"i"'),
            checks.AC_DEFINE(define = "g_pollfd_format", value = '"%d"'),
            checks.AC_DEFINE(define = "g_dir_separator", value = '/'),
            checks.AC_DEFINE(define = "g_searchpath_separator", value = ':'),
        ]
    })

    poll_checks = [
        checks.AC_COMPUTE_INT(define = tuple[1], expression = tuple[0],
                              includes = ["#include <sys/poll.h>",
"#include <sys/types.h>"]) for tuple in [("POLLIN","g_pollin"), ("POLLOUT", "g_pollout"), ("POLLPRI", "g_pollpri"), ("POLLERR","g_pollerr"), ("POLLHUP","g_pollhup"),("POLLNVAL", "g_pollnval")]
    ]

    inet_checks = [
        checks.AC_COMPUTE_INT(define = tuple[1],expression = tuple[0],includes = ["#include <sys/types.h>", "#include <sys/socket.h>"]) for tuple in [
            ("AF_UNIX","g_af_unix"),("AF_INET","g_af_inet"),("AF_INET6","g_af_inet6"), ("MSG_OOB","g_msg_oob"),("MSG_PEEK","g_msg_peek"),("MSG_DONTROUTE","g_msg_dontroute")
        ]
    ]

    ipv6_check = select({
        "@platforms//os:windows":[
            checks.AC_DEFINE(define = "HAVE_IPV6",value = True),
        ],
        "//conditions:default":[
            checks.AC_CHECK_TYPE("struct in6_addr", includes = ["#include <netinet/in.h>"], define = "HAVE_IPV6")
        ]
    })


    autoconf(
        name = "glibconfig_conf",
        checks = [
            checks.AC_DEFINE("LT_CURRENT_MINUS_AGE", soversion),
            checks.AC_CHECK_FUNC("free_sized"),
            checks.AC_DEFINE("G_HAVE_FREE_SIZED",
                             condition = "ac_cv_func_free_sized", if_true = True,if_false=False),
            checks.AC_CHECK_FUNC("stpcpy",define = "HAVE_STPCPY"),
            checks.AC_DEFINE("GLIB_MAJOR_VERSION", major_version),
            checks.AC_DEFINE("GLIB_MINOR_VERSION", minor_version),
            checks.AC_DEFINE("GLIB_MICRO_VERSION", micro_version),

            # TODO glib_build_static_only
        ] + func_checks + endian_checks + type_checks + os_define + select(
            {"@platforms//os:windows":[
                checks.AC_DEFINE_UNQUOTED("glib_os",'''#define G_PLATFORM_WIN32
#define G_PLATFORM_WIN32
'''),
            ] ,
            "//conditions:default":[checks.AC_DEFINE("glib_os", "#define G_OS_UNIX"),
            ]})+ select({
                "growing_stack_setting":[
                    checks.AC_DEFINE("G_HAVE_GROWING_STACK"),
                ],
                "//conditions:default":[
                    checks.AC_DEFINE("G_HAVE_GROWING_STACK", value = 0),
                ]
            }) + poll_checks + inet_checks + ipv6_check + select({
                "@platforms//os:windows":[
                    checks.AC_DEFINE(define = "g_threads_impl_def", value = 'WIN32'),],
                    "//conditions:default":[
                    checks.AC_DEFINE(define = "g_threads_impl_def", value = 'POSIX'),]}),

                    
            visibility = ["//visibility:public"] ,
    )
