platform "debian-9-armhf" do |plat|
  plat.servicedir "/lib/systemd/system"
  plat.defaultdir "/etc/default"
  plat.servicetype "systemd"
  plat.codename "stretch"
  plat.platform_triple "arm-linux-gnueabihf"

  plat.install_build_dependencies_with "DEBIAN_FRONTEND=noninteractive; apt-get install -qy --no-install-recommends "

  plat.provision_with "dpkg --add-architecture #{plat.get_architecture}"

  packages = [
    'cmake',
    "crossbuild-essential-#{plat.get_architecture}",
    'debhelper',
    'devscripts',
    'fakeroot',
    'gettext',
    "libblkid-dev:#{plat.get_architecture}",
    "libboost-chrono-dev:#{plat.get_architecture}",
    "libboost-date-time-dev:#{plat.get_architecture}",
    "libboost-filesystem-dev:#{plat.get_architecture}",
    "libboost-locale-dev:#{plat.get_architecture}",
    "libboost-log-dev:#{plat.get_architecture}",
    "libboost-program-options-dev:#{plat.get_architecture}",
    "libboost-random-dev:#{plat.get_architecture}",
    "libboost-regex-dev:#{plat.get_architecture}",
    "libboost-system-dev:#{plat.get_architecture}",
    "libboost-thread-dev:#{plat.get_architecture}",
    "libc6-dev:#{plat.get_architecture}",
    "libbz2-dev:#{plat.get_architecture}",
    "libreadline-dev:#{plat.get_architecture}",
    "libyaml-cpp-dev:#{plat.get_architecture}",
    'make',
    'pkg-config',
    'qemu-user-static',
    'quilt',
    'rsync',
    "zlib1g-dev:#{plat.get_architecture}",
  ]
  plat.provision_with "export DEBIAN_FRONTEND=noninteractive; apt-get update -qq; apt-get install -qy --no-install-recommends #{packages.join(' ')}"

  # Allow the CMake search path for cross-compiled libraries to be extended
  # by passing -DCMAKE_FIND_ROOT_PATH when running cmake.
  plat.provision_with "sed -i 's/SET (CMAKE_FIND_ROOT_PATH/list (INSERT CMAKE_FIND_ROOT_PATH 0/' /etc/dpkg-cross/cmake/CMakeCross.txt"

  plat.cross_compiled "true"
  plat.output_dir File.join("deb", plat.get_codename, "PC1")

  # NOTE: May have to cross-build on i386 due to some bugs noted in
  #       puppet-agent/pull/1343. This can be switched to x86_64 when
  #       Buster shows up.
  plat.vmpooler_template "debian-9-x86_64"
  # NOTE: Bring your own image. The image is expected to satisfy the following
  #       conditions:
  #
  #         - Runs SystemD
  #         - Runs SSHD under SystemD
  #           - SSHD allows pubkey access to the root user via a
  #             key set by the VANAGON_SSH_KEY environment variable.
  plat.docker_image ENV['VANAGON_DOCKER_IMAGE']
  plat.ssh_port 4222
  plat.docker_run_args ['--tmpfs=/tmp:exec',
                        '--tmpfs=/run',
                        '--volume=/sys/fs/cgroup:/sys/fs/cgroup:ro',
                        # The SystemD version used by Debian 9 is old
                        # enough that it requires some elevated privilages.
                        '--cap-add=SYS_ADMIN']
end
