load("@rules_cc_autoconf//autoconf:cc_autoconf_info.bzl", "CcAutoconfInfo")
load("@rules_cc_autoconf//autoconf:package_info.bzl", "package_info")
load("@rules_cc_autoconf//autoconf:autoconf.bzl", "autoconf")
load("@rules_cc_autoconf//autoconf:autoconf_hdr.bzl", "autoconf_hdr")
load("@rules_cc_autoconf//autoconf:meson_hdr.bzl", "meson_hdr")
load("@rules_cc_autoconf//autoconf:checks.bzl", "checks")
load("@rules_cc//cc:cc_library.bzl", "cc_library")
load("@version_info//:version.bzl", "major_version","minor_version","micro_version")

def _get_package_info(ctx):
    infos = ctx.attr["package_target"]["define_results"]

    #package_version = 

def check_header_or_func(func):
    return checks.AC_CHECK_FUNC(func, define = define_name(func))

get_package_info = rule(
    implementation = _get_package_info,
    attrs = {
        "package_target": attr.label(providers = [CcAutoconfInfo]),
    },
)

def define_name(header):
    return "HAVE_" + header.upper().replace(".","_").replace("/","_")


def gen_glib_conf():

    interface_age = 0 if minor_version %2 == 1 else micro_version
    binary_age = 100 * minor_version + micro_version

    package_info(
        name = "package_info",
        module_bazel = "//:MODULE.bazel",
        package_bugreport = '"https://gitlab.gnome.org/GNOME/glib/issues/new"',
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

    functions_checks = [check_header_or_func(func) for func in functions] + select({
                "@platforms//os:windows":[],
                "//conditions:default":[check_header_or_func("if_indextoname"),
                check_header_or_func("if_nametoindex")]
            })

    print(functions_checks)
    
    header_checks = [check_header_or_func(h) for h in headers]

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
        checks.AC_CHECK_SIZEOF("wchar_t", define = "SIZEOF_WCHAR_T", includes = ["#include <stddef.h>"])]



    #always required

    always_required = [checks.AC_DEFINE(key, value = 1) for key in ["HAVE_DCGETTEXT", "HAVE_GETTEXT"]]



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
        ]+functions_checks + header_checks + header_cond_checks + exeext + sizeof_checks + always_required,

        # TODO meson only check has_header for headers (preprocess only)
    )

    # TODO linux libmount


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



    autoconf(
        name = "glibconfig_conf",
        checks = [
            checks.AC_DEFINE("LT_CURRENT_MINUS_AGE", soversion),
            #checks.AC_DEFINE("G_HAVE_FREE_SIZED",
            #                 condition = "HAVE_FREE_SIZED", if_false=None),
            checks.AC_CHECK_FUNC("stpcpy",define = "HAVE_STPCPY"),
            checks.AC_DEFINE("GLIB_MAJOR_VERSION", major_version),
            checks.AC_DEFINE("GLIB_MINOR_VERSION", minor_version),
            checks.AC_DEFINE("GLIB_MICRO_VERSION", micro_version),

            # TODO glib_build_static_only
        ] + select(
            {"@platforms//os:windows":[
                checks.AC_DEFINE_UNQUOTED("G_PLATFORM_WIN32"),
                checks.AC_DEFINE_UNQUOTED("G_OS_WIN32")
            ],
             # cygwin not supported?
             #"@platforms//os:cygwin":[
             #checks.AC_DEFINE_UNQUOTED("G_OS_UNIX"),
             #checks.AC_DEFINE_UNQUOTED("G_WITH_CYGWIN"),

             #],
            "//conditions:default":[checks.AC_DEFINE_UNQUOTED("G_OS_UNIX")]}),
            visibility = ["//visibility:public"],
    )
