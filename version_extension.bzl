def _version_repo_impl(repository_ctx):
    # Generate a constant that can be loaded by other rules
    major, minor, micro = repository_ctx.attr.version.split(".")
    content = "version=\"{}\"\nmajor_version={}\nminor_version = {}\nmicro_version = {}\n".format(repository_ctx.attr.version, int(major), int(minor), int(micro))
    repository_ctx.file("version.bzl", content)

    # A dummy BUILD file to make it a valid package
    repository_ctx.file("BUILD", "")

version_repo = repository_rule(
    implementation = _version_repo_impl,
    attrs = {
        "version": attr.string(),
        "major_version": attr.int(),
        "minor_version": attr.int(),
        "micro_version": attr.int(),
    },
)

def _version_extension_impl(module_ctx):
    root_version = "unknown"
    for mod in module_ctx.modules:
        if mod.is_root:
            root_version = mod.version

    # Create an external repository that holds the version string
    version_repo(name = "version_info", version = root_version)

version_extension = module_extension(
    implementation = _version_extension_impl,
)
