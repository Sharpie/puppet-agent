platform 'debian-10-armhf' do |plat|
  plat.servicedir '/lib/systemd/system'
  plat.defaultdir '/etc/default'
  plat.servicetype 'systemd'
  plat.codename 'buster'
  plat.platform_triple 'arm-linux-gnueabihf'
  plat.cross_compiled true
  plat.output_dir File.join('deb', plat.get_codename, 'PC1')


  plat.install_build_dependencies_with 'DEBIAN_FRONTEND=noninteractive; apt-get install -qy --no-install-recommends '

  # STORY TIME: In order to keep on-disk sizes low, most docker containers
  #             are configured to skip installation of man pages. This
  #             generally works out fine except the post-install script
  #             of `openjdk-11-jdk-headless` assumes noone would ever do
  #             such a thing and fails.
  plat.provision_with 'mkdir -p /usr/share/man/man1'
  plat.provision_with "dpkg --add-architecture #{plat.get_architecture}"

  packages = [
    'build-essential',
    'cmake',
    "crossbuild-essential-#{plat.get_architecture}",
    'debhelper',
    'devscripts',
    'fakeroot',
    "libc6-dev:#{plat.get_architecture}",
    # The middle component should match the GCC version.
    "libstdc++-8-dev:#{plat.get_architecture}",
    "libbz2-dev:#{plat.get_architecture}",
    "libffi-dev:#{plat.get_architecture}",
    "libreadline-dev:#{plat.get_architecture}",
    "libselinux1-dev:#{plat.get_architecture}",
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
    "libyaml-cpp-dev:#{plat.get_architecture}",
    'make',
    'openjdk-11-jdk-headless',
    'pkg-config',
    'qemu-user-static',
    'quilt',
    'rsync',
    'swig',
    "zlib1g-dev:#{plat.get_architecture}",
  ]
  plat.provision_with "export DEBIAN_FRONTEND=noninteractive; apt-get update -qq; apt-get install -qy --no-install-recommends #{packages.join(' ')}"

  plat.setting :use_pl_build_tools, false
  plat.setting :cc, "#{_platform.platform_triple}-gcc"
  plat.setting :cxx, "#{_platform.platform_triple}-g++"

  # CMake configuration
  # Allow the CMake search path for cross-compiled libraries to be extended
  # by passing -DCMAKE_FIND_ROOT_PATH when running cmake.
  plat.provision_with "sed -i 's/SET (CMAKE_FIND_ROOT_PATH/list (INSERT CMAKE_FIND_ROOT_PATH 0/' /etc/dpkg-cross/cmake/CMakeCross.txt"
  plat.setting :cmake_toolchain, "-DCMAKE_TOOLCHAIN_FILE=/etc/dpkg-cross/cmake/CMakeCross.txt -DCMAKE_FIND_ROOT_PATH='/opt/puppetlabs/puppet;/usr'"
  plat.environment 'DEB_HOST_ARCH', _platform.architecture
  plat.environment 'DEB_HOST_GNU_TYPE', _platform.platform_triple


  plat.vmpooler_template 'debian-10-x86_64'

  plat.docker_image ENV.fetch('VANAGON_DOCKER_IMAGE', 'debian:10-slim')
  # Vanagon starts detached containers, adding `--tty` and using a shell as
  # the entry point causes the container to persist for other commands to run.
  plat.docker_run_args ['--tty', '--entrypoint=/bin/sh']
  plat.use_docker_exec true
end
