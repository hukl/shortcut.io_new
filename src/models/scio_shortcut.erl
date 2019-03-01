-module(scio_shortcut).

-export([
    count/0,
    create/1,
    find_all_by_user_id/1
]).

-include("scio.hrl").

-spec create(#{ bitstring() => bitstring() }) -> {'ok', #shortcut{}} | {'error', tuple()}.
create(#{
    <<"url">>         := Url,
    <<"title">>       := Title,
    <<"description">> := Description,
    <<"user_id">>     := UserId} = _Params) ->

    Query = "INSERT INTO shortcuts "
             "    (url, title, description, user_id) "
             "VALUES  "
             "    ($1, $2, $3, $4) "
             "RETURNING id, url, title, description, user_id, screenshot_id, created_at, updated_at;",

    case scio_sql:equery(pg, Query, [Url, Title, Description, UserId]) of
        {ok, _Count, _Colums, [{Id, Url, Title, Description, UserId, ScreenshotId, CreatedAt, UpdatedAt}]}->

            Shortcut = #shortcut{
                id              = Id,
                url             = Url,
                title           = Title,
                description     = Description,
                user_id         = UserId,
                screenshot_id   = ScreenshotId,
                created_at      = CreatedAt,
                updated_at      = UpdatedAt
            },

            {ok, Shortcut};
        {error, Error} -> 
            {error, Error}
    end.

-spec find_all_by_user_id(integer()) -> {'ok', []} | {'ok', [#shortcut{}]}.
find_all_by_user_id(UserId) ->
    Query = "SELECT * "
            "FROM shortcuts "
            "WHERE user_id = $1 "
            "ORDER BY created_at DESC "
            "LIMIT 25;",

    {ok, _Colums, Rows} = scio_sql:equery(pg, Query, [UserId]),

    MapFun = fun({Id, Url, Title, Description, UserId, ScreenshotId, CreatedAt, UpdatedAt}) ->
        #shortcut{
            id              = Id,
            url             = Url,
            title           = Title,
            description     = Description,
            user_id         = UserId,
            screenshot_id   = ScreenshotId,
            created_at      = CreatedAt,
            updated_at      = UpdatedAt
        }
    end,

    {ok, lists:map(MapFun, Rows)}.


-spec count() -> {'ok', integer()} | {'error', tuple()}.
count() ->
    Query = "SELECT count(id) FROM shortcuts;",

    case scio_sql:equery(pg, Query, []) of
        {ok, _Colums, Rows} ->
            [Count] = [Row || {Row} <- Rows],
            {ok, Count};
        {error, Error} ->
            {error, Error}
    end.
