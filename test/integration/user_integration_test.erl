-module(user_integration_test).


-compile(export_all).

% Include etest's assertion macros.
-include_lib("etest/include/etest.hrl").
% etest_http macros
-include_lib ("etest_http/include/etest_http.hrl").

-define(BASE_URL, "http://localhost:9090/").

before_suite() ->
    application:ensure_all_started(scio).

before_test() ->
    scio_session_store:flush(),
    scio_sql:flush_db().

after_suite() ->
    application:stop(scio).


% Helper for creating new users
create_user() ->
    Url     = ?BASE_URL ++ "/users/",
    Headers = [{"content-type", "application/json"}],
    Params  = #{
        <<"username">> => <<"Peter">>,
        <<"email">>    => <<"foo@bar.com">>,
        <<"password">> => <<"dreimalraten">>
    },
    Json = jiffy:encode(Params),

    ?perform_post(Url, Headers, Json, []).


test_signup_page() ->
    Url = ?BASE_URL ++ "/users/new",
    Res = ?perform_get(Url),

    ?assert_status(200, Res).


test_submitting_valid_form_should_create_user() ->
    Url     = ?BASE_URL ++ "/users/",
    Headers = [{"content-type", "application/json"}],
    Params  = #{
        <<"username">> => <<"Peter">>,
        <<"email">>    => <<"foo@bar.com">>,
        <<"password">> => <<"dreimalraten">>
    },
    Json = jiffy:encode(Params),

    Res = ?perform_post(Url, Headers, Json, []),

    ?assert_header("location", Res),
    ?assert_header_value("location", "/", Res),
    ?assert_status(303, Res),

    ?assert_equal({ok, 1}, scio_user:count()).


test_log_in_page() ->
    Url = ?BASE_URL ++ "/sessions/new",
    Res = ?perform_get(Url),

    ?assert_status(200, Res).


test_successful_log_in() ->
    create_user(),

    Url     = ?BASE_URL ++ "/sessions",
    Headers = [{"content-type", "application/json"}],
    Params  = #{
        <<"email">>    => <<"foo@bar.com">>,
        <<"password">> => <<"dreimalraten">>
    },

    Json = jiffy:encode(Params),

    Res  = ?perform_post(Url, Headers, Json, []),

    ?assert_header("set-cookie", Res),

    ?assert_header("location", Res),
    ?assert_header_value("location", "/", Res),
    ?assert_status(201, Res),
    ?assert_equal({ok, 1}, scio_session_store:count()).


test_unsuccessful_log_in_with_wrong_password() ->
    create_user(),

    Url     = ?BASE_URL ++ "/sessions",
    Headers = [{"content-type", "application/json"}],
    Params  = #{
        <<"email">>    => <<"foo@bar.com">>,
        <<"password">> => <<"wrongpassword">>
    },

    Json = jiffy:encode(Params),

    Res  = ?perform_post(Url, Headers, Json, []),

    ?assert_status(403, Res),
    ?assert_equal({ok, 0}, scio_session_store:count()).

test_unsuccessful_log_in_with_wrong_email() ->
    create_user(),

    Url     = ?BASE_URL ++ "/sessions",
    Headers = [{"content-type", "application/json"}],
    Params  = #{
        <<"email">>    => <<"foo@wrong.com">>,
        <<"password">> => <<"dreimalraten">>
    },

    Json = jiffy:encode(Params),

    Res  = ?perform_post(Url, Headers, Json, []),

    ?assert_status(403, Res),
    ?assert_equal({ok, 0}, scio_session_store:count()).