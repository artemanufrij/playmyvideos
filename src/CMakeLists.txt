set (CONFIG_FILE ${CMAKE_CURRENT_BINARY_DIR}/Config.vala)
configure_file (${CMAKE_SOURCE_DIR}/Config.vala.cmake ${CONFIG_FILE})

vala_precompile (VALA_C ${CMAKE_PROJECT_NAME}
    Objects/Box.vala
    Objects/Video.vala
    Services/DataBaseManager.vala
    Services/LocalFilesManager.vala
    Services/LibraryManager.vala
    Interfaces/Thubnailer.vala
    Widgets/Box.vala
    Widgets/SubTitleRow.vala
    Widgets/Video.vala
    Widgets/Playlist.vala
    Widgets/VideoTimeLine.vala
    Widgets/Views/Welcome.vala
    Widgets/Views/BoxesView.vala
    Widgets/Views/BoxView.vala
    Widgets/Views/PlayerView.vala
    Utils/Utils.vala
    Utils/Pixbuf.vala
    Settings.vala
    MainWindow.vala
    Application.vala
PACKAGES
    granite
    gtk+-3.0
    sqlite3
    clutter-gtk-1.0
    clutter-gst-3.0
OPTIONS
    --vapidir=${CMAKE_SOURCE_DIR}/vapi
    --target-glib=2.32
    --thread
)

add_executable (${CMAKE_PROJECT_NAME} ${VALA_C})
target_link_libraries (${CMAKE_PROJECT_NAME} ${DEPS_LIBRARIES})

# Installation
install (TARGETS ${CMAKE_PROJECT_NAME} RUNTIME DESTINATION ${CMAKE_INSTALL_FULL_BINDIR})
