add_library(md4c STATIC md4c.c md4c-html.c entity.c)
target_include_directories(md4c PUBLIC ${CMAKE_CURRENT_SOURCE_DIR})
