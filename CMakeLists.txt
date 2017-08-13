cmake_minimum_required(VERSION 3.7)
project(valence_server)

add_custom_target(valence_server
        COMMAND /usr/bin/swift build
        WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}
        SOURCES Sources
        .build/checkouts/vapor.git--4558353409971932234/Sources
        .build/checkouts/fluent-provider.git-5260370552942322081/Sources
        .build/checkouts/node.git--8201290811699525911/Sources
        .build/checkouts/engine.git--2531510256373420/Sources
        .build/checkouts/core.git-6872224045443563605/Sources
        .build/checkouts/routing.git--3680016705356462756/Sources
        .build/checkouts/Regex.git--5629299300102126860/Sources
        .build/checkouts/json.git-2428229160783412772/Sources
        .build/checkouts/bits.git-6439006344406123066/Sources
        )
