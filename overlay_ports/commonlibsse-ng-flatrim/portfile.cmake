# Aventura RP - CommonLibSSE-NG port for Skyrim 1.7.104.
# v7.5.4 supports Skyrim 1.7.x runtime classification and Address Library v5.

vcpkg_from_git(
    OUT_SOURCE_PATH SOURCE_PATH
    URL https://github.com/alandtse/CommonLibSSE-NG.git
    REF c5424463bba9af0d75cde8640ba7ddd4cacb9e39
)

include("${CMAKE_CURRENT_LIST_DIR}/patch_source.cmake")

vcpkg_cmake_configure(
    SOURCE_PATH "${SOURCE_PATH}"
    OPTIONS
      -DENABLE_SKYRIM_SE=ON
      -DENABLE_SKYRIM_AE=ON
      -DENABLE_SKYRIM_VR=OFF
      -DBUILD_TESTS=OFF
      -DSKSE_SUPPORT_XBYAK=ON
      -DSKSE_SUPPORT_PATCH_SAFETY=OFF
      -DCOMMONLIB_ENABLE_IPO=OFF
)

vcpkg_cmake_install()
vcpkg_cmake_config_fixup(PACKAGE_NAME CommonLibSSE CONFIG_PATH lib/cmake/CommonLibSSE)
vcpkg_copy_pdbs()

file(REMOVE_RECURSE "${CURRENT_PACKAGES_DIR}/debug/include")
file(REMOVE_RECURSE "${CURRENT_PACKAGES_DIR}/debug/share")

file(
    INSTALL "${SOURCE_PATH}/LICENSE"
    DESTINATION "${CURRENT_PACKAGES_DIR}/share/${PORT}"
    RENAME copyright
)
